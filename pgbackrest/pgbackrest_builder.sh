#!/usr/bin/env bash
set -x
# Versions and other variables
source versions.sh "pgbackrest"
# Common functions
source common-functions.sh

get_sources(){
    cd "${WORKDIR}"
    if [ "${SOURCE}" = 0 ]
    then
        echo "Sources will not be downloaded"
        return 0
    fi

    echo "PRODUCT=${PG_BCKREST_PRODUCT}" > pgbackrest.properties
    echo "PRODUCT_FULL=${PG_BCKREST_PRODUCT_FULL}" >> pgbackrest.properties
    echo "VERSION=${PSM_VER}" >> pgbackrest.properties
    echo "BUILD_NUMBER=${BUILD_NUMBER}" >> pgbackrest.properties
    echo "BUILD_ID=${BUILD_ID}" >> pgbackrest.properties

    git clone "$PG_BCKREST_SRC_REPO" ${PG_BCKREST_PRODUCT_FULL}
    retval=$?
    if [ $retval != 0 ]
    then
        echo "There were some issues during repo cloning from github. Please retry one more time"
        exit 1
    fi
    cd ${PG_BCKREST_PRODUCT_FULL}
    if [ ! -z "$PG_BCKREST_SRC_BRANCH" ]
    then
        git reset --hard
        git clean -xdf
        git checkout "$PG_BCKREST_SRC_BRANCH"
    fi
    REVISION=$(git rev-parse --short HEAD)
    echo "REVISION=${REVISION}" >> ${WORKDIR}/pgbackrest.properties
    rm -fr debian rpm

    GIT_SSL_NO_VERIFY=true git clone ${PG_BCKREST_SRC_REPO_DEB} deb_packaging
    cd deb_packaging
    git checkout ${PG_BCKREST_DEB_TAG}
    cd -

    mv deb_packaging/debian ./
    cd debian/
    for file in $(ls | grep ^pgbackrest | grep -v pgbackrest.conf); do
        mv $file "percona-$file"
    done
    rm -f control
    wget ${PKG_RAW_URL}/pgbackrest/control
    wget ${PKG_RAW_URL}/pgbackrest/compat
    wget ${PKG_RAW_URL}/pgbackrest/rules.patch
    patch -p0 < rules.patch
    rm rules.patch
    cd ../
    sed -i "s|Upstream-Name: pgbackrest|Upstream-Name: percona-pgbackrest|" debian/copyright
    sed -i 's:debian/pgbackrest:debian/percona-pgbackrest:' debian/rules
    rm -rf deb_packaging
    mkdir rpm
    cd rpm
    wget ${PKG_RAW_URL}/pgbackrest/pgbackrest.spec
    wget ${PKG_RAW_URL}/pgbackrest/pgbackrest.service
    wget ${PKG_RAW_URL}/pgbackrest/pgbackrest.logrotate
    wget ${PKG_RAW_URL}/pgbackrest/pgbackrest-tmpfiles.d
    wget ${PKG_RAW_URL}/pgbackrest/pgbackrest.conf
    cd ${WORKDIR}
    #
    source pgbackrest.properties
    #

    tar --owner=0 --group=0 --exclude=.* -czf ${PG_BCKREST_PRODUCT_FULL}.tar.gz ${PG_BCKREST_PRODUCT_FULL}
    DATE_TIMESTAMP=$(date +%F_%H-%M-%S)
    echo "UPLOAD=UPLOAD/experimental/BUILDS/${PG_BCKREST_PRODUCT}/${PG_BCKREST_PRODUCT_FULL}/${PSM_BRANCH}/${REVISION}/${DATE_TIMESTAMP}/${BUILD_ID}" >> pgbackrest.properties
    mkdir $WORKDIR/source_tarball
    mkdir $CURDIR/source_tarball
    cp ${PG_BCKREST_PRODUCT_FULL}.tar.gz $WORKDIR/source_tarball
    cp ${PG_BCKREST_PRODUCT_FULL}.tar.gz $CURDIR/source_tarball
    cd $CURDIR
    rm -rf percona-pgbackrest*
    return
}

