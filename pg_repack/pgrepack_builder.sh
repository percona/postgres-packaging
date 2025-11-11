#!/usr/bin/env bash
set -x
# Versions and other variables
source versions.sh "pg_repack"
# Common functions
source common-functions.sh

get_sources(){
    cd "${WORKDIR}"
    if [ "${SOURCE}" = 0 ]
    then
        echo "Sources will not be downloaded"
        return 0
    fi

    echo "PRODUCT=${PG_REPACK_PRODUCT}" > pg_repack.properties
    echo "PRODUCT_FULL=${PG_REPACK_PRODUCT_FULL}" >> pg_repack.properties
    echo "VERSION=${PSM_VER}" >> pg_repack.properties
    echo "BUILD_NUMBER=${BUILD_NUMBER}" >> pg_repack.properties
    echo "BUILD_ID=${BUILD_ID}" >> pg_repack.properties

    git clone "$PG_REPACK_SRC_REPO" ${PG_REPACK_PRODUCT_FULL}
    retval=$?
    if [ $retval != 0 ]
    then
        echo "There were some issues during repo cloning from github. Please retry one more time"
        exit 1
    fi
    cd ${PG_REPACK_PRODUCT_FULL}
    if [ ! -z "$PG_REPACK_SRC_BRANCH" ]
    then
        git reset --hard
        git clean -xdf
        git checkout "$PG_REPACK_SRC_BRANCH"
    fi
    REVISION=$(git rev-parse --short HEAD)
    echo "REVISION=${REVISION}" >> ${WORKDIR}/pg_repack.properties
    rm -fr debian rpm
    git clone ${PG_REPACK_SRC_REPO_DEB} deb_packaging
    cd deb_packaging
      git checkout -b percona-pg_repack debian/${PG_REPACK_VERSION}-${PG_REPACK_RELEASE}
    cd ../
    mv deb_packaging/debian ./
    wget ${PKG_RAW_URL}/pg_repack/Makefile.patch
    wget ${PKG_RAW_URL}/pg_repack/rules
    wget ${PKG_RAW_URL}/pg_repack/control
    wget ${PKG_RAW_URL}/pg_repack/control.in
    sed -i "s/@@PGMAJOR@@/${PG_MAJOR}/g" control control.in rules
    sed -i "s/@@PGVERSION@@/${PG_VERSION}/g" control control.in
    patch -p0 < Makefile.patch
    rm -rf Makefile.patch
    cd debian
    mv ../rules ./
    mv ../control ./
    mv ../control.in ./
    cd ../
    echo $PG_MAJOR > debian/pgversions
    echo 10 > debian/compat
    rm -rf deb_packaging
    mkdir rpm
    cd rpm
    wget ${PKG_RAW_URL}/pg_repack/pg_repack.spec
    wget ${PKG_RAW_URL}/pg_repack/pg_repack-pg$PG_MAJOR-makefile-pgxs.patch
    cd ../
    wget ${PKG_RAW_URL}/pg_repack/make.patch
    patch -p0 < make.patch
    rm -f make.patch
    cd ${WORKDIR}
    #
    source pg_repack.properties
    #

    tar --owner=0 --group=0 --exclude=.* -czf ${PG_REPACK_PRODUCT_FULL}.tar.gz ${PG_REPACK_PRODUCT_FULL}
    DATE_TIMESTAMP=$(date +%F_%H-%M-%S)
    echo "UPLOAD=UPLOAD/experimental/BUILDS/${PG_REPACK_PRODUCT}/${PG_REPACK_PRODUCT_FULL}/${PG_REPACK_SRC_BRANCH}/${REVISION}/${DATE_TIMESTAMP}/${BUILD_ID}" >> pg_repack.properties
    mkdir $WORKDIR/source_tarball
    mkdir $CURDIR/source_tarball
    cp ${PG_REPACK_PRODUCT_FULL}.tar.gz $WORKDIR/source_tarball
    cp ${PG_REPACK_PRODUCT_FULL}.tar.gz $CURDIR/source_tarball
    cd $CURDIR
    rm -rf percona-pg_repack*
    return
}

