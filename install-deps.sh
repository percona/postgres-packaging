#!/usr/bin/env bash
set -x

COMPONENT=$1

if [ $( id -u ) -ne 0 ]; then
  echo "It is not possible to install dependencies. Please run as root"
  exit 1
fi
CURPLACE=$(pwd)

# postgresql
if [ "$COMPONENT" = "postgresql" ]; then
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

        INSTALL_LIST="chrpath clang-devel clang llvm-devel python3-devel perl-generators bison e2fsprogs-devel flex gettext git glibc-devel krb5-devel libicu-devel libselinux-devel libuuid-devel libxml2-devel libxslt-devel openldap-devel openssl-devel pam-devel patch perl perl-ExtUtils-MakeMaker perl-ExtUtils-Embed readline-devel rpmdevtools selinux-policy systemd systemd-devel systemtap-sdt-devel tcl-devel vim wget zlib-devel lz4-devel libzstd-devel perl-IPC-Run perl-Test-Simple rpmdevtools"
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

      if [ x"$RHEL" = x9 ]; then
           yum -y install gcc-toolset-14
      fi
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
      if [ "x${DEBIAN}" != "xfocal" -a "x${DEBIAN}" != "xbullseye" -a "x${DEBIAN}" != "xjammy" -a "x${DEBIAN}" != "xbookworm" -a "x${DEBIAN}" != "xnoble" -a "x${DEBIAN}" != "xtrixie" ]; then
        INSTALL_LIST="bison build-essential ccache cron debconf debhelper devscripts dh-exec dh-systemd docbook-xml docbook-xsl dpkg-dev flex gcc gettext git krb5-multidev libbsd-resource-perl libedit-dev libicu-dev libipc-run-perl libkrb5-dev libldap-dev libldap2-dev libmemchan-tcl-dev libpam0g-dev libperl-dev libpython-dev libreadline-dev libselinux1-dev libssl-dev libsystemd-dev libwww-perl libxml2-dev libxml2-utils libxslt-dev libxslt1-dev llvm-dev perl pkg-config python python-dev python3-dev systemtap-sdt-dev tcl-dev tcl8.6-dev uuid-dev vim wget xsltproc zlib1g-dev rename clang gdb liblz4-dev libipc-run-perl libcurl4-openssl-dev libzstd-dev"
      else
        INSTALL_LIST="bison build-essential ccache cron debconf debhelper devscripts dh-exec docbook-xml docbook-xsl dpkg-dev flex gcc gettext git krb5-multidev libbsd-resource-perl libedit-dev libicu-dev libipc-run-perl libkrb5-dev libldap-dev libldap2-dev libmemchan-tcl-dev libpam0g-dev libperl-dev libpython3-dev libreadline-dev libselinux1-dev libssl-dev libsystemd-dev libwww-perl libxml2-dev libxml2-utils libxslt-dev libxslt1-dev llvm-dev perl pkg-config python3 python3-dev systemtap-sdt-dev tcl-dev tcl8.6-dev uuid-dev vim wget xsltproc zlib1g-dev rename clang gdb liblz4-dev libipc-run-perl libcurl4-openssl-dev libzstd-dev"
      fi
 
       until DEBIAN_FRONTEND=noninteractive apt-get -y --allow-unauthenticated install ${INSTALL_LIST}; do
        sleep 1
        echo "waiting"
      done
    fi
fi


# postgresql-common
if [ "$COMPONENT" = "postgresql-common" ]; then
    if [ "x$OS" = "xrpm" ]; then
      yum -y install wget
      yum clean all
      RHEL=$(rpm --eval %rhel)
      if [[ "${RHEL}" -eq 10 ]]; then
        yum install oracle-epel-release-el10
      else
        yum -y install epel-release
      fi
      INSTALL_LIST="git patch perl perl-ExtUtils-MakeMaker perl-ExtUtils-Embed rpmdevtools wget perl-podlators sudo make"
      yum -y install ${INSTALL_LIST}
    else
      apt-get update || true
      apt-get -y install lsb-release
      export DEBIAN=$(lsb_release -sc)
      export ARCH=$(echo $(uname -m) | sed -e 's:i686:i386:g')
      apt-get -y install gnupg2
      apt-get update || true
      INSTALL_LIST="git wget debhelper libreadline-dev lsb-release rename devscripts sudo"
      until DEBIAN_FRONTEND=noninteractive apt-get -y install ${INSTALL_LIST}; do
        sleep 1
        echo "waiting"
      done
    fi
fi

# ydiff
if [ "$COMPONENT" = "ydiff" ]; then
  if [ "x$OS" = "xrpm" ]; then
      if [ x"$RHEL" = x8 ]; then
          switch_to_vault_repo || true
      fi
      yum -y install wget
      yum clean all
      if [[ "${RHEL}" -eq 10 ]]; then
        yum install oracle-epel-release-el10
      else
        yum -y install epel-release
      fi
      RHEL=$(rpm --eval %rhel)
      if [ ${RHEL} -gt 7 ]; then
          yum config-manager --set-enabled PowerTools || yum config-manager --set-enabled powertools || true
      fi
      if [ ${RHEL} = 7 ]; then
          INSTALL_LIST="git wget rpm-build python3-devel rpmdevtools"
          yum -y install ${INSTALL_LIST}
      else
          dnf config-manager --set-enabled ol${RHEL}_codeready_builder
          dnf clean all
          rm -r /var/cache/dnf
          dnf -y upgrade
          INSTALL_LIST="git wget rpm-build python3-devel python3-setuptools rpmdevtools"
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

      INSTALL_LIST="build-essential debconf debhelper devscripts dh-exec git wget fakeroot devscripts python3-psycopg2 python3-setuptools libyaml-dev python3-virtualenv ruby ruby-dev rubygems curl golang dh-python libjs-mathjax pyflakes3 python3-dateutil python3-dnspython python3-etcd  python3-flake8 python3-kazoo python3-mccabe python3-mock python3-prettytable python3-psutil python3-pycodestyle python3-pytest python3-pytest-cov python3-sphinx python3-sphinx-rtd-theme python3-tz python3-tzlocal sphinx-common python3-click python3-doc python3-all "
      if [ "x${DEBIAN}" = "xtrixie" ]; then
        INSTALL_LIST+="python3-dev dh-virtualenv python3-boto3"  
      elif [ "x${DEBIAN}" != "xfocal" ]; then
        INSTALL_LIST+="python3-dev dh-virtualenv python3-boto"
      else
        INSTALL_LIST+="python2-dev python3-boto"
      fi
      DEBIAN_FRONTEND=noninteractive apt-get -y install ${INSTALL_LIST}
    fi
