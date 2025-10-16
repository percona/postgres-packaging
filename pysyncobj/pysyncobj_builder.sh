#!/usr/bin/env bash
set -x
# Versions and other variables
source versions.sh "pysyncobj"
# Common functions
source common-functions.sh

get_sources(){
    cd "${WORKDIR}"
    if [ "${SOURCE}" = 0 ]
    then
        echo "Sources will not be downloaded"
        return 0
    fi

    echo "PRODUCT=${PYSYNCOBJ_PRODUCT}" > pysyncobj.properties
    GIT_USER=$(echo ${PYSYNCOBJ_SRC_REPO} | awk -F'/' '{print $4}')
    echo "PRODUCT_FULL=${PYSYNCOBJ_PRODUCT_FULL}" >> pysyncobj.properties
    echo "VERSION=${PYSYNCOBJ_VERSION}" >> pysyncobj.properties
    echo "BUILD_NUMBER=${BUILD_NUMBER}" >> pysyncobj.properties
    echo "BUILD_ID=${BUILD_ID}" >> pysyncobj.properties
    git clone "$PYSYNCOBJ_SRC_REPO" ${PYSYNCOBJ_PRODUCT_FULL}
    retval=$?
    if [ $retval != 0 ]
    then
        echo "There were some issues during repo cloning from github. Please retry one more time"
        exit 1
    fi
    cd ${PYSYNCOBJ_PRODUCT_FULL}
    if [ ! -z "$PYSYNCOBJ_SRC_BRANCH" ]
    then
        git reset --hard
        git clean -xdf
        git checkout "$PYSYNCOBJ_SRC_BRANCH"
    fi
    REVISION=$(git rev-parse --short HEAD)
    echo "REVISION=${REVISION}" >> ${WORKDIR}/pysyncobj.properties
    rm -fr debian rpm
    git clone ${PYSYNCOBJ_PERCONA_REPO}
    mv python3-pysyncobj/debian ./
    mkdir rpm
    cd rpm
    wget ${PKG_RAW_URL}/pysyncobj/python3-pysyncobj.spec
    cd ../
    rm -rf python3-pysyncobj
    cd ../

    export DEBIAN=$(lsb_release -sc)
    cd ${WORKDIR}

    source pysyncobj.properties

    tar --owner=0 --group=0 --exclude=.* -czf ${PYSYNCOBJ_PRODUCT_FULL}.tar.gz ${PYSYNCOBJ_PRODUCT_FULL}
    DATE_TIMESTAMP=$(date +%F_%H-%M-%S)
    echo "UPLOAD=UPLOAD/experimental/BUILDS/${PYSYNCOBJ_PRODUCT}/${PYSYNCOBJ_PRODUCT_FULL}/${PYSYNCOBJ_SRC_BRANCH}/${REVISION}/${DATE_TIMESTAMP}/${BUILD_ID}" >> pysyncobj.properties
    mkdir $WORKDIR/source_tarball
    mkdir $CURDIR/source_tarball
    cp ${PYSYNCOBJ_PRODUCT_FULL}.tar.gz $WORKDIR/source_tarball
    cp ${PYSYNCOBJ_PRODUCT_FULL}.tar.gz $CURDIR/source_tarball
    cd $CURDIR
    rm -rf python3-pysyncobj*
    return
}

