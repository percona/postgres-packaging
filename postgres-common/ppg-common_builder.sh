#!/usr/bin/env bash
set -x

# Versions and other variables
source versions.sh "postgresql-common"
# Common functions
source common-functions.sh

get_sources(){
    cd "${WORKDIR}"
    if [ "${SOURCE}" = 0 ]
    then
        echo "Sources will not be downloaded"
        return 0
    fi

    echo "PRODUCT=${PPG_COMMON_PRODUCT}" > percona-postgresql.properties
    echo "PRODUCT_FULL=${PPG_COMMON_PRODUCT_FULL}" >> percona-postgresql.properties
    echo "VERSION=${PPG_COMMON_MAJOR}" >> percona-postgresql.properties
    echo "BUILD_NUMBER=${BUILD_NUMBER}" >> percona-postgresql.properties
    echo "BUILD_ID=${BUILD_ID}" >> percona-postgresql.properties
    git clone "$PPG_COMMON_SRC_REPO"
    retval=$?
    if [ $retval != 0 ]
    then
        echo "There were some issues during repo cloning from github. Please retry one more time"
        exit 1
    fi
    mv postgresql-common ${PPG_COMMON_PRODUCT_FULL}
    cd ${PPG_COMMON_PRODUCT_FULL}
    if [ ! -z "$PPG_COMMON_SRC_BRANCH" ]
    then
        git reset --hard
        git clean -xdf
        git checkout "$PPG_COMMON_SRC_BRANCH"
    fi
    REVISION=$(git rev-parse --short HEAD)
    echo "REVISION=${REVISION}" >> ${WORKDIR}/percona-postgresql.properties
    cd debian
        for file in $(ls | grep ^postgresql); do 
            mv $file "percona-$file"
        done
            for file in $(ls | grep percona-postgresql-common | grep -v dev); do 
            newname=$(echo $file | awk -F'percona-' '{print $2}'); 
                mv $file $newname; 
        done
            for file in $(ls|grep percona-postgresql-client-common); do 
            newname=$(echo $file | awk -F'percona-' '{print $2}'); 
                mv $file $newname; 
        done
            rm -rf rules control supported-versions 
        wget ${PKG_RAW_URL}/postgres-common/control
        wget ${PKG_RAW_URL}/postgres-common/maintscripts-functions.patch
        wget ${PKG_RAW_URL}/postgres-common/percona-postgresql-common.templates.patch
        wget ${PKG_RAW_URL}/postgres-common/rules
        wget ${PKG_RAW_URL}/postgres-common/supported-versions
        wget ${PKG_RAW_URL}/postgres-common/postgresql-common.install
        wget ${PKG_RAW_URL}/postgres-common/percona-postgresql-common-dev.install
        wget ${PKG_RAW_URL}/postgres-common/percona-postgresql-server-dev-all.install
        sed -i "s/@@PGMAJOR@@/${PG_MAJOR}/g" rules
        cp postgresql-common.tmpfiles postgresql-common.conf
        sudo chmod +x supported-versions
        patch -p0 < maintscripts-functions.patch
        patch -p0 < percona-postgresql-common.templates.patch
        rm -rf maintscripts-functions.patch percona-postgresql-common.templates.patch
        rm -rf changelog
        echo "percona-postgresql-common (${PPG_COMMON_MAJOR}) unstable; urgency=low" >> changelog
        echo "  * Initial Release." >> changelog
        echo " -- EvgeniyPatlan <evgeniy.patlan@percona.com> $(date -R)" >> changelog
        sed -i 's:percona-postgresql-plpython-$v,::' rules
        echo 12 > compat
        sed -i 's:supported_versions:debian/supported-versions:' postgresql-client-common.install
        sed -i 's:ucfr:ucfr --force:g' postgresql-common.postinst
        sed -i 's:ucfr:ucfr --force:g' postgresql-common.postrm
        mv postgresql-common.install.1 postgresql-common.install
        mv percona-postgresql-common-dev.install.1 percona-postgresql-common-dev.install
        sed -i '3d' postgresql-client-common.install
        rm -rf percona-postgresql-common-dev.manpages
        echo "pgcommon.sh usr/share/postgresql-common" >> postgresql-client-common.install
        echo "debhelper/dh_pgxs_test /usr/bin" >> percona-postgresql-server-dev-all.install
        sudo sed -i 's:db_stop:db_stop || true:' maintscripts-functions
        echo "dh_make_pgxs/dh_make_pgxs.1" >> percona-postgresql-server-dev-all.manpages
        echo "debhelper/dh_pgxs_test.1" >> percona-postgresql-server-dev-all.manpages
    cd ../
    wget ${PKG_RAW_URL}/postgres-common/pgcommon.sh
    sudo chmod +x pgcommon.sh
    cd rpm
        for file in $(ls | grep postgresql); do
            mv $file "percona-$file"
        done
        rm -rf percona-postgresql-common.spec
        wget ${PKG_RAW_URL}/postgres-common/percona-postgresql-common.spec
        if [ ${ARCH} = "aarch64" ]; then
            sed -e '4d' percona-postgresql-common.spec
        fi
    cd ../
    cd ${WORKDIR}

    source percona-postgresql.properties

    tar --owner=0 --group=0 --exclude=.* -czf ${PPG_COMMON_PRODUCT_FULL}.tar.gz ${PPG_COMMON_PRODUCT_FULL}
    DATE_TIMESTAMP=$(date +%F_%H-%M-%S)
    echo "UPLOAD=UPLOAD/experimental/BUILDS/${PPG_COMMON_PRODUCT}-$PG_MAJOR/${PPG_COMMON_PRODUCT_FULL}/${PPG_COMMON_SRC_BRANCH}/${REVISION}/${DATE_TIMESTAMP}/${BUILD_ID}" >> percona-postgresql.properties
    mkdir $WORKDIR/source_tarball
    mkdir $CURDIR/source_tarball
    cp ${PPG_COMMON_PRODUCT_FULL}.tar.gz $WORKDIR/source_tarball
    cp ${PPG_COMMON_PRODUCT_FULL}.tar.gz $CURDIR/source_tarball
    cd $CURDIR
    rm -rf percona-postgresql*
    return
}