fi

# wal2json
if [ "$COMPONENT" = "wal2json" ]; then
  if [ "x$OS" = "xrpm" ]; then
      RHEL=$(rpm --eval %rhel)
      if [ x"$RHEL" = x8 ]; then
          switch_to_vault_repo || true
      fi
      yum -y install wget
      add_percona_yum_repo
      yum clean all
      if [[ "${RHEL}" -eq 10 ]]; then
        yum install oracle-epel-release-el10
      else
        yum -y install epel-release
      fi
      if [ ${RHEL} -gt 7 ]; then
          dnf -y module disable postgresql || true
          dnf config-manager --set-enabled ol${RHEL}_codeready_builder
          dnf clean all
          rm -r /var/cache/dnf
          dnf -y upgrade
	  switch_to_vault_repo || true

          yum -y install clang-devel clang llvm-devel perl lz4-libs c-ares-devel
      else
        until yum -y install centos-release-scl; do
            echo "waiting"
            sleep 1
        done
        yum -y install llvm-toolset-7-clang llvm5.0-devtoolset
        source /opt/rh/devtoolset-7/enable
        source /opt/rh/llvm-toolset-7/enable
      fi
      INSTALL_LIST="pandoc libtool libevent-devel python3-psycopg2 openssl-devel pam-devel percona-postgresql${PG_MAJOR}-devel git rpmdevtools systemd systemd-devel wget libxml2-devel perl perl-DBD-Pg perl-Digest-SHA perl-IO-Socket-SSL perl-JSON-PP zlib-devel gcc make autoconf perl-ExtUtils-Embed"
      yum -y install ${INSTALL_LIST}
      yum -y install lz4 || true

    else
      export ARCH=$(echo $(uname -m) | sed -e 's:i686:i386:g')
      apt-get update || true
      apt-get -y install lsb-release wget gnupg2 curl
      export DEBIAN=$(lsb_release -sc)
      add_percona_apt_repo
      apt-get update || true
      INSTALL_LIST="build-essential pkg-config liblz4-dev debconf debhelper devscripts dh-exec git wget libxml-checker-perl libxml-libxml-perl libio-socket-ssl-perl libperl-dev libssl-dev libxml2-dev txt2man zlib1g-dev libpq-dev percona-postgresql-${PG_MAJOR} percona-postgresql-common percona-postgresql-server-dev-all percona-postgresql-all libbz2-dev libzstd-dev libevent-dev libssl-dev libc-ares-dev pandoc pkg-config"
      until DEBIAN_FRONTEND=noninteractive apt-get -y --allow-unauthenticated install ${INSTALL_LIST}; do
        sleep 1
        echo "waiting"
      done
      DEBIAN_FRONTEND=noninteractive apt-get -y --allow-unauthenticated install libpam0g-dev || DEBIAN_FRONTEND=noninteractive apt-get -y --allow-unauthenticated install libpam-dev
    fi
fi

# pysyncobj
if [ "$COMPONENT" = "pysyncobj" ]; then
  if [ "x$OS" = "xrpm" ]; then
      if [ x"$RHEL" = x8 ]; then
          switch_to_vault_repo || true
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
fi

# ppg-server-ha
if [ "$COMPONENT" = "ppg-server-ha" ]; then
  if [ "x$OS" = "xrpm" ]; then
      RHEL=$(rpm --eval %rhel)
      yum -y install wget
      add_percona_yum_repo
      yum clean all

      if [ ${RHEL} = 8 ]; then
          dnf -y module disable postgresql || true
          dnf config-manager --set-enabled codeready-builder-for-rhel-8-x86_64-rpms
          dnf clean all
          rm -r /var/cache/dnf
          dnf -y upgrade
          yum -y install perl lz4-libs c-ares-devel
      fi
      if [[ "${RHEL}" -eq 10 ]]; then
        INSTALL_LIST="git rpm-build rpmdevtools"
      else
        INSTALL_LIST="git rpm-build rpmdevtools rpmlint"
      fi
      yum -y install ${INSTALL_LIST}
      yum -y install lz4 || true

    else
      export ARCH=$(echo $(uname -m) | sed -e 's:i686:i386:g')
      apt-get -y update
      apt-get -y install wget curl lsb-release gnupg2
      export DEBIAN=$(lsb_release -sc)
      add_percona_apt_repo
      apt-get update || true
      INSTALL_LIST="debconf debhelper devscripts dh-exec git"
      until DEBIAN_FRONTEND=noninteractive apt-get -y --allow-unauthenticated install ${INSTALL_LIST}; do
        sleep 1
        echo "waiting"
      done
    fi
fi

# ppg-server
if [ "$COMPONENT" = "ppg-server" ]; then
  if [ "x$OS" = "xrpm" ]; then
      RHEL=$(rpm --eval %rhel)
      yum -y install wget
      add_percona_yum_repo
      yum clean all

      if [ ${RHEL} = 8 ]; then
          dnf -y module disable postgresql || true
          dnf config-manager --set-enabled codeready-builder-for-rhel-8-x86_64-rpms
          dnf clean all
          rm -r /var/cache/dnf
          dnf -y upgrade
          yum -y install perl lz4-libs c-ares-devel
      fi
      if [[ "${RHEL}" -eq 10 ]]; then
        INSTALL_LIST="git rpm-build rpmdevtools"
      else
        INSTALL_LIST="git rpm-build rpmdevtools rpmlint"
      fi
      yum -y install ${INSTALL_LIST}
      yum -y install lz4 || true

    else
      export ARCH=$(echo $(uname -m) | sed -e 's:i686:i386:g')
      apt-get -y update
      apt-get -y install wget curl lsb-release gnupg2
      export DEBIAN=$(lsb_release -sc)
      add_percona_apt_repo
      apt-get update || true
      INSTALL_LIST="debconf debhelper devscripts dh-exec git"
      until DEBIAN_FRONTEND=noninteractive apt-get -y --allow-unauthenticated install ${INSTALL_LIST}; do
        sleep 1
        echo "waiting"
      done
    fi
fi

