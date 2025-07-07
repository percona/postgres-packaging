#!/usr/bin/env bash

shell_quote_string() {
  echo "$1" | sed -e 's,\([^a-zA-Z0-9/_.=-]\),\\\1,g'
}

usage () {
    cat <<EOF
Usage: $0 [OPTIONS]
    The following options may be given :
        --builddir=DIR      Absolute path to the dir where all actions will be performed
        --get_src_rpm       If it is set - downloads src rpm
        --build_rpm         If it is set - rpm will be built
        --install_deps      Install build dependencies(root privilages are required)
        --branch            Branch for build
        --repo              Repo for build
        --help) usage ;;
Example $0 --builddir=/tmp/BUILD --get_src_rpm=1 --build_rpm=1
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
            --get_src_rpm=*) SRPM="$val" ;;
            --build_rpm=*) RPM="$val" ;;
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
      yum -y install epel-release wget
      yum clean all
      RHEL=$(rpm --eval %rhel)
      ARCH=$(echo $(uname -m) | sed -e 's:i686:i386:g')
      dnf config-manager --set-enabled ol${RHEL}_codeready_builder
      yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-${RHEL}.noarch.rpm
      yum -y install https://download.postgresql.org/pub/repos/yum/reporpms/EL-${RHEL}-${ARCH}/pgdg-redhat-repo-latest.noarch.rpm
      yum -y install pgdg-srpm-macros
      INSTALL_LIST="wget git vim chrpath rpmdevtools cmake gcc-c++ libcurl-devel libtiff-devel sqlite-devel"
      yum -y install ${INSTALL_LIST}
    fi
    return;
}

get_srpm(){
    if [ $SRPM = 0 ]
    then
        echo "SRC RPM will not be created"
        return;
    fi

    cd $WORKDIR
    PRODUCT=proj95
    echo "PRODUCT=${PRODUCT}" > proj95.properties
    GIT_USER=$(echo ${REPO} | awk -F'/' '{print $4}')

    PRODUCT_FULL=${PRODUCT}-${VERSION}
    echo "PRODUCT_FULL=${PRODUCT_FULL}" >> proj95.properties
    echo "VERSION=${VERSION}" >> proj95.properties
    echo "BUILD_NUMBER=${BUILD_NUMBER}" >> proj95.properties
    echo "BUILD_ID=${BUILD_ID}" >> proj95.properties

    source proj95.properties
    DATE_TIMESTAMP=$(date +%F_%H-%M-%S)
    echo "UPLOAD=UPLOAD/experimental/BUILDS/${PRODUCT}/${PRODUCT_FULL}/${DATE_TIMESTAMP}/${BUILD_ID}" >> proj95.properties

    rm -fr rpmbuild
    #
    mkdir -vp rpmbuild/{SOURCES,SPECS,BUILD,SRPMS,RPMS}
    rpmdev-setuptree
    latest_rpm="proj95-9.5.1-1PGDG.rhel8.src.rpm"
    
    cd ${WORKDIR}/rpmbuild/SRPMS/
    wget https://dnf-srpms.postgresql.org/srpms/common/redhat/rhel-8-x86_64/proj95-9.5.1-1PGDG.rhel8.src.rpm
    latest_rpm=$(find . | grep proj95 | grep src.rpm | cut -f2 -d'/')
    rpm2cpio $latest_rpm | cpio -id
    rm -f $latest_rpm
    mv proj95.spec ../SPECS/
    mv * ../SOURCES/
    cd ../SPECS
    rm -rf proj95.spec
    wget <spec from git>
    cd ../../
    rpmbuild -bs --define "_topdir ${WORKDIR}/rpmbuild" --define "dist .generic" rpmbuild/SPECS/proj95.spec

    cp rpmbuild/SRPMS/*.src.rpm ${WORKDIR}/rpmbuild/SRPMS
    mkdir -p ${WORKDIR}/srpm
    mkdir -p ${CURDIR}/srpm

    ls -lrt rpmbuild/SRPMS/*.src.rpm
    cp rpmbuild/SRPMS/*.src.rpm ${CURDIR}/srpm
    cp rpmbuild/SRPMS/*.src.rpm ${WORKDIR}/srpm
    cd ${WORKDIR}
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
    SRC_RPM=$(basename $(find $WORKDIR/srpm -name 'proj95*.src.rpm' | sort | tail -n1))
    if [ -z $SRC_RPM ]
    then
        SRC_RPM=$(basename $(find $CURDIR/srpm -name 'proj95*.src.rpm' | sort | tail -n1))
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
    #
    cd $WORKDIR
    RHEL=$(rpm --eval %rhel)
    ARCH=$(echo $(uname -m) | sed -e 's:i686:i386:g')
    rpmbuild --define "_topdir ${WORKDIR}/rb" --define "dist .$OS_NAME" --define "version ${VERSION}" --rebuild rb/SRPMS/$SRC_RPM

    return_code=$?
    if [ $return_code != 0 ]; then
        exit $return_code
    fi
    mkdir -p ${WORKDIR}/rpm
    mkdir -p ${CURDIR}/rpm
    cp rb/RPMS/*/*.rpm ${WORKDIR}/rpm
    cp rb/RPMS/*/*.rpm ${CURDIR}/rpm
}

#main
export GIT_SSL_NO_VERIFY=1
CURDIR=$(pwd)
VERSION_FILE=$CURDIR/proj95.properties
args=
WORKDIR=
SRPM=0
RPM=0
SOURCE=0
OS_NAME=
ARCH=
OS=
INSTALL=0
RPM_RELEASE=1
REVISION=0
PRODUCT=proj95
DEBUG=0
parse_arguments PICK-ARGS-FROM-ARGV "$@"
VERSION='17.0'
RELEASE='1'
PG_VERSION=17.5
PRODUCT_FULL=${PRODUCT}-${VERSION}
check_workdir
get_system
install_deps
get_srpm
build_rpm
