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
        --build_src_rpm     If it is 1 src rpm will be built
        --build_source_deb  If it is 1 source deb package will be built
        --build_rpm         If it is 1 rpm will be built
        --build_deb         If it is 1 deb will be built
        --build_tarball     If it is 1 tarball will be built
        --install_deps      Install build dependencies(root previlages are required)
        --branch            Branch for build
        --repo              Repo for build
        --pp_branch         Branch for postgres-packaging repo
        --pp_repo           Used postgres-packaging repo for build
        --rpm_release       RPM version( default = 1)
        --deb_release       DEB version( default = 1)
        --pg_release        PPG version build on( default = 11)
        --version           product version
        --help) usage ;;
Example $0 --builddir=/tmp/test --get_sources=1 --build_src_rpm=1 --build_rpm=1
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
            # these get passed explicitly to mysqld
            --builddir=*) WORKDIR="$val" ;;
            --build_src_rpm=*) SRPM="$val" ;;
            --build_source_deb=*) SDEB="$val" ;;
            --build_rpm=*) RPM="$val" ;;
            --build_deb=*) DEB="$val" ;;
            --get_sources=*) SOURCE="$val" ;;
            --build_tarball=*) TARBALL="$val" ;;
            --install_deps=*) INSTALL="$val" ;;
            --branch=*) BRANCH="$val" ;;
            --repo=*) REPO="$val" ;;
            --pp_branch=*) BUILD_BRANCH="$val" ;;
            --pp_repo=*) GIT_BUILD_REPO="$val" ;;
            --rpm_release=*) RPM_RELEASE="$val" ;;
            --deb_release=*) DEB_RELEASE="$val" ;;
            --pg_release=*) PG_RELEASE="$val" ;;
            --version=*) VERSION="$val" ;;
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


set_changelog(){
    if [ -z $1 ]
    then
        echo "No spec file is provided"
        return
    else
        start_line=0
        while read -r line; do
            (( start_line++ ))
            if [ "$line" = "%changelog" ]
            then
                (( start_line++ ))
                echo "$start_line"
                current_date=$(date +"%a %b %d %Y")
                sed -i "$start_line,$ d" $1
                echo "* $current_date Percona Build/Release Team <eng-build@percona.com> - ${VERSION}-${RPM_RELEASE}" >> $1
                echo "- Release ${VERSION}-${RPM_RELEASE}" >> $1
                echo >> $1
                return
            fi
        done <$1
    fi
}