# postgis
if [ "$COMPONENT" = "postgis" ]; then
  if [ "x$OS" = "xrpm" ]; then
      yum -y install wget
      add_percona_yum_repo
      yum clean all
      RHEL=$(rpm --eval %rhel)
      ARCH=$(uname -m)
      if [[ "${RHEL}" -eq 10 ]]; then
          yum install oracle-epel-release-el10
          dnf config-manager --set-enabled ol${RHEL}_codeready_builder
      else
          yum -y install epel-release
      fi
      if [ x"$RHEL" = x6 -o x"$RHEL" = x7 ]; then
          until yum -y install centos-release-scl; do
              echo "waiting"
              sleep 1
          done
          wget --no-check-certificate https://download.postgresql.org/pub/repos/yum/reporpms/EL-${RHEL}-${ARCH}/pgdg-redhat-repo-latest.noarch.rpm
          yum -y install pgdg-redhat-repo-latest.noarch.rpm
          yum -y install pgdg-srpm-macros
          INSTALL_LIST="git rpm-build autoconf libtool flex rpmdevtools wget llvm-toolset-7 devtoolset-7 rpmlint percona-postgresql${PG_MAJOR}-devel gcc make  geos geos-devel proj libgeotiff-devel pcre-devel gmp-devel SFCGAL SFCGAL-devel gdal33-devel gdal34-devel geos311-devel gmp-devel gtk2-devel json-c-devel libgeotiff17-devel proj72-devel protobuf-c-devel pkg-config"
          yum -y install ${INSTALL_LIST}
          source /opt/rh/devtoolset-7/enable
          source /opt/rh/llvm-toolset-7/enable
      else
	 yum config-manager --enable PowerTools AppStream BaseOS *epel || true
	 dnf module -y disable postgresql || true
         dnf config-manager --set-enabled ol${RHEL}_codeready_builder
         yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-${RHEL}.noarch.rpm
         wget --no-check-certificate https://download.postgresql.org/pub/repos/yum/reporpms/EL-${RHEL}-${ARCH}/pgdg-redhat-repo-latest.noarch.rpm
         yum -y install pgdg-redhat-repo-latest.noarch.rpm
         yum -y install pgdg-srpm-macros
         if [ x"$RHEL" = x9 ]; then
            yum -y install SFCGAL SFCGAL-devel gdal311-devel proj95-devel
         elif [ x"$RHEL" = x10 ]; then
            yum -y install SFCGAL SFCGAL-devel gdal311-devel proj96-devel
         else
            yum -y install SFCGAL SFCGAL-devel gdal38-devel proj95-devel
         fi
         if [ x"$RHEL" = x10 ]; then
            yum -y install geos313-devel pcre2-devel which
         else
            yum -y install geos311-devel pcre-devel
         fi
         INSTALL_LIST="xerces-c-devel clang-devel clang llvm-devel git rpm-build  autoconf libtool flex rpmdevtools wget rpmlint percona-postgresql${PG_MAJOR}-devel gcc make  geos geos-devel libgeotiff-devel gmp-devel gmp-devel gtk2-devel json-c-devel libgeotiff17-devel protobuf-c-devel pkg-config"
         yum -y install ${INSTALL_LIST}
         yum -y install binutils gcc gcc-c++
         yum clean all
         if [ ! -f  /usr/bin/llvm-config ]; then
             ln -s /usr/bin/llvm-config-64 /usr/bin/llvm-config
         fi
       fi
       yum -y install docbook-xsl libxslt-devel
    else
      apt-get -y update
      apt-get -y install curl wget lsb-release
      export DEBIAN=$(lsb_release -sc)
      export ARCH=$(echo $(uname -m) | sed -e 's:i686:i386:g')
      apt-get -y install gnupg2
      apt-get update || true
      ENV export DEBIAN_FRONTEND=noninteractive
      DEBIAN_FRONTEND=noninteractive apt-get -y install tzdata
      ln -fs /usr/share/zoneinfo/America/New_York /etc/localtime
      dpkg-reconfigure --frontend noninteractive tzdata
      wget https://repo.percona.com/apt/percona-release_latest.generic_all.deb
      dpkg -i percona-release_latest.generic_all.deb
      rm -f percona-release_latest.generic_all.deb
      percona-release enable-only ppg-${PG_VERSION} testing
      percona-release enable telemetry testing
      apt-get update
      
      INSTALL_LIST="bison build-essential imagemagick debconf debhelper devscripts dh-exec dpkg-dev flex gcc git cmake vim wget dctrl-tools docbook docbook-xsl libcunit1-dev libgdal-dev libgeos-dev libjson-c-dev libpcre2-dev libproj-dev libprotobuf-c-dev libsfcgal-dev libxml2-dev pkg-config po-debconf percona-postgresql-all percona-postgresql-common percona-postgresql-server-dev-all percona-postgresql-${PG_MAJOR_VERSION} protobuf-c-compiler rdfind xsltproc"
      until DEBIAN_FRONTEND=noninteractive apt-get -y --allow-unauthenticated install ${INSTALL_LIST}; do
        sleep 1
        echo "waiting"
      done
       apt-get install -y dblatex || true

       if [ "x${DEBIAN}" = "xbionic" ]; then
          install_sfcgal
       fi
    fi
fi

# pgvector
if [ "$COMPONENT" = "pgvector" ]; then
  if [ "x$OS" = "xrpm" ]; then
        yum -y install wget
        add_percona_yum_repo
        yum clean all
        RHEL=$(rpm --eval %rhel)
        if [[ "${RHEL}" -eq 10 ]]; then
            yum install oracle-epel-release-el10
        else
            yum -y install epel-release
        fi
        if [ x"$RHEL" = x6 -o x"$RHEL" = x7 ]; then
            until yum -y install centos-release-scl; do
                echo "waiting"
                sleep 1
            done
            INSTALL_LIST="bison e2fsprogs-devel flex gettext git glibc-devel krb5-devel libicu-devel libselinux-devel libuuid-devel libxml2-devel libxslt-devel llvm5.0-devel llvm-toolset-7-clang openldap-devel openssl-devel pam-devel patch perl perl-ExtUtils-Embed perl-ExtUtils-MakeMaker python2-devel readline-devel rpmbuild percona-postgresql${PG_MAJOR}-devel percona-postgresql${PG_MAJOR}-server rpm-build rpmdevtools selinux-policy systemd systemd-devel systemtap-sdt-devel tcl-devel vim wget zlib-devel llvm-toolset-7-clang-devel make gcc gcc-c++"
            yum -y install ${INSTALL_LIST}
            source /opt/rh/devtoolset-7/enable
            source /opt/rh/llvm-toolset-7/enable
        else
            dnf module -y disable postgresql || true
            dnf config-manager --set-enabled ol${RHEL}_codeready_builder

            INSTALL_LIST="clang-devel clang llvm-devel python3-devel perl-generators bison e2fsprogs-devel flex gettext git glibc-devel krb5-devel libicu-devel libselinux-devel libuuid-devel libxml2-devel libxslt-devel openldap-devel openssl-devel pam-devel patch perl perl-ExtUtils-MakeMaker perl-ExtUtils-Embed readline-devel percona-postgresql${PG_MAJOR}-devel percona-postgresql${PG_MAJOR}-server rpm-build rpmdevtools selinux-policy systemd systemd-devel systemtap-sdt-devel tcl-devel vim wget zlib-devel "
            yum -y install ${INSTALL_LIST}
            yum -y install binutils gcc gcc-c++
        fi
    else
        apt-get -y update
        apt-get -y install wget lsb-release
        export DEBIAN=$(lsb_release -sc)
        export ARCH=$(echo $(uname -m) | sed -e 's:i686:i386:g')
	apt-get -y update || true
        apt-get -y install gnupg2 curl
        add_percona_apt_repo
        apt-get update || true
        INSTALL_LIST="build-essential dpkg-dev debconf debhelper clang devscripts dh-exec git wget libkrb5-dev libssl-dev percona-postgresql-common percona-postgresql-server-dev-all"
        DEBIAN_FRONTEND=noninteractive apt-get -y --allow-unauthenticated install ${INSTALL_LIST}
    fi