get_deb_sources(){
    param=$1
    echo $param
    FILE=$(basename $(find $WORKDIR/source_deb -name "*repack*.$param" | sort | tail -n1))
    if [ -z $FILE ]
    then
        FILE=$(basename $(find $CURDIR/source_deb -name "*repack*.$param" | sort | tail -n1))
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
    get_tar "source_tarball" "percona-pg_repack"
    rm -fr rpmbuild
    ls | grep -v tar.gz | xargs rm -rf
    TARFILE=$(find . -name '*repack*.tar.gz' | sort | tail -n1)
    SRC_DIR=${TARFILE%.tar.gz}
    #
    mkdir -vp rpmbuild/{SOURCES,SPECS,BUILD,SRPMS,RPMS}
    tar vxzf ${WORKDIR}/${TARFILE} --wildcards '*/rpm' --strip=1
    #
    cp -av rpm/* rpmbuild/SOURCES
    cp -av rpm/pg_repack.spec rpmbuild/SPECS
    #
    mv -fv ${TARFILE} ${WORKDIR}/rpmbuild/SOURCES
    rpmbuild -bs \
        --define "_topdir ${WORKDIR}/rpmbuild" \
        --define "dist .generic" \
        --define "pgmajor ${PG_MAJOR}" \
        --define "version ${PG_REPACK_VERSION}" \
        --define "release ${PG_REPACK_RELEASE}" \
        rpmbuild/SPECS/pg_repack.spec
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
    SRC_RPM=$(basename $(find $WORKDIR/srpm -name '*repack*.src.rpm' | sort | tail -n1))
    if [ -z $SRC_RPM ]
    then
        SRC_RPM=$(basename $(find $CURDIR/srpm -name '*repack*.src.rpm' | sort | tail -n1))
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
    mkdir -vp rpmbuild/{SOURCES,SPECS,BUILD,SRPMS,RPMS,BUILDROOT}
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
        --define "version ${PG_REPACK_VERSION}" \
        --define "release ${PG_REPACK_RELEASE}" \
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
    rm -rf percona-pg_repack*
    get_tar "source_tarball" "percona-pg_repack"
    rm -f *.dsc *.orig.tar.gz *.debian.tar.gz *.changes
    #
    TARFILE=$(basename $(find . -name '*repack*.tar.gz' | sort | tail -n1))
    DEBIAN=$(lsb_release -sc)
    ARCH=$(echo $(uname -m) | sed -e 's:i686:i386:g')
    tar zxf ${TARFILE}
    BUILDDIR=${TARFILE%.tar.gz}
    #
    
    mv ${TARFILE} ${PG_REPACK_PRODUCT_DEB}_${PG_REPACK_VERSION}.orig.tar.gz
    cd ${BUILDDIR}

    cd debian
    rm -rf changelog
    echo "percona-pg-repack (${PG_REPACK_VERSION}-${PG_REPACK_RELEASE}) unstable; urgency=low" >> changelog
    echo "  * Initial Release." >> changelog
    echo " -- EvgeniyPatlan <evgeniy.patlan@percona.com>  $(date -R)" >> changelog

    cd ../
    
    dch -D unstable --force-distribution -v "${PG_REPACK_VERSION}-${PG_REPACK_RELEASE}" "Update to new version ${PG_REPACK_VERSION}"
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
    echo "DEBIAN=${DEBIAN}" >> pg_repack.properties
    echo "ARCH=${ARCH}" >> pg_repack.properties

    #
    DSC=$(basename $(find . -name '*.dsc' | sort | tail -n1))
    #
    dpkg-source -x ${DSC}
    #
    cd ${PG_REPACK_PRODUCT_DEB}-${PG_REPACK_VERSION}
    dch -m -D "${DEBIAN}" --force-distribution -v "1:${PG_REPACK_VERSION}-${PG_REPACK_RELEASE}.${DEBIAN}" 'Update distribution'
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
VERSION_FILE=$CURDIR/pg_repack.properties
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
    source install-deps.sh "pg_repack"
fi
get_sources
build_srpm
build_source_deb
build_rpm
build_deb
