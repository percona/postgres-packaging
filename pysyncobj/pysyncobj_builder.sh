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

switch_to_vault_repo() {
    sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-Linux-*
    sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-Linux-*
}

get_sources(){
    cd "${WORKDIR}"
    if [ "${SOURCE}" = 0 ]
    then
        echo "Sources will not be downloaded"
        return 0
    fi
    PRODUCT=python3-pysyncobj
    echo "PRODUCT=${PRODUCT}" > pysyncobj.properties
    GIT_USER=$(echo ${REPO} | awk -F'/' '{print $4}')

    PRODUCT_FULL=${PRODUCT}-${VERSION}
    echo "PRODUCT_FULL=${PRODUCT_FULL}" >> pysyncobj.properties
    echo "VERSION=${VERSION}" >> pysyncobj.properties
    echo "BUILD_NUMBER=${BUILD_NUMBER}" >> pysyncobj.properties
    echo "BUILD_ID=${BUILD_ID}" >> pysyncobj.properties
    git clone "$REPO" ${PRODUCT}-${VERSION}
    retval=$?
    if [ $retval != 0 ]
    then
        echo "There were some issues during repo cloning from github. Please retry one more time"
        exit 1
    fi
    cd ${PRODUCT}-${VERSION}
    if [ ! -z "$BRANCH" ]
    then
        git reset --hard
        git clean -xdf
        git checkout "$BRANCH"
    fi
    REVISION=$(git rev-parse --short HEAD)
    echo "REVISION=${REVISION}" >> ${WORKDIR}/pysyncobj.properties
    rm -fr debian rpm
    git clone https://github.com/Percona-Lab/python3-pysyncobj.git
    mv python3-pysyncobj/debian ./
    mkdir rpm
    cd rpm
    wget https://raw.githubusercontent.com/percona/postgres-packaging/${PG_VERSION}/pysyncobj/python3-pysyncobj.spec
    cd ../
    rm -rf python3-pysyncobj
    cd ../

    export DEBIAN=$(lsb_release -sc)
    cd ${WORKDIR}
    #
    source pysyncobj.properties
    #

    tar --owner=0 --group=0 --exclude=.* -czf ${PRODUCT}-${VERSION}.tar.gz ${PRODUCT}-${VERSION}
    DATE_TIMESTAMP=$(date +%F_%H-%M-%S)
    echo "UPLOAD=UPLOAD/experimental/BUILDS/${PRODUCT}/${PRODUCT_FULL}/${BRANCH}/${REVISION}/${DATE_TIMESTAMP}/${BUILD_ID}" >> pysyncobj.properties
    mkdir $WORKDIR/source_tarball
    mkdir $CURDIR/source_tarball
    cp ${PRODUCT}-${VERSION}.tar.gz $WORKDIR/source_tarball
    cp ${PRODUCT}-${VERSION}.tar.gz $CURDIR/source_tarball
    cd $CURDIR
    rm -rf python3-pysyncobj*
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
      if [ x"$RHEL" = x8 ]; then
          switch_to_vault_repo
      fi
      yum -y install wget
      yum clean all
      if [[ "${RHEL}" -eq 10 ]]; then
        yum install oracle-epel-release-el10
      else
        yum -y install epel-release
      fi
      RHEL=$(rpm --eval %rhel)
      if [ ${RHEL} = 7 ]; then
          INSTALL_LIST="git rpm-build python3-devel rpmdevtools rpmlint"
          yum -y install ${INSTALL_LIST}
      else
          dnf config-manager --set-enabled ol${RHEL}_codeready_builder
          dnf clean all
          rm -r /var/cache/dnf
          dnf -y upgrade
          INSTALL_LIST="git rpm-build python3-devel python3-setuptools rpmdevtools rpmlint"
          yum -y install ${INSTALL_LIST}
      fi
    else
      apt-get update || true
      apt-get -y install lsb-release wget curl gnupg2
      export DEBIAN=$(lsb_release -sc)
      export ARCH=$(echo $(uname -m) | sed -e 's:i686:i386:g')
      until apt-get -y install gnupg2; do
          sleep 3
	  echo "WAITING"
      done
      apt-get update || true

      INSTALL_LIST="build-essential debconf debhelper devscripts dh-exec git wget fakeroot devscripts python3-psycopg2 python3-setuptools libyaml-dev python3-virtualenv python3-psycopg2 ruby ruby-dev rubygems curl golang dh-python libjs-mathjax pyflakes3 python3-dateutil python3-dnspython python3-etcd  python3-flake8 python3-kazoo python3-mccabe python3-mock python3-prettytable python3-psutil python3-pycodestyle python3-pytest python3-pytest-cov python3-sphinx python3-sphinx-rtd-theme python3-tz python3-tzlocal sphinx-common python3-click python3-doc python3-all "
      if [ "x${DEBIAN}" = "xtrixie" ]; then
        INSTALL_LIST+="python3-dev dh-virtualenv python3-boto3"  
      elif [ "x${DEBIAN}" != "xfocal" ]; then
        INSTALL_LIST+="python3-dev dh-virtualenv python3-boto"
      else
        INSTALL_LIST+="python2-dev python3-boto"
      fi
      DEBIAN_FRONTEND=noninteractive apt-get -y install ${INSTALL_LIST}
    fi
    return;
}

