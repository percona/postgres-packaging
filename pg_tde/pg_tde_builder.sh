#!/usr/bin/env bash
set -x
# Versions and other variables
source versions.sh "pg_tde"
# Common functions
source common-functions.sh

get_sources(){
    cd "${WORKDIR}"
    if [ "${SOURCE}" = 0 ]
    then
        echo "Sources will not be downloaded"
        return 0
    fi

    echo "PRODUCT=${PG_TDE_PRODUCT}" > pg_tde.properties
    echo "PRODUCT_FULL=${PG_TDE_PRODUCT_FULL}" >> pg_tde.properties
    echo "VERSION=${PG_TDE_VERSION}" >> pg_tde.properties
    echo "BUILD_NUMBER=${BUILD_NUMBER}" >> pg_tde.properties
    echo "BUILD_ID=${BUILD_ID}" >> pg_tde.properties
    git clone --recursive "$PG_TDE_SRC_REPO" ${PG_TDE_PRODUCT_FULL}
    retval=$?
    if [ $retval != 0 ]
    then
        echo "There were some issues during repo cloning from github. Please retry one more time"
        exit 1
    fi
    cd ${PG_TDE_PRODUCT_FULL}
    if [ ! -z "$PG_TDE_SRC_BRANCH" ]
    then
        git reset --hard
        git clean -xdf
        git checkout "$PG_TDE_SRC_BRANCH"
    fi
    REVISION=$(git rev-parse --short HEAD)
    echo "REVISION=${REVISION}" >> ${WORKDIR}/pg_tde.properties
    rm -fr debian rpm

    #git clone https://salsa.debian.org/postgresql/pg_tde.git deb_packaging
    mkdir debian
    cd debian
    #git checkout debian/${VERSION}-${RELEASE}
    wget ${PKG_RAW_URL}/pg_tde/debian/control
    wget ${PKG_RAW_URL}/pg_tde/debian/control.in
    wget ${PKG_RAW_URL}/pg_tde/debian/rules
    wget ${PKG_RAW_URL}/pg_tde/debian/percona-pg-tde${PG_MAJOR}.install
    wget ${PKG_RAW_URL}/pg_tde/debian/percona-pg-tde${PG_MAJOR}-client.install
    sed -i "s/@@PGMAJOR@@/${PG_MAJOR}/g" control control.in rules percona-pg-tde${PG_MAJOR}.install percona-pg-tde${PG_MAJOR}-client.install
    sudo chmod +x rules
    cd ../

    echo ${PG_MAJOR} > debian/pgversions
    echo 10 > debian/compat
    rm -rf deb_packaging
    mkdir rpm
    cd rpm
    wget ${PKG_RAW_URL}/pg_tde/pg_tde.spec

    cd ${WORKDIR}
    #
    source pg_tde.properties
    #

    tar --owner=0 --group=0 --exclude=.* -czf ${PG_TDE_PRODUCT_FULL}.tar.gz ${PG_TDE_PRODUCT_FULL}
    DATE_TIMESTAMP=$(date +%F_%H-%M-%S)
    echo "UPLOAD=UPLOAD/experimental/BUILDS/${PG_TDE_PRODUCT}/${PG_TDE_PRODUCT_FULL}/${PG_TDE_SRC_BRANCH}/${REVISION}/${DATE_TIMESTAMP}/${BUILD_ID}" >> pg_tde.properties
    mkdir $WORKDIR/source_tarball
    mkdir $CURDIR/source_tarball
    cp ${PG_TDE_PRODUCT_FULL}.tar.gz $WORKDIR/source_tarball
    cp ${PG_TDE_PRODUCT_FULL}.tar.gz $CURDIR/source_tarball
    cd $CURDIR
    return
}

get_deb_sources(){
    param=$1

    FILE=$(basename $(find $WORKDIR/source_deb -name "percona-pg*tde*.$param" | sort | tail -n1))
    if [ -z $FILE ]
    then
        FILE=$(basename $(find $CURDIR/source_deb -name "percona-pg*tde*.$param" | sort | tail -n1))
        if [ -z $FILE ]
        then
            echo "There is no sources for build"
            exit 1
        else
            cp $CURDIR/source_deb/$FILE $WORKDIR/
        fi
    else
        cp $WORKDIR/source_deb/$FILE $WORKDIR/
    fi
    return
}