get_sources(){
    cd "${WORKDIR}"
    if [ "${SOURCE}" = 0 ]
    then
        echo "Sources will not be downloaded"
        return 0
    fi

    PRODUCT=percona-pgpool-II-pg${PG_RELEASE}
    PRODUCT_CUT=percona-pgpool-II-${VERSION}
    PRODUCT_FULL=${PRODUCT}-${VERSION}

    echo "PRODUCT=${PRODUCT}" > pgpool2.properties
    echo "PRODUCT_FULL=${PRODUCT_FULL}" >> pgpool2.properties
    echo "PRODUCT_CUT=${PRODUCT_CUT}" >> pgpool2.properties
    echo "VERSION=${VERSION}" >> pgpool2.properties
    echo "BRANCH_NAME=$(echo ${BRANCH} | awk -F '/' '{print $(NF)}')" >> pgpool2.properties
    echo "BUILD_BRANCH=$(echo ${BUILD_BRANCH} | awk -F '/' '{print $(NF)}')" >> pgpool2.properties
    echo "BUILD_NUMBER=${BUILD_NUMBER}" >> pgpool2.properties
    echo "BUILD_ID=${BUILD_ID}" >> pgpool2.properties
    echo "BRANCH_NAME=$(echo ${BRANCH} | awk -F '/' '{print $(NF)}')" >> pgpool2.properties
    echo "PG_RELEASE=${PG_RELEASE}" >> pgpool2.properties
    echo "RPM_RELEASE=${RPM_RELEASE}" >> pgpool2.properties
    echo "DEB_RELEASE=${DEB_RELEASE}" >> pgpool2.properties

    cat pgpool2.properties

    git clone "$REPO" ${PRODUCT_CUT}
    retval=$?
    if [ $retval != 0 ]
    then
        echo "There were some issues during repo cloning from github. Please retry one more time"
        exit 1
    fi
    cd ${PRODUCT_CUT}
    if [ ! -z "$BRANCH" ]
    then
        git reset --hard
        git clean -xdf
        git checkout "$BRANCH"
    fi
    REVISION=$(git rev-parse --short HEAD)
    echo "REVISION=${REVISION}" >> ${WORKDIR}/pgpool2.properties

    # get files for deb
    GIT_SSL_NO_VERIFY=true git clone https://salsa.debian.org/postgresql/pgpool2.git ../pgpool2
    mv ../pgpool2/debian/ .
    wget $(echo ${GIT_BUILD_REPO} | sed -re 's|github.com|raw.githubusercontent.com|; s|\.git$||')/${BUILD_BRANCH}/pgpool2/pgpool2-debian-config.patch -O debian/patches/pgpool2-debian-config.patch

    sed -i "s:PGVERSION:${PG_VER}:g" debian/control.in
    sed -i "s:Source\: pgpool2:Source\: percona-pgpool2:g" debian/control.in
    sed -i "s:Package\: pgpool2:Package\: percona-pgpool2:g" debian/control.in
    sed -i "/Vcs-Git/d" debian/control.in
    sed -i "/Vcs-Browser/d" debian/control.in
    sed -i "s:Debian PostgreSQL Maintainers <team+postgresql@tracker.debian.org>:Percona Development Team <info@percona.com>:g" debian/control.in
    sed -i '/Uploaders/{N;N;N;d;}' debian/control.in
    sed -i "0,/pgpool2/ s/pgpool2.*/percona-pgpool2 (${VERSION}-${DEB_RELEASE}) stable; urgency=medium/" debian/changelog
    sed -i "84s:${PG_RELEASE}:12:" debian/control.in
    sed -i "90s:${PG_RELEASE}:12:" debian/control
    sed -i '84s:postgresql-12:postgresql-12|percona-postgresql-12:' debian/control.in
    sed -i '90s:postgresql-12:postgresql-12|percona-postgresql-12:' debian/control
    #sed -i 's:debhelper-compat (= 13):debhelper-compat:' debian/control
    #sed -i 's:debhelper-compat (= 13):debhelper-compat:' debian/control.in

    sed -i '/debhelper-compat (= 13)/d' debian/control
    sed -i '/debhelper-compat (= 13)/d' debian/control.in

    sed -i 's:./configure --prefix=/usr:autoreconf --force --install; ./configure --prefix=/usr:g' debian/rules

    echo "10" > debian/compat

    DEBEDITFILES=$(ls debian | grep ^pgpool2\.)
    for file in $DEBEDITFILES; do 
        cp debian/$file debian/percona-$file; 
    done 
    cat <<EOT >> debian/rules

override_dh_builddeb:
	dh_builddeb -- -Zgzip
EOT
    mv -f "debian/percona-pgpool2.tmpfile" "debian/percona-pgpool2.tmpfiles"
    echo "etc/pgpool2/aws_eip_if_cmd.sh.sample            usr/share/doc/pgpool2/examples" >> debian/percona-pgpool2.install
    echo "etc/pgpool2/aws_rtb_if_cmd.sh.sample            usr/share/doc/pgpool2/examples" >> debian/percona-pgpool2.install 

    sed -i "s:pgpool-II:percona-pgpool-II:g" src/pgpool.spec
    sed -i "s:short_name  percona-pgpool-II:short_name  pgpool-II:g" src/pgpool.spec
    sed -i "s:pgdg::g" src/pgpool.spec
    sed -i "/mv doc.ja/d" src/pgpool.spec

    sed -i "s:%patch1 -p0:#%patch1 -p0:g" src/pgpool.spec
    sed -i "s:%configure --with-pgsql=%{pghome}:libtoolize; autoreconf --force --install; %configure --with-pgsql=%{pghome}:g" src/pgpool.spec

    sed -i "s:make %{?_smp_mflags}:make:g" src/pgpool.spec

    #EDITFILES="debian/control debian/control.in debian/rules rpm/pgpool.spec"
    #for file in $EDITFILES; do
    #    sed -i "s:@@PG_REL@@:${PG_RELEASE}:g" "$file"
    #done

    #sed -i "s:@@RPM_RELEASE@@:${RPM_RELEASE}:g" rpm/pgpool.spec
    #sed -i "s:@@VERSION@@:${VERSION}:g" rpm/pgpool.spec

    set_changelog src/pgpool.spec

    sed -i 's/SPFLAGS = /SPFLAGS = -E0 /g' doc.ja/src/sgml/Makefile.am
    sed -i 's/SPFLAGS = /SPFLAGS = -E0 /g' doc.ja/src/sgml/Makefile.in
    rm src/sample/pgpool.conf.sample
    mv src/sample/pgpool.conf.sample-stream src/sample/pgpool.conf.sample

    sed -i "s|#port = 9999|#port = 5433|g" src/sample/pgpool.conf.sample
    sed -i "s|#unix_socket_directories = '/tmp'|#unix_socket_directories = '/var/run/postgresql'|g" src/sample/pgpool.conf.sample
    sed -i "s|#pcp_socket_dir = '/tmp'|#pcp_socket_dir = '/var/run/postgresql'|g" src/sample/pgpool.conf.sample
    sed -i "s|#pid_file_name = '/var/run/pgpool/pgpool.pid'|#pid_file_name = '/var/run/postgresql/pgpool.pid'|g" src/sample/pgpool.conf.sample
    sed -i "s|#logdir = '/tmp'|#logdir = '/var/log/postgresql'|g" src/sample/pgpool.conf.sample

    cd ${WORKDIR}
    #
    source pgpool2.properties
    #
    tar --owner=0 --group=0 --exclude=.* -czf ${PRODUCT_CUT}.tar.gz ${PRODUCT_CUT}
    echo "UPLOAD=UPLOAD/experimental/BUILDS/${PRODUCT}/${PRODUCT_FULL}/${BRANCH}/${REVISION}/${BUILD_ID}" >> pgpool2.properties
    mkdir $WORKDIR/source_tarball
    mkdir $CURDIR/source_tarball
    cp percona-pgpool-II-*.tar.gz $WORKDIR/source_tarball
    cp percona-pgpool-II-*.tar.gz $CURDIR/source_tarball
    cd $CURDIR
    rm -rf percona-pgpool-II*
    return
}

