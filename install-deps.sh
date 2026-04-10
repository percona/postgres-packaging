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
    if [[ "$COMPONENT" == "postgresql" || "$COMPONENT" == "pg_repack" ]]; then
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
    wget http://mirrors.edge.kernel.org/ubuntu/pool/universe/l/llvm-toolchain-7/llvm-7_7.0.1-12_amd64.deb http://mirrors.edge.kernel.org/ubuntu/pool/universe/l/llvm-toolchain-7/libllvm7_7.0.1-12_amd64.deb http://mirrors.edge.kernel.org/ubuntu/pool/universe/l/llvm-toolchain-7/llvm-7-runtime_7.0.1-12_amd64.deb 
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
  postgis)
    if [ "x$OS" = "xrpm" ]; then
      rpm_deps
      INSTALL_LIST+="wget git vim which binutils gcc gcc-c++ rpm-build rpmdevtools SFCGAL SFCGAL-devel pcre2-devel xerces-c-devel clang-devel clang llvm-devel autoconf libtool flex rpmlint percona-postgresql${PG_MAJOR}-devel make geos geos-devel libgeotiff-devel gmp-devel gmp-devel gtk2-devel json-c-devel libgeotiff17-devel protobuf-c-devel pkg-config docbook-xsl libxslt-devel"
      dnf -y install ${INSTALL_LIST}
      if [ ! -f  /usr/bin/llvm-config ]; then
        ln -s /usr/bin/llvm-config-64 /usr/bin/llvm-config
      fi
    else
      deb_deps
      DEBIAN_FRONTEND=noninteractive apt-get -y install tzdata
      ln -fs /usr/share/zoneinfo/America/New_York /etc/localtime
      dpkg-reconfigure --frontend noninteractive tzdata
      INSTALL_LIST+="bison build-essential debconf pkgconf debhelper devscripts dh-exec dpkg-dev flex gcc cmake vim dctrl-tools docbook docbook-xsl libcunit1-dev libgdal-dev libgeos-dev libjson-c-dev libpcre2-dev libproj-dev libprotobuf-c-dev libsfcgal-dev libxml2-dev po-debconf percona-postgresql-all percona-postgresql-common percona-postgresql-server-dev-all percona-postgresql-${PG_MAJOR} protobuf-c-compiler rdfind xsltproc"
      DEBIAN_FRONTEND=noninteractive apt-get -y --allow-unauthenticated install ${INSTALL_LIST}
      apt-get install -y dblatex || true
    fi
    ;;


  timescaledb)
    if [ "x$OS" = "xrpm" ]; then
      rpm_deps
      INSTALL_LIST="wget gcc make autoconf clang-devel clang llvm-devel cmake git rpmdevtools percona-postgresql${PG_MAJOR}-devel openssl-devel"
      yum -y install ${INSTALL_LIST}
    else
      deb_deps
      INSTALL_LIST="build-essential pkg-config debconf debhelper debhelper-compat devscripts dh-exec git wget cmake libssl-dev percona-postgresql-${PG_MAJOR} percona-postgresql-common percona-postgresql-server-dev-all percona-postgresql-all"
      until DEBIAN_FRONTEND=noninteractive apt-get -y --allow-unauthenticated install ${INSTALL_LIST}; do
        sleep 1
        echo "waiting"
      done
    fi
    ;;


  
  h3-pg)
    if [ "x$OS" = "xrpm" ]; then
      rpm_deps
      INSTALL_LIST="wget gcc make autoconf cmake git rpmdevtools percona-postgresql${PG_MAJOR}-devel h3-devel"
      yum -y install ${INSTALL_LIST}
    else
      deb_deps
      INSTALL_LIST="build-essential pkg-config debconf debhelper debhelper-compat devscripts dh-exec git wget cmake libh3-dev percona-postgresql-server-dev-all percona-postgresql-all"
      until DEBIAN_FRONTEND=noninteractive apt-get -y --allow-unauthenticated install ${INSTALL_LIST}; do
        sleep 1
        echo "waiting"
      done
    fi
    ;;


  pgrouting)
    if [ "x$OS" = "xrpm" ]; then
      rpm_deps
      INSTALL_LIST="wget gcc make autoconf cmake git rpmdevtools percona-postgresql${PG_MAJOR}-devel boost-devel gcc-c++ gmp-devel perl-version"
      yum -y install ${INSTALL_LIST}
    else
      deb_deps
      INSTALL_LIST="build-essential pkg-config debconf debhelper debhelper-compat devscripts dh-exec git wget cmake percona-postgresql-server-dev-all percona-postgresql-all"
      until DEBIAN_FRONTEND=noninteractive apt-get -y --allow-unauthenticated install ${INSTALL_LIST}; do
        sleep 1
        echo "waiting"
      done
    fi
    ;;

  pg_cron)
    if [ "x$OS" = "xrpm" ]; then
      rpm_deps
      INSTALL_LIST="wget gcc make git rpmdevtools percona-postgresql${PG_MAJOR}-devel libxml2-devel openssl-devel openldap-devel"
      yum -y install ${INSTALL_LIST}
    fi
    ;;

  pgvectorscale)
    if [ "x$OS" = "xrpm" ]; then
      rpm_deps
      INSTALL_LIST="wget gcc make autoconf git jq rpmdevtools percona-postgresql${PG_MAJOR}-devel clang openssl-devel rust-toolset rustfmt llvm-devel"
      yum -y install ${INSTALL_LIST}
    fi
    ;;

  hll)
    if [ "x$OS" = "xrpm" ]; then
      rpm_deps
      INSTALL_LIST="wget gcc make git rpmdevtools percona-postgresql${PG_MAJOR}-devel libxml2-devel"
      yum -y install ${INSTALL_LIST}
    fi
    ;;

  pg_similarity)
    if [ "x$OS" = "xrpm" ]; then
      rpm_deps
      INSTALL_LIST="wget gcc make autoconf cmake git rpmdevtools percona-postgresql${PG_MAJOR}-devel llvm-devel clang-devel"
      yum -y install ${INSTALL_LIST}
    fi
    ;;


  anon)
    if [ "x$OS" = "xrpm" ]; then
      rpm_deps
      INSTALL_LIST="wget gcc make git rpmdevtools percona-postgresql${PG_MAJOR}-devel openssl-devel clang-devel pkg-config rust-toolset rustfmt"
      yum -y install ${INSTALL_LIST}
    fi
    ;;


  pg_partman)
    if [ "x$OS" = "xrpm" ]; then
      rpm_deps
      INSTALL_LIST="wget gcc make git rpmdevtools percona-postgresql${PG_MAJOR}-devel clang-devel llvm-devel python3-psycopg2"
      yum -y install ${INSTALL_LIST}
    fi
    ;;


  rum)
    if [ "x$OS" = "xrpm" ]; then
      rpm_deps
      INSTALL_LIST="wget gcc make autoconf cmake git rpmdevtools percona-postgresql${PG_MAJOR}-devel percona-postgresql${PG_MAJOR} llvm-devel clang-devel"
      yum -y install ${INSTALL_LIST}
    fi
    ;;


  postgresql-unit)
    if [ "x$OS" = "xrpm" ]; then
      rpm_deps
      INSTALL_LIST="wget gcc make autoconf cmake git rpmdevtools percona-postgresql${PG_MAJOR}-devel flex llvm-devel clang-devel"
      yum -y install ${INSTALL_LIST}
    fi
    ;;
  

  ip4r)
    if [ "x$OS" = "xrpm" ]; then
      rpm_deps
      INSTALL_LIST="wget gcc make autoconf cmake git rpmdevtools percona-postgresql${PG_MAJOR}-devel llvm-devel clang-devel"
      yum -y install ${INSTALL_LIST}
    fi
    ;;


  *)
    echo "No special dependencies defined for $COMPONENT"
    ;;
esac
