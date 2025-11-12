#!/usr/bin/env bash
set -x
# Versions and other variables
source versions.sh "pg_gather"
# Common functions
source common-functions.sh

get_sources(){
    cd "${WORKDIR}"
    if [ "${SOURCE}" = 0 ]
    then
        echo "Sources will not be downloaded"
        return 0
    fi

    echo "PRODUCT=${PG_GATHER_PRODUCT}" > pg_gather.properties
    echo "PRODUCT_FULL=${PG_GATHER_PRODUCT_FULL}" >> pg_gather.properties
    echo "VERSION=${PSM_VER}" >> pg_gather.properties
    echo "BUILD_NUMBER=${BUILD_NUMBER}" >> pg_gather.properties
    echo "BUILD_ID=${BUILD_ID}" >> pg_gather.properties

    mkdir ${PG_GATHER_PRODUCT_FULL} 
    cd ${PG_GATHER_PRODUCT_FULL}
    wget ${PG_GATHER_SRC_URL}/gather.sql
    wget ${PG_GATHER_SRC_URL}/README.md
    echo "REVISION=${REVISION}" >> ${WORKDIR}/pg_gather.properties
    rm -fr debian rpm
    mkdir debian rpm
    cd debian 
    wget ${PKG_RAW_URL}/pg_gather/debian/rules
    wget ${PKG_RAW_URL}/pg_gather/debian/control
    wget ${PKG_RAW_URL}/pg_gather/debian/percona-pg-gather.install
    sed -i "s/@@PGMAJOR@@/${PG_MAJOR}/g" control percona-pg-gather.install
    sed -i "s/@@PGGATHERVERSION@@/${PG_GATHER_VERSION}/g" control
    cd ../
    echo 9 > debian/compat
    cd rpm
    wget ${PKG_RAW_URL}/pg_gather/rpm/pg_gather.spec
    cd ${WORKDIR}
    #
    source pg_gather.properties
    #

    tar --owner=0 --group=0 --exclude=.* -czf ${PG_GATHER_PRODUCT_FULL}.tar.gz ${PG_GATHER_PRODUCT_FULL}
    DATE_TIMESTAMP=$(date +%F_%H-%M-%S)
    echo "UPLOAD=UPLOAD/experimental/BUILDS/${PG_GATHER_PRODUCT}/${PG_GATHER_PRODUCT_FULL}/${PG_GATHER_SRC_BRANCH}/${REVISION}/${DATE_TIMESTAMP}/${BUILD_ID}" >> pg_gather.properties
    mkdir $WORKDIR/source_tarball
    mkdir $CURDIR/source_tarball
    cp ${PG_GATHER_PRODUCT_FULL}.tar.gz $WORKDIR/source_tarball
    cp ${PG_GATHER_PRODUCT_FULL}.tar.gz $CURDIR/source_tarball
    cd $CURDIR
    rm -rf percona-pg_gather*
    return
}

