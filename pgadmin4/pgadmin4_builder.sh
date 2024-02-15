#!/usr/bin/env bash

shell_quote_string() {
  echo "$1" | sed -e 's,\([^a-zA-Z0-9/_.=-]\),\\\1,g'
}

usage () {
    cat <<EOF
Usage: $0 [OPTIONS]
    The following options may be given :
        --builddir=DIR      Absolute path to the dir where all actions will be performed
        --get_sources       Source will be downloaded from github
        --build_src_rpm     If it is set - src rpm will be built
        --build_src_deb  If it is set - source deb package will be built
        --build_rpm         If it is set - rpm will be built
        --build_deb         If it is set - deb will be built
        --install_deps      Install build dependencies(root privilages are required)
        --branch            Branch for build
        --repo              Repo for build
        --help) usage ;;
Example $0 --builddir=/tmp/BUILD --get_sources=1 --build_src_rpm=1 --build_rpm=1
EOF
        exit 1
}

append_arg_to_args () {
  args="$args "$(shell_quote_string "$1")
}

parse_arguments() {
    pick_args=
    if test "$1" = PICK-ARGS-FROM-ARGV
    then
        pick_args=1
        shift
    fi

    for arg do
        val=$(echo "$arg" | sed -e 's;^--[^=]*=;;')
        case "$arg" in
            --builddir=*) WORKDIR="$val" ;;
            --build_src_rpm=*) SRPM="$val" ;;
            --build_src_deb=*) SDEB="$val" ;;
            --build_rpm=*) RPM="$val" ;;
            --build_deb=*) DEB="$val" ;;
            --get_sources=*) SOURCE="$val" ;;
            --branch=*) BRANCH="$val" ;;
            --repo=*) REPO="$val" ;;
            --install_deps=*) INSTALL="$val" ;;
            --help) usage ;;
            *)
              if test -n "$pick_args"
              then
                  append_arg_to_args "$arg"
              fi
              ;;
        esac
    done
}

check_workdir(){
    if [ "x$WORKDIR" = "x$CURDIR" ]
    then
        echo >&2 "Current directory cannot be used for building!"
        exit 1
    else
        if ! test -d "$WORKDIR"
        then
            echo >&2 "$WORKDIR is not a directory."
            exit 1
        fi
    fi
    return
}

add_percona_yum_repo(){
    if [ ! -f /etc/yum.repos.d/percona-dev.repo ]
    then
      wget http://jenkins.percona.com/yum-repo/percona-dev.repo || true
      #mv -f percona-dev.repo /etc/yum.repos.d/
    fi
    yum -y install https://repo.percona.com/yum/percona-release-latest.noarch.rpm
    percona-release disable all
    percona-release enable ppg-${PG_VERSION} testing
    return
}

add_percona_apt_repo(){
    wget https://repo.percona.com/apt/percona-release_latest.generic_all.deb
    dpkg -i percona-release_latest.generic_all.deb
    rm -f percona-release_latest.generic_all.deb
    percona-release disable all
    percona-release enable ppg-13.2 testing
    return
}

