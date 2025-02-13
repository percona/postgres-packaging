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
      if [ ${RHEL} = 7 ]; then
          INSTALL_LIST="git curl rpm-build rpmdevtools"
          yum -y install ${INSTALL_LIST}
      else
          dnf config-manager --set-enabled ol${RHEL}_codeready_builder
          dnf clean all
          rm -r /var/cache/dnf
          dnf -y upgrade
          if [ ${RHEL} = 9 ]; then
             yum install -y gcc-toolset-13-gdb
          fi
          INSTALL_LIST="git curl rpm-build rpmdevtools gcc gcc-c++ cmake ninja-build zlib-devel libffi-devel ncurses-devel python3-sphinx python3-recommonmark multilib-rpm-config binutils-devel valgrind-devel libedit-devel python3-devel libarchive pandoc clang python3-psutil rpmlint"
          yum -y install ${INSTALL_LIST}
      fi
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
    PRODUCT=llvm
    echo "PRODUCT=${PRODUCT}" > llvm.properties
    GIT_USER=$(echo ${REPO} | awk -F'/' '{print $4}')

    PRODUCT_FULL=${PRODUCT}-${VERSION}
    echo "PRODUCT_FULL=${PRODUCT_FULL}" >> llvm.properties
    echo "VERSION=${VERSION}" >> llvm.properties
    echo "BUILD_NUMBER=${BUILD_NUMBER}" >> llvm.properties
    echo "BUILD_ID=${BUILD_ID}" >> llvm.properties

    source llvm.properties
    DATE_TIMESTAMP=$(date +%F_%H-%M-%S)
    echo "UPLOAD=UPLOAD/experimental/BUILDS/${PRODUCT}/${PRODUCT_FULL}/${DATE_TIMESTAMP}/${BUILD_ID}" >> llvm.properties

    rm -fr rpmbuild
    #
    mkdir -vp rpmbuild/{SOURCES,SPECS,BUILD,SRPMS,RPMS}
    rpmdev-setuptree

    if [ ${RHEL} = 9 ]; then
        # RHEL repository version that carries llvm 17 src rpm
        RHEL_FULL_VERSION=9.4
        latest_rpm=$(curl -s https://vault.almalinux.org/${RHEL_FULL_VERSION}/AppStream/Source/Packages/ | grep -o 'llvm-[1-9][1-9].*\.src.rpm' | sort -V | grep ${VERSION} | tail -n 1 | awk -F'>' '{print $2}')
    elif [ ${RHEL} = 8 ]; then
        # RHEL repository version that carries llvm 17 src rpm
        RHEL_FULL_VERSION=8.10
        latest_rpm=$(curl -s https://vault.almalinux.org/${RHEL_FULL_VERSION}/AppStream/Source/Packages/ | grep -o 'llvm-[1-9][1-9].*\.src.rpm' | sort -V | grep ${VERSION} | tail -n 1)
    fi

    echo latest_rpm=$latest_rpm
    llvm_version=$(echo ${latest_rpm} | cut -f2 -d'-' | cut -f1 -d'.')
    echo llvm_version=$llvm_version

    cd ${WORKDIR}/rpmbuild/SRPMS/
    wget https://vault.almalinux.org/${RHEL_FULL_VERSION}/AppStream/Source/Packages/$latest_rpm
    latest_rpm=$(find . | grep llvm | grep src.rpm | cut -f2 -d'/')
    rpm -ivh $latest_rpm
    rm -f $latest_rpm
    cd /root/rpmbuild/SPECS
    sed -i 's/\.alma\.[0-9]\+//' llvm.spec
    sed -i '/^%if %{with check}/,/^%endif/s/^/#/' llvm.spec
    rpmbuild -bs llvm.spec
    cd -

    cp /root/rpmbuild/SRPMS/*.src.rpm ${WORKDIR}/rpmbuild/SRPMS
    mkdir -p ${WORKDIR}/srpm
    mkdir -p ${CURDIR}/srpm

    ls -lrt /root/rpmbuild/SRPMS/*.src.rpm
    cp /root/rpmbuild/SRPMS/*.src.rpm ${CURDIR}/srpm
    cp /root/rpmbuild/SRPMS/*.src.rpm ${WORKDIR}/srpm
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
    SRC_RPM=$(basename $(find $WORKDIR/srpm -name 'llvm*.src.rpm' | sort | tail -n1))
    if [ -z $SRC_RPM ]
    then
        SRC_RPM=$(basename $(find $CURDIR/srpm -name 'llvm*.src.rpm' | sort | tail -n1))
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
VERSION_FILE=$CURDIR/llvm.properties
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
#BRANCH="1.2"
#REPO="https://github.com/ymattw/llvm.git"
PRODUCT=llvm
DEBUG=0
parse_arguments PICK-ARGS-FROM-ARGV "$@"
VERSION='17.0'
RELEASE='1'
PG_VERSION=16.7
PRODUCT_FULL=${PRODUCT}-${VERSION}

check_workdir
get_system
install_deps
get_srpm
build_rpm
