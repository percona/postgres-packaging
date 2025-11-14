#!/usr/bin/env bash
set -x
# Versions and other variables
source versions.sh "postgresql"
# Common functions
source common-functions.sh

get_sources(){
    cd "${WORKDIR}"
    if [ "${SOURCE}" = 0 ]
    then
        echo "Sources will not be downloaded"
        return 0
    fi

    echo "PRODUCT=${PPG_PRODUCT}" > percona-postgresql.properties
    echo "PRODUCT_FULL=${PPG_PRODUCT_FULL}" >> percona-postgresql.properties
    echo "VERSION=${PSM_VER}" >> percona-postgresql.properties
    echo "BUILD_NUMBER=${BUILD_NUMBER}" >> percona-postgresql.properties
    echo "BUILD_ID=${BUILD_ID}" >> percona-postgresql.properties
    git clone "$PG_SRC_REPO" postgresql
    retval=$?
    if [ $retval != 0 ]
    then
        echo "There were some issues during repo cloning from github. Please retry one more time"
        exit 1
    fi
    mv postgresql ${PPG_PRODUCT_FULL}
    cd ${PPG_PRODUCT_FULL}
    if [ ! -z "$PG_SRC_BRANCH" ]
    then
        git reset --hard
        git clean -xdf
        git checkout "$PG_SRC_BRANCH"
        git submodule update --init --recursive
	sed -i 's:enable_tap_tests=no:enable_tap_tests=yes:' configure
    fi
    REVISION=$(git rev-parse --short HEAD)
    echo "REVISION=${REVISION}" >> ${WORKDIR}/percona-postgresql.properties
    rm -fr debian rpm

    git clone $PG_SRC_REPO_DEB deb_packaging
    cd deb_packaging
        git checkout -b $PG_MAJOR remotes/origin/$PG_MAJOR
    cd ../
    mv deb_packaging/debian ./
    rm -rf deb_packaging
    cd debian
        for file in $(ls | grep postgresql); do
            mv $file "percona-$file"
        done
	rm -f rules control
        wget ${PKG_RAW_URL}/postgres/rules
        wget ${PKG_RAW_URL}/postgres/control
        sed -i "s/@@PGMAJOR@@/${PG_MAJOR}/g" control rules
        sed -i "s/@@PGVERSION@@/${PG_VERSION}/g" control
        sed -i "s/postgresql-$PG_MAJOR/percona-postgresql-$PG_MAJOR/" percona-postgresql-$PG_MAJOR.templates
	echo "10" > compat
	sed -i '14d' patches/series
    cd ../
    git clone $PGRPMS_GIT_REPO
    mkdir rpm
    mv pgrpms/rpm/redhat/main/non-common/postgresql-$PG_MAJOR/main/*   rpm/
    rm -rf pgrpms
    cd rpm
        rm postgresql-$PG_MAJOR.spec
        wget ${PKG_RAW_URL}/postgres/percona-postgresql-${PG_MAJOR}.spec
	wget ${PKG_RAW_URL}/postgres/llvm_static_linking.patch
    cd ../
    cd ${WORKDIR}
    source percona-postgresql.properties

    tar --owner=0 --group=0 --exclude=.* -czf ${PPG_PRODUCT_FULL}.tar.gz ${PPG_PRODUCT_FULL}
    DATE_TIMESTAMP=$(date +%F_%H-%M-%S)
    echo "UPLOAD=UPLOAD/experimental/BUILDS/${PPG_PRODUCT}-$PG_MAJOR/${PPG_PRODUCT_FULL}/${PSM_BRANCH}/${REVISION}/${DATE_TIMESTAMP}/${BUILD_ID}" >> percona-postgresql.properties
    mkdir $WORKDIR/source_tarball
    mkdir $CURDIR/source_tarball
    cp ${PPG_PRODUCT_FULL}.tar.gz $WORKDIR/source_tarball
    cp ${PPG_PRODUCT_FULL}.tar.gz $CURDIR/source_tarball
    cd $CURDIR
    rm -rf percona-postgresql*
    return
}

get_deb_sources(){
    param=$1
    echo $param
    FILE=$(basename $(find $WORKDIR/source_deb -name "percona-postgresql*.$param" | sort | tail -n1))
    if [ -z $FILE ]
    then
        FILE=$(basename $(find $CURDIR/source_deb -name "percona-postgresql*.$param" | sort | tail -n1))
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
    get_tar "source_tarball" "percona-postgresql"
    rm -fr rpmbuild
    ls | grep -v tar.gz | xargs rm -rf
    TARFILE=$(find . -name 'percona-postgresql*.tar.gz' | sort | tail -n1)
    SRC_DIR=${TARFILE%.tar.gz}

    mkdir -vp rpmbuild/{SOURCES,SPECS,BUILD,SRPMS,RPMS}
    tar vxzf ${WORKDIR}/${TARFILE} --wildcards '*/rpm' --strip=1

    cp -av rpm/* rpmbuild/SOURCES
    cd rpmbuild/SOURCES
    wget --no-check-certificate "${PG_DOC}"
    cd ../../
    cp -av rpmbuild/SOURCES/percona-postgresql-$PG_MAJOR.spec rpmbuild/SPECS

    mv -fv ${TARFILE} ${WORKDIR}/rpmbuild/SOURCES
    if [ -f /opt/rh/devtoolset-7/enable ]; then
        source /opt/rh/devtoolset-7/enable
        source /opt/rh/llvm-toolset-7/enable
    fi

    cd ${WORKDIR}
    rpmbuild -bs \
        --define "_topdir ${WORKDIR}/rpmbuild" \
        --define "dist .generic" \
        --define "pgmajorversion ${PG_MAJOR}" \
        --define "pginstdir /usr/pgsql-${PG_MAJOR}"  \
        --define "pgpackageversion ${PG_MAJOR}" \
        --define "version ${PG_VERSION}" \
        --define "pg_release ${PG_RELEASE}" \
        --define "release ${BUILD_RELEASE}" \
        rpmbuild/SPECS/percona-postgresql-${PG_MAJOR}.spec
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
    SRC_RPM=$(basename $(find $WORKDIR/srpm -name 'percona-postgresql*.src.rpm' | sort | tail -n1))
    if [ -z $SRC_RPM ]
    then
        SRC_RPM=$(basename $(find $CURDIR/srpm -name 'percona-postgresql*.src.rpm' | sort | tail -n1))
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
        --define "pgmajorversion ${PG_MAJOR}" \
        --define "pginstdir /usr/pgsql-${PG_MAJOR}" \
        --define "pgpackageversion ${PG_MAJOR}" \
        --define "version ${PG_VERSION}" \
        --define "pg_release ${PG_RELEASE}" \
        --define "release ${BUILD_RELEASE}" \
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
    rm -rf percona-postgresql*
    get_tar "source_tarball" "percona-postgresql"
    rm -f *.dsc *.orig.tar.gz *.debian.tar.gz *.changes

    TARFILE=$(basename $(find . -name 'percona-postgresql*.tar.gz' | sort | tail -n1))
    DEBIAN=$(lsb_release -sc)
    ARCH=$(echo $(uname -m) | sed -e 's:i686:i386:g')
    tar zxf ${TARFILE}
    BUILDDIR=${TARFILE%.tar.gz}

    
    mv ${TARFILE} ${PPG_PRODUCT}-${PG_MAJOR}_${PG_VERSION}.orig.tar.gz
    cd ${BUILDDIR}

    cd debian
    rm -rf changelog
    echo "percona-postgresql-${PG_MAJOR} (${PG_VERSION}) unstable; urgency=low" >> changelog
    echo "  * Initial Release." >> changelog
    echo " -- EvgeniyPatlan <evgeniy.patlan@percona.com> $(date -R)" >> changelog

    cd ../
    quilt refresh
    dch -D unstable --force-distribution -v "${PG_VERSION}-${PG_DEB_RELEASE}" "Update to new Percona Platform for PostgreSQL version ${PG_VERSION}-${PG_DEB_RELEASE}"
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

    export DEBIAN=$(lsb_release -sc)
    export ARCH=$(echo $(uname -m) | sed -e 's:i686:i386:g')

    echo "DEBIAN=${DEBIAN}" >> percona-postgresql.properties
    echo "ARCH=${ARCH}" >> percona-postgresql.properties


    DSC=$(basename $(find . -name '*.dsc' | sort | tail -n1))

    dpkg-source -x ${DSC}

    cd ${PPG_PRODUCT}-${PG_MAJOR}-${PG_VERSION}
    dch -m -D "${DEBIAN}" --force-distribution -v "2:${PG_VERSION}-${PG_DEB_RELEASE}.${DEBIAN}" 'Update distribution'
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
VERSION_FILE=$CURDIR/percona-postgresql.properties
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

if [ "x$OS" = "xrpm" ]; then
    BUILD_RELEASE=${PG_RPM_RELEASE}
else
    BUILD_RELEASE=${PG_DEB_RELEASE}
fi

check_workdir
get_system

#install_deps
if [ $INSTALL = 0 ]; then
    echo "Dependencies will not be installed"
else
    source install-deps.sh "postgresql"
fi

get_sources
build_srpm
build_source_deb
build_rpm
build_deb
