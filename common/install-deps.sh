#!/usr/bin/env bash
set -x


# ---------- RPMs dependencies -----------
rpm_deps() {
  export RHEL=$(rpm --eval %rhel)
  export ARCH=$(uname -m)

  dnf config-manager --set-enabled ol${RHEL}_codeready_builder

  if [[ "${RHEL}" -eq 8 ]]; then
    dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-${RHEL}.noarch.rpm
    if [[ "$COMPONENT" == "ydiff" ]]; then
      INSTALL_LIST+="python3-devel python3-setuptools "
    fi
  else
    if [[ "$COMPONENT" == "ydiff" ]]; then
      INSTALL_LIST+="python3.12-setuptools python3.12-devel "
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

  if [[ "$COMPONENT" == "patroni" || "$COMPONENT" == "pgbackrest" || "$COMPONENT" == "ydiff" || "$COMPONENT" == "pgpool2" ]]; then
    dnf config-manager --set-enabled PowerTools || dnf config-manager --set-enabled powertools || true
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
    if [ "x${DEBIAN}" = "xtrixie" -o "x${DEBIAN}" = "xresolute" ]; then
      INSTALL_LIST+="python3-boto3 "  
    else
      INSTALL_LIST+="python3-boto "
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