get_sources(){
    cd "${WORKDIR}"
    if [ "${SOURCE}" = 0 ]
    then
        echo "Sources will not be downloaded"
        return 0
    fi
    PRODUCT=percona-pgadmin4
    echo "PRODUCT=${PRODUCT}" > pgadmin4.properties

    PRODUCT_FULL=${PRODUCT}-${VERSION}
    echo "PRODUCT_FULL=${PRODUCT_FULL}" >> pgadmin4.properties
    echo "VERSION=${PSM_VER}" >> pgadmin4.properties
    echo "BUILD_NUMBER=${BUILD_NUMBER}" >> pgadmin4.properties
    echo "BUILD_ID=${BUILD_ID}" >> pgadmin4.properties
    git clone "$REPO" ${PRODUCT_FULL}
    retval=$?
    if [ $retval != 0 ]
    then
        echo "There were some issues during repo cloning from github. Please retry one more time"
        exit 1
    fi
    cd ${PRODUCT_FULL}
    if [ ! -z "$BRANCH" ]
    then
        git reset --hard
        git clean -xdf
        git checkout "$BRANCH"
    fi
    sed -i '34,$d' pkg/redhat/build.sh
    sed -i '25,$d' pkg/debian/build.sh
    sed -i '174i pip3 install sphinx' pkg/linux/build-functions.sh
    sed -i 's:pgsql-12:pgsql-13:' pkg/redhat/build.sh
    sed -i 's:pgsql-12:pgsql-13:' docs/en_US/container_deployment.rst
    REVISION=$(git rev-parse --short HEAD)
    echo "REVISION=${REVISION}" >> ${WORKDIR}/pgadmin4.properties
    
    mkdir debian
    cd debian/
    wget https://raw.githubusercontent.com/percona/postgres-packaging/13/pgadmin4/control
    wget https://raw.githubusercontent.com/percona/postgres-packaging/13/pgadmin4/rules
    chmod +x rules
    wget https://raw.githubusercontent.com/percona/postgres-packaging/13/pgadmin4/copyright
    echo 9 > compat
    echo "percona-pgadmin4 (${VERSION}-${RELEASE}) unstable; urgency=low" >> changelog
    echo "  * Initial Release." >> changelog
    echo " -- EvgeniyPatlan <evgeniy.patlan@percona.com> $(date -R)" >> changelog

    cd ../
    mkdir rpm
    cd rpm
    wget https://raw.githubusercontent.com/percona/postgres-packaging/13/pgadmin4/percona-pgadmin4.spec
    wget https://raw.githubusercontent.com/percona/postgres-packaging/13/pgadmin4/pgadmin4-sphinx-theme.patch
    wget https://raw.githubusercontent.com/percona/postgres-packaging/13/pgadmin4/pgadmin4-python3-mod_wsgi.conf
    wget https://raw.githubusercontent.com/percona/postgres-packaging/13/pgadmin4/pgadmin4-python3-mod_wsgi-exports.patch
    cd ${WORKDIR}
    #
    source pgadmin4.properties
    #

    tar --owner=0 --group=0 -czf ${PRODUCT_FULL}.tar.gz ${PRODUCT_FULL}
    echo "UPLOAD=UPLOAD/experimental/BUILDS/${PRODUCT}/${PRODUCT_FULL}/${PSM_BRANCH}/${REVISION}/${BUILD_ID}" >> pgadmin4.properties
    mkdir $WORKDIR/source_tarball
    mkdir $CURDIR/source_tarball
    cp ${PRODUCT_FULL}.tar.gz $WORKDIR/source_tarball
    cp ${PRODUCT_FULL}.tar.gz $CURDIR/source_tarball
    cd $CURDIR
    rm -rf percona-pgadmin4*
    return
}

get_system(){
    if [ -f /etc/redhat-release ]; then
        RHEL=$(rpm --eval %rhel)
        ARCH=$(echo $(uname -m) | sed -e 's:i686:i386:g')
        OS_NAME="el$RHEL"
        OS="rpm"
    else
        ARCH=$(uname -m)
        OS_NAME="$(lsb_release -sc)"
        OS="deb"
    fi
    return
}