get_system(){
    if [ -f /etc/redhat-release ]; then
        GLIBC_VER_TMP="$(rpm glibc -qa --qf %{VERSION})"
        export RHEL=$(rpm --eval %rhel)
        export ARCH=$(echo $(uname -m) | sed -e 's:i686:i386:g')
        export OS_NAME="el$RHEL"
        export OS="rpm"
    else
        GLIBC_VER_TMP="$(dpkg-query -W -f='${Version}' libc6 | awk -F'-' '{print $1}')"
        export ARCH=$(uname -m)
        export OS_NAME="$(lsb_release -sc)"
        export OS="deb"
    fi
    return
}

get_openjade_devel() {
    pushd /tmp
    apt-get update
    apt-get install sudo || true
    sudo apt-get -y install libosp-dev libperl4-corelibs-perl
    sudo apt -y install dh-buildinfo
    wget http://archive.ubuntu.com/ubuntu/pool/universe/o/openjade/openjade_1.4devel1-22.dsc http://archive.ubuntu.com/ubuntu/pool/universe/o/openjade/openjade_1.4devel1.orig.tar.gz http://archive.ubuntu.com/ubuntu/pool/universe/o/openjade/openjade_1.4devel1-22.diff.gz
    dpkg-source -x openjade_1.4devel1-22.dsc
    cd openjade-1.4devel1/
    dpkg-buildpackage -rfakeroot -uc -us -b
    cd ../
    sudo apt -y install ./openjade_1.4devel1-22_amd64.deb ./libostyle-dev_1.4devel1-22_amd64.deb ./libostyle1c2_1.4devel1-22_amd64.deb
    popd
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
    if [ "$OS" == "rpm" ]
    then
        yum install -y https://repo.percona.com/yum/percona-release-latest.noarch.rpm
        percona-release enable ppg-${PG_RELEASE} testing
        yum -y install epel-release git wget libtool bison flex byacc
        PKGLIST="percona-postgresql${PG_VER}-devel"
        PKGLIST+=" clang-devel git clang llvm-devel rpmdevtools vim wget"
        PKGLIST+=" perl binutils gcc gcc-c++"
        PKGLIST+=" clang-devel llvm-devel git rpmdevtools wget gcc make autoconf"
        PKGLIST+=" jade pam-devel openssl-devel docbook-dtds docbook-style-xsl openldap-devel docbook-style-dsssl libmemcached-devel libxslt"
        
	if [[ "${RHEL}" -eq 8 ]]; then
            dnf config-manager --set-enabled powertools
            dnf config-manager --set-enabled ol${RHEL}_codeready_builder
        fi
        if [ $RHEL -eq 9 ]; then
	   dnf config-manager --set-enabled ol${RHEL}_codeready_builder
            sed -i 's/enabled=0/enabled=1/g' /etc/yum.repos.d/oracle-linux-ol9.repo
        fi	
	if [[ "${RHEL}" -eq 8 ]]; then 
            dnf -y module disable postgresql
        elif [[ "${RHEL}" -eq 7 ]]; then
            PKGLIST+=" llvm-toolset-7-clang llvm-toolset-7 llvm5.0-devel llvm-toolset-7-llvm-devel"
            until yum -y install epel-release centos-release-scl; do
                yum clean all
                sleep 1
                echo "waiting"
            done
            until yum -y makecache; do
                yum clean all
                sleep 1
                echo "waiting"
            done
        fi
        until yum -y install ${PKGLIST}; do
            echo "waiting"
            sleep 5
        done
    else
        apt-get update
        DEBIAN_FRONTEND=noninteractive apt-get -y install lsb-release gnupg git wget curl

        wget https://repo.percona.com/apt/percona-release_latest.generic_all.deb
        dpkg -i percona-release_latest.generic_all.deb
        rm -f percona-release_latest.generic_all.deb
        percona-release enable ppg-${PG_RELEASE} testing

        PKGLIST="percona-postgresql-${PG_VER} percona-postgresql-common percona-postgresql-server-dev-all"

        # ---- using a community version of postgresql
        # wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
        # echo "deb http://apt.postgresql.org/pub/repos/apt/ ${PG_RELEASE}"-pgdg main | sudo tee  /etc/apt/sources.list.d/pgdg.list
        # PKGLIST="postgresql-${PG_RELEASE} postgresql-common postgresql-server-dev-all"

        apt-get update

        if [[ "${OS_NAME}" != "focal" ]]; then
            LLVM_EXISTS=$(grep -c "apt.llvm.org" /etc/apt/sources.list)
            if [ "${LLVM_EXISTS}" == 0 ]; then
                wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key|sudo apt-key add -
                echo "deb http://apt.llvm.org/${OS_NAME}/ llvm-toolchain-${OS_NAME}-7 main" >> /etc/apt/sources.list
                echo "deb-src http://apt.llvm.org/${OS_NAME}/ llvm-toolchain-${OS_NAME}-7 main" >> /etc/apt/sources.list
                apt-get update
            fi
        fi

        PKGLIST+=" debconf devscripts dh-exec git wget libkrb5-dev libssl-dev"
        PKGLIST+=" build-essential debconf debhelper devscripts dh-exec libxml-checker-perl"
      # PKGLIST+=" libxml-libxml-perl libio-socket-ssl-perl libperl-dev libssl-dev libxml2-dev txt2man zlib1g-dev libpq-dev"
        PKGLIST+=" chrpath docbook docbook-dsssl docbook-xml docbook-xsl flex libmemcached-dev libxml2-utils openjade opensp xsltproc"
        PKGLIST+=" bison libldap-dev libpam0g-dev"

        until DEBIAN_FRONTEND=noninteractive apt-get -y install ${PKGLIST}; do
            sleep 5
            echo "waiting"
        done

        cat /etc/apt/sources.list | grep ${OS_NAME}-backports
        apt list --all-versions debhelper
        apt-get -y install -t ${OS_NAME}-backports debhelper

        get_openjade_devel
    fi
    return;
}