get_deb_sources(){
    param=$1
    echo $param
    FILE=$(basename $(find $WORKDIR/source_deb -name "percona-pgbackrest*.$param" | sort | tail -n1))
    if [ -z $FILE ]
    then
        FILE=$(basename $(find $CURDIR/source_deb -name "percona-pgbackrest*.$param" | sort | tail -n1))
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
    get_tar "source_tarball" "percona-pgbackrest"
    rm -fr rpmbuild
    ls | grep -v tar.gz | xargs rm -rf
    TARFILE=$(find . -name 'percona-pgbackrest*.tar.gz' | sort | tail -n1)
    SRC_DIR=${TARFILE%.tar.gz}
    #
    mkdir -vp rpmbuild/{SOURCES,SPECS,BUILD,SRPMS,RPMS}
    tar vxzf ${WORKDIR}/${TARFILE} --wildcards '*/rpm' --strip=1
    #
    cp -av rpm/* rpmbuild/SOURCES
    cp -av rpm/pgbackrest.spec rpmbuild/SPECS
    #
    mv -fv ${TARFILE} ${WORKDIR}/rpmbuild/SOURCES
    rpmbuild -bs \
        --define "_topdir ${WORKDIR}/rpmbuild" \
        --define "pginstdir /usr/pgsql-$PG_MAJOR" \
        --define "dist .generic" \
        --define "pgmajor ${PG_MAJOR}" \
        --define "version ${PG_BCKREST_VERSION}" \
        --define "release ${PG_BCKREST_RELEASE}" \
        rpmbuild/SPECS/pgbackrest.spec
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
    SRC_RPM=$(basename $(find $WORKDIR/srpm -name 'percona-pgbackrest*.src.rpm' | sort | tail -n1))
    if [ -z $SRC_RPM ]
    then
        SRC_RPM=$(basename $(find $CURDIR/srpm -name 'percona-pgbackrest*.src.rpm' | sort | tail -n1))
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
    export LIBPQ_DIR=/usr/pgsql-${PG_MAJOR}/
    export LIBRARY_PATH=/usr/pgsql-${PG_MAJOR}/lib/:/usr/pgsql-${PG_MAJOR}/include/
    rpmbuild \
        --define "_topdir ${WORKDIR}/rpmbuild" \
        --define "pginstdir /usr/pgsql-$PG_MAJOR" \
        --define "dist .$OS_NAME" \
        --define "pgmajor ${PG_MAJOR}" \
        --define "version ${PG_BCKREST_VERSION}" \
        --define "release ${PG_BCKREST_RELEASE}" \
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
    rm -rf percona-pgbackrest*
    get_tar "source_tarball" "percona-pgbackrest"
    rm -f *.dsc *.orig.tar.gz *.debian.tar.gz *.changes
    #
    TARFILE=$(basename $(find . -name 'percona-pgbackrest*.tar.gz' | sort | tail -n1))
    DEBIAN=$(lsb_release -sc)
    ARCH=$(echo $(uname -m) | sed -e 's:i686:i386:g')
    tar zxf ${TARFILE}
    BUILDDIR=${TARFILE%.tar.gz}
    #
    
    mv ${TARFILE} ${PG_BCKREST_PRODUCT}_${PG_BCKREST_VERSION}.orig.tar.gz
    cd ${BUILDDIR}

    cd debian
    rm -rf changelog
    echo "percona-pgbackrest (${PG_BCKREST_VERSION}-${PG_BCKREST_RELEASE}) unstable; urgency=low" >> changelog
    echo >> changelog
    echo "  * Initial Release." >> changelog
    echo >> changelog
    echo " -- EvgeniyPatlan <evgeniy.patlan@percona.com>  $(date -R)" >> changelog

    cd ../
    
    dch -D unstable --force-distribution -v "${PG_BCKREST_VERSION}-${PG_BCKREST_RELEASE}" "Update to new pgbackrest version ${PG_BCKREST_VERSION}"
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
    echo "DEBIAN=${DEBIAN}" >> pgbackrest.properties
    echo "ARCH=${ARCH}" >> pgbackrest.properties

    #
    DSC=$(basename $(find . -name '*.dsc' | sort | tail -n1))
    #
    dpkg-source -x ${DSC}
    #
    cd ${PG_BCKREST_PRODUCT_FULL}
    dch -m -D "${DEBIAN}" --force-distribution -v "1:${PG_BCKREST_VERSION}-${PG_BCKREST_RELEASE}.${DEBIAN}" 'Update distribution'
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
VERSION_FILE=$CURDIR/pgbackrest.properties
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
    source install-deps.sh "pgbackrest"
fi
get_sources
build_srpm
build_source_deb
build_rpm
build_deb
