#!/usr/bin/env bash
set -x
# Versions and other variables
source versions.sh "ydiff"
# Common functions
source common-functions.sh

get_sources(){
    cd "${WORKDIR}"
    if [ "${SOURCE}" = 0 ]
    then
        echo "Sources will not be downloaded"
        return 0
    fi

    echo "PRODUCT=${YDIFF_PRODUCT}" > ydiff.properties
    GIT_USER=$(echo ${YDIFF_SRC_REPO} | awk -F'/' '{print $4}')
    echo "PRODUCT_FULL=${YDIFF_PRODUCT_FULL}" >> ydiff.properties
    echo "VERSION=${YDIFF_VERSION}" >> ydiff.properties
    echo "BUILD_NUMBER=${BUILD_NUMBER}" >> ydiff.properties
    echo "BUILD_ID=${BUILD_ID}" >> ydiff.properties
    git clone "$YDIFF_SRC_REPO" ydiff-${YDIFF_VERSION}
    retval=$?
    if [ $retval != 0 ]
    then
        echo "There were some issues during repo cloning from github. Please retry one more time"
        exit 1
    fi
    cd ydiff-${YDIFF_VERSION}
    if [ ! -z "$YDIFF_SRC_BRANCH" ]
    then
        git reset --hard
        git clean -xdf
        git checkout "$YDIFF_SRC_BRANCH"
    fi
    REVISION=$(git rev-parse --short HEAD)
    echo "REVISION=${REVISION}" >> ${WORKDIR}/ydiff.properties
    rm -fr debian rpm
    mkdir -p debian/source
    cd debian
    wget ${PKG_RAW_URL}/ydiff/debian/rules
    wget ${PKG_RAW_URL}/ydiff/debian/changelog
    wget ${PKG_RAW_URL}/ydiff/debian/compat
    wget ${PKG_RAW_URL}/ydiff/debian/control
    wget ${PKG_RAW_URL}/ydiff/debian/copyright
    wget ${PKG_RAW_URL}/ydiff/debian/docs
    wget ${PKG_RAW_URL}/ydiff/debian/watch
    cd source
    wget ${PKG_RAW_URL}/ydiff/debian/source/format
    cd ../../

    export DEBIAN=$(lsb_release -sc)
    mkdir rpm
    cd rpm
    wget ${PKG_RAW_URL}/ydiff/rpm/ydiff.spec
    cd ../
    cd ${WORKDIR}

    source ydiff.properties


    tar --owner=0 --group=0 --exclude=.* -czf ydiff-${YDIFF_VERSION}.tar.gz ydiff-${YDIFF_VERSION}
    DATE_TIMESTAMP=$(date +%F_%H-%M-%S)
    echo "UPLOAD=UPLOAD/experimental/BUILDS/${YDIFF_PRODUCT}/${YDIFF_PRODUCT_FULL}/${YDIFF_SRC_BRANCH}/${REVISION}/${DATE_TIMESTAMP}/${BUILD_ID}" >> ydiff.properties
    mkdir $WORKDIR/source_tarball
    mkdir $CURDIR/source_tarball
    cp ydiff-${YDIFF_VERSION}.tar.gz $WORKDIR/source_tarball
    cp ydiff-${YDIFF_VERSION}.tar.gz $CURDIR/source_tarball
    cd $CURDIR
    rm -rf python3-ydiff*
    return
}