get_deb_sources(){
    param=$1
    echo $param
    FILE=$(basename $(find $WORKDIR/source_deb -name "*gather*.$param" | sort | tail -n1))
    if [ -z $FILE ]
    then
        FILE=$(basename $(find $CURDIR/source_deb -name "*gather*.$param" | sort | tail -n1))
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
    get_tar "source_tarball" "percona-pg_gather"
    rm -fr rpmbuild
    ls | grep -v tar.gz | xargs rm -rf
    TARFILE=$(find . -name '*gather*.tar.gz' | sort | tail -n1)
    SRC_DIR=${TARFILE%.tar.gz}
    #
    mkdir -vp rpmbuild/{SOURCES,SPECS,BUILD,SRPMS,RPMS}
    tar vxzf ${WORKDIR}/${TARFILE} --wildcards '*/rpm' --strip=1
    #
    cp -av rpm/* rpmbuild/SOURCES
    cp -av rpm/pg_gather.spec rpmbuild/SPECS
    #
    mv -fv ${TARFILE} ${WORKDIR}/rpmbuild/SOURCES
    rpmbuild -bs \
        --define "_topdir ${WORKDIR}/rpmbuild" \
        --define "dist .generic" \
        --define "pgmajor ${PG_MAJOR}" \
        --define "version ${PG_GATHER_VERSION}" \
        --define "release ${PG_GATHER_RELEASE}" \
        rpmbuild/SPECS/pg_gather.spec
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
    SRC_RPM=$(basename $(find $WORKDIR/srpm -name '*gather*.src.rpm' | sort | tail -n1))
    if [ -z $SRC_RPM ]
    then
        SRC_RPM=$(basename $(find $CURDIR/srpm -name '*gather*.src.rpm' | sort | tail -n1))
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
    rpmbuild \
        --define "_topdir ${WORKDIR}/rpmbuild" \
        --define "dist .$OS_NAME" \
        --define "pgmajor ${PG_MAJOR}" \
        --define "version ${PG_GATHER_VERSION}" \
        --define "release ${PG_GATHER_RELEASE}" \
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
    rm -rf percona-pg_gather*
    get_tar "source_tarball" "percona-pg_gather"
    rm -f *.dsc *.orig.tar.gz *.debian.tar.gz *.changes
    #
    TARFILE=$(basename $(find . -name '*gather*.tar.gz' | sort | tail -n1))
    DEBIAN=$(lsb_release -sc)
    ARCH=$(echo $(uname -m) | sed -e 's:i686:i386:g')
    tar zxf ${TARFILE}
    BUILDDIR=${TARFILE%.tar.gz}
    #
    
    mv ${TARFILE} ${PG_GATHER_PRODUCT_DEB}_${PG_GATHER_VERSION}.orig.tar.gz
    mv ${BUILDDIR} ${PG_GATHER_PRODUCT_DEB}-${PG_GATHER_VERSION}
    cd ${PG_GATHER_PRODUCT_DEB}-${PG_GATHER_VERSION}

    cd debian
    rm -rf changelog
    echo "percona-pg-gather (${PG_GATHER_VERSION}-${PG_GATHER_RELEASE}) unstable; urgency=low" >> changelog
    echo "  * Initial Release." >> changelog
    echo " -- SurabhiBhat <surabhi.bhat@percona.com> $(date -R)" >> changelog

    cd ../
    
    dch -D unstable --force-distribution -v "${PG_GATHER_VERSION}-${PG_GATHER_RELEASE}" "Update to new version ${PG_GATHER_VERSION}"
    dpkg-buildpackage -S
    cd ../
    mkdir -p $WORKDIR/source_deb
    mkdir -p $CURDIR/source_deb
    cp *_source.changes $WORKDIR/source_deb
    cp *.dsc $WORKDIR/source_deb
    cp *.orig.tar.gz $WORKDIR/source_deb
    cp *.diff.gz $WORKDIR/source_deb
    cp *_source.changes $CURDIR/source_deb
    cp *.dsc $CURDIR/source_deb
    cp *.orig.tar.gz $CURDIR/source_deb
    cp *.diff.gz $CURDIR/source_deb
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
    #
    export DEBIAN=$(lsb_release -sc)
    export ARCH=$(echo $(uname -m) | sed -e 's:i686:i386:g')
    #
    echo "DEBIAN=${DEBIAN}" >> pg_gather.properties
    echo "ARCH=${ARCH}" >> pg_gather.properties

    #
    DSC=$(basename $(find . -name '*.dsc' | sort | tail -n1))
    #
    dpkg-source -x ${DSC}
    #
    cd ${PG_GATHER_PRODUCT_DEB}-${PG_GATHER_VERSION}
    dch -m -D "${DEBIAN}" --force-distribution -v "1:${PG_GATHER_VERSION}-${PG_GATHER_RELEASE}.${DEBIAN}" 'Update distribution'
    unset $(locale|cut -d= -f1)
    dpkg-buildpackage -rfakeroot -us -uc -b
    mkdir -p $CURDIR/deb
    mkdir -p $WORKDIR/deb
    cp $WORKDIR/*.*deb $WORKDIR/deb
    cp $WORKDIR/*.*deb $CURDIR/deb
}
#main

CURDIR=$(pwd)
VERSION_FILE=$CURDIR/pg_gather.properties
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
    source install-deps.sh "pg_gather"
fi
get_sources
build_srpm
build_source_deb
build_rpm
build_deb