fi

# pgpool2
if [ "$COMPONENT" = "pgpool2" ]; then
  if [ "$OS" == "rpm" ]
    then
        if [[ "${RHEL}" -eq 10 ]]; then
            yum install oracle-epel-release-el10
            dnf config-manager --set-enabled ol${RHEL}_codeready_builder
        else
            yum -y install epel-release
        fi
        yum -y install wget
        yum install -y https://repo.percona.com/yum/percona-release-latest.noarch.rpm
        percona-release enable ppg-${PG_VERSION} testing
        yum -y install git libtool bison flex byacc

        PKGLIST="clang-devel clang llvm-devel percona-postgresql${PG_MAJOR}-devel"
        PKGLIST+=" git rpmdevtools vim wget"
        PKGLIST+=" perl binutils gcc gcc-c++"
        PKGLIST+=" git rpmdevtools wget gcc make autoconf"
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
            dnf -y module disable postgresql || true
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
        export DEBIAN=$(lsb_release -sc)

        wget https://repo.percona.com/apt/percona-release_latest.generic_all.deb
        dpkg -i percona-release_latest.generic_all.deb
        rm -f percona-release_latest.generic_all.deb
        percona-release enable ppg-${PG_VERSION} testing

        PKGLIST="percona-postgresql-${PG_MAJOR} percona-postgresql-common percona-postgresql-server-dev-all"
        
        apt-get update

        if [[ "${DEBIAN}" != "focal" ]]; then
            #LLVM_EXISTS=$(grep -c "apt.llvm.org" /etc/apt/sources.list)
            #if [ "${LLVM_EXISTS}" == 0 ]; then
            #    wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key|sudo apt-key add -
            #    echo "deb http://apt.llvm.org/${OS_NAME}/ llvm-toolchain-${OS_NAME}-7 main" >> /etc/apt/sources.list
            #    echo "deb-src http://apt.llvm.org/${OS_NAME}/ llvm-toolchain-${OS_NAME}-7 main" >> /etc/apt/sources.list
            #    apt-get update
            #fi
			wget http://mirrors.kernel.org/ubuntu/pool/universe/l/llvm-toolchain-7/llvm-7_7.0.1-12_amd64.deb http://mirrors.kernel.org/ubuntu/pool/universe/l/llvm-toolchain-7/libllvm7_7.0.1-12_amd64.deb http://mirrors.kernel.org/ubuntu/pool/universe/l/llvm-toolchain-7/llvm-7-runtime_7.0.1-12_amd64.deb
            apt install ./libllvm7_7.0.1-12_amd64.deb ./llvm-7_7.0.1-12_amd64.deb ./llvm-7-runtime_7.0.1-12_amd64.deb
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

        cat /etc/apt/sources.list | grep ${DEBIAN}-backports
        apt list --all-versions debhelper
        apt-get -y install -t ${DEBIAN}-backports debhelper

        get_openjade_devel
    fi
fi

# pgbouncer
if [ "$COMPONENT" = "pgbouncer" ]; then
  if [ "x$OS" = "xrpm" ]; then
      RHEL=$(rpm --eval %rhel)
      if [ x"$RHEL" = x8 ]; then
          switch_to_vault_repo || true
      fi
      yum -y install wget
      add_percona_yum_repo
      yum clean all
      if [[ "${RHEL}" -eq 10 ]]; then
          yum install oracle-epel-release-el10
      else
          yum -y install epel-release
      fi
      if [ ${RHEL} -gt 7 ]; then
          dnf -y module disable postgresql || true
          dnf config-manager --set-enabled ol${RHEL}_codeready_builder
          dnf clean all
          rm -r /var/cache/dnf
          dnf -y upgrade
	  switch_to_vault_repo || true
          yum -y install perl lz4-libs c-ares-devel
      else
        until yum -y install centos-release-scl; do
            echo "waiting"
            sleep 1
        done
        yum -y install llvm-toolset-7-clang llvm5.0-devtoolset
        source /opt/rh/devtoolset-7/enable
        source /opt/rh/llvm-toolset-7/enable
      fi
      INSTALL_LIST="pandoc libtool libevent-devel python3 python3-psycopg2 openssl-devel pam-devel git rpm-build rpmdevtools systemd systemd-devel wget libxml2-devel perl perl-DBD-Pg perl-Digest-SHA perl-IO-Socket-SSL perl-JSON-PP zlib-devel gcc make autoconf perl-ExtUtils-Embed libevent-devel libtool pandoc"
      yum -y install ${INSTALL_LIST}
      yum -y install lz4 || true

    else
      apt-get update || true
      export ARCH=$(echo $(uname -m) | sed -e 's:i686:i386:g')
      apt-get -y install lsb-release wget curl gnupg2
      export DEBIAN=$(lsb_release -sc)
      add_percona_apt_repo
      apt-get update || true
      INSTALL_LIST="build-essential pkg-config liblz4-dev debconf debhelper devscripts dh-exec git wget libxml-checker-perl libxml-libxml-perl libio-socket-ssl-perl libperl-dev libssl-dev libxml2-dev txt2man zlib1g-dev libpq-dev percona-postgresql-common libbz2-dev libzstd-dev libevent-dev libssl-dev libc-ares-dev pandoc pkg-config"
      until DEBIAN_FRONTEND=noninteractive apt-get -y --allow-unauthenticated install ${INSTALL_LIST}; do
        sleep 1
        echo "waiting"
      done
      DEBIAN_FRONTEND=noninteractive apt-get -y --allow-unauthenticated install libpam0g-dev || DEBIAN_FRONTEND=noninteractive apt-get -y --allow-unauthenticated install libpam-dev
    fi