get_deb_sources(){
    param=$1
    echo $param
    FILE=$(basename $(find $WORKDIR/source_deb -name "percona-postgresql*$param" | sort | tail -n1))
    if [ -z $FILE ]
    then
        FILE=$(basename $(find $CURDIR/source_deb -name "percona-postgresql*$param" | sort | tail -n1))
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
    get_tar "source_tarball" "percona-postgresql-common"
    rm -fr rpmbuild
    ls | grep -v tar.gz | xargs rm -rf
    TARFILE=$(find . -name 'percona-postgresql*.tar.gz' | sort | tail -n1)
    SRC_DIR=${TARFILE%.tar.gz}

    mkdir -vp rpmbuild/{SOURCES,SPECS,BUILD,SRPMS,RPMS}
    tar vxzf ${WORKDIR}/${TARFILE} --wildcards '*/rpm' --strip=1

    cp -av rpm/* rpmbuild/SOURCES
    cd rpmbuild/SOURCES
    cd ../../
    cp -av rpmbuild/SOURCES/*.spec rpmbuild/SPECS

    mv -fv ${TARFILE} ${WORKDIR}/rpmbuild/SOURCES
    rpmbuild -bs \
        --define "_topdir ${WORKDIR}/rpmbuild" \
        --define "dist .generic" \
        --define "version ${PPG_COMMON_MAJOR}" \
        --define "ppg_cmn_release ${PPG_COMMON_RELEASE}" \
        rpmbuild/SPECS/percona-postgresql-common.spec
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
    SRC_RPM=$(basename $(find $WORKDIR/srpm -name 'percona-postgresql-common*.src.rpm' | sort | tail -n1))
    if [ -z $SRC_RPM ]
    then
        SRC_RPM=$(basename $(find $CURDIR/srpm -name 'percona-postgresql-common*.src.rpm' | sort | tail -n1))
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
    rpmbuild \
        --define "_topdir ${WORKDIR}/rpmbuild" \
        --define "version ${PPG_COMMON_MAJOR}" \
        --define "ppg_cmn_release ${PPG_COMMON_RELEASE}" \
        --define "dist .$OS_NAME" \
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
    rm -rf percona-postgresql-common*
    rm -f *.dsc *.orig.tar.gz *.tar.* *.changes
    get_tar "source_tarball" "percona-postgresql-common"

    TARFILE=$(basename $(find . -name 'percona-postgresql-common*.tar.gz' | sort | tail -n1))
    DEBIAN=$(lsb_release -sc)
    ARCH=$(echo $(uname -m) | sed -e 's:i686:i386:g')
    tar zxf ${TARFILE}
    BUILDDIR=${TARFILE%.tar.gz}

    
    mv ${TARFILE} ${PPG_COMMON_PRODUCT}_${PPG_COMMON_MAJOR}.orig.tar.gz
    cd ${BUILDDIR}

    dch -D unstable --force-distribution -v "${PPG_COMMON_MAJOR}" "Update to new Percona Platform for PostgreSQL version ${PPG_COMMON_MAJOR}"
    dpkg-buildpackage -S
    cd ../
    mkdir -p $WORKDIR/source_deb
    mkdir -p $CURDIR/source_deb
    cp *.tar.* $WORKDIR/source_deb
    cp *_source.changes $WORKDIR/source_deb
    cp *.dsc $WORKDIR/source_deb
    cp *.orig.tar.gz $WORKDIR/source_deb
    cp *.tar.* $CURDIR/source_deb
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
    for file in 'dsc' 'orig.tar.gz' 'changes' 'common*.tar.*'
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

    cd ${PPG_COMMON_PRODUCT_FULL}
    if [ ${DEBIAN} = "stretch" ]; then
        sed -i 's:12:11:' debian/compat
    fi
    dch -m -D "${DEBIAN}" --force-distribution -v "1:${PPG_COMMON_MAJOR}-${PPG_COMMON_MINOR}.${DEBIAN}" 'Update distribution'
    unset $(locale|cut -d= -f1)
    sed -i '38,55d' Makefile
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
VERSION_FILE=$CURDIR/percona-server-mongodb.properties
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
    source install-deps.sh "postgresql-common"
fi
get_sources
build_srpm
build_source_deb
build_rpm
build_deb
