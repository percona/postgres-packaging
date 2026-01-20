#!/usr/bin/env bash
set -x


# ---------- RPMs dependencies -----------
rpm_deps() {
  export RHEL=$(rpm --eval %rhel)
  export ARCH=$(uname -m)

  dnf config-manager --set-enabled ol${RHEL}_codeready_builder

  if [[ "${RHEL}" -eq 8 ]]; then
    dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-${RHEL}.noarch.rpm
    if [[ "$COMPONENT" == "pgrepack" ]]; then
      INSTALL_LIST+="python3-devel "
    fi
    if [[ "$COMPONENT" == "ppg-server-ha" ]]; then
      INSTALL_LIST+="perl lz4-libs c-ares-devel "
    fi
    if [[ "$COMPONENT" == "postgis" ]]; then
      INSTALL_LIST+="gdal38-devel proj95-devel geos311-devel pcre-devel "
    fi
  fi

  if [[ "${RHEL}" -eq 9 ]]; then
    if [[ "$COMPONENT" == "postgresql" || "$COMPONENT" == "pg_repack" ]]; then
      INSTALL_LIST+="gcc-toolset-14 "
    fi
    if [[ "$COMPONENT" == "pgpool2" ]]; then
      sed -i 's/enabled=0/enabled=1/g' /etc/yum.repos.d/oracle-linux-ol9.repo
    fi
    if [[ "$COMPONENT" == "postgis" ]]; then
      INSTALL_LIST+="gdal311-devel proj95-devel geos311-devel pcre-devel "
    fi
  fi

  if [[ "${RHEL}" -eq 10 ]]; then
    if [[ "$COMPONENT" == "postgis" ]]; then
      INSTALL_LIST+="gdal311-devel proj96-devel geos313-devel pcre2-devel "
    fi
  fi
  
  dnf -y module disable postgresql || true
  dnf clean all
  rm -r /var/cache/dnf
  dnf -y upgrade

  if [[ "$COMPONENT" != "postgresql" && "$COMPONENT" != "ppg-server-ha" && "$COMPONENT" != "ppg-server" && "$COMPONENT" != "pg_gather" ]]; then
    dnf -y install epel-release || dnf -y install oracle-epel-release-el10
  fi

  if [[ "$COMPONENT" == "ydiff" || "$COMPONENT" == "wal2json" || "$COMPONENT" == "pysyncobj" || "$COMPONENT" == "pgbouncer" || "$COMPONENT" == "pgbadger" || "$COMPONENT" == "pgbackrest" || "$COMPONENT" == "patroni" ]]; then
    switch_to_vault_repo || true
  fi
  
  if [[ "$COMPONENT" != "postgresql" ]]; then
    add_percona_yum_repo
  fi

  if [[ "$COMPONENT" == "pgaudit_set_user" || "$COMPONENT" == "pgaudit" ]]; then
    percona-release enable telemetry testing
  fi

  if [[ "$COMPONENT" == "patroni" || "$COMPONENT" == "pgbackrest" || "$COMPONENT" == "ydiff" || "$COMPONENT" == "pgpool2" ]]; then
    dnf config-manager --set-enabled PowerTools || dnf config-manager --set-enabled powertools || true
  fi

  if [[ "$COMPONENT" == "postgis" ]]; then
    yum -y install wget
    yum config-manager --enable PowerTools AppStream BaseOS *epel || true
    yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-${RHEL}.noarch.rpm
    wget --no-check-certificate https://download.postgresql.org/pub/repos/yum/reporpms/EL-${RHEL}-${ARCH}/pgdg-redhat-repo-latest.noarch.rpm
    yum -y install pgdg-redhat-repo-latest.noarch.rpm
    yum -y install pgdg-srpm-macros
  fi

  return;
}