get_deb_sources(){
    param=$1
    echo $param
    FILE=$(basename $(find $WORKDIR/source_deb -name "python3-pysyncobj*.$param" | sort | tail -n1))
    if [ -z $FILE ]
    then
        FILE=$(basename $(find $CURDIR/source_deb -name "python3-pysyncobj*.$param" | sort | tail -n1))
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
    get_tar "source_tarball" "python3-pysyncobj"
    rm -fr rpmbuild
    ls | grep -v tar.gz | xargs rm -rf
    TARFILE=$(find . -name 'python3-pysyncobj*.tar.gz' | sort | tail -n1)
    SRC_DIR=${TARFILE%.tar.gz}

    mkdir -vp rpmbuild/{SOURCES,SPECS,BUILD,SRPMS,RPMS}
    tar vxzf ${WORKDIR}/${TARFILE} --wildcards '*/rpm' --strip=1

    cp -av rpm/* rpmbuild/SOURCES
    cp -av rpm/python3-pysyncobj.spec rpmbuild/SPECS

    mv -fv ${TARFILE} ${WORKDIR}/rpmbuild/SOURCES
    sed -i 's:.rhel7:%{dist}:' ${WORKDIR}/rpmbuild/SPECS/python3-pysyncobj.spec
    rpmbuild -bs --define "_topdir ${WORKDIR}/rpmbuild" --define "dist .generic" \
        --define "version ${PYSYNCOBJ_VERSION}" rpmbuild/SPECS/python3-pysyncobj.spec
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
    SRC_RPM=$(basename $(find $WORKDIR/srpm -name 'python3-pysyncobj*.src.rpm' | sort | tail -n1))
    if [ -z $SRC_RPM ]
    then
        SRC_RPM=$(basename $(find $CURDIR/srpm -name 'python3-pysyncobj*.src.rpm' | sort | tail -n1))
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
    rpmbuild --define "_topdir ${WORKDIR}/rb" --define "dist .$OS_NAME" --define "version ${PYSYNCOBJ_VERSION}" --rebuild rb/SRPMS/$SRC_RPM

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
    rm -rf python3-pysyncobj*
    get_tar "source_tarball" "python3-pysyncobj"
    rm -f *.dsc *.orig.tar.gz *.debian.tar.gz *.changes

    TARFILE=$(basename $(find . -name 'python3-pysyncobj*.tar.gz' | sort | tail -n1))
    DEBIAN=$(lsb_release -sc)
    ARCH=$(echo $(uname -m) | sed -e 's:i686:i386:g')
    tar zxf ${TARFILE}
    BUILDDIR=${TARFILE%.tar.gz}

    
    mv ${TARFILE} python3-pysyncobj_${PYSYNCOBJ_VERSION}.orig.tar.gz
    cd ${BUILDDIR}

    dch -D unstable --force-distribution -v "${PYSYNCOBJ_VERSION}-${PYSYNCOBJ_RELEASE}" "Update to new pysyncobj version ${PYSYNCOBJ_VERSION}"
    dpkg-buildpackage -S || true
    cd ../
    mkdir -p $WORKDIR/source_deb
    mkdir -p $CURDIR/source_deb
    cp *.diff.gz $WORKDIR/source_deb
    cp *_source.changes $WORKDIR/source_deb
    cp *.dsc $WORKDIR/source_deb
    cp *.orig.tar.gz $WORKDIR/source_deb
    cp *.diff.gz $CURDIR/source_deb
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
    for file in 'dsc' 'orig.tar.gz' 'changes' 'diff.gz'
    do
        get_deb_sources $file
    done
    cd $WORKDIR
    rm -fv *.deb

    export DEBIAN=$(lsb_release -sc)
    export ARCH=$(echo $(uname -m) | sed -e 's:i686:i386:g')

    echo "DEBIAN=${DEBIAN}" >> pysyncobj.properties
    echo "ARCH=${ARCH}" >> pysyncobj.properties

    DSC=$(basename $(find . -name '*.dsc' | sort | tail -n1))

    dpkg-source -x ${DSC}

    cd ${PYSYNCOBJ_PRODUCT_FULL}
    dch -m -D "${DEBIAN}" --force-distribution -v "1:${PYSYNCOBJ_VERSION}-${PYSYNCOBJ_RELEASE}.${DEBIAN}" 'Update distribution'
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
VERSION_FILE=$CURDIR/pysyncobj.properties
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
    source install-deps.sh "pysyncobj"
fi
get_sources
build_srpm
build_source_deb
build_rpm
build_deb