get_tar(){
    TARBALL=$1
    TARFILE=$(basename $(find $WORKDIR/$TARBALL -name 'percona-pgpool-II*.tar.gz' | sort | tail -n1))
    if [ -z $TARFILE ]
    then
        TARFILE=$(basename $(find $CURDIR/$TARBALL -name 'percona-pgpool-II*.tar.gz' | sort | tail -n1))
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
    FILE=$(basename $(find $WORKDIR/source_deb -name "percona-pgpool2*.$param" | sort | tail -n1))
    if [ -z $FILE ]
    then
        FILE=$(basename $(find $CURDIR/source_deb -name "percona-pgpool2*.$param" | sort | tail -n1))
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
    TARFILE=$(find . -name 'percona-pgpool-II*.tar.gz' | sort | tail -n1)
    SRC_DIR=${TARFILE%.tar.gz}
    #
    mkdir -vp rpmbuild/{SOURCES,SPECS,BUILD,SRPMS,RPMS}
    cp ${TARFILE} rpmbuild/SOURCES
    tar vxzf ${WORKDIR}/${TARFILE} --wildcards '*/src' --strip=1
    #
    cp -av src/redhat/* rpmbuild/SOURCES
    cp -av src/*.spec rpmbuild/SPECS
    #
    mv -fv ${TARFILE} ${WORKDIR}/rpmbuild/SOURCES
    QA_RPATHS=$(( 0x0001|0x0002|0x0010 )) rpmbuild -bs --define "_topdir ${WORKDIR}/rpmbuild" --define "dist .generic" \
    --define "pgpool_version ${VERSION}" --define "pg_version ${PG_VER}" --define "pghome /usr/pgsql-${PG_VER}" \
    --define "pgsql_ver ${PG_VER}0" --define "with-pgsql-includedir /usr/pgsql-${PG_VER}/include/" ${WORKDIR}/rpmbuild/SPECS/pgpool.spec
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
    SRC_RPM=$(basename $(find $WORKDIR/srpm -name 'percona-pgpool-II*.src.rpm' | sort | tail -n1))
    if [ -z $SRC_RPM ]
    then
        SRC_RPM=$(basename $(find $CURDIR/srpm -name 'percona-pgpool-II*.src.rpm' | sort | tail -n1))
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
    export LIBPQ_DIR=/usr/pgsql-${PG_RELEASE}/
    export LIBRARY_PATH=/usr/pgsql-${PG_RELEASE}/lib/:/usr/pgsql-${PG_RELEASE}/include/
    rpmbuild --define "_topdir ${WORKDIR}/rpmbuild" --define "dist .$OS_NAME" --define "version ${VERSION}" \
    --define "pgpool_version ${VERSION}" --define "pg_version ${PG_VER}" --define "pghome /usr/pgsql-${PG_VER}" \
    --define "pgsql_ver ${PG_VER}0" --define "with-pgsql-includedir /usr/pgsql-${PG_VER}/include/" \
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
    rm -rf percona-pgpool2*
    get_tar "source_tarball"
    rm -f *.dsc *.orig.tar.gz *.debian.tar.gz *.changes
    #
    TARFILE=$(basename $(find . -name 'percona-pgpool-II*.tar.gz' | sort | tail -n1))
    DEBIAN=$(lsb_release -sc)
    ARCH=$(echo $(uname -m) | sed -e 's:i686:i386:g')
    tar zxf ${TARFILE}
    BUILDDIR=${TARFILE%.tar.gz}
    #

    mv ${TARFILE} percona-pgpool2_${VERSION}.orig.tar.gz
    cd ${BUILDDIR}
    DEBEMAIL="info@percona.com"
    dch -D unstable --force-distribution -v "${VERSION}-${DEB_RELEASE}" "Update to new percona-pgpool2 pg${PG_RELEASE} version ${VERSION}"
    pg_buildext updatecontrol
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
    export ARCH=$(echo $(uname -m) | sed -e 's:i686:i386:g')
    #
    echo "DEBIAN=${OS_NAME}" >> pgpool2.properties
    echo "ARCH=${ARCH}" >> pgpool2.properties
    #
    DSC=$(basename $(find . -name '*.dsc' | sort | tail -n1))
    #
    dpkg-source -x ${DSC}
    #
    cd percona-pgpool2-${VERSION}
    sed -i "s:\. :${WORKDIR}/percona-pgpool2-${VERSION} :g" debian/rules
    dch -m -D "${OS_NAME}" --force-distribution -v "1:${VERSION}-${DEB_RELEASE}.${OS_NAME}" 'Update distribution'
    unset $(locale|cut -d= -f1)
    pg_buildext updatecontrol
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

CURDIR=$(pwd)
VERSION_FILE=$CURDIR/percona-pgpool2.properties
args=
WORKDIR=
SRPM=0
SDEB=0
RPM=0
DEB=0
SOURCE=0
TARBALL=0
OS_NAME=
ARCH=
OS=
REVISION=0
BRANCH="V4_5_1"
INSTALL=0
RPM_RELEASE=1
DEB_RELEASE=1
REPO="https://git.postgresql.org/git/pgpool2.git"
VERSION="4.5.1"
PG_RELEASE=12.19
GIT_BUILD_REPO="https://github.com/percona/postgres-packaging.git"
BUILD_BRANCH=${PG_RELEASE}
parse_arguments PICK-ARGS-FROM-ARGV "$@"
PG_VER=$(echo ${PG_RELEASE} | awk -F'.' '{print $1}')
check_workdir
get_system
install_deps
get_sources
build_srpm
build_source_deb
build_rpm
build_deb