# ---------- DEBs dependencies -----------
deb_deps() {
  apt-get update || true
  ENV export DEBIAN_FRONTEND=noninteractive
  DEBIAN_FRONTEND=noninteractive apt-get -y install git gnupg2 curl wget lsb-release quilt
  export DEBIAN=$(lsb_release -sc)
  export ARCH=$(echo $(uname -m) | sed -e 's:i686:i386:g')
  add_percona_apt_repo

  if [[ "$COMPONENT" == "ydiff" || "$COMPONENT" == "pysyncobj" ]]; then
    if [ "x${DEBIAN}" = "xtrixie" ]; then
      INSTALL_LIST+="python3-boto3 "  
    else
      INSTALL_LIST+="python3-boto "
    fi
  fi

  if [[ "$COMPONENT" == "postgis" ]]; then
    DEBIAN_FRONTEND=noninteractive apt-get -y install imagemagick
    if [ "x${DEBIAN}" = "xnoble" -o "x${DEBIAN}" = "xtrixie" ]; then
      pushd /etc/ImageMagick-* > /dev/null
      sed -i 's/rights="none"/rights="read|write"/' policy.xml
      popd > /dev/null
    fi
  fi

  if [[ "$COMPONENT" == "pgpool2" ]]; then
    wget http://mirrors.kernel.org/ubuntu/pool/universe/l/llvm-toolchain-7/llvm-7_7.0.1-12_amd64.deb http://mirrors.kernel.org/ubuntu/pool/universe/l/llvm-toolchain-7/libllvm7_7.0.1-12_amd64.deb http://mirrors.kernel.org/ubuntu/pool/universe/l/llvm-toolchain-7/llvm-7-runtime_7.0.1-12_amd64.deb
    apt install ./libllvm7_7.0.1-12_amd64.deb ./llvm-7_7.0.1-12_amd64.deb ./llvm-7-runtime_7.0.1-12_amd64.deb
    DEBIAN_FRONTEND=noninteractive apt-get -y install debhelper
    cat /etc/apt/sources.list | grep ${DEBIAN}-backports
    apt list --all-versions debhelper
    apt-get -y install -t ${DEBIAN}-backports debhelper
    get_openjade_devel
  fi

  if [[ "$COMPONENT" == "patroni" ]]; then
    DEBIAN_FRONTEND=noninteractive apt-get -y install python3-pip python3-consul python3-kubernetes python3-cdiff python3-boto3 || true
    if [ "x${DEBIAN}" = "xbookworm" -o "x${DEBIAN}" = "xnoble" -o "x${DEBIAN}" = "xtrixie" ]; then
        apt-get install -y python3-sphinxcontrib.apidoc python3-pysyncobj python3-boto3
    elif [ "x${DEBIAN}" = "xjammy" -o "x${DEBIAN}" = "xbuster" -o "x${DEBIAN}" = "xbullseye" ]; then
        pip3 install --upgrade sphinx sphinx-rtd-theme
        pip3 install sphinxcontrib.apidoc pysyncobj boto3
    fi
  fi

  if [[ "x${DEBIAN}" == "xbullseye" ]]; then
    DEBIAN_FRONTEND=noninteractive apt-get -y install software-properties-common
    wget https://apt.llvm.org/llvm.sh
    chmod +x llvm.sh
    ./llvm.sh 13 bullseye
    if [[ "$COMPONENT" == "pgbackrest" ]]; then
      DEBIAN_FRONTEND=noninteractive apt-get -y --allow-unauthenticated install dh_systemd
    fi
  fi
  
  return;  
}




# ------- main ---------
COMPONENT=$1

if [ $( id -u ) -ne 0 ]; then
  echo "It is not possible to install dependencies. Please run as root"
  exit 1
fi
CURPLACE=$(pwd)

INSTALL_LIST=" "