fi

# pgbadger
if [ "$COMPONENT" = "pgbadger" ]; then
  if [ "x$OS" = "xrpm" ]; then
      RHEL=$(rpm --eval %rhel)
      if [ x"$RHEL" = x8 ]; then
        switch_to_vault_repo || true
      fi
      yum -y install wget
      add_percona_yum_repo
      yum clean all
      if [[ "${RHEL}" -eq 10 ]]; then
          yum install oracle-epel-release-el10
      else
          yum -y install epel-release
      fi

      if [ ${RHEL} -gt 7 ]; then
          dnf -y module disable postgresql || true
          dnf config-manager --set-enabled ol${RHEL}_codeready_builder
          dnf clean all
          rm -r /var/cache/dnf
          dnf -y upgrade
          switch_to_vault_repo || true
          yum -y install perl lz4-libs c-ares-devel
	  yum -y install rpm-build
      else
        until yum -y install centos-release-scl; do
            echo "waiting"
            sleep 1
        done
        yum -y install llvm-toolset-7-clang llvm5.0-devtoolset
        source /opt/rh/devtoolset-7/enable
        source /opt/rh/llvm-toolset-7/enable
      fi
      INSTALL_LIST="pandoc libtool libevent-devel python3-psycopg2 openssl-devel pam-devel git rpm-build rpmdevtools systemd systemd-devel wget libxml2-devel perl perl-DBD-Pg perl-Digest-SHA perl-IO-Socket-SSL perl-JSON-PP zlib-devel gcc make autoconf perl-ExtUtils-Embed which perl-Pod-Markdown"
      yum -y install ${INSTALL_LIST}
      yum -y install lz4 || true

    else
      apt-get update || true
      apt-get -y install gnupg2 lsb-release wget curl
      export DEBIAN=$(lsb_release -sc)
      export ARCH=$(echo $(uname -m) | sed -e 's:i686:i386:g')
      add_percona_apt_repo
      apt-get update || true
      INSTALL_LIST="build-essential pkg-config liblz4-dev debconf debhelper devscripts dh-exec git wget libxml-libxml-perl libcontextual-return-perl libxml-checker-perl libio-socket-ssl-perl libperl-dev libssl-dev libxml2-dev txt2man zlib1g-dev libpq-dev percona-postgresql-common libbz2-dev libzstd-dev libevent-dev libssl-dev libc-ares-dev pandoc pkg-config libjson-xs-perl libpod-markdown-perl"
      until DEBIAN_FRONTEND=noninteractive apt-get -y --allow-unauthenticated install ${INSTALL_LIST}; do
        sleep 1
        echo "waiting"
      done
      DEBIAN_FRONTEND=noninteractive apt-get -y --allow-unauthenticated install libpam0g-dev || DEBIAN_FRONTEND=noninteractive apt-get -y --allow-unauthenticated install libpam-dev
    fi
fi

# pgbackrest
if [ "$COMPONENT" = "pgbackrest" ]; then
  if [ "x$OS" = "xrpm" ]; then
      if [ x"$RHEL" = x8 ]; then
          switch_to_vault_repo || true
      fi
      yum -y install wget
      add_percona_yum_repo
      yum clean all
      RHEL=$(rpm --eval %rhel)
      if [[ "${RHEL}" -eq 10 ]]; then
          yum install oracle-epel-release-el10
      else
          yum -y install epel-release
      fi
      if [ ${RHEL} -gt 7 ]; then
          dnf -y module disable postgresql || true
          dnf config-manager --enable ol${RHEL}_codeready_builder
          dnf clean all
          rm -r /var/cache/dnf
          dnf -y upgrade
          yum -y install perl lz4-libs
          yum config-manager --set-enabled powertools || true
          yum -y install libyaml-devel
      else
        until yum -y install centos-release-scl; do
            echo "waiting"
            sleep 1
        done
        yum -y install llvm-toolset-7-clang llvm5.0-devtoolset
        yum -y install libyaml-devel
        source /opt/rh/devtoolset-7/enable
        source /opt/rh/llvm-toolset-7/enable
      fi
      INSTALL_LIST="percona-postgresql${PG_MAJOR}-devel git rpm-build rpmdevtools systemd systemd-devel wget bzip2-devel libxml2-devel openssl-devel perl  perl-DBD-Pg perl-Digest-SHA perl-IO-Socket-SSL perl-JSON-PP zlib-devel gcc make autoconf perl-ExtUtils-Embed libssh-devel libzstd-devel lz4-devel"
      yum -y install ${INSTALL_LIST}
      yum -y install lz4 || true
      yum -y install perl-libxml-perl || true

      yum install meson gcc make git autoconf libtool cmake
      git clone https://github.com/ianlancetaylor/libbacktrace.git
      cd libbacktrace/
          ./configure --prefix=/usr/local
          make
          make install
      cd ../

    else
      export ARCH=$(echo $(uname -m) | sed -e 's:i686:i386:g')
      apt-get update || true
      apt-get -y install gnupg2 wget curl lsb-release

      export DEBIAN=$(lsb_release -sc)
      add_percona_apt_repo
      percona-release enable tools testing
      percona-release enable ppg-${PG_VERSION} testing
      apt-get update || true
      INSTALL_LIST="build-essential pkg-config liblz4-dev debconf debhelper devscripts dh-exec git wget libxml-checker-perl libxml-libxml-perl libio-socket-ssl-perl libperl-dev libssl-dev libxml2-dev txt2man zlib1g-dev libpq-dev percona-postgresql-${PG_MAJOR} percona-postgresql-common percona-postgresql-server-dev-all libbz2-dev libzstd-dev libyaml-dev meson python3-setuptools"
      until DEBIAN_FRONTEND=noninteractive apt-get -y --allow-unauthenticated install ${INSTALL_LIST}; do
        sleep 1
        echo "waiting"
      done
      if [ "x${DEBIAN}" != "xbullseye" ]; then
          DEBIAN_FRONTEND=noninteractive apt-get -y --allow-unauthenticated install dh_systemd
      fi
      if [ "x${DEBIAN}" = "xstretch" ]; then
          wget http://ftp.us.debian.org/debian/pool/main/liby/libyaml-libyaml-perl/libyaml-libyaml-perl_0.76+repack-1~bpo9+1_amd64.deb
          dpkg -i ./libyaml-libyaml-perl_0.76+repack-1~bpo9+1_amd64.deb
      fi
    fi
