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


get_sources(){
    cd "${WORKDIR}"
    if [ "${SOURCE}" = 0 ]
    then
        echo "Sources will not be downloaded"
        return 0
    fi
    PRODUCT=percona-postgresql
    echo "PRODUCT=${PRODUCT}" > percona-postgresql.properties

    PRODUCT_FULL=${PRODUCT}-${VERSION}.${RELEASE}
    echo "PRODUCT_FULL=${PRODUCT_FULL}" >> percona-postgresql.properties
    echo "VERSION=${PSM_VER}" >> percona-postgresql.properties
    echo "BUILD_NUMBER=${BUILD_NUMBER}" >> percona-postgresql.properties
    echo "BUILD_ID=${BUILD_ID}" >> percona-postgresql.properties
    git clone "$REPO" postgresql
    retval=$?
    if [ $retval != 0 ]
    then
        echo "There were some issues during repo cloning from github. Please retry one more time"
        exit 1
    fi
    mv postgresql ${PRODUCT_FULL}
    cd ${PRODUCT_FULL}
    if [ ! -z "$BRANCH" ]
    then
        git reset --hard
        git clean -xdf
        git checkout "$BRANCH"
        #git submodule update --init
	sed -i 's:enable_tap_tests=no:enable_tap_tests=yes:' configure
    fi
    REVISION=$(git rev-parse --short HEAD)
    echo "REVISION=${REVISION}" >> ${WORKDIR}/percona-postgresql.properties
    rm -fr debian rpm

    git clone https://salsa.debian.org/postgresql/postgresql.git deb_packaging
    cd deb_packaging
        git checkout -b ${VERSION} remotes/origin/${VERSION}
    cd ../
    mv deb_packaging/debian ./
    rm -rf deb_packaging
    cd debian
        for file in $(ls | grep postgresql); do
            mv $file "percona-$file"
        done
	rm -f rules control
        wget https://raw.githubusercontent.com/percona/postgres-packaging/${PG_VERSION}/postgres/rules
        wget https://raw.githubusercontent.com/percona/postgres-packaging/${PG_VERSION}/postgres/control
	sed -i "s/postgresql-${VERSION}/percona-postgresql-${VERSION}/" percona-postgresql-${VERSION}.templates
	echo "10" > compat
	sed -i '14d' patches/series
    cd ../
    git clone https://git.postgresql.org/git/pgrpms.git
    mkdir rpm
    mv pgrpms/rpm/redhat/main/non-common/postgresql-${VERSION}/main/*   rpm/
    rm -rf pgrpms
    cd rpm
        rm postgresql-${VERSION}.spec
        wget  https://raw.githubusercontent.com/percona/postgres-packaging/${PG_VERSION}/postgres/percona-postgresql-${VERSION}.spec
    cd ../
    cd ${WORKDIR}
    #
    source percona-postgresql.properties
    #

    tar --owner=0 --group=0 --exclude=.* -czf ${PRODUCT_FULL}.tar.gz ${PRODUCT_FULL}
    echo "UPLOAD=UPLOAD/experimental/BUILDS/${PRODUCT}-${VERSION}/${PRODUCT_FULL}/${PSM_BRANCH}/${REVISION}/${BUILD_ID}" >> percona-postgresql.properties
    mkdir $WORKDIR/source_tarball
    mkdir $CURDIR/source_tarball
    cp ${PRODUCT_FULL}.tar.gz $WORKDIR/source_tarball
    cp ${PRODUCT_FULL}.tar.gz $CURDIR/source_tarball
    cd $CURDIR
    rm -rf percona-postgresql*
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
      yum clean all
      RHEL=$(rpm --eval %rhel)
      if [ x"$RHEL" = x6 -o x"$RHEL" = x7 ]; then
        until yum -y install centos-release-scl; do
            echo "waiting"
            sleep 1
        done
        yum -y install epel-release
        INSTALL_LIST="bison e2fsprogs-devel flex gettext git glibc-devel krb5-devel libicu-devel libselinux-devel libuuid-devel libxml2-devel libxslt-devel llvm-toolset-7-clang llvm5.0-devel openldap-devel openssl-devel pam-devel patch perl perl-ExtUtils-MakeMaker perl-ExtUtils-Embed python2-devel readline-devel rpm-build rpmdevtools selinux-policy systemd systemd-devel systemtap-sdt-devel tcl-devel vim wget zlib-devel python3-devel lz4-devel libzstd-devel perl-IPC-Run perl-Test-Simple rpmdevtools"
        yum -y install ${INSTALL_LIST}
        source /opt/rh/devtoolset-7/enable
        source /opt/rh/llvm-toolset-7/enable
      else
	dnf config-manager --set-enabled ol${RHEL}_codeready_builder

        if [ x"$RHEL" = x8 ];
        then
            clang_version=$(yum list --showduplicates clang-devel | grep "17.0" | grep clang | awk '{print $2}' | head -n 1)
            llvm_version=$(yum list --showduplicates llvm-devel | grep "17.0" | grep llvm | awk '{print $2}' | head -n 1)
            yum install -y clang-devel-${clang_version} clang-${clang_version} llvm-devel-${llvm_version}
            dnf module -y disable llvm-toolset
        else
            yum install -y clang-devel clang llvm-devel
        fi

        INSTALL_LIST="python3-devel perl-generators bison e2fsprogs-devel flex gettext git glibc-devel krb5-devel libicu-devel libselinux-devel libuuid-devel libxml2-devel libxslt-devel openldap-devel openssl-devel pam-devel patch perl perl-ExtUtils-MakeMaker perl-ExtUtils-Embed readline-devel rpmdevtools selinux-policy systemd systemd-devel systemtap-sdt-devel tcl-devel vim wget zlib-devel lz4-devel libzstd-devel perl-IPC-Run perl-Test-Simple rpmdevtools"
	yum -y install rpmbuild || yum -y install rpm-build || true
        yum -y install ${INSTALL_LIST}
        yum -y install binutils gcc gcc-c++
	if [ x"$RHEL" = x8 ]; then
	    yum -y install python2-devel
        else
	    yum -y install python-devel
        fi
        yum clean all
        if [ ! -f  /usr/bin/llvm-config ]; then
            ln -s /usr/bin/llvm-config-64 /usr/bin/llvm-config
        fi
    
      fi
      yum -y install bzip2-devel gcc gcc-c++ rpm-build || true
      yum -y install cmake cyrus-sasl-devel make openssl-devel zlib-devel libcurl-devel || true
      yum -y install perl-IPC-Run perl-Test-Simple
      yum -y install docbook-xsl libxslt-devel
    else
      apt-get update || true
      DEBIAN_FRONTEND=noninteractive apt-get -y install gnupg2 curl wget lsb-release quilt
      apt-get update || true
      export DEBIAN=$(lsb_release -sc)
      export ARCH=$(echo $(uname -m) | sed -e 's:i686:i386:g')
      ENV export DEBIAN_FRONTEND=noninteractive
      DEBIAN_FRONTEND=noninteractive apt-get -y install tzdata
      ln -fs /usr/share/zoneinfo/America/New_York /etc/localtime
      dpkg-reconfigure --frontend noninteractive tzdata
      wget https://repo.percona.com/apt/percona-release_latest.generic_all.deb
      dpkg -i percona-release_latest.generic_all.deb
      rm -f percona-release_latest.generic_all.deb
      percona-release disable all
      percona-release enable ppg-${PG_VERSION} testing
      apt-get update
      if [ "x${DEBIAN}" != "xfocal" -a "x${DEBIAN}" != "xbullseye" -a "x${DEBIAN}" != "xjammy" -a "x${DEBIAN}" != "xbookworm" -a "x${DEBIAN}" != "xnoble" ]; then
        INSTALL_LIST="bison build-essential ccache cron debconf debhelper devscripts dh-exec dh-systemd docbook-xml docbook-xsl dpkg-dev flex gcc gettext git krb5-multidev libbsd-resource-perl libedit-dev libicu-dev libipc-run-perl libkrb5-dev libldap-dev libldap2-dev libmemchan-tcl-dev libpam0g-dev libperl-dev libpython-dev libreadline-dev libselinux1-dev libssl-dev libsystemd-dev libwww-perl libxml2-dev libxml2-utils libxslt-dev libxslt1-dev llvm-dev perl pkg-config python python-dev python3-dev systemtap-sdt-dev tcl-dev tcl8.6-dev uuid-dev vim wget xsltproc zlib1g-dev rename clang gdb liblz4-dev libipc-run-perl libcurl4-openssl-dev"
      else
        INSTALL_LIST="bison build-essential ccache cron debconf debhelper devscripts dh-exec docbook-xml docbook-xsl dpkg-dev flex gcc gettext git krb5-multidev libbsd-resource-perl libedit-dev libicu-dev libipc-run-perl libkrb5-dev libldap-dev libldap2-dev libmemchan-tcl-dev libpam0g-dev libperl-dev libpython3-dev libreadline-dev libselinux1-dev libssl-dev libsystemd-dev libwww-perl libxml2-dev libxml2-utils libxslt-dev libxslt1-dev llvm-dev perl pkg-config python3 python3-dev systemtap-sdt-dev tcl-dev tcl8.6-dev uuid-dev vim wget xsltproc zlib1g-dev rename clang gdb liblz4-dev libipc-run-perl libcurl4-openssl-dev"
      fi
 
       until DEBIAN_FRONTEND=noninteractive apt-get -y --allow-unauthenticated install ${INSTALL_LIST}; do
        sleep 1
        echo "waiting"
      done
    fi
    return;
}

get_tar(){
    TARBALL=$1
    TARFILE=$(basename $(find $WORKDIR/$TARBALL -name 'percona-postgresql*.tar.gz' | sort | tail -n1))
    if [ -z $TARFILE ]
    then
        TARFILE=$(basename $(find $CURDIR/$TARBALL -name 'percona-postgresql*.tar.gz' | sort | tail -n1))
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
    get_tar "source_tarball"
    rm -fr rpmbuild
    ls | grep -v tar.gz | xargs rm -rf
    TARFILE=$(find . -name 'percona-postgresql*.tar.gz' | sort | tail -n1)
    SRC_DIR=${TARFILE%.tar.gz}
    #
    mkdir -vp rpmbuild/{SOURCES,SPECS,BUILD,SRPMS,RPMS}
    tar vxzf ${WORKDIR}/${TARFILE} --wildcards '*/rpm' --strip=1
    #
    cp -av rpm/* rpmbuild/SOURCES
    cd rpmbuild/SOURCES
    wget --no-check-certificate https://www.postgresql.org/files/documentation/pdf/${VERSION}/postgresql-${VERSION}-A4.pdf
    cd ../../
    cp -av rpmbuild/SOURCES/percona-postgresql-${VERSION}.spec rpmbuild/SPECS
    #
    mv -fv ${TARFILE} ${WORKDIR}/rpmbuild/SOURCES
    if [ -f /opt/rh/devtoolset-7/enable ]; then
        source /opt/rh/devtoolset-7/enable
        source /opt/rh/llvm-toolset-7/enable
    fi
    wget https://raw.githubusercontent.com/Percona-Lab/telemetry-agent/phase-0/call-home.sh
    mv call-home.sh rpmbuild/SOURCES
    cd ${WORKDIR}/rpmbuild/SPECS
    line_number=$(grep -n SOURCE999 percona-postgresql-${VERSION}.spec | awk -F ':' '{print $1}')
    cp ../SOURCES/call-home.sh ./
    awk -v n=$line_number 'NR <= n {print > "part1.txt"} NR > n {print > "part2.txt"}' percona-postgresql-${VERSION}.spec
    head -n -1 part1.txt > temp && mv temp part1.txt
    echo "cat <<'CALLHOME' > /tmp/call-home.sh" >> part1.txt
    cat call-home.sh >> part1.txt
    echo "CALLHOME" >> part1.txt
    cat part2.txt >> part1.txt
    rm -f call-home.sh part2.txt
    mv part1.txt percona-postgresql-${VERSION}.spec
    cd ${WORKDIR}
    rpmbuild -bs --define "_topdir ${WORKDIR}/rpmbuild" --define "dist .generic" \
        --define "pgmajorversion ${VERSION}" --define "pginstdir /usr/pgsql-${VERSION}"  --define "pgpackageversion ${VERSION}" \
        rpmbuild/SPECS/percona-postgresql-${VERSION}.spec
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
    #
    cd $WORKDIR
    RHEL=$(rpm --eval %rhel)
    ARCH=$(echo $(uname -m) | sed -e 's:i686:i386:g')
    if [ -f /opt/rh/devtoolset-7/enable ]; then
        source /opt/rh/devtoolset-7/enable
        source /opt/rh/llvm-toolset-7/enable
    fi
    rpmbuild --define "_topdir ${WORKDIR}/rpmbuild" --define "dist .$OS_NAME" --define "pgmajorversion ${VERSION}" --define "pginstdir /usr/pgsql-${VERSION}" --define "pgpackageversion ${VERSION}" --rebuild rpmbuild/SRPMS/$SRC_RPM

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
    get_tar "source_tarball"
    rm -f *.dsc *.orig.tar.gz *.debian.tar.gz *.changes
    #
    TARFILE=$(basename $(find . -name 'percona-postgresql*.tar.gz' | sort | tail -n1))
    DEBIAN=$(lsb_release -sc)
    ARCH=$(echo $(uname -m) | sed -e 's:i686:i386:g')
    tar zxf ${TARFILE}
    BUILDDIR=${TARFILE%.tar.gz}
    #
    
    mv ${TARFILE} ${PRODUCT}-${VERSION}_${VERSION}.${RELEASE}.orig.tar.gz
    cd ${BUILDDIR}

    cd debian
    rm -rf changelog
    echo "percona-postgresql-${VERSION} (${VERSION}.${RELEASE}) unstable; urgency=low" >> changelog
    echo "  * Initial Release." >> changelog
    echo " -- EvgeniyPatlan <evgeniy.patlan@percona.com> $(date -R)" >> changelog

    cd ../
    quilt refresh
    dch -D unstable --force-distribution -v "${VERSION}.${RELEASE}-${DEB_RELEASE}" "Update to new Percona Platform for PostgreSQL version ${VERSION}.${RELEASE}-${DEB_RELEASE}"
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
    echo "DEBIAN=${DEBIAN}" >> percona-postgresql.properties
    echo "ARCH=${ARCH}" >> percona-postgresql.properties

    #
    DSC=$(basename $(find . -name '*.dsc' | sort | tail -n1))
    #
    dpkg-source -x ${DSC}
    #
    cd ${PRODUCT}-${VERSION}-${VERSION}.${RELEASE}
    dch -m -D "${DEBIAN}" --force-distribution -v "2:${VERSION}.${RELEASE}-${DEB_RELEASE}.${DEBIAN}" 'Update distribution'
    unset $(locale|cut -d= -f1)
        cd debian/
        wget https://raw.githubusercontent.com/Percona-Lab/telemetry-agent/phase-0/call-home.sh
        sed -i 's:exit 0::' percona-postgresql-${VERSION}.postinst
        echo "cat <<'CALLHOME' > /tmp/call-home.sh" >> percona-postgresql-${VERSION}.postinst
        cat call-home.sh >> percona-postgresql-${VERSION}.postinst
        echo "CALLHOME" >> percona-postgresql-${VERSION}.postinst
        echo "bash +x /tmp/call-home.sh -f \"PRODUCT_FAMILY_POSTGRESQL\" -v \"${PG_VERSION}-${DEB_RELEASE}\" -d \"PACKAGE\" || :" >> percona-postgresql-${VERSION}.postinst
	echo "chgrp percona-telemetry /usr/local/percona/telemetry_uuid &>/dev/null || :" >> percona-postgresql-17.postinst
        echo "chmod 664 /usr/local/percona/telemetry_uuid &>/dev/null || :" >> percona-postgresql-17.postinst
        echo "rm -rf /tmp/call-home.sh" >> percona-postgresql-${VERSION}.postinst
        echo "exit 0" >> percona-postgresql-${VERSION}.postinst
        rm -f call-home.sh
    cd ../
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
OS_NAME=
ARCH=
OS=
INSTALL=0
RPM_RELEASE=1
DEB_RELEASE=1
REVISION=0
#BRANCH="TDE_REL_17_STABLE"
#REPO="https://github.com/Percona-Lab/postgres.git"
BRANCH="REL_17_0"
REPO="git://git.postgresql.org/git/postgresql.git"
PRODUCT=percona-postgresql
DEBUG=0
parse_arguments PICK-ARGS-FROM-ARGV "$@"
VERSION='17'
RELEASE='0'
PG_VERSION=${VERSION}.${RELEASE}
PRODUCT_FULL=${PRODUCT}-${VERSION}-${RELEASE}

check_workdir
get_system
install_deps
get_sources
build_srpm
build_source_deb
build_rpm
build_deb