get_tar(){
    TARBALL=$1
    TARFILE=$(basename $(find $WORKDIR/$TARBALL -name 'python3-pysyncobj*.tar.gz' | sort | tail -n1))
    if [ -z $TARFILE ]
    then
        TARFILE=$(basename $(find $CURDIR/$TARBALL -name 'python3-pysyncobj*.tar.gz' | sort | tail -n1))
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
    get_tar "source_tarball"
    rm -fr rpmbuild
    ls | grep -v tar.gz | xargs rm -rf
    TARFILE=$(find . -name 'python3-pysyncobj*.tar.gz' | sort | tail -n1)
    SRC_DIR=${TARFILE%.tar.gz}
    #
    mkdir -vp rpmbuild/{SOURCES,SPECS,BUILD,SRPMS,RPMS}
    tar vxzf ${WORKDIR}/${TARFILE} --wildcards '*/rpm' --strip=1
    #
    cp -av rpm/* rpmbuild/SOURCES
    cp -av rpm/python3-pysyncobj.spec rpmbuild/SPECS
    #
    mv -fv ${TARFILE} ${WORKDIR}/rpmbuild/SOURCES
    sed -i 's:.rhel7:%{dist}:' ${WORKDIR}/rpmbuild/SPECS/python3-pysyncobj.spec
    rpmbuild -bs --define "_topdir ${WORKDIR}/rpmbuild" --define "dist .generic" \
        --define "version ${VERSION}" rpmbuild/SPECS/python3-pysyncobj.spec
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
    get_tar "source_tarball"
    rm -f *.dsc *.orig.tar.gz *.debian.tar.gz *.changes
    #
    TARFILE=$(basename $(find . -name 'python3-pysyncobj*.tar.gz' | sort | tail -n1))
    DEBIAN=$(lsb_release -sc)
    ARCH=$(echo $(uname -m) | sed -e 's:i686:i386:g')
    tar zxf ${TARFILE}
    BUILDDIR=${TARFILE%.tar.gz}
    #
    
    mv ${TARFILE} python3-pysyncobj_${VERSION}.orig.tar.gz
    cd ${BUILDDIR}

    dch -D unstable --force-distribution -v "${VERSION}-${RELEASE}" "Update to new pysyncobj version ${VERSION}"
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
    #
    export DEBIAN=$(lsb_release -sc)
    export ARCH=$(echo $(uname -m) | sed -e 's:i686:i386:g')
    #
    echo "DEBIAN=${DEBIAN}" >> pysyncobj.properties
    echo "ARCH=${ARCH}" >> pysyncobj.properties

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
RPM_RELEASE=1
DEB_RELEASE=1
REVISION=0
BRANCH="0.3.10"
REPO="https://github.com/bakwc/PySyncObj.git"
PRODUCT=python3-pysyncobj
DEBUG=0
parse_arguments PICK-ARGS-FROM-ARGV "$@"
VERSION='0.3.10'
RELEASE='2'
PG_VERSION=14.19
PRODUCT_FULL=${PRODUCT}-${VERSION}-${RELEASE}
PG_MAJOR_VERSION=$(echo ${PG_VERSION} | cut -f1 -d'.')

check_workdir
get_system
install_deps
get_sources
build_srpm
build_source_deb
build_rpm
build_deb