fi

# pgaudit_set_user
if [ "$COMPONENT" = "pgaudit_set_user" ]; then
  if [ "x$OS" = "xrpm" ]; then
        yum -y install wget
        add_percona_yum_repo
        percona-release enable telemetry testing
        yum clean all
        RHEL=$(rpm --eval %rhel)
        if [[ "${RHEL}" -eq 10 ]]; then
          yum install oracle-epel-release-el10
        else
          yum -y install epel-release
        fi
        if [ x"$RHEL" = x6 -o x"$RHEL" = x7 ]; then
            until yum -y install centos-release-scl; do
                echo "waiting"
                sleep 1
            done
            INSTALL_LIST="bison e2fsprogs-devel flex gettext git glibc-devel krb5-devel libicu-devel libselinux-devel libuuid-devel libxml2-devel libxslt-devel llvm5.0-devel llvm-toolset-7-clang openldap-devel openssl-devel pam-devel patch perl perl-ExtUtils-Embed perl-ExtUtils-MakeMaker python2-devel readline-devel rpmbuild percona-postgresql${PG_MAJOR}-devel percona-postgresql${PG_MAJOR}-server rpm-build rpmdevtools selinux-policy systemd systemd-devel systemtap-sdt-devel tcl-devel vim wget zlib-devel llvm-toolset-7-clang-devel make"
            yum -y install ${INSTALL_LIST}
            source /opt/rh/devtoolset-7/enable
            source /opt/rh/llvm-toolset-7/enable
        else
            dnf config-manager --set-enabled ol${RHEL}_codeready_builder
            dnf module disable postgresql || true

            INSTALL_LIST="clang-devel clang llvm-devel python3-devel perl-generators bison e2fsprogs-devel flex gettext git glibc-devel krb5-devel libicu-devel libselinux-devel libuuid-devel libxml2-devel libxslt-devel openldap-devel openssl-devel pam-devel patch perl perl-ExtUtils-MakeMaker perl-ExtUtils-Embed readline-devel percona-postgresql${PG_MAJOR}-devel percona-postgresql${PG_MAJOR}-server rpm-build rpmdevtools selinux-policy systemd systemd-devel systemtap-sdt-devel tcl-devel vim wget zlib-devel "
            yum -y install ${INSTALL_LIST}
            yum -y install binutils gcc gcc-c++
        fi
    else
        export ARCH=$(echo $(uname -m) | sed -e 's:i686:i386:g')
	apt-get -y update || true
        apt-get -y install lsb-release wget gnupg2 curl
        export DEBIAN=$(lsb_release -sc)
        add_percona_apt_repo
        percona-release enable tools testing
        percona-release enable ppg-${PG_VERSION} testing
        apt-get update || true
        INSTALL_LIST="build-essential dpkg-dev debconf debhelper clang devscripts dh-exec git wget libkrb5-dev libssl-dev percona-postgresql-common percona-postgresql-server-dev-all"
        DEBIAN_FRONTEND=noninteractive apt-get -y --allow-unauthenticated install ${INSTALL_LIST}
    fi
fi

# pgaudit
if [ "$COMPONENT" = "pgaudit" ]; then
  if [ "x$OS" = "xrpm" ]; then
        yum -y install wget
        add_percona_yum_repo
        percona-release enable telemetry testing
        yum clean all
        RHEL=$(rpm --eval %rhel)
        if [[ "${RHEL}" -eq 10 ]]; then
          yum install oracle-epel-release-el10
        else
          yum -y install epel-release
        fi
        if [ x"$RHEL" = x6 -o x"$RHEL" = x7 ]; then
            until yum -y install centos-release-scl; do
                echo "waiting"
                sleep 1
            done
            INSTALL_LIST="bison e2fsprogs-devel flex gettext git glibc-devel krb5-devel libicu-devel libselinux-devel libuuid-devel libxml2-devel libxslt-devel llvm5.0-devel llvm-toolset-7-clang openldap-devel openssl-devel pam-devel patch perl perl-ExtUtils-Embed perl-ExtUtils-MakeMaker python2-devel readline-devel rpmbuild percona-postgresql${PG_MAJOR}-devel percona-postgresql${PG_MAJOR}-server rpm-build rpmdevtools selinux-policy systemd systemd-devel systemtap-sdt-devel tcl-devel vim wget zlib-devel llvm-toolset-7-clang-devel make gcc gcc-c++"
            yum -y install ${INSTALL_LIST}
            source /opt/rh/devtoolset-7/enable
            source /opt/rh/llvm-toolset-7/enable
        else
            if [ x"$RHEL" = x10 ]; then
                yum -y install oracle-epel-release-el10
            else
                yum -y install epel-release
            fi
            dnf module -y disable postgresql || true
            dnf config-manager --set-enabled ol${RHEL}_codeready_builder

            INSTALL_LIST="clang-devel clang llvm-devel python3-devel perl-generators bison e2fsprogs-devel flex gettext git glibc-devel krb5-devel libicu-devel libselinux-devel libuuid-devel libxml2-devel libxslt-devel openldap-devel openssl-devel pam-devel patch perl perl-ExtUtils-MakeMaker perl-ExtUtils-Embed readline-devel percona-postgresql${PG_MAJOR}-devel percona-postgresql${PG_MAJOR}-server rpm-build rpmdevtools selinux-policy systemd systemd-devel systemtap-sdt-devel tcl-devel vim wget zlib-devel "
            yum -y install ${INSTALL_LIST}
            yum -y install binutils gcc gcc-c++
        fi
    else
        apt-get -y update
        apt-get -y install wget lsb-release
        export DEBIAN=$(lsb_release -sc)
        export ARCH=$(echo $(uname -m) | sed -e 's:i686:i386:g')
	apt-get -y update || true
        apt-get -y install gnupg2 curl
        add_percona_apt_repo
        percona-release enable tools testing
        percona-release enable ppg-${PG_VERSION} testing
        apt-get update || true
        INSTALL_LIST="build-essential dpkg-dev debconf debhelper clang devscripts dh-exec git wget libkrb5-dev libssl-dev percona-postgresql-common percona-postgresql-server-dev-all"
        DEBIAN_FRONTEND=noninteractive apt-get -y --allow-unauthenticated install ${INSTALL_LIST}
    fi
fi