build_srpm(){
    if [ $SRPM = 0 ]
    then
        echo "SRC RPM will not be created"
        return;
    fi
    if [ "x$OS" = "xdeb" ]
    then
        echo "It is not possible to build src rpm here"
        exit 1
    fi
    cd $WORKDIR
    get_tar "source_tarball" "percona-pg*tde"
    rm -fr rpmbuild
    ls | grep -v tar.gz | xargs rm -rf
    TARFILE=$(find . -name 'percona-pg_tde*.tar.gz' | sort | tail -n1)
    SRC_DIR=${TARFILE%.tar.gz}
    #
    mkdir -vp rpmbuild/{SOURCES,SPECS,BUILD,SRPMS,RPMS}
    tar vxzf ${WORKDIR}/${TARFILE} --wildcards '*/rpm' --strip=1
    #
    cp -av rpm/* rpmbuild/SOURCES
    cp -av rpm/pg_tde.spec rpmbuild/SPECS
    #
    mv -fv ${TARFILE} ${WORKDIR}/rpmbuild/SOURCES
    rpmbuild -bs \
        --define "_topdir ${WORKDIR}/rpmbuild" \
        --define "dist .generic" \
        --define "pgmajor ${PG_MAJOR}" \
        --define "version ${PG_TDE_VERSION}" \
        --define "release ${PG_TDE_RELEASE}" \
        rpmbuild/SPECS/pg_tde.spec
    mkdir -p ${WORKDIR}/srpm
    mkdir -p ${CURDIR}/srpm
    cp rpmbuild/SRPMS/*.src.rpm ${CURDIR}/srpm
    cp rpmbuild/SRPMS/*.src.rpm ${WORKDIR}/srpm
    return
}

build_rpm(){
    if [ $RPM = 0 ]
    then
        echo "RPM will not be created"
        return;
    fi
    if [ "x$OS" = "xdeb" ]
    then
        echo "It is not possible to build rpm here"
        exit 1
    fi
    SRC_RPM=$(basename $(find $WORKDIR/srpm -name 'percona-pg_tde*.src.rpm' | sort | tail -n1))
    if [ -z $SRC_RPM ]
    then
        SRC_RPM=$(basename $(find $CURDIR/srpm -name 'percona-pg_tde*.src.rpm' | sort | tail -n1))
        if [ -z $SRC_RPM ]
        then
            echo "There is no src rpm for build"
            echo "You can create it using key --build_src_rpm=1"
            exit 1
        else
            cp $CURDIR/srpm/$SRC_RPM $WORKDIR
        fi
    else
        cp $WORKDIR/srpm/$SRC_RPM $WORKDIR
    fi
    cd $WORKDIR
    rm -fr rpmbuild
    mkdir -vp rpmbuild/{SOURCES,SPECS,BUILD,SRPMS,RPMS}
    cp $SRC_RPM rpmbuild/SRPMS/

    cd rpmbuild/SRPMS/
    #
    cd $WORKDIR
    RHEL=$(rpm --eval %rhel)
    ARCH=$(echo $(uname -m) | sed -e 's:i686:i386:g')
    if [ -f /opt/rh/devtoolset-7/enable ]; then
        source /opt/rh/devtoolset-7/enable
        source /opt/rh/llvm-toolset-7/enable
    fi

    if [[ "${RHEL}" -eq 10 ]]; then
        export QA_RPATHS=0x0002
    fi
    rpmbuild \
        --define "_topdir ${WORKDIR}/rpmbuild" \
        --define "dist .$OS_NAME" \
        --define "pgmajor ${PG_MAJOR}" \
        --define "version ${PG_TDE_VERSION}" \
        --define "release ${PG_TDE_RELEASE}" \
        --rebuild rpmbuild/SRPMS/$SRC_RPM

    return_code=$?
    if [ $return_code != 0 ]; then
        exit $return_code
    fi
    mkdir -p ${WORKDIR}/rpm
    mkdir -p ${CURDIR}/rpm
    cp rpmbuild/RPMS/*/*.rpm ${WORKDIR}/rpm
    cp rpmbuild/RPMS/*/*.rpm ${CURDIR}/rpm
}

build_source_deb(){
    if [ $SDEB = 0 ]
    then
        echo "source deb package will not be created"
        return;
    fi
    if [ "x$OS" = "xrpm" ]
    then
        echo "It is not possible to build source deb here"
        exit 1
    fi
    rm -rf percona-pg_tde*
    get_tar "source_tarball" "percona-pg*tde"
    rm -f *.dsc *.orig.tar.gz *.debian.tar.gz *.changes
    #
    TARFILE=$(basename $(find . -name 'percona-pg*tde*.tar.gz' | sort | tail -n1))
    DEBIAN=$(lsb_release -sc)
    ARCH=$(echo $(uname -m) | sed -e 's:i686:i386:g')
    tar zxf ${TARFILE}
    BUILDDIR=${TARFILE%.tar.gz}

    mv ${TARFILE} ${PG_TDE_PRODUCT_DEB}_${PG_TDE_VERSION}.orig.tar.gz
    cd ${BUILDDIR}
    rm -f .github/workflows/*.yml
    rm -f .github/workflows/*.yaml
    rm -f .github/*.yml
    rm -rf .github
    find . | grep yml | xargs rm -f
    rm -f documentation/_resource/.icons/percona/logo.svg
    cd debian
    rm -rf changelog
    mkdir -p source
    echo "3.0 (quilt)" > source/format
    echo ${PG_MAJOR} > pgversions
    echo 10 > compat
    echo "${PG_TDE_PRODUCT_DEB} (${PG_TDE_VERSION}-${PG_TDE_RELEASE}) unstable; urgency=low" > changelog
    echo "  * Initial Release." >> changelog
    echo " -- Muhammad Aqeel <muhammad.aqeel@percona.com>  $(date -R)" >> changelog

    cd ../
    
    dch -D unstable --force-distribution -v "${PG_TDE_VERSION}-${PG_TDE_RELEASE}" "Update to new pg-tde version ${PG_TDE_VERSION}"
    pg_buildext updatecontrol
    dpkg-buildpackage -S
    cd ../
    mkdir -p $WORKDIR/source_deb
    mkdir -p $CURDIR/source_deb
    cp *.debian.tar.* $WORKDIR/source_deb
    cp *_source.changes $WORKDIR/source_deb
    cp *.dsc $WORKDIR/source_deb
    cp *.orig.tar.gz $WORKDIR/source_deb
    cp *.debian.tar.* $CURDIR/source_deb
    cp *_source.changes $CURDIR/source_deb
    cp *.dsc $CURDIR/source_deb
    cp *.orig.tar.gz $CURDIR/source_deb
}

build_deb(){
    if [ $DEB = 0 ]
    then
        echo "source deb package will not be created"
        return;
    fi
    if [ "x$OS" = "xrmp" ]
    then
        echo "It is not possible to build source deb here"
        exit 1
    fi
    for file in 'dsc' 'orig.tar.gz' 'changes' 'debian.tar*'
    do
        get_deb_sources $file
    done
    cd $WORKDIR
    rm -fv *.deb
    #
    export DEBIAN=$(lsb_release -sc)
    export ARCH=$(echo $(uname -m) | sed -e 's:i686:i386:g')
    #
    echo "DEBIAN=${DEBIAN}" >> pg_tde.properties
    echo "ARCH=${ARCH}" >> pg_tde.properties

    #
    DSC=$(basename $(find . -name '*.dsc' | sort | tail -n1))
    #
    dpkg-source -x ${DSC}

    cd ${PG_TDE_PRODUCT_DEB}-${PG_TDE_VERSION}
    dch -m -D "${DEBIAN}" --force-distribution -v "1:${PG_TDE_VERSION}-${PG_TDE_RELEASE}.${DEBIAN}" 'Update distribution'
    unset $(locale|cut -d= -f1)
    dpkg-buildpackage -rfakeroot -us -uc -b
    mkdir -p $CURDIR/deb
    mkdir -p $WORKDIR/deb
    cd $WORKDIR/
    for file in $(ls | grep ddeb); do
        mv "$file" "${file%.ddeb}.deb";
    done
    cp $WORKDIR/*.*deb $WORKDIR/deb
    cp $WORKDIR/*.*deb $CURDIR/deb
}
#main

CURDIR=$(pwd)
VERSION_FILE=$CURDIR/pg_tde.properties
args=
WORKDIR=
SRPM=0
SDEB=0
RPM=0
DEB=0
SOURCE=0
INSTALL=0
REVISION=0
DEBUG=0

parse_arguments PICK-ARGS-FROM-ARGV "$@"
check_workdir
get_system
#install_deps
if [ $INSTALL = 0 ]; then
    echo "Dependencies will not be installed"
else
    source install-deps.sh "pg_tde"
fi
get_sources
build_srpm
build_source_deb
build_rpm
build_deb