# ---- Component-specific dependencies ----
case "$COMPONENT" in
  postgresql)
    if [ "x$OS" = "xrpm" ]; then
      rpm_deps
      INSTALL_LIST+="wget git vim rpm-build chrpath rpmdevtools clang perl-generators bison flex gettext patch perl perl-ExtUtils-MakeMaker perl-ExtUtils-Embed selinux-policy systemd systemd-devel systemtap-sdt-devel perl-IPC-Run perl-Test-Simple binutils gcc gcc-c++ cmake cyrus-sasl-devel make docbook-xsl "
      INSTALL_LIST+="clang-devel python3-devel llvm-devel glibc-devel e2fsprogs-devel krb5-devel libicu-devel libselinux-devel libuuid-devel libxml2-devel libxslt-devel openldap-devel openssl-devel pam-devel readline-devel tcl-devel zlib-devel lz4-devel libzstd-devel bzip2-devel libcurl-devel"
      dnf -y install ${INSTALL_LIST}
      if [ ! -f  /usr/bin/llvm-config ]; then
        ln -s /usr/bin/llvm-config-64 /usr/bin/llvm-config
      fi
    else
      deb_deps
      DEBIAN_FRONTEND=noninteractive apt-get -y install tzdata
      ln -fs /usr/share/zoneinfo/America/New_York /etc/localtime
      dpkg-reconfigure --frontend noninteractive tzdata
      INSTALL_LIST+="bison build-essential ccache cron debconf debhelper devscripts dh-exec docbook-xml docbook-xsl dpkg-dev flex gcc gettext krb5-multidev libbsd-resource-perl libedit-dev libicu-dev libipc-run-perl libkrb5-dev libldap-dev libldap2-dev libmemchan-tcl-dev libpam0g-dev libperl-dev libpython3-dev libreadline-dev libselinux1-dev libssl-dev libsystemd-dev libwww-perl libxml2-dev libxml2-utils libxslt-dev libxslt1-dev llvm-dev perl pkg-config python3 python3-dev systemtap-sdt-dev tcl-dev tcl8.6-dev uuid-dev vim xsltproc zlib1g-dev rename clang gdb liblz4-dev libcurl4-openssl-dev libzstd-dev libnuma-dev"
      DEBIAN_FRONTEND=noninteractive apt-get -y --allow-unauthenticated install ${INSTALL_LIST}
      # generate a temporary numa.pc file if libnuma-dev does not provide it
      if ! pkg-config --exists numa 2>/dev/null; then
        echo "numa.pc not found, generating temporary one..."
        # Get libnuma version dynamically (fallback to 2.0.12 if unavailable)
        NUMA_VERSION=$(dpkg-query -W -f='${Version}' libnuma1 2>/dev/null | cut -d- -f1)
        NUMA_VERSION=${NUMA_VERSION:-2.0.12}
        mkdir -p "/usr/lib/pkgconfig"
        cat > "/usr/lib/pkgconfig/numa.pc" <<EOF
prefix=/usr
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib/$(dpkg-architecture -qDEB_HOST_MULTIARCH)
includedir=\${prefix}/include