# pg_repack
if [ "$COMPONENT" = "pg_repack" ]; then
  if [ "x$OS" = "xrpm" ]; then
      yum -y install wget
      add_percona_yum_repo
      yum clean all
      RHEL=$(rpm --eval %rhel)
      if [[ "${RHEL}" -eq 10 ]]; then
        yum install oracle-epel-release-el10
      else
        yum -y install epel-release
      fi
      if [ x"$RHEL" = x6 -o x"$RHEL" = x7 ]; then
        until yum -y install centos-release-scl; do
            echo "waiting"
            sleep 1
        done
        yum groupinstall -y "Development Tools"
        INSTALL_LIST="percona-postgresql${PG_MAJOR} bison e2fsprogs-devel flex gettext git glibc-devel krb5-devel libicu-devel libselinux-devel libuuid-devel libxml2-devel libxslt-devel llvm5.0-devel llvm-toolset-7-clang openldap-devel openssl-devel pam-devel patch perl perl-ExtUtils-Embed perl-ExtUtils-MakeMaker python2-devel readline-devel rpmbuild percona-postgresql${PG_MAJOR}-devel percona-postgresql${PG_MAJOR}-server  rpm-build rpmdevtools selinux-policy systemd systemd-devel systemtap-sdt-devel tcl-devel vim wget zlib-devel libzstd-devel lz4-devel"
        yum -y install ${INSTALL_LIST}
        source /opt/rh/devtoolset-7/enable
        source /opt/rh/llvm-toolset-7/enable
      else
	dnf module -y disable postgresql || true
	dnf config-manager --enable ol${RHEL}_codeready_builder
        yum install -y libcurl-devel

        if [ x"$RHEL" = x8 ]; then
        	INSTALL_LIST="clang-devel clang llvm-devel percona-postgresql${PG_MAJOR} python3-devel perl-generators bison e2fsprogs-devel flex gettext git glibc-devel krb5-devel libicu-devel libselinux-devel libuuid-devel libxml2-devel libxslt-devel openldap-devel openssl-devel pam-devel patch perl perl-ExtUtils-MakeMaker perl-ExtUtils-Embed readline-devel percona-postgresql${PG_MAJOR}-devel percona-postgresql${PG_MAJOR}-server rpm-build rpmdevtools selinux-policy systemd systemd-devel systemtap-sdt-devel tcl-devel vim wget zlib-devel libzstd-devel lz4-devel"
        	yum -y install ${INSTALL_LIST}
        	yum -y install binutils gcc gcc-c++
	else
		yum -y install percona-postgresql${PG_MAJOR}-devel
		yum -y install zlib-devel libzstd-devel readline-devel lz4-devel clang rpmdevtools git openssl-devel openssl-libs lz4-devel
	fi
	if [ x"$RHEL" = x9 ]; then
		yum -y install gcc-toolset-14
	fi
      fi
    else
      apt-get update
      apt-get -y install wget gnupg2 lsb-release curl
      export DEBIAN=$(lsb_release -sc)
      export ARCH=$(echo $(uname -m) | sed -e 's:i686:i386:g')
      add_percona_apt_repo
      percona-release enable tools testing
      apt-get update || true
      INSTALL_LIST="dpkg-dev build-essential percona-postgresql-${PG_MAJOR} debconf debhelper devscripts dh-exec git wget libkrb5-dev libssl-dev percona-postgresql-common percona-postgresql-server-dev-all"
      DEBIAN_FRONTEND=noninteractive apt-get -y --allow-unauthenticated install ${INSTALL_LIST}
    fi
fi

# pg_gather
if [ "$COMPONENT" = "pg_gather" ]; then
  if [ "x$OS" = "xrpm" ]; then
      yum -y install wget
      #mv -f percona-dev.repo /etc/yum.repos.d/
      yum clean all
      RHEL=$(rpm --eval %rhel)
      if [ x"$RHEL" = x6 -o x"$RHEL" = x7 ]; then
        until yum -y install centos-release-scl; do
            echo "waiting"
            sleep 1
        done
      fi
      if [[ "${RHEL}" -eq 10 ]]; then
        INSTALL_LIST="git rpm-build rpmdevtools wget"
      else
        INSTALL_LIST="git rpm-build rpmdevtools wget rpmlint"
      fi
      yum -y install ${INSTALL_LIST}
    else
      apt-get update || true
      apt-get -y install wget lsb-release
      export DEBIAN=$(lsb_release -sc)
      export ARCH=$(echo $(uname -m) | sed -e 's:i686:i386:g')
      apt-get -y install gnupg2
      apt-get update || true
      INSTALL_LIST="debconf debhelper devscripts dh-exec git"
      DEBIAN_FRONTEND=noninteractive apt-get -y --allow-unauthenticated install ${INSTALL_LIST}
    fi
fi

# pg_cron
if [ "$COMPONENT" = "pg_cron" ]; then
  if [ "x$OS" = "xrpm" ]; then
        yum -y install wget
        add_percona_yum_repo
        yum clean all
        RHEL=$(rpm --eval %rhel)
        if [[ "${RHEL}" -eq 10 ]]; then
            yum install oracle-epel-release-el10
        else
            yum -y install epel-release
        fi
        if [ x"$RHEL" = x6 -o x"$RHEL" = x7 ]; then
            until yum -y install centos-release-scl; do
                echo "waiting"
                sleep 1
            done
            INSTALL_LIST="bison e2fsprogs-devel flex gettext git glibc-devel krb5-devel libicu-devel libselinux-devel libuuid-devel libxml2-devel libxslt-devel llvm5.0-devel llvm-toolset-7-clang openldap-devel openssl-devel pam-devel patch perl perl-ExtUtils-Embed perl-ExtUtils-MakeMaker python2-devel readline-devel rpmbuild percona-postgresql${PG_MAJOR}-devel percona-postgresql${PG_MAJOR}-server rpm-build rpmdevtools selinux-policy systemd systemd-devel systemtap-sdt-devel tcl-devel vim wget zlib-devel llvm-toolset-7-clang-devel make gcc gcc-c++"
            yum -y install ${INSTALL_LIST}
            source /opt/rh/devtoolset-7/enable
            source /opt/rh/llvm-toolset-7/enable
        else
            dnf module -y disable postgresql || true
            dnf config-manager --set-enabled ol${RHEL}_codeready_builder

            INSTALL_LIST="clang-devel clang llvm-devel python3-devel perl-generators bison e2fsprogs-devel flex gettext git glibc-devel krb5-devel libicu-devel libselinux-devel libuuid-devel libxml2-devel libxslt-devel openldap-devel openssl-devel pam-devel patch perl perl-ExtUtils-MakeMaker perl-ExtUtils-Embed readline-devel percona-postgresql${PG_MAJOR}-devel percona-postgresql${PG_MAJOR}-server rpm-build rpmdevtools selinux-policy systemd systemd-devel systemtap-sdt-devel tcl-devel vim wget zlib-devel "
            yum -y install ${INSTALL_LIST}
            yum -y install binutils gcc gcc-c++
        fi
    else
        apt-get -y update
        apt-get -y install wget lsb-release
        export DEBIAN=$(lsb_release -sc)
        export ARCH=$(echo $(uname -m) | sed -e 's:i686:i386:g')
	apt-get -y update || true
        apt-get -y install gnupg2 curl
        add_percona_apt_repo
        percona-release enable tools testing
        percona-release enable ppg-${PG_VERSION} testing
        apt-get update || true
        INSTALL_LIST="build-essential dpkg-dev debconf debhelper clang devscripts dh-exec git wget libkrb5-dev libssl-dev percona-postgresql-common percona-postgresql-server-dev-all"
        DEBIAN_FRONTEND=noninteractive apt-get -y --allow-unauthenticated install ${INSTALL_LIST}
    fi
