#!/usr/bin/env bash
set -x
# Versions and other variables
source versions.sh "ppg-server-ha"
# Common functions
source common-functions.sh

get_sources(){
    cd "${WORKDIR}"
    if [ "${SOURCE}" = 0 ]
    then
        echo "Sources will not be downloaded"
        return 0
    fi

    echo "PRODUCT=${PPG_SERVER_HA_PRODUCT}" > ppg-server-ha.properties

    echo "PRODUCT_FULL=${PPG_SERVER_HA_PRODUCT_FULL}" >> ppg-server-ha.properties
    echo "VERSION=${PSM_VER}" >> ppg-server-ha.properties
    echo "BUILD_NUMBER=${BUILD_NUMBER}" >> ppg-server-ha.properties
    echo "BUILD_ID=${BUILD_ID}" >> ppg-server-ha.properties
    git clone "$PPG_SERVER_HA_SRC_REPO" ${PPG_SERVER_HA_PRODUCT_FULL}
    retval=$?
    if [ $retval != 0 ]
    then
        echo "There were some issues during repo cloning from github. Please retry one more time"
        exit 1
    fi
    cd ${PPG_SERVER_HA_PRODUCT_FULL}
    if [ ! -z "$PPG_SERVER_HA_SRC_BRANCH" ]
    then
        git reset --hard
        git clean -xdf
        git checkout "$PPG_SERVER_HA_SRC_BRANCH"
        git submodule update --init
    fi
    REVISION=$(git rev-parse --short HEAD)
    echo "REVISION=${REVISION}" >> ${WORKDIR}/ppg-server-ha.properties

    mkdir debian
    cd debian/
    wget ${PKG_RAW_URL}/ppg-server-ha/control
    wget ${PKG_RAW_URL}/ppg-server-ha/rules
    sed -i "s/@@PGMAJOR@@/${PG_MAJOR}/g" control
    sed -i "s/@@PGVERSION@@/${PG_VERSION}/g" control
    echo 9 > compat
    echo "percona-ppg-server-ha-$PG_MAJOR (${PG_VERSION}-${PPG_SERVER_HA_RELEASE}) unstable; urgency=low" >> changelog
    echo "  * Initial Release." >> changelog
    echo " -- SurabhiBhat <surabhi.bhat@percona.com> $(date -R)" >> changelog

    cd ../
    mkdir rpm
    cd rpm
    wget ${PKG_RAW_URL}/ppg-server-ha/ppg-server-ha.spec
    cd ${WORKDIR}
    #
    source ppg-server-ha.properties
    #

    tar --owner=0 --group=0 --exclude=.* -czf ${PPG_SERVER_HA_PRODUCT_FULL}.tar.gz ${PPG_SERVER_HA_PRODUCT_FULL}
    DATE_TIMESTAMP=$(date +%F_%H-%M-%S)
    echo "UPLOAD=UPLOAD/experimental/BUILDS/${PPG_SERVER_HA_PRODUCT}/${PPG_SERVER_HA_PRODUCT_FULL}/${PSM_BRANCH}/${REVISION}/${DATE_TIMESTAMP}/${BUILD_ID}" >> ppg-server-ha.properties
    mkdir $WORKDIR/source_tarball
    mkdir $CURDIR/source_tarball
    cp ${PPG_SERVER_HA_PRODUCT_FULL}.tar.gz $WORKDIR/source_tarball
    cp ${PPG_SERVER_HA_PRODUCT_FULL}.tar.gz $CURDIR/source_tarball
    cd $CURDIR
    rm -rf percona-ppg-server-ha*
    return
}