install_deps() {
    if [ $INSTALL = 0 ]
    then
        echo "Dependencies will not be installed"
        return;
    fi
    if [ $( id -u ) -ne 0 ]
    then
        echo "It is not possible to instal dependencies. Please run as root"
        exit 1
    fi
    CURPLACE=$(pwd)

    if [ "x$OS" = "xrpm" ]; then
        yum -y install wget
        #add_percona_yum_repo
        yum clean all
        yum install -y epel-release
        yum -y install centos-release-scl
        yum -y install curl
        RHEL=$(rpm --eval %rhel)
        if [ ${RHEL} -gt 7 ]; then
            yum config-manager --enable PowerTools AppStream BaseOS *epel
            dnf -qy module disable postgresql
            dnf config-manager --set-enabled codeready-builder-for-rhel-${RHEL}-x86_64-rpms
            dnf clean all
            rm -r /var/cache/dnf
            dnf -y upgrade
            yum -y install rpmbuild
        fi
        curl -sL https://rpm.nodesource.com/setup_12.x | bash -
        curl --silent --location https://dl.yarnpkg.com/rpm/yarn.repo | tee /etc/yum.repos.d/yarn.repo
        yum groupinstall -y "Development Tools"
        if [ ${RHEL} = 7 ]; then
            yum install -y expect fakeroot httpd-devel percona-postgresql13-devel percona-postgresql-common percona-postgresql-server-dev-all percona-postgresql13-devel python3-devel nodejs yarn rpm-build rpm-sign yum-utils krb5-devel pip3 install sphinx python3-sphinx
        else
            yum install -y expect fakeroot percona-postgresql13-devel percona-postgresql-common percona-postgresql-server-dev-all percona-postgresql13-devel python3-devel nodejs yarn rpm-build rpm-sign yum-utils krb5-devel
            pip3 install sphinx
        fi
    else
        export DEBIAN=$(lsb_release -sc)
        export ARCH=$(echo $(uname -m) | sed -e 's:i686:i386:g')
        until apt-get update; do
            sleep 1
            echo "waiting"
        done
        DEBIAN_FRONTEND=noninteractive apt install -y curl apt-transport-https ca-certificates gnupg
        apt-get -y install gnupg2
        add_percona_apt_repo
        apt-get update || true
        dpkg -r yarn
        curl -sL https://deb.nodesource.com/setup_12.x | bash -
        curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
        echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
        apt-get update
        INSTALL_LIST="build-essential python3-dev python3-venv python3-sphinx python3-wheel libpq-dev libffi-dev nodejs yarn libkrb5-dev debhelper dpkg-dev git"
        until DEBIAN_FRONTEND=noninteractive apt-get -y --allow-unauthenticated install ${INSTALL_LIST}; do
            sleep 1
            echo "waiting"
        done
    fi
    return;
}

get_tar(){
    TARBALL=$1
    TARFILE=$(basename $(find $WORKDIR/$TARBALL -name 'percona-pgadmin4*.tar.gz' | sort | tail -n1))
    if [ -z $TARFILE ]
    then
        TARFILE=$(basename $(find $CURDIR/$TARBALL -name 'percona-pgadmin4*.tar.gz' | sort | tail -n1))
        if [ -z $TARFILE ]
        then
            echo "There is no $TARBALL for build"
            exit 1
        else
            cp $CURDIR/$TARBALL/$TARFILE $WORKDIR/$TARFILE
        fi
    else
        cp $WORKDIR/$TARBALL/$TARFILE $WORKDIR/$TARFILE
    fi
    return
}

