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

add_percona_yum_repo(){
    if [ ! -f /etc/yum.repos.d/percona-dev.repo ]
    then
      wget http://jenkins.percona.com/yum-repo/percona-dev.repo
      #mv -f percona-dev.repo /etc/yum.repos.d/
    fi
    yum -y install https://repo.percona.com/yum/percona-release-latest.noarch.rpm
    percona-release disable all
    percona-release enable ppg-12.15 testing
    return
}

add_percona_apt_repo(){
    wget https://repo.percona.com/apt/percona-release_latest.generic_all.deb
    dpkg -i percona-release_latest.generic_all.deb
    rm -f percona-release_latest.generic_all.deb
    percona-release disable all
    percona-release enable ppg-12.15 testing
    return
}

get_sources(){
    cd "${WORKDIR}"
    if [ "${SOURCE}" = 0 ]
    then
        echo "Sources will not be downloaded"
        return 0
    fi
    PRODUCT=percona-patroni
    echo "PRODUCT=${PRODUCT}" > patroni.properties
    GIT_USER=$(echo ${REPO} | awk -F'/' '{print $4}')

    PRODUCT_FULL=${PRODUCT}-${VERSION}
    echo "PRODUCT_FULL=${PRODUCT_FULL}" >> patroni.properties
    echo "VERSION=${PSM_VER}" >> patroni.properties
    echo "BUILD_NUMBER=${BUILD_NUMBER}" >> patroni.properties
    echo "BUILD_ID=${BUILD_ID}" >> patroni.properties
#   git clone "$REPO" ${PRODUCT_FULL}
    git clone https://github.com/zalando/patroni.git ${PRODUCT_FULL}
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
    echo "REVISION=${REVISION}" >> ${WORKDIR}/patroni.properties
    rm -fr debian rpm
    git clone https://github.com/cybertec-postgresql/patroni-packaging.git all_packaging
    cd all_packaging
        git reset --hard
        git clean -xdf
        git checkout "v1.6.5-1"
    cd ../
    mv all_packaging/DEB/debian ./
    cd debian
    rm -f rules
    wget https://raw.githubusercontent.com/percona/postgres-packaging/12.15/patroni/rules
    rm -f control
    rm -f postinst
    wget https://raw.githubusercontent.com/percona/postgres-packaging/12.15/patroni/control
    sed -i 's:service-info-only-in-pretty-format.patch::' patches/series
    sed -i 's:patronictl-reinit-wait-rebased-1.6.0.patch::' patches/series
    mv install percona-patroni.install
    echo "debian/tmp/usr/lib" >> percona-patroni.install
    echo "debian/tmp/usr/bin" >> percona-patroni.install
    echo "docs/README.rst" >> percona-patroni-doc.install
    cd ../
    mkdir rpm
    mv all_packaging/RPM/* rpm/
    cd rpm
    rm -f patroni.spec
    wget https://raw.githubusercontent.com/percona/postgres-packaging/12.15/patroni/patroni.spec
    sed -i 's:/opt/app:/opt:g' patroni.2.service
    sed -i 's:/opt/patroni/bin:/usr/bin:' patroni.2.service
    sed -i 's:/opt/patroni/etc/:/etc/patroni/:' patroni.2.service
    mv patroni.2.service patroni.service
    tar -czf patroni-customizations.tar.gz patroni.service patroni-watchdog.service postgres-telia.yml
    cd ../
    rm -rf all_packaging
    cd ${WORKDIR}
    #
    source patroni.properties
    #

    tar --owner=0 --group=0 --exclude=.* -czf ${PRODUCT_FULL}.tar.gz ${PRODUCT_FULL}
    echo "UPLOAD=UPLOAD/experimental/BUILDS/${PRODUCT}/${PRODUCT_FULL}/${BRANCH}/${REVISION}/${BUILD_ID}" >> patroni.properties
    mkdir $WORKDIR/source_tarball
    mkdir $CURDIR/source_tarball
    cp ${PRODUCT_FULL}.tar.gz $WORKDIR/source_tarball
    cp ${PRODUCT_FULL}.tar.gz $CURDIR/source_tarball
    cd $CURDIR
    rm -rf percona-patroni*
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
      add_percona_yum_repo
      wget http://jenkins.percona.com/yum-repo/percona-dev.repo
      #mv -f percona-dev.repo /etc/yum.repos.d/
      yum clean all
      RHEL=$(rpm --eval %rhel)
      if [ ${RHEL} -gt 7 ]; then
          yum config-manager --set-enabled PowerTools || yum config-manager --set-enabled powertools || true
      fi
      if [ ${RHEL} = 7 ]; then
          INSTALL_LIST="git wget rpm-build python36-virtualenv prelink libyaml-devel gcc python36-psycopg2 python36-six"
          yum -y install ${INSTALL_LIST}
      else
          dnf config-manager --set-enabled ol${RHEL}_codeready_builder
          dnf clean all
          rm -r /var/cache/dnf
          dnf -y upgrade
          wget https://rpmfind.net/linux/centos/7/os/x86_64/Packages/prelink-0.5.0-9.el7.x86_64.rpm
          INSTALL_LIST="git wget rpm-build python3-virtualenv libyaml-devel gcc python3-psycopg2"
          yum -y install ${INSTALL_LIST}
          yum -y install prelink-0.5.0-9.el7.x86_64.rpm
	      #ln -s /usr/bin/virtualenv-2 /usr/bin/virtualenv
      fi
    else
      export DEBIAN=$(lsb_release -sc)
      export ARCH=$(echo $(uname -m) | sed -e 's:i686:i386:g')
      until apt-get -y install gnupg2; do
          sleep 3
	  echo "WAITING"
      done
      add_percona_apt_repo
      apt-get update || true
      if [ "x${DEBIAN}" != "xfocal" -a "x${DEBIAN}" != "xbullseye" -a "x${DEBIAN}" != "xjammy" ]; then
        INSTALL_LIST="build-essential debconf debhelper clang-11 devscripts dh-exec git wget build-essential fakeroot devscripts python3-psycopg2 python-setuptools python-dev libyaml-dev python3-virtualenv dh-virtualenv python3-psycopg2 wget git ruby ruby-dev rubygems build-essential curl golang libjs-mathjax pyflakes3 python3-boto python3-dateutil python3-dnspython python3-etcd  python3-flake8 python3-kazoo python3-mccabe python3-mock python3-prettytable python3-psutil python3-pycodestyle python3-pytest python3-pytest-cov python3-setuptools python3-sphinx python3-sphinx-rtd-theme python3-tz python3-tzlocal sphinx-common python3-click python3-doc python3-cdiff dh-python"
      else
        INSTALL_LIST="build-essential debconf debhelper clang-11 devscripts dh-exec git wget build-essential fakeroot devscripts python3-psycopg2 python2-dev libyaml-dev python3-virtualenv python3-psycopg2 wget git ruby ruby-dev rubygems build-essential curl golang libjs-mathjax pyflakes3 python3-boto python3-dateutil python3-dnspython python3-etcd  python3-flake8 python3-kazoo python3-mccabe python3-mock python3-prettytable python3-psutil python3-pycodestyle python3-pytest python3-pytest-cov python3-setuptools python3-sphinx python3-sphinx-rtd-theme python3-tz python3-tzlocal sphinx-common python3-click python3-doc python3-cdiff dh-python"
      fi
      DEBIAN_FRONTEND=noninteractive apt-get -y install ${INSTALL_LIST}
      if [ "x${DEBIAN}" = "xstretch" ]; then
        DEBIAN_FRONTEND=noninteractive apt-get -y install python3-pip
	pip3 install python-consul
	pip3 install python-kubernetes 
      else 
        DEBIAN_FRONTEND=noninteractive apt-get -y install python3-consul python3-kubernetes python3-cdiff || true
      fi
      if [ "x${DEBIAN}" = "xfocal" ]; then
        wget https://bootstrap.pypa.io/get-pip.py
        python2.7 get-pip.py
        rm -rf /usr/bin/python2
        ln -s /usr/bin/python2.7 /usr/bin/python2
        wget https://jenkins.percona.com/downloads/dh-virtualenv_1.0-1_all.deb
        DEBIAN_FRONTEND=noninteractive apt-get -y install ./dh-virtualenv_1.0-1_all.deb
        rm -f dh-virtualenv_1.0-1_all.deb
      fi
    fi
    return;
}

get_tar(){
    TARBALL=$1
    TARFILE=$(basename $(find $WORKDIR/$TARBALL -name 'percona-patroni*.tar.gz' | sort | tail -n1))
    if [ -z $TARFILE ]
    then
        TARFILE=$(basename $(find $CURDIR/$TARBALL -name 'percona-patroni*.tar.gz' | sort | tail -n1))
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
    FILE=$(basename $(find $WORKDIR/source_deb -name "percona-patroni*.$param" | sort | tail -n1))
    if [ -z $FILE ]
    then
        FILE=$(basename $(find $CURDIR/source_deb -name "percona-patroni*.$param" | sort | tail -n1))
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
    TARFILE=$(find . -name 'percona-patroni*.tar.gz' | sort | tail -n1)
    SRC_DIR=${TARFILE%.tar.gz}
    #
    mkdir -vp rpmbuild/{SOURCES,SPECS,BUILD,SRPMS,RPMS}
    tar vxzf ${WORKDIR}/${TARFILE} --wildcards '*/rpm' --strip=1
    #
    cp -av rpm/* rpmbuild/SOURCES
    cp -av rpm/patroni.spec rpmbuild/SPECS
    cp -av rpm/patches/* rpmbuild/SOURCES
    #
    mv -fv ${TARFILE} ${WORKDIR}/rpmbuild/SOURCES
    sed -i 's:.rhel7:%{dist}:' ${WORKDIR}/rpmbuild/SPECS/patroni.spec
    rpmbuild -bs --define "_topdir ${WORKDIR}/rpmbuild" --define "dist .generic" \
        --define "version ${VERSION}" rpmbuild/SPECS/patroni.spec
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
    SRC_RPM=$(basename $(find $WORKDIR/srpm -name 'percona-patroni*.src.rpm' | sort | tail -n1))
    if [ -z $SRC_RPM ]
    then
        SRC_RPM=$(basename $(find $CURDIR/srpm -name 'percona-patroni*.src.rpm' | sort | tail -n1))
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
    rm -rf percona-patroni*
    get_tar "source_tarball"
    rm -f *.dsc *.orig.tar.gz *.debian.tar.gz *.changes
    #
    TARFILE=$(basename $(find . -name 'percona-patroni*.tar.gz' | sort | tail -n1))
    DEBIAN=$(lsb_release -sc)
    ARCH=$(echo $(uname -m) | sed -e 's:i686:i386:g')
    tar zxf ${TARFILE}
    BUILDDIR=${TARFILE%.tar.gz}
    #
    
    mv ${TARFILE} ${PRODUCT}_${VERSION}.orig.tar.gz
    cd ${BUILDDIR}

    cd debian
    rm -rf changelog
    echo "percona-patroni (${VERSION}-${RELEASE}) unstable; urgency=low" >> changelog
    echo "  * Initial Release." >> changelog
    echo " -- EvgeniyPatlan <evgeniy.patlan@percona.com> $(date -R)" >> changelog

    cd ../
    
    dch -D unstable --force-distribution -v "${VERSION}-${RELEASE}" "Update to new patroni version ${VERSION}"
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
    echo "DEBIAN=${DEBIAN}" >> patroni.properties
    echo "ARCH=${ARCH}" >> patroni.properties

    #
    DSC=$(basename $(find . -name '*.dsc' | sort | tail -n1))
    #
    dpkg-source -x ${DSC}
    #
    cd ${PRODUCT}-${VERSION}
    cp debian/patches/add-sample-config.patch ./patroni.yml.sample
    sed -i 's:ExecStart=/bin/patroni /etc/patroni.yml:ExecStart=/opt/patroni/bin/patroni /etc/patroni/patroni.yml:' extras/startup-scripts/patroni.service
    dch -m -D "${DEBIAN}" --force-distribution -v "1:${VERSION}-${RELEASE}.${DEBIAN}" 'Update distribution'
    unset $(locale|cut -d= -f1)
    dpkg-buildpackage -rfakeroot -us -uc -b
    mkdir -p $CURDIR/deb
    mkdir -p $WORKDIR/deb
    cp $WORKDIR/*.*deb $WORKDIR/deb
    cp $WORKDIR/*.*deb $CURDIR/deb
}
#main
export GIT_SSL_NO_VERIFY=1
CURDIR=$(pwd)
VERSION_FILE=$CURDIR/patroni.properties
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
BRANCH="v3.0.2"
REPO="https://github.com/zalando/patroni.git"
PRODUCT=percona-patroni
DEBUG=0
parse_arguments PICK-ARGS-FROM-ARGV "$@"
VERSION='3.0.2'
RELEASE='1'
PRODUCT_FULL=${PRODUCT}-${VERSION}-${RELEASE}

check_workdir
get_system
install_deps
get_sources
build_srpm
build_source_deb
build_rpm
build_deb