get_deb_sources(){
    param=$1
    echo $param
    FILE=$(basename $(find $WORKDIR/source_deb -name "percona-ppg-server-ha*.$param" | sort | tail -n1))
    if [ -z $FILE ]
    then
        FILE=$(basename $(find $CURDIR/source_deb -name "percona-ppg-server-ha*.$param" | sort | tail -n1))
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
    get_tar "source_tarball" "percona-ppg-server-ha"
    rm -fr rpmbuild
    ls | grep -v tar.gz | xargs rm -rf
    TARFILE=$(find . -name 'percona-ppg-server-ha*.tar.gz' | sort | tail -n1)
    SRC_DIR=${TARFILE%.tar.gz}
    #
    mkdir -vp rpmbuild/{SOURCES,SPECS,BUILD,SRPMS,RPMS}
    tar vxzf ${WORKDIR}/${TARFILE} --wildcards '*/rpm' --strip=1
    #
    cp -av rpm/* rpmbuild/SOURCES
    cp -av rpm/ppg-server-ha.spec rpmbuild/SPECS
    #
    mv -fv ${TARFILE} ${WORKDIR}/rpmbuild/SOURCES
    rpmbuild -bs \
        --define "_topdir ${WORKDIR}/rpmbuild" \
        --define "dist .generic" \
        --define "pgmajor ${PG_MAJOR}" \
        --define "pgminorversion ${PG_MINOR}" \
        --define "release ${PPG_SERVER_HA_RELEASE}" \
        rpmbuild/SPECS/ppg-server-ha.spec
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
    SRC_RPM=$(basename $(find $WORKDIR/srpm -name 'percona-ppg-server-ha*.src.rpm' | sort | tail -n1))
    if [ -z $SRC_RPM ]
    then
        SRC_RPM=$(basename $(find $CURDIR/srpm -name 'percona-ppg-server-ha*.src.rpm' | sort | tail -n1))
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
    export LIBPQ_DIR=/usr/pgsql-${PG_MAJOR}/
    export LIBRARY_PATH=/usr/pgsql-${PG_MAJOR}/lib/:/usr/pgsql-${PG_MAJOR}/include/
    rpmbuild \
        --define "_topdir ${WORKDIR}/rpmbuild" \
        --define "dist .$OS_NAME" \
        --define "pgmajor ${PG_MAJOR}" \
        --define "pgminorversion ${PG_MINOR}" \
        --define "release ${PPG_SERVER_HA_RELEASE}" \
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
    #rm -rf percona-ppg-server-ha*
    get_tar "source_tarball" "percona-ppg-server-ha"
    rm -f *.dsc *.orig.tar.gz *.debian.tar.gz *.changes
    #
    TARFILE=$(basename $(find . -name 'percona-ppg-server-ha*.tar.gz' | sort | tail -n1))
    DEBIAN=$(lsb_release -sc)
    ARCH=$(echo $(uname -m) | sed -e 's:i686:i386:g')
    tar zxf ${TARFILE}
    BUILDDIR=${TARFILE%.tar.gz}
    #

    
    mv ${TARFILE} ${PPG_SERVER_HA_PRODUCT}_${PPG_SERVER_HA_VERSION}.orig.tar.gz
    cd ${BUILDDIR}    
    dch -D unstable --force-distribution -v "${PPG_SERVER_HA_VERSION}-${PPG_SERVER_HA_RELEASE}" "Update to new ppg-server-ha version ${PPG_SERVER_HA_VERSION}"
    dpkg-buildpackage -S
    cd ../
    mkdir -p $WORKDIR/source_deb
    mkdir -p $CURDIR/source_deb
    cp *_source.changes $WORKDIR/source_deb
    cp *.dsc $WORKDIR/source_deb
    cp *.orig.tar.gz $WORKDIR/source_deb
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
    #for file in 'dsc' 'orig.tar.gz' 'changes' 'debian.tar*'
    for file in 'dsc' 'orig.tar.gz' 'changes'
    do
        get_deb_sources $file
    done
    cd $WORKDIR
    TARFILE=$(basename $(find . -name 'percona-ppg-server-ha*.tar.gz' | sort | tail -n1))
    tar zxf ${TARFILE}
    rm -fv *.deb
    #
    export DEBIAN=$(lsb_release -sc)
    export ARCH=$(echo $(uname -m) | sed -e 's:i686:i386:g')
    #
    echo "DEBIAN=${DEBIAN}" >> ppg-server-ha.properties
    echo "ARCH=${ARCH}" >> ppg-server-ha.properties

    #
    DSC=$(basename $(find . -name '*.dsc' | sort | tail -n1))
    #
    dpkg-source -x ${DSC}
    #
    cd ${PPG_SERVER_HA_PRODUCT_FULL}
    dch -m -D "${DEBIAN}" --force-distribution -v "1:${PPG_SERVER_HA_VERSION}-${PPG_SERVER_HA_RELEASE}.${DEBIAN}" 'Update distribution'
    unset $(locale|cut -d= -f1)
    dpkg-buildpackage -rfakeroot -us -uc -b
    mkdir -p $CURDIR/deb
    mkdir -p $WORKDIR/deb
    cp $WORKDIR/*.*deb $WORKDIR/deb
    cp $WORKDIR/*.*deb $CURDIR/deb
}
#main

CURDIR=$(pwd)
VERSION_FILE=$CURDIR/ppg-server-ha.properties
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
    source install-deps.sh "ppg-server-ha"
fi
get_sources
build_srpm
build_source_deb
build_rpm
build_deb