get_deb_sources(){
    param=$1
    echo $param
    FILE=$(basename $(find $WORKDIR/source_deb -name "percona-pgadmin4*.$param" | sort | tail -n1))
    if [ -z $FILE ]
    then
        FILE=$(basename $(find $CURDIR/source_deb -name "percona-pgadmin4*.$param" | sort | tail -n1))
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
    get_tar "source_tarball"
    rm -fr rpmbuild
    ls | grep -v tar.gz | xargs rm -rf
    TARFILE=$(find . -name 'percona-pgadmin4*.tar.gz' | sort | tail -n1)
    SRC_DIR=${TARFILE%.tar.gz}
    #
    mkdir -vp rpmbuild/{SOURCES,SPECS,BUILD,SRPMS,RPMS}
    tar vxzf ${WORKDIR}/${TARFILE} --wildcards '*/rpm' --strip=1
    #
    cp -av rpm/* rpmbuild/SOURCES
    cp -av rpm/percona-pgadmin4.spec rpmbuild/SPECS
    #
    curl -o ${WORKDIR}/rpmbuild/SOURCES/mod_wsgi-4.7.1.tar.gz https://codeload.github.com/GrahamDumpleton/mod_wsgi/tar.gz/4.7.1
    mv -fv ${TARFILE} ${WORKDIR}/rpmbuild/SOURCES
    rpmbuild -bs --define "_topdir ${WORKDIR}/rpmbuild" --define "pginstdir /usr/pgsql-13" --define "dist .generic" \
        --define "version ${VERSION}" rpmbuild/SPECS/percona-pgadmin4.spec
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
    SRC_RPM=$(basename $(find $WORKDIR/srpm -name 'percona-pgadmin4*.src.rpm' | sort | tail -n1))
    if [ -z $SRC_RPM ]
    then
        SRC_RPM=$(basename $(find $CURDIR/srpm -name 'percona-pgadmin4*.src.rpm' | sort | tail -n1))
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
    export LIBPQ_DIR=/usr/pgsql-13/
    export LIBRARY_PATH=/usr/pgsql-13/lib/:/usr/pgsql-13/include/
    rpmbuild --define "_topdir ${WORKDIR}/rpmbuild" --define "pginstdir /usr/pgsql-13" --define "dist .$OS_NAME" --define "version ${VERSION}" --rebuild rpmbuild/SRPMS/$SRC_RPM

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
    rm -rf percona-pgadmin4*
    get_tar "source_tarball"
    rm -f *.dsc *.orig.tar.gz *.debian.tar.gz *.changes
    #
    TARFILE=$(basename $(find . -name 'percona-pgadmin4*.tar.gz' | sort | tail -n1))
    DEBIAN=$(lsb_release -sc)
    ARCH=$(echo $(uname -m) | sed -e 's:i686:i386:g')
    tar zxf ${TARFILE}
    BUILDDIR=${TARFILE%.tar.gz}
    #
    
    mv ${TARFILE} ${PRODUCT}_${VERSION}.orig.tar.gz
    cd ${BUILDDIR}    
    dch -D unstable --force-distribution -v "${VERSION}-${RELEASE}" "Update to new pgadmin4 version ${VERSION}"
    dpkg-buildpackage -S
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
    #for file in 'dsc' 'orig.tar.gz' 'changes' 'debian.tar*'
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
    echo "DEBIAN=${DEBIAN}" >> pgadmin4.properties
    echo "ARCH=${ARCH}" >> pgadmin4.properties

    #
    DSC=$(basename $(find . -name '*.dsc' | sort | tail -n1))
    #
    dpkg-source -x ${DSC}
    #
    cd ${PRODUCT}-${VERSION}
    dch -m -D "${DEBIAN}" --force-distribution -v "1:${VERSION}-${RELEASE}.${DEBIAN}" 'Update distribution'
    unset $(locale|cut -d= -f1)
    dpkg-buildpackage -rfakeroot -us -uc -b
    mkdir -p $CURDIR/deb
    mkdir -p $WORKDIR/deb
    cp $WORKDIR/*.*deb $WORKDIR/deb
    cp $WORKDIR/*.*deb $CURDIR/deb
}
#main

CURDIR=$(pwd)
VERSION_FILE=$CURDIR/pgadmin4.properties
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
RPM_RELEASE=1
DEB_RELEASE=1
REVISION=0
BRANCH="REL-5_0"
REPO="https://github.com/postgres/pgadmin4.git"
PRODUCT=percona-pgadmin4
DEBUG=0
parse_arguments PICK-ARGS-FROM-ARGV "$@"
VERSION='5.0'
RELEASE='1'
PRODUCT_FULL=${PRODUCT}-${VERSION}-${RELEASE}
PG_VERSION=16.2

check_workdir
get_system
install_deps
get_sources
build_srpm
build_source_deb
build_rpm
build_deb