Name: numa
Description: NUMA policy library
Version: ${NUMA_VERSION}
Libs: -lnuma
Cflags:
EOF
        echo "✅ Created temporary numa.pc (version ${NUMA_VERSION})"
      else
        echo "✅ numa.pc already present, nothing to do."
      fi
    fi
    ;;


  postgresql-common)
    if [ "x$OS" = "xrpm" ]; then
      rpm_deps
      INSTALL_LIST+="wget git vim rpmdevtools patch perl perl-ExtUtils-MakeMaker perl-ExtUtils-Embed perl-podlators sudo make"
      dnf -y install ${INSTALL_LIST}
    else
      deb_deps
      INSTALL_LIST+="debhelper libreadline-dev rename devscripts sudo"
      DEBIAN_FRONTEND=noninteractive apt-get -y --allow-unauthenticated install ${INSTALL_LIST}
    fi
    ;;


  pg_tde)
    if [ "x$OS" = "xrpm" ]; then
      rpm_deps
      INSTALL_LIST+="wget git vim chrpath clang-devel clang llvm-devel json-c-devel libcurl-devel openssl-devel lz4-devel zlib-devel libzstd-devel libxml2-devel libxslt-devel libselinux-devel pam-devel krb5-devel readline-devel gettext percona-postgresql${PG_MAJOR}-devel percona-postgresql${PG_MAJOR}-server rpmdevtools binutils make gcc gcc-c++"
      dnf -y install ${INSTALL_LIST}
    else
      deb_deps
      DEBIAN_FRONTEND=noninteractive apt-get -y install tzdata
      ln -fs /usr/share/zoneinfo/America/New_York /etc/localtime
      dpkg-reconfigure --frontend noninteractive tzdata
      INSTALL_LIST+="build-essential debhelper clang git libjson-c-dev pkg-config libcurl4-openssl-dev liblz4-dev libssl-dev zlib1g-dev libzstd-dev libxml2-dev libxml2-utils libxslt-dev libxslt1-dev libselinux1-dev libpam0g-dev krb5-multidev libkrb5-dev libreadline-dev shtool devscripts percona-postgresql-common percona-postgresql-server-dev-all libnuma-dev"
      DEBIAN_FRONTEND=noninteractive apt-get -y --allow-unauthenticated install ${INSTALL_LIST}
    fi
    ;;


  ydiff)
    if [ "x$OS" = "xrpm" ]; then
      rpm_deps
      INSTALL_LIST+="wget git vim rpm-build rpmdevtools python3-devel python3-setuptools"
      dnf -y install ${INSTALL_LIST}
    else
      deb_deps
      INSTALL_LIST+="build-essential debconf debhelper dh-exec fakeroot devscripts python3-psycopg2 python3-setuptools libyaml-dev python3-dev dh-virtualenv python3-virtualenv ruby ruby-dev rubygems golang dh-python libjs-mathjax pyflakes3 python3-dateutil python3-dnspython python3-etcd python3-flake8 python3-kazoo python3-mccabe python3-mock python3-prettytable python3-psutil python3-pycodestyle python3-pytest python3-pytest-cov python3-sphinx python3-sphinx-rtd-theme python3-tz python3-tzlocal sphinx-common python3-click python3-doc python3-all"
      DEBIAN_FRONTEND=noninteractive apt-get -y --allow-unauthenticated install ${INSTALL_LIST}
    fi
    ;;


  wal2json)
    if [ "x$OS" = "xrpm" ]; then
      rpm_deps
      INSTALL_LIST+="wget git vim clang-devel clang rpmdevtools llvm-devel lz4-libs c-ares-devel pandoc libtool libevent-devel python3-psycopg2 openssl-devel pam-devel percona-postgresql${PG_MAJOR}-devel systemd systemd-devel libxml2-devel perl perl-DBD-Pg perl-Digest-SHA perl-IO-Socket-SSL perl-JSON-PP zlib-devel gcc make autoconf perl-ExtUtils-Embed"
      dnf -y install ${INSTALL_LIST}
      yum -y install lz4 || true
    else
      deb_deps
      INSTALL_LIST+="build-essential pkg-config liblz4-dev debconf debhelper devscripts dh-exec libxml-checker-perl libxml-libxml-perl libio-socket-ssl-perl libperl-dev libssl-dev libxml2-dev txt2man zlib1g-dev libpq-dev percona-postgresql-${PG_MAJOR} percona-postgresql-common percona-postgresql-server-dev-all percona-postgresql-all libbz2-dev libzstd-dev libevent-dev libc-ares-dev pandoc"
      DEBIAN_FRONTEND=noninteractive apt-get -y --allow-unauthenticated install ${INSTALL_LIST}
      DEBIAN_FRONTEND=noninteractive apt-get -y --allow-unauthenticated install libpam0g-dev || DEBIAN_FRONTEND=noninteractive apt-get -y --allow-unauthenticated install libpam-dev
    fi
    ;;


  pysyncobj)
    if [ "x$OS" = "xrpm" ]; then
      rpm_deps
      INSTALL_LIST+="wget git vim rpm-build rpmdevtools python3-devel python3-setuptools rpmlint"
      dnf -y install ${INSTALL_LIST}
    else
      deb_deps
      INSTALL_LIST+="build-essential debconf debhelper devscripts dh-exec fakeroot python3-psycopg2 python3-setuptools libyaml-dev python3-virtualenv ruby ruby-dev rubygems golang dh-python libjs-mathjax pyflakes3 python3-dateutil python3-dnspython python3-etcd python3-flake8 python3-kazoo python3-mccabe python3-mock python3-prettytable python3-psutil python3-pycodestyle python3-pytest python3-pytest-cov python3-sphinx python3-sphinx-rtd-theme python3-tz python3-tzlocal sphinx-common python3-click python3-doc python3-all"
      DEBIAN_FRONTEND=noninteractive apt-get -y --allow-unauthenticated install ${INSTALL_LIST}
    fi
    ;;


  ppg-server-ha)
    if [ "x$OS" = "xrpm" ]; then
      rpm_deps
      INSTALL_LIST+="wget git vim rpm-build rpmdevtools"
      dnf -y install ${INSTALL_LIST}
      dnf -y install rpmlint || true
      dnf -y install lz4 || true
    else
      deb_deps
      INSTALL_LIST+="debconf debhelper devscripts dh-exec"
      DEBIAN_FRONTEND=noninteractive apt-get -y --allow-unauthenticated install ${INSTALL_LIST}
    fi
    ;;


  ppg-server)
    if [ "x$OS" = "xrpm" ]; then
      rpm_deps
      INSTALL_LIST+="wget git vim rpm-build rpmdevtools"
      dnf -y install ${INSTALL_LIST}
      dnf -y install rpmlint || true
      dnf -y install lz4 || true
    else
      deb_deps
      INSTALL_LIST+="debconf debhelper devscripts dh-exec"
      DEBIAN_FRONTEND=noninteractive apt-get -y --allow-unauthenticated install ${INSTALL_LIST}
    fi
    ;;


  postgis)
    if [ "x$OS" = "xrpm" ]; then
      rpm_deps
      INSTALL_LIST+="wget git vim which binutils gcc gcc-c++ rpm-build rpmdevtools SFCGAL SFCGAL-devel xerces-c-devel clang-devel clang llvm-devel autoconf libtool flex rpmlint percona-postgresql${PG_MAJOR}-devel make geos geos-devel libgeotiff-devel gmp-devel gmp-devel gtk2-devel json-c-devel libgeotiff17-devel protobuf-c-devel pkg-config docbook-xsl libxslt-devel"
      dnf -y install ${INSTALL_LIST}
      if [ ! -f  /usr/bin/llvm-config ]; then
        ln -s /usr/bin/llvm-config-64 /usr/bin/llvm-config
      fi
    else
      deb_deps
      DEBIAN_FRONTEND=noninteractive apt-get -y install tzdata
      ln -fs /usr/share/zoneinfo/America/New_York /etc/localtime
      dpkg-reconfigure --frontend noninteractive tzdata
      INSTALL_LIST+="bison build-essential debconf debhelper devscripts dh-exec dpkg-dev flex gcc cmake vim dctrl-tools docbook docbook-xsl libcunit1-dev libgdal-dev libgeos-dev libjson-c-dev libpcre2-dev libproj-dev libprotobuf-c-dev libsfcgal-dev libxml2-dev pkg-config po-debconf percona-postgresql-all percona-postgresql-common percona-postgresql-server-dev-all percona-postgresql-${PG_MAJOR_VERSION} protobuf-c-compiler rdfind xsltproc"
      DEBIAN_FRONTEND=noninteractive apt-get -y --allow-unauthenticated install ${INSTALL_LIST}
      apt-get install -y dblatex || true
    fi
    ;;


  pgvector)
    if [ "x$OS" = "xrpm" ]; then
      rpm_deps
      INSTALL_LIST+="wget git vim binutils gcc gcc-c++ rpm-build rpmdevtools clang-devel clang perl-generators bison flex patch perl perl-ExtUtils-MakeMaker perl-ExtUtils-Embed readline-devel percona-postgresql${PG_MAJOR}-devel percona-postgresql${PG_MAJOR}-server selinux-policy systemd systemd-devel systemtap-sdt-devel "
      INSTALL_LIST+="llvm-devel python3-devel e2fsprogs-devel gettext glibc-devel krb5-devel libicu-devel libselinux-devel libuuid-devel libxml2-devel libxslt-devel openldap-devel openssl-devel pam-devel tcl-devel zlib-devel"
      dnf -y install ${INSTALL_LIST}
    else
      deb_deps
      INSTALL_LIST+="build-essential dpkg-dev debconf debhelper clang devscripts dh-exec libkrb5-dev libssl-dev percona-postgresql-common percona-postgresql-server-dev-all"
      DEBIAN_FRONTEND=noninteractive apt-get -y --allow-unauthenticated install ${INSTALL_LIST}
    fi
    ;;


  pgpool2)
    if [ "x$OS" = "xrpm" ]; then
      rpm_deps
      INSTALL_LIST+="wget git vim binutils gcc gcc-c++ make autoconf libtool bison flex byacc chrpath clang-devel clang rpmdevtools percona-postgresql${PG_MAJOR}-devel llvm-devel jade pam-devel openssl-devel docbook-dtds docbook-style-xsl openldap-devel docbook-style-dsssl libmemcached-devel libxslt"
      dnf -y install ${INSTALL_LIST}
    else
      deb_deps
      INSTALL_LIST+="percona-postgresql-${PG_MAJOR} percona-postgresql-common percona-postgresql-server-dev-all debconf devscripts dh-exec libkrb5-dev libssl-dev build-essential libxml-checker-perl chrpath docbook docbook-dsssl docbook-xml docbook-xsl flex libmemcached-dev libxml2-utils openjade opensp xsltproc bison libldap-dev libpam0g-dev"
      DEBIAN_FRONTEND=noninteractive apt-get -y --allow-unauthenticated install ${INSTALL_LIST}
    fi
    ;;


  pgbouncer)
    if [ "x$OS" = "xrpm" ]; then
      rpm_deps
      INSTALL_LIST+="wget git vim rpm-build rpmdevtools lz4-libs c-ares-devel pandoc libtool openldap-devel libevent-devel python3 python3-psycopg2 openssl-devel pam-devel systemd systemd-devel libxml2-devel perl perl-DBD-Pg perl-Digest-SHA perl-IO-Socket-SSL perl-JSON-PP zlib-devel gcc make autoconf perl-ExtUtils-Embed"
      dnf -y install ${INSTALL_LIST}
      dnf -y install lz4 || true
    else
      deb_deps
      INSTALL_LIST+="build-essential pkg-config liblz4-dev debconf debhelper devscripts dh-exec libldap-dev ldap-utils libsystemd-dev libxml-checker-perl libxml-libxml-perl libio-socket-ssl-perl libperl-dev libssl-dev libxml2-dev txt2man zlib1g-dev libpq-dev percona-postgresql-common libbz2-dev libzstd-dev libevent-dev libc-ares-dev pandoc"
      DEBIAN_FRONTEND=noninteractive apt-get -y --allow-unauthenticated install ${INSTALL_LIST}
      DEBIAN_FRONTEND=noninteractive apt-get -y --allow-unauthenticated install libpam0g-dev || DEBIAN_FRONTEND=noninteractive apt-get -y --allow-unauthenticated install libpam-dev
    fi
    ;;


  pgbadger)
    if [ "x$OS" = "xrpm" ]; then
      rpm_deps
      INSTALL_LIST+="wget git vim rpm-build rpmdevtools lz4-libs c-ares-devel pandoc libtool libevent-devel python3-psycopg2 openssl-devel pam-devel systemd systemd-devel libxml2-devel perl perl-DBD-Pg perl-Digest-SHA perl-IO-Socket-SSL perl-JSON-PP zlib-devel gcc make autoconf perl-ExtUtils-Embed which perl-Pod-Markdown"
      dnf -y install ${INSTALL_LIST}
      dnf -y install lz4 || true
    else
      deb_deps
      INSTALL_LIST+="build-essential pkg-config liblz4-dev debconf debhelper devscripts dh-exec libxml-libxml-perl libcontextual-return-perl libxml-checker-perl libio-socket-ssl-perl libperl-dev libssl-dev libxml2-dev txt2man zlib1g-dev libpq-dev percona-postgresql-common libbz2-dev libzstd-dev libevent-dev libc-ares-dev pandoc libjson-xs-perl libpod-markdown-perl"
      DEBIAN_FRONTEND=noninteractive apt-get -y --allow-unauthenticated install ${INSTALL_LIST}
      DEBIAN_FRONTEND=noninteractive apt-get -y --allow-unauthenticated install libpam0g-dev || DEBIAN_FRONTEND=noninteractive apt-get -y --allow-unauthenticated install libpam-dev
    fi
    ;;


  pgbackrest)
    if [ "x$OS" = "xrpm" ]; then
      rpm_deps
      git clone https://github.com/ianlancetaylor/libbacktrace.git
      cd libbacktrace/
        ./configure --prefix=/usr/local
        make
        make install
      cd ../
      INSTALL_LIST+="wget git vim rpm-build libcurl-devel rpmdevtools lz4-libs libyaml-devel percona-postgresql${PG_MAJOR}-devel systemd systemd-devel bzip2-devel libxml2-devel openssl-devel perl perl-DBD-Pg perl-Digest-SHA perl-IO-Socket-SSL perl-JSON-PP zlib-devel gcc make autoconf perl-ExtUtils-Embed libssh-devel libzstd-devel lz4-devel meson libtool cmake"
      dnf -y install ${INSTALL_LIST}
      dnf -y install lz4 || true
      dnf -y install perl-libxml-perl || true
    else
      deb_deps
      INSTALL_LIST+="build-essential pkg-config liblz4-dev debconf debhelper devscripts dh-exec libxml-checker-perl libxml-libxml-perl libio-socket-ssl-perl libperl-dev libssl-dev libxml2-dev txt2man zlib1g-dev libpq-dev percona-postgresql-${PG_MAJOR} percona-postgresql-common percona-postgresql-server-dev-all libbz2-dev libzstd-dev libyaml-dev meson python3-setuptools"
      DEBIAN_FRONTEND=noninteractive apt-get -y --allow-unauthenticated install ${INSTALL_LIST}
    fi
    ;;


  pgaudit_set_user)
    if [ "x$OS" = "xrpm" ]; then
      rpm_deps
      INSTALL_LIST+="wget git vim binutils gcc gcc-c++ rpm-build rpmdevtools clang perl-generators bison e2fsprogs-devel flex patch perl perl-ExtUtils-MakeMaker perl-ExtUtils-Embed percona-postgresql${PG_MAJOR}-devel percona-postgresql${PG_MAJOR}-server selinux-policy systemd systemd-devel systemtap-sdt-devel "
      INSTALL_LIST+="clang-devel llvm-devel python3-devel gettext glibc-devel krb5-devel libicu-devel libselinux-devel libuuid-devel libxml2-devel libxslt-devel openldap-devel openssl-devel pam-devel readline-devel tcl-devel zlib-devel"
      dnf -y install ${INSTALL_LIST}
    else
      deb_deps
      INSTALL_LIST+="build-essential dpkg-dev debconf debhelper clang devscripts dh-exec libkrb5-dev libssl-dev percona-postgresql-common percona-postgresql-server-dev-all"
      DEBIAN_FRONTEND=noninteractive apt-get -y --allow-unauthenticated install ${INSTALL_LIST}
    fi
    ;;


  pgaudit)
    if [ "x$OS" = "xrpm" ]; then
      rpm_deps
      INSTALL_LIST+="wget git vim binutils gcc gcc-c++ rpm-build clang-devel rpmdevtools python3-devel clang llvm-devel perl-generators bison e2fsprogs-devel flex gettext glibc-devel krb5-devel libicu-devel libselinux-devel libuuid-devel libxml2-devel libxslt-devel openldap-devel openssl-devel pam-devel patch perl perl-ExtUtils-MakeMaker perl-ExtUtils-Embed readline-devel percona-postgresql${PG_MAJOR}-devel percona-postgresql${PG_MAJOR}-server selinux-policy systemd systemd-devel systemtap-sdt-devel tcl-devel zlib-devel"
      dnf -y install ${INSTALL_LIST}
    else
      deb_deps
      INSTALL_LIST+="build-essential dpkg-dev debconf debhelper clang devscripts dh-exec libkrb5-dev libssl-dev percona-postgresql-common percona-postgresql-server-dev-all"
      DEBIAN_FRONTEND=noninteractive apt-get -y --allow-unauthenticated install ${INSTALL_LIST}
    fi
    ;;


  pg_repack)
    if [ "x$OS" = "xrpm" ]; then
      rpm_deps
      INSTALL_LIST+="wget git vim binutils gcc gcc-c++ rpm-build rpmdevtools clang-devel clang percona-postgresql${PG_MAJOR} perl-generators bison flex patch perl perl-ExtUtils-MakeMaker perl-ExtUtils-Embed percona-postgresql${PG_MAJOR}-devel percona-postgresql${PG_MAJOR}-server selinux-policy systemd systemd-devel systemtap-sdt-devel "
      INSTALL_LIST+="llvm-devel python3-devel e2fsprogs-devel gettext glibc-devel krb5-devel libicu-devel libselinux-devel libuuid-devel libxml2-devel libxslt-devel openldap-devel openssl-devel openssl-libs pam-devel readline-devel tcl-devel zlib-devel libzstd-devel lz4-devel libcurl-devel"
      dnf -y install ${INSTALL_LIST}
    else
      deb_deps
      INSTALL_LIST+="dpkg-dev build-essential percona-postgresql-${PG_MAJOR} debconf debhelper devscripts dh-exec libkrb5-dev libssl-dev percona-postgresql-common percona-postgresql-server-dev-all"
      DEBIAN_FRONTEND=noninteractive apt-get -y --allow-unauthenticated install ${INSTALL_LIST}
    fi
    ;;


  pg_gather)
    if [ "x$OS" = "xrpm" ]; then
      rpm_deps
      INSTALL_LIST+="wget git vim rpm-build rpmdevtools"
      dnf -y install ${INSTALL_LIST}
      dnf -y install rpmlint || true
    else
      deb_deps
      INSTALL_LIST+="debconf debhelper devscripts dh-exec"
      DEBIAN_FRONTEND=noninteractive apt-get -y --allow-unauthenticated install ${INSTALL_LIST}
    fi
    ;;


  pg_cron)
    if [ "x$OS" = "xrpm" ]; then
      rpm_deps
      INSTALL_LIST+="wget git vim binutils gcc gcc-c++ rpm-build clang-devel rpmdevtools python3-devel clang llvm-devel perl-generators bison e2fsprogs-devel flex gettext glibc-devel krb5-devel libicu-devel libselinux-devel libuuid-devel libxml2-devel libxslt-devel openldap-devel openssl-devel pam-devel patch perl perl-ExtUtils-MakeMaker perl-ExtUtils-Embed readline-devel percona-postgresql${PG_MAJOR}-devel percona-postgresql${PG_MAJOR}-server selinux-policy systemd systemd-devel systemtap-sdt-devel tcl-devel zlib-devel"
      dnf -y install ${INSTALL_LIST}
    else
      deb_deps
      INSTALL_LIST+="build-essential dpkg-dev debconf debhelper clang devscripts dh-exec libkrb5-dev libssl-dev percona-postgresql-common percona-postgresql-server-dev-all"
      DEBIAN_FRONTEND=noninteractive apt-get -y --allow-unauthenticated install ${INSTALL_LIST}
    fi
    ;;


  patroni)
    if [ "x$OS" = "xrpm" ]; then
      rpm_deps
      INSTALL_LIST+="wget git vim rpm-build python3-virtualenv python3.12-setuptools libyaml-devel gcc python3.12-psycopg2 python3.12-devel"
      dnf -y install ${INSTALL_LIST}
    else
      deb_deps
      INSTALL_LIST+="build-essential debconf debhelper clang devscripts dh-exec fakeroot dh-virtualenv python3-psycopg2 libyaml-dev python3-virtualenv ruby ruby-dev rubygems golang libjs-mathjax pyflakes3 python3-dateutil python3-dnspython python3-etcd python3-flake8 python3-kazoo python3-mccabe python3-mock python3-prettytable python3-psutil python3-pycodestyle python3-pytest python3-pytest-cov python3-setuptools python3-dev python3-pip python3-sphinx python3-sphinx-rtd-theme python3-tz python3-tzlocal sphinx-common python3-click python3-doc python3-cdiff dh-python python3-pysyncobj python3-sphinxcontrib.apidoc python3-ydiff"
      DEBIAN_FRONTEND=noninteractive apt-get -y --allow-unauthenticated install ${INSTALL_LIST}
    fi
    ;;


  etcd)
    if [ "x$OS" = "xrpm" ]; then
      rpm_deps
      INSTALL_LIST+="wget git vim go-toolset rpmdevtools python3-devel"
      dnf -y install ${INSTALL_LIST}
    else
      deb_deps
      INSTALL_LIST+="vim rpm dpkg-dev build-essential ccache cron debconf debhelper devscripts dh-exec dh-golang fakeroot golang-go"
      DEBIAN_FRONTEND=noninteractive apt-get -y --allow-unauthenticated install ${INSTALL_LIST}
    fi
    ;;


  *)
    echo "No special dependencies defined for $COMPONENT"
    ;;
esac
