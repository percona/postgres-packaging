#!/usr/bin/env bash
set -x


# ---------- RPMs dependencies -----------
rpm_deps() {
  export RHEL=$(rpm --eval %rhel)
  export ARCH=$(uname -m)

  dnf config-manager --set-enabled ol${RHEL}_codeready_builder

  if [[ "${RHEL}" -eq 8 ]]; then
    dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-${RHEL}.noarch.rpm
    if [[ "$COMPONENT" == "pgrepack" || "$COMPONENT" == "patroni" || "$COMPONENT" == "ydiff" ]]; then
      INSTALL_LIST+="python3-devel "
    fi
    if [[ "$COMPONENT" == "ppg-server-ha" ]]; then
      INSTALL_LIST+="perl lz4-libs c-ares-devel "
    fi
    if [[ "$COMPONENT" == "postgis" ]]; then
      INSTALL_LIST+="gdal38-devel proj95-devel geos311-devel "
    fi
    if [[ "$COMPONENT" == "pg_oidc" ]]; then
      INSTALL_LIST+="gcc-toolset-14 "
    fi
    if [[ "$COMPONENT" == "patroni" || "$COMPONENT" == "ydiff" ]]; then
      INSTALL_LIST+="python3-setuptools "
    fi
     if [[ "$COMPONENT" == "patroni" ]]; then
      INSTALL_LIST+="python3-psycopg2 "
    fi
  else
    if [[ "$COMPONENT" == "patroni" || "$COMPONENT" == "ydiff" ]]; then
      INSTALL_LIST+="python3.12-setuptools python3.12-devel "
    fi
     if [[ "$COMPONENT" == "patroni" ]]; then
      INSTALL_LIST+="python3.12-psycopg2 "
    fi
  fi

  if [[ "${RHEL}" -eq 9 ]]; then
    if [[ "$COMPONENT" == "postgresql" || "$COMPONENT" == "pg_repack" || "$COMPONENT" == "pg_oidc" ]]; then
      INSTALL_LIST+="gcc-toolset-14 "
    fi
    if [[ "$COMPONENT" == "pgpool2" ]]; then
      sed -i 's/enabled=0/enabled=1/g' /etc/yum.repos.d/oracle-linux-ol9.repo
    fi
    if [[ "$COMPONENT" == "postgis" ]]; then
      INSTALL_LIST+="gdal311-devel proj95-devel geos311-devel "
    fi
  fi

  if [[ "${RHEL}" -eq 10 ]]; then
    if [[ "$COMPONENT" == "postgis" ]]; then
      INSTALL_LIST+="gdal311-devel proj96-devel geos313-devel "
    fi
    if [[ "$COMPONENT" == "pg_oidc" ]]; then
      INSTALL_LIST+="libstdc++-static "
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
  #export DEBIAN_FRONTEND=noninteractive
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
    #wget http://mirrors.edge.kernel.org/ubuntu/pool/universe/l/llvm-toolchain-7/llvm-7_7.0.1-12_amd64.deb http://mirrors.edge.kernel.org/ubuntu/pool/universe/l/llvm-toolchain-7/libllvm7_7.0.1-12_amd64.deb http://mirrors.edge.kernel.org/ubuntu/pool/universe/l/llvm-toolchain-7/llvm-7-runtime_7.0.1-12_amd64.deb 
    #apt -y install ./libllvm7_7.0.1-12_amd64.deb ./llvm-7_7.0.1-12_amd64.deb ./llvm-7-runtime_7.0.1-12_amd64.deb
    DEBIAN_FRONTEND=noninteractive apt-get -y install debhelper
    if grep -q "${DEBIAN}-backports" /etc/apt/sources.list; then
      apt-get -y install -t ${DEBIAN}-backports debhelper
    else
      echo "Backports repo NOT found"
    fi
    apt list --all-versions debhelper
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
    ./llvm.sh 14 bullseye
    if [[ "$COMPONENT" == "pgbackrest" ]]; then
      DEBIAN_FRONTEND=noninteractive apt-get -y --allow-unauthenticated install dh_systemd
    fi
  fi

  if [[ "$COMPONENT" == "pg_oidc" ]]; then
    DEBIAN_FRONTEND=noninteractive apt-get -y install software-properties-common
    wget https://apt.llvm.org/llvm.sh
    chmod +x llvm.sh
    ./llvm.sh 21 all
    apt-get install libc++-21-dev libc++abi-21-dev clang-21 clang++-21
  fi
  
  return;  
}




# ------- main ---------
COMPONENT=$1
PG_MAJOR=$2

if [ $( id -u ) -ne 0 ]; then
  echo "It is not possible to install dependencies. Please run as root"
  exit 1
fi
CURPLACE=$(pwd)

INSTALL_LIST=" "

# ---- Component-specific dependencies ----
case "$COMPONENT" in
  ydiff)
    if [ "x$OS" = "xrpm" ]; then
      rpm_deps
      INSTALL_LIST+="wget git vim rpm-build rpmdevtools"
      dnf -y install ${INSTALL_LIST}
    else
      deb_deps
      INSTALL_LIST+="build-essential debconf debhelper dh-exec fakeroot devscripts python3-psycopg2 python3-setuptools libyaml-dev python3-dev dh-virtualenv python3-virtualenv ruby ruby-dev rubygems golang dh-python libjs-mathjax pyflakes3 python3-dateutil python3-dnspython python3-etcd python3-flake8 python3-kazoo python3-mccabe python3-mock python3-prettytable python3-psutil python3-pycodestyle python3-pytest python3-pytest-cov python3-sphinx python3-sphinx-rtd-theme python3-tz python3-tzlocal sphinx-common python3-click python3-doc python3-all"
      DEBIAN_FRONTEND=noninteractive apt-get -y --allow-unauthenticated install ${INSTALL_LIST}
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
      INSTALL_LIST+="build-essential pkg-config liblz4-dev debconf debhelper devscripts dh-exec libxml-libxml-perl libtext-csv-xs-perl libcontextual-return-perl libxml-checker-perl libio-socket-ssl-perl libperl-dev libssl-dev libxml2-dev txt2man zlib1g-dev libpq-dev percona-postgresql-common libbz2-dev libzstd-dev libevent-dev libc-ares-dev pandoc libjson-xs-perl libpod-markdown-perl"
      DEBIAN_FRONTEND=noninteractive apt-get -y --allow-unauthenticated install ${INSTALL_LIST}
      DEBIAN_FRONTEND=noninteractive apt-get -y --allow-unauthenticated install libpam0g-dev || DEBIAN_FRONTEND=noninteractive apt-get -y --allow-unauthenticated install libpam-dev
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


  h3)
    if [ "x$OS" = "xrpm" ]; then
      rpm_deps
      INSTALL_LIST+="gcc gcc-c++ make cmake git rpm-build rpmdevtools"
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
