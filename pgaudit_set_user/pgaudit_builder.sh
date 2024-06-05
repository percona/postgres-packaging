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
    yum -y install https://repo.percona.com/yum/percona-release-latest.noarch.rpm
    wget https://raw.githubusercontent.com/percona/percona-repositories/release-1.0-28/scripts/percona-release.sh
    mv percona-release.sh /usr/bin/percona-release
    chmod 777 /usr/bin/percona-release
    percona-release disable all
    percona-release enable ppg-${PG_VERSION} testing
    return
}

add_percona_apt_repo(){
    wget https://repo.percona.com/apt/percona-release_latest.generic_all.deb
    dpkg -i percona-release_latest.generic_all.deb
    rm -f percona-release_latest.generic_all.deb
    percona-release disable all
    percona-release enable ppg-${PG_VERSION} testing
    return
}

get_sources(){
    cd "${WORKDIR}"
    if [ "${SOURCE}" = 0 ]
    then
        echo "Sources will not be downloaded"
        return 0
    fi
    PRODUCT=percona-pgaudit14_set_user
    echo "PRODUCT=${PRODUCT}" > pgaudit.properties

    PRODUCT_FULL=${PRODUCT}-${VERSION}
    echo "PRODUCT_FULL=${PRODUCT_FULL}" >> pgaudit.properties
    echo "VERSION=${PSM_VER}" >> pgaudit.properties
    echo "BUILD_NUMBER=${BUILD_NUMBER}" >> pgaudit.properties
    echo "BUILD_ID=${BUILD_ID}" >> pgaudit.properties
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
    REVISION=$(git rev-parse --short HEAD)
    echo "REVISION=${REVISION}" >> ${WORKDIR}/pgaudit.properties
    mkdir debian
    cd debian/
    mkdir source
    echo "3.0 (quilt)" > source/format
    echo 14 > pgversions
    echo 9 > compat
    echo "percona-pgaudit14-set-user (${VERSION}-${RELEASE}) unstable; urgency=low" >> changelog
    echo "  * Initial Release." >> changelog
    echo " -- EvgeniyPatlan <evgeniy.patlan@percona.com> $(date -R)" >> changelog
    
    wget https://raw.githubusercontent.com/percona/postgres-packaging/${PG_VERSION}/pgaudit_set_user/control
    wget https://raw.githubusercontent.com/percona/postgres-packaging/${PG_VERSION}/pgaudit_set_user/control.in
    wget https://raw.githubusercontent.com/percona/postgres-packaging/${PG_VERSION}/pgaudit_set_user/copyright
    wget https://raw.githubusercontent.com/percona/postgres-packaging/${PG_VERSION}/pgaudit_set_user/rules
    cd ../ 
    mkdir rpm
    cd rpm
    wget https://raw.githubusercontent.com/percona/postgres-packaging/${PG_VERSION}/pgaudit_set_user/percona-pgaudit14_set_user.spec
    cd ${WORKDIR}
    #
    source pgaudit.properties
    #

    tar --owner=0 --group=0 --exclude=.* -czf ${PRODUCT_FULL}.tar.gz ${PRODUCT_FULL}
    echo "UPLOAD=UPLOAD/experimental/BUILDS/${PRODUCT}/${PRODUCT_FULL}/${BRANCH}/${REVISION}/${BUILD_ID}" >> pgaudit.properties
    mkdir $WORKDIR/source_tarball
    mkdir $CURDIR/source_tarball
    cp ${PRODUCT_FULL}.tar.gz $WORKDIR/source_tarball
    cp ${PRODUCT_FULL}.tar.gz $CURDIR/source_tarball
    cd $CURDIR
    rm -rf pgaudit*
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
        add_percona_yum_repo
        yum clean all
        RHEL=$(rpm --eval %rhel)
        if [ x"$RHEL" = x6 -o x"$RHEL" = x7 ]; then
            until yum -y install centos-release-scl; do
                echo "waiting"
                sleep 1
            done
            yum -y install epel-release
            INSTALL_LIST="bison e2fsprogs-devel flex gettext git glibc-devel krb5-devel libicu-devel libselinux-devel libuuid-devel libxml2-devel libxslt-devel llvm5.0-devel llvm-toolset-7-clang openldap-devel openssl-devel pam-devel patch perl perl-ExtUtils-Embed perl-ExtUtils-MakeMaker python2-devel readline-devel rpmbuild percona-postgresql14-devel percona-postgresql14-server rpm-build rpmdevtools selinux-policy systemd systemd-devel systemtap-sdt-devel tcl-devel vim wget zlib-devel llvm-toolset-7-clang-devel make"
            yum -y install ${INSTALL_LIST}
            source /opt/rh/devtoolset-7/enable
            source /opt/rh/llvm-toolset-7/enable
        else
            yum -y install epel-release
            dnf config-manager --set-enabled ol${RHEL}_codeready_builder
            dnf module disable postgresql

            if [ x"$RHEL" = x8 ];
            then
                clang_version=$(yum list --showduplicates clang-devel | grep "16.0" | awk '{print $2}' | head -n 1)
                yum install -y clang-devel-${clang_version} clang-${clang_version}
                dnf module -y disable llvm-toolset
            else
                yum install -y clang-devel clang
            fi

            INSTALL_LIST="python3-devel perl-generators bison e2fsprogs-devel flex gettext git glibc-devel krb5-devel libicu-devel libselinux-devel libuuid-devel libxml2-devel libxslt-devel llvm-devel openldap-devel openssl-devel pam-devel patch perl perl-ExtUtils-MakeMaker perl-ExtUtils-Embed readline-devel percona-postgresql14-devel percona-postgresql14-server rpm-build rpmdevtools selinux-policy systemd systemd-devel systemtap-sdt-devel tcl-devel vim wget zlib-devel "
            yum -y install ${INSTALL_LIST}
            yum -y install binutils gcc gcc-c++
        fi
    else
        export ARCH=$(echo $(uname -m) | sed -e 's:i686:i386:g')
	apt-get -y update || true
        apt-get -y install lsb-release wget gnupg2 curl
        export DEBIAN=$(lsb_release -sc)
        add_percona_apt_repo
        percona-release enable tools testing
        percona-release enable ppg-${PG_VERSION} testing
        apt-get update || true
        INSTALL_LIST="build-essential dpkg-dev debconf debhelper clang devscripts dh-exec git wget libkrb5-dev libssl-dev percona-postgresql-common percona-postgresql-server-dev-all"
        DEBIAN_FRONTEND=noninteractive apt-get -y --allow-unauthenticated install ${INSTALL_LIST}
    fi
    return;
}