fi

# patroni
if [ "$COMPONENT" = "patroni" ]; then
  if [ "x$OS" = "xrpm" ]; then
      if [ x"$RHEL" = x8 ]; then
          switch_to_vault_repo || true
      fi
      yum -y install wget
      add_percona_yum_repo
      yum clean all
      if [[ "${RHEL}" -eq 10 ]]; then
        yum install oracle-epel-release-el10
      else
        yum -y install epel-release
      fi
      RHEL=$(rpm --eval %rhel)
      if [ ${RHEL} -gt 7 ]; then
          yum config-manager --set-enabled PowerTools || yum config-manager --set-enabled powertools || true
      fi
      if [ ${RHEL} = 7 ]; then
          INSTALL_LIST="git wget rpm-build python36-virtualenv libyaml-devel gcc python36-psycopg2 python36-six"
          yum -y install ${INSTALL_LIST}
      else
          dnf config-manager --set-enabled ol${RHEL}_codeready_builder
          dnf clean all
          rm -r /var/cache/dnf
          dnf -y upgrade
          INSTALL_LIST="git wget rpm-build python3-virtualenv python3-setuptools libyaml-devel gcc python3-psycopg2"
          yum -y install ${INSTALL_LIST}
	      #ln -s /usr/bin/virtualenv-2 /usr/bin/virtualenv
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
      add_percona_apt_repo
      apt-get update || true
      INSTALL_LIST="build-essential debconf debhelper clang devscripts dh-exec git wget fakeroot devscripts python3-psycopg2 libyaml-dev python3-virtualenv python3-psycopg2 ruby ruby-dev rubygems curl golang libjs-mathjax pyflakes3  python3-dateutil python3-dnspython python3-etcd  python3-flake8 python3-kazoo python3-mccabe python3-mock python3-prettytable python3-psutil python3-pycodestyle python3-pytest python3-pytest-cov python3-setuptools python3-pip python3-sphinx python3-sphinx-rtd-theme python3-tz python3-tzlocal sphinx-common python3-click python3-doc python3-cdiff dh-python "
      if [ "x${DEBIAN}" = "xtrixie" ]; then
        INSTALL_LIST+="python3-dev dh-virtualenv python3-boto3"  
      elif [ "x${DEBIAN}" != "xfocal" -a "x${DEBIAN}" != "xbullseye" -a "x${DEBIAN}" != "xjammy" -a "x${DEBIAN}" != "xbookworm" -a "x${DEBIAN}" != "xnoble" -a "x${DEBIAN}" != "xtrixie" ]; then
        INSTALL_LIST+="python-setuptools python-dev dh-virtualenv python3-boto"
      else
        INSTALL_LIST+="python3-dev python3-boto"
      fi
      DEBIAN_FRONTEND=noninteractive apt-get -y install ${INSTALL_LIST}
      if [ "x${DEBIAN}" = "xstretch" ]; then
        DEBIAN_FRONTEND=noninteractive apt-get -y install python3-pip
	pip3 install python-consul
	pip3 install python-kubernetes 
      else 
        DEBIAN_FRONTEND=noninteractive apt-get -y install python3-consul python3-kubernetes python3-cdiff || true
        if [ "x${DEBIAN}" = "xbookworm" -o "x${DEBIAN}" = "xnoble" -o "x${DEBIAN}" = "xtrixie" ]; then
          apt-get install -y python3-sphinxcontrib.apidoc
          apt-get install -y python3-pysyncobj
          apt-get install -y python3-boto3
        elif [ "x${DEBIAN}" = "xjammy" -o "x${DEBIAN}" = "xbuster" -o "x${DEBIAN}" = "xbullseye" ]; then
          pip3 install --upgrade sphinx sphinx-rtd-theme
          pip3 install sphinxcontrib.apidoc
          pip3 install pysyncobj
          pip3 install boto3
        fi
      fi
      if [ "x${DEBIAN}" = "xfocal" ]; then
        wget https://bootstrap.pypa.io/get-pip.py
        python2.7 get-pip.py
        rm -rf /usr/bin/python2
        ln -s /usr/bin/python2.7 /usr/bin/python2
        pip install --upgrade sphinx sphinx-rtd-theme
        pip install sphinxcontrib.apidoc
        pip install pysyncobj
        pip install boto3
      fi
    fi
fi

# etcd
if [ "$COMPONENT" = "etcd" ]; then
  if [ "x$OS" = "xrpm" ]; then
      RHEL=$(rpm --eval %rhel)
      #add_percona_yum_repo
      yum clean all
      if [[ "${RHEL}" -eq 10 ]]; then
        yum install oracle-epel-release-el10
      else
        yum -y install epel-release
      fi
      if [ ${RHEL} -gt 7 ]; then
          #dnf -y module disable postgresql
          dnf config-manager --set-enabled ol${RHEL}_codeready_builder
          dnf clean all
          rm -r /var/cache/dnf
          dnf -y upgrade
      fi
      INSTALL_LIST="git vim wget go-toolset rpmdevtools python3-devel"
      yum -y install ${INSTALL_LIST}

    else
      apt-get update || true
      export ARCH=$(echo $(uname -m) | sed -e 's:i686:i386:g')
      apt-get -y install lsb-release wget curl gnupg2
      export DEBIAN=$(lsb_release -sc)
      add_percona_apt_repo
      apt-get update || true
      INSTALL_LIST="git vim wget rpm dpkg-dev build-essential ccache cron debconf debhelper devscripts dh-exec curl dh-golang fakeroot golang-go"
      DEBIAN_FRONTEND=noninteractive apt-get -y --allow-unauthenticated install ${INSTALL_LIST}
    fi
fi