get_deb_sources(){
    param=$1
    echo $param
    FILE=$(basename $(find $WORKDIR/source_deb -name "ydiff*.$param" | sort | tail -n1))
    if [ -z $FILE ]
    then
        FILE=$(basename $(find $CURDIR/source_deb -name "ydiff*.$param" | sort | tail -n1))
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
    get_tar "source_tarball" "ydiff"
    rm -fr rpmbuild
    ls | grep -v tar.gz | xargs rm -rf
    TARFILE=$(find . -name 'ydiff*.tar.gz' | sort | tail -n1)
    SRC_DIR=${TARFILE%.tar.gz}

    mkdir -vp rpmbuild/{SOURCES,SPECS,BUILD,SRPMS,RPMS}
    tar vxzf ${WORKDIR}/${TARFILE} --wildcards '*/rpm' --strip=1

    cp -av rpm/* rpmbuild/SOURCES
    cp -av rpm/ydiff.spec rpmbuild/SPECS

    mv -fv ${TARFILE} ${WORKDIR}/rpmbuild/SOURCES
    sed -i 's:.rhel7:%{dist}:' ${WORKDIR}/rpmbuild/SPECS/ydiff.spec
    rpmbuild -bs \
        --define "_topdir ${WORKDIR}/rpmbuild" \
        --define "dist .generic" \
        --define "version ${YDIFF_VERSION}" \
        --define "release ${YDIFF_RELEASE}" \
        rpmbuild/SPECS/ydiff.spec

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
    SRC_RPM=$(basename $(find $WORKDIR/srpm -name 'ydiff*.src.rpm' | sort | tail -n1))
    if [ -z $SRC_RPM ]
    then
        SRC_RPM=$(basename $(find $CURDIR/srpm -name 'ydiff*.src.rpm' | sort | tail -n1))
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
    rm -fr rb
    mkdir -vp rb/{SOURCES,SPECS,BUILD,SRPMS,RPMS,BUILDROOT}
    cp $SRC_RPM rb/SRPMS/

    cd rb/SRPMS/

    cd $WORKDIR
    RHEL=$(rpm --eval %rhel)
    ARCH=$(echo $(uname -m) | sed -e 's:i686:i386:g')
    rpmbuild \
        --define "_topdir ${WORKDIR}/rb" \
        --define "dist .$OS_NAME" \
        --define "version ${YDIFF_VERSION}" \
        --define "release ${YDIFF_RELEASE}" \
        --rebuild rb/SRPMS/$SRC_RPM

    return_code=$?
    if [ $return_code != 0 ]; then
        exit $return_code
    fi
    mkdir -p ${WORKDIR}/rpm
    mkdir -p ${CURDIR}/rpm
    cp rb/RPMS/*/*.rpm ${WORKDIR}/rpm
    cp rb/RPMS/*/*.rpm ${CURDIR}/rpm
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
    rm -rf python3-ydiff*
    get_tar "source_tarball" "ydiff"
    rm -f *.dsc *.orig.tar.gz *.debian.tar.gz *.changes

    TARFILE=$(basename $(find . -name 'ydiff*.tar.gz' | sort | tail -n1))
    DEBIAN=$(lsb_release -sc)
    ARCH=$(echo $(uname -m) | sed -e 's:i686:i386:g')
    tar zxf ${TARFILE}
    rm -f ydiff-${YDIFF_VERSION}/.travis.yml
    BUILDDIR=${TARFILE%.tar.gz}

    
    mv ${TARFILE} ydiff_${YDIFF_VERSION}.orig.tar.gz
    cd ${BUILDDIR}

    dch -D unstable --force-distribution -v "${YDIFF_VERSION}-${YDIFF_RELEASE}" "Update to new ydiff version ${YDIFF_VERSION}"
    rm -rf .github
    dpkg-buildpackage -S || true
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

    export DEBIAN=$(lsb_release -sc)
    export ARCH=$(echo $(uname -m) | sed -e 's:i686:i386:g')

    echo "DEBIAN=${DEBIAN}" >> ydiff.properties
    echo "ARCH=${ARCH}" >> ydiff.properties


    DSC=$(basename $(find . -name '*.dsc' | sort | tail -n1))

    dpkg-source -x ${DSC}

    cd ydiff-${YDIFF_VERSION}
    dch -m -D "${DEBIAN}" --force-distribution -v "1:${YDIFF_VERSION}-${YDIFF_RELEASE}.${DEBIAN}" 'Update distribution'
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
export GIT_SSL_NO_VERIFY=1
CURDIR=$(pwd)
VERSION_FILE=$CURDIR/ydiff.properties
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
    source install-deps.sh "ydiff"
fi
get_sources
build_srpm
build_source_deb
build_rpm
build_deb