get_tar(){
    TARBALL=$1
    TARFILE=$(basename $(find $WORKDIR/$TARBALL -name 'percona-pgaudit*.tar.gz' | sort | tail -n1))
    if [ -z $TARFILE ]
    then
        TARFILE=$(basename $(find $CURDIR/$TARBALL -name 'percona-pgaudit*.tar.gz' | sort | tail -n1))
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
    FILE=$(basename $(find $WORKDIR/source_deb -name "percona-pgaudit*.$param" | sort | tail -n1))
    if [ -z $FILE ]
    then
        FILE=$(basename $(find $CURDIR/source_deb -name "percona-pgaudit*.$param" | sort | tail -n1))
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
    TARFILE=$(find . -name 'percona-pgaudit*.tar.gz' | sort | tail -n1)
    SRC_DIR=${TARFILE%.tar.gz}
    #
    mkdir -vp rpmbuild/{SOURCES,SPECS,BUILD,SRPMS,RPMS}
    tar vxzf ${WORKDIR}/${TARFILE} --wildcards '*/rpm' --strip=1
    #
    cp -av rpm/* rpmbuild/SOURCES
    cp -av rpm/percona-pgaudit14_set_user.spec rpmbuild/SPECS
    #
    mv -fv ${TARFILE} ${WORKDIR}/rpmbuild/SOURCES
    rpmbuild -bs --define "_topdir ${WORKDIR}/rpmbuild" --define "dist .generic" \
        --define "version ${VERSION}" rpmbuild/SPECS/percona-pgaudit14_set_user.spec
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
    SRC_RPM=$(basename $(find $WORKDIR/srpm -name 'percona-pgaudit*.src.rpm' | sort | tail -n1))
    if [ -z $SRC_RPM ]
    then
        SRC_RPM=$(basename $(find $CURDIR/srpm -name 'percona-pgaudit*.src.rpm' | sort | tail -n1))
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
    rpmbuild --define "_topdir ${WORKDIR}/rpmbuild" --define "pgmajorversion 14" --define "dist .$OS_NAME" --define "version ${VERSION}" --rebuild rpmbuild/SRPMS/$SRC_RPM

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
    rm -rf percona-pgaudit*
    get_tar "source_tarball"
    rm -f *.dsc *.orig.tar.gz *.debian.tar.gz *.changes
    #
    TARFILE=$(basename $(find . -name 'percona-pgaudit*.tar.gz' | sort | tail -n1))
    DEBIAN=$(lsb_release -sc)
    ARCH=$(echo $(uname -m) | sed -e 's:i686:i386:g')
    tar zxf ${TARFILE}
    BUILDDIR=${TARFILE%.tar.gz}
    #
    PRODUCT_DEB="percona-pgaudit14-set-user"
    mv ${TARFILE} ${PRODUCT_DEB}_${VERSION}.orig.tar.gz
    cd ${BUILDDIR}

    dch -D unstable --force-distribution -v "${VERSION}-${RELEASE}" "Update to new pgaudit version ${VERSION}"
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
    echo "DEBIAN=${DEBIAN}" >> pgaudit.properties
    echo "ARCH=${ARCH}" >> pgaudit.properties

    #
    DSC=$(basename $(find . -name '*.dsc' | sort | tail -n1))
    #
    dpkg-source -x ${DSC}
    #
    cd percona-pgaudit14-set-user-${VERSION}
    dch -m -D "${DEBIAN}" --force-distribution -v "1:${VERSION}-${RELEASE}.${DEBIAN}" 'Update distribution'
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
VERSION_FILE=$CURDIR/pgaudit.properties
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
RPM_RELEASE=4
DEB_RELEASE=4
REVISION=0
BRANCH="REL4_0_1"
REPO="https://github.com/pgaudit/set_user.git"
PRODUCT=percona-pgaudit14_set_user
DEBUG=0
parse_arguments PICK-ARGS-FROM-ARGV "$@"
VERSION='4.0.1'
RELEASE='4'
PRODUCT_FULL=${PRODUCT}-${VERSION}-${RELEASE}
PG_VERSION=14.12

check_workdir
get_system
install_deps
get_sources
build_srpm
build_source_deb
build_rpm
build_deb
