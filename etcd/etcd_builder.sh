#!/usr/bin/env bash
set -x
# Versions and other variables
source versions.sh "etcd"
# Common functions
source common-functions.sh

get_sources(){
    cd "${WORKDIR}"
    if [ "${SOURCE}" = 0 ]
    then
        echo "Sources will not be downloaded"
        return 0
    fi

    echo "PRODUCT=${ETCD_PRODUCT}" > etcd.properties
    echo "PRODUCT_FULL=${ETCD_PRODUCT_FULL}" >> etcd.properties
    echo "VERSION=${PSM_VER}" >> etcd.properties
    echo "BUILD_NUMBER=${BUILD_NUMBER}" >> etcd.properties
    echo "BUILD_ID=${BUILD_ID}" >> etcd.properties

    ARCH=$(uname -m)
    if [ "$ARCH" = "x86_64" ]; then
        ARCH="amd64"
    elif [ "$ARCH" = "aarch64" ]; then
        ARCH="arm64"
    fi

    wget ${ETCD_SRC_REPO}/etcd-v${ETCD_VERSION}-linux-${ARCH}.tar.gz
    tar -xvzf etcd-v${ETCD_VERSION}-linux-${ARCH}.tar.gz
    mkdir -p ${ETCD_PRODUCT_FULL}
    cp -rp etcd-v${ETCD_VERSION}-linux-${ARCH}/* ${ETCD_PRODUCT_FULL}
    cd ${ETCD_PRODUCT_FULL}
    rm -fr debian rpm

    git clone ${ETCD_SRC_REPO_DEB} deb_packaging
    mv deb_packaging/deb ./debian
    cd debian/
    rm -f etcd-server.install etcd-client.install rules
    wget ${PKG_RAW_URL}/etcd/etcd-server.install
    wget ${PKG_RAW_URL}/etcd/rules
    wget ${PKG_RAW_URL}/etcd/etcd-client.install
    wget ${PKG_RAW_URL}/etcd/etcd.service
    wget ${PKG_RAW_URL}/etcd/etcd.conf.yaml
    mv etcd.conf.yaml ../

    rm -f etcd-server.etcd.service
    mv etcd.service etcd-server.etcd.service 
    rm -rf man
    echo 10 > compat
    cd ../
    rm -rf deb_packaging

    mkdir rpm
    cd rpm
    wget ${PKG_RAW_URL}/etcd/etcd.spec
    wget ${PKG_RAW_URL}/etcd/etcd.service
    wget ${PKG_RAW_URL}/etcd/etcd.conf.yaml
    cd ${WORKDIR}
    #
    source etcd.properties
    #

    tar --owner=0 --group=0 --exclude=.* -czf ${ETCD_PRODUCT_FULL}.tar.gz ${ETCD_PRODUCT_FULL}
    DATE_TIMESTAMP=$(date +%F_%H-%M-%S)
    echo "UPLOAD=UPLOAD/experimental/BUILDS/${ETCD_PRODUCT}/${ETCD_PRODUCT_FULL}/${PSM_BRANCH}/${REVISION}/${DATE_TIMESTAMP}/${BUILD_ID}" >> etcd.properties
    mkdir $WORKDIR/source_tarball
    mkdir $CURDIR/source_tarball
    cp ${ETCD_PRODUCT_FULL}.tar.gz $WORKDIR/source_tarball
    cp ${ETCD_PRODUCT_FULL}.tar.gz $CURDIR/source_tarball
    cd $CURDIR
    #rm -rf etcd*
    return
}

get_deb_sources(){
    param=$1
    echo $param
    FILE=$(basename $(find $WORKDIR/source_deb -name "etcd*.$param" | sort | tail -n1))
    if [ -z $FILE ]
    then
        FILE=$(basename $(find $CURDIR/source_deb -name "etcd*.$param" | sort | tail -n1))
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
    get_tar "source_tarball" "etcd"
    rm -fr rpmbuild
    #ls | grep -v tar.gz | xargs rm -rf
    TARFILE=$(find . -name 'etcd*.tar.gz' | sort | tail -n1)
    SRC_DIR=${TARFILE%.tar.gz}
    #
    mkdir -vp rpmbuild/{SOURCES,SPECS,BUILD,SRPMS,RPMS}
    tar vxzf ${WORKDIR}/${TARFILE} --wildcards '*/rpm' --strip=1
    #
    pwd
    cp -av rpm/* rpmbuild/SOURCES
    cp -av rpm/etcd.spec rpmbuild/SPECS
    #
    mv -fv ${TARFILE} ${WORKDIR}/rpmbuild/SOURCES
    rpmbuild -bs --define "_topdir ${WORKDIR}/rpmbuild" --define "dist .generic" \
        --define "version ${ETCD_VERSION}" rpmbuild/SPECS/etcd.spec
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
    SRC_RPM=$(basename $(find $WORKDIR/srpm -name 'etcd*.src.rpm' | sort | tail -n1))
    if [ -z $SRC_RPM ]
    then
        SRC_RPM=$(basename $(find $CURDIR/srpm -name 'etcd*.src.rpm' | sort | tail -n1))
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
    rpmbuild --define "_topdir ${WORKDIR}/rpmbuild" --define "pginstdir /usr/pgsql-$PG_MAJOR" --define "dist .$OS_NAME" --define "version ${ETCD_VERSION}" --rebuild rpmbuild/SRPMS/$SRC_RPM

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
    rm -rf etcd*
    get_tar "source_tarball" "etcd"
    rm -f *.dsc *.orig.tar.gz *.debian.tar.gz *.changes
    #
    TARFILE=$(basename $(find . -name 'etcd*.tar.gz' | sort | tail -n1))
    DEBIAN=$(lsb_release -sc)
    ARCH=$(echo $(uname -m) | sed -e 's:i686:i386:g')
    tar zxf ${TARFILE}
    BUILDDIR=${TARFILE%.tar.gz}
    #
    
    mv ${TARFILE} ${ETCD_PRODUCT}_${ETCD_VERSION}.orig.tar.gz
    cd ${BUILDDIR}

    cd debian
    rm -rf changelog
    echo "etcd (${ETCD_VERSION}-${ETCD_RELEASE}) unstable; urgency=low" >> changelog
    echo "  * Initial Release." >> changelog
    echo " -- EvgeniyPatlan <evgeniy.patlan@percona.com> $(date -R)" >> changelog

    cd ../
    
    dch -D unstable --force-distribution -v "${ETCD_VERSION}-${ETCD_RELEASE}" "Update to new etcd version ${ETCD_VERSION}"
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
    echo "DEBIAN=${DEBIAN}" >> etcd.properties
    echo "ARCH=${ARCH}" >> etcd.properties

    #
    DSC=$(basename $(find . -name '*.dsc' | sort | tail -n1))
    #
    dpkg-source -x ${DSC}
    #
    cd ${ETCD_PRODUCT_FULL}
    dch -m -D "${DEBIAN}" --force-distribution -v "1:${ETCD_VERSION}-${ETCD_RELEASE}.${DEBIAN}" 'Update distribution'
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
VERSION_FILE=$CURDIR/etcd.properties
args=
WORKDIR=
SRPM=0
SDEB=0
RPM=0
DEB=0
SOURCE=0
OS_NAME=
ARCH=
OS=
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
    source install-deps.sh "etcd"
fi
get_sources
build_srpm
build_source_deb
build_rpm
build_deb
