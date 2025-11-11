#!/usr/bin/env bash
set -x
# Versions and other variables
source versions.sh "pgvector"
# Common functions
source common-functions.sh

get_sources(){
    cd "${WORKDIR}"
    if [ "${SOURCE}" = 0 ]
    then
        echo "Sources will not be downloaded"
        return 0
    fi

    echo "PRODUCT=${PGVECTOR_PRODUCT}" > pgvector.properties

    echo "PRODUCT_FULL=${PGVECTOR_PRODUCT_FULL}" >> pgvector.properties
    echo "VERSION=${PGVECTOR_VERSION}" >> pgvector.properties
    echo "BUILD_NUMBER=${BUILD_NUMBER}" >> pgvector.properties
    echo "BUILD_ID=${BUILD_ID}" >> pgvector.properties
    git clone "$PGVECTOR_SRC_REPO" ${PGVECTOR_PRODUCT_FULL}
    retval=$?
    if [ $retval != 0 ]
    then
        echo "There were some issues during repo cloning from github. Please retry one more time"
        exit 1
    fi
    cd ${PGVECTOR_PRODUCT_FULL}
    if [ ! -z "$PGVECTOR_SRC_BRANCH" ]
    then
        git reset --hard
        git clean -xdf
        git checkout "$PGVECTOR_SRC_BRANCH"
    fi
    REVISION=$(git rev-parse --short HEAD)
    echo "REVISION=${REVISION}" >> ${WORKDIR}/pgvector.properties
    rm -fr debian rpm

    git clone ${PGVECTOR_SRC_REPO_DEB} deb_packaging
    cd deb_packaging
    git checkout debian/${PGVECTOR_VERSION}-${PGVECTOR_RELEASE}
    cd ../
    mv deb_packaging/debian ./
    wget ${PKG_RAW_URL}/pgvector/control
    wget ${PKG_RAW_URL}/pgvector/control.in
    wget ${PKG_RAW_URL}/pgvector/rules
    sed -i "s/@@PGMAJOR@@/${PG_MAJOR}/g" control control.in

    patch -p1 <debian/patches/no-native
    sed -i 's|no-native|#no-native|g' debian/patches/series

    rm -rf debian/control*
    mv control* debian/
    mv rules debian/
    echo ${PG_MAJOR} > debian/pgversions
    echo 10 > debian/compat
    rm -rf deb_packaging
    mkdir rpm
    cd rpm
    wget ${PKG_RAW_URL}/pgvector/pgvector.spec
    cd ${WORKDIR}
    #
    source pgvector.properties
    #

    tar --owner=0 --group=0 --exclude=.* -czf ${PGVECTOR_PRODUCT_FULL}.tar.gz ${PGVECTOR_PRODUCT_FULL}
    DATE_TIMESTAMP=$(date +%F_%H-%M-%S)
    echo "UPLOAD=UPLOAD/experimental/BUILDS/${PGVECTOR_PRODUCT}/${PGVECTOR_PRODUCT_FULL}/${PGVECTOR_SRC_BRANCH}/${REVISION}/${DATE_TIMESTAMP}/${BUILD_ID}" >> pgvector.properties
    mkdir $WORKDIR/source_tarball
    mkdir $CURDIR/source_tarball
    cp ${PGVECTOR_PRODUCT_FULL}.tar.gz $WORKDIR/source_tarball
    cp ${PGVECTOR_PRODUCT_FULL}.tar.gz $CURDIR/source_tarball
    cd $CURDIR
    rm -rf pgvector*
    return
}

get_deb_sources(){
    param=$1

    FILE=$(basename $(find $WORKDIR/source_deb -name "percona-pgvector*.$param" | sort | tail -n1))
    if [ -z $FILE ]
    then
        FILE=$(basename $(find $CURDIR/source_deb -name "percona-pgvector*.$param" | sort | tail -n1))
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
    get_tar "source_tarball" "percona-pgvector"
    rm -fr rpmbuild
    ls | grep -v tar.gz | xargs rm -rf
    TARFILE=$(find . -name 'percona-pgvector*.tar.gz' | sort | tail -n1)
    SRC_DIR=${TARFILE%.tar.gz}
    #
    mkdir -vp rpmbuild/{SOURCES,SPECS,BUILD,SRPMS,RPMS}
    tar vxzf ${WORKDIR}/${TARFILE} --wildcards '*/rpm' --strip=1
    #
    cp -av rpm/* rpmbuild/SOURCES
    cp -av rpm/pgvector.spec rpmbuild/SPECS
    #
    mv -fv ${TARFILE} ${WORKDIR}/rpmbuild/SOURCES
    rpmbuild -bs \
        --define "_topdir ${WORKDIR}/rpmbuild" \
        --define "dist .generic" \
        --define "pgmajor ${PG_MAJOR}" \
        --define "version ${PGVECTOR_VERSION}" \
        --define "release ${PGVECTOR_RELEASE}" \
        rpmbuild/SPECS/pgvector.spec
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
    SRC_RPM=$(basename $(find $WORKDIR/srpm -name 'percona-pgvector*.src.rpm' | sort | tail -n1))
    if [ -z $SRC_RPM ]
    then
        SRC_RPM=$(basename $(find $CURDIR/srpm -name 'percona-pgvector*.src.rpm' | sort | tail -n1))
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
        --define "version ${PGVECTOR_VERSION}" \
        --define "release ${PGVECTOR_RELEASE}" \
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
    rm -rf percona-pgvector*
    get_tar "source_tarball" "percona-pgvector"
    rm -f *.dsc *.orig.tar.gz *.debian.tar.gz *.changes
    #
    TARFILE=$(basename $(find . -name 'percona-pgvector*.tar.gz' | sort | tail -n1))
    DEBIAN=$(lsb_release -sc)
    ARCH=$(echo $(uname -m) | sed -e 's:i686:i386:g')
    tar zxf ${TARFILE}
    BUILDDIR=${TARFILE%.tar.gz}
    #

    mv ${TARFILE} ${PGVECTOR_PRODUCT_DEB}_${PGVECTOR_VERSION}.orig.tar.gz
    cd ${BUILDDIR}

    cd debian
    rm -rf changelog
    echo "percona-pgvector (${PGVECTOR_VERSION}-${PGVECTOR_RELEASE}) unstable; urgency=low" > changelog
    echo "  * Initial Release." >> changelog
    echo " -- Muhammad Aqeel <muhammad.aqeel@percona.com>  $(date -R)" >> changelog

    cd ../
    
    dch -D unstable --force-distribution -v "${PGVECTOR_VERSION}-${PGVECTOR_RELEASE}" "Update to new pgvector version ${PGVECTOR_VERSION}"
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
    echo "DEBIAN=${DEBIAN}" >> pgvector.properties
    echo "ARCH=${ARCH}" >> pgvector.properties

    #
    DSC=$(basename $(find . -name '*.dsc' | sort | tail -n1))
    #
    dpkg-source -x ${DSC}
    #

    cd ${PGVECTOR_PRODUCT_DEB}-${PGVECTOR_VERSION}
    dch -m -D "${DEBIAN}" --force-distribution -v "1:${PGVECTOR_VERSION}-${PGVECTOR_RELEASE}.${DEBIAN}" 'Update distribution'
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
VERSION_FILE=$CURDIR/pgvector.properties
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
    source install-deps.sh "pgvector"
fi
get_sources
build_srpm
build_source_deb
build_rpm
build_deb
