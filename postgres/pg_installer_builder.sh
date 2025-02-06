#!/bin/bash

shell_quote_string() {
  echo "$1" | sed -e 's,\([^a-zA-Z0-9/_.=-]\),\\\1,g'
}

usage () {
    cat <<EOF
Usage: $0 [OPTIONS]
    The following options may be given :
        --version               Tarball version
	--use_system_ssl        Use system SSL or our own prebuilt SSL
	--build_dependencies    Build dependency packages
        --help) usage ;;
Example $0 --version=16.1
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
            --version=*) PG_VERSION="$val" ;;
	    --use_system_ssl=*) USE_SYSTEM_SSL="$val" ;;
	    --build_dependencies=*) BUILD_DEPENDENCIES="$val" ;;
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

parse_arguments PICK-ARGS-FROM-ARGV "$@"

if [ -z "$PG_VERSION" ]; then
    echo "Error: Please specify Postgresql version as <PG MAJOR VERSION>.<PG_MINOR_VERSION>. For example --version=16.1"
    usage
    exit 1
fi

SSL_VERSION=ssl3
export DEPENDENCY_LIBS_PATH=/opt/dependency-libs64
SSL_INSTALL_PATH=${DEPENDENCY_LIBS_PATH}

if [ -n "$USE_SYSTEM_SSL" ]; then

	if [ "$USE_SYSTEM_SSL" = "1" ]; then
		SSL_INSTALL_PATH=/usr
		SSL_VERSION=ssl1.1
	fi
fi

export OPENSSL_VERSION=3.1.7
export ZLIB_VERSION=1.3
export KRB5_VERSION=1.21.3
export KEYUTILS_VERSION=1.6.1
export NCURSES_VERSION=6.5
export LIBEDIT_VERSION=0.3
export LIBUUID_VERSION=1.0.2
#export LIBXML2_VERSION=2.13.5   # Latest version deprecated xmlNanoHTTPCleanup symbol required for SPATIALITE and GDAL
export LIBXML2_VERSION=2.12.9
export LIBXML2_MAJOR_VERSION=$(echo ${LIBXML2_VERSION}|  cut -f1,2 -d'.')
export LIBXSLT_VERSION=1.1.42
export LIBXSLT_MAJOR_VERSION=$(echo ${LIBXSLT_VERSION}|  cut -f1,2 -d'.')
export LIBICONV_VERSION=1.17
export OPENLDAP_VERSION=2.6.6
export CYRUS_SASL_VERSION=2.1.28
export CURL_VERSION=8.5.0
export ICU_VERSION=73-2
export LIBEVENT_VERSION=2.1.12
export LIBMEMCACHED_VERSION=1.0.18
export LIBMEMCACHED_MAJOR_VERSION=$(echo ${LIBMEMCACHED_VERSION} | cut -f1,2 -d'.')
export UUID_VERSION=1.6.2
export LUA_VERSION=5.3.5
export PCRE2_VERSION=10.42
export LIBMD_VERSION=1.1.0
export LIBBSD_VERSION=0.12.2
export MINIZIP_VERSION=2.5.0
export GEOS_VERSION=3.12.1
export LIBTIFF_VERSION=4.6.0
export LIBPROJ_VERSION=9.3.1
export LIBGEOTIFF_VERSION=1.7.3
export LIBPNG_VERSION=1.6.45
export LIBJPEG_VERSION=3.1.0
export LIBQHULL_VERSION=2020.2
export SQLITE_VERSION=3480000
export JSONC_VERSION=0.18
export GDAL_VERSION=3.10.1
export PROTOBUF_VERSION=29.3
export PROTOBUF_C_VERSION=1.5.0
export GMP_VERSION=6.3.0
export MPFR_VERSION=4.2.1
export BOOST_VERSION=1.84.0
export EXPAT_VERSION=2.5.0
export EXPAT_HYPHEN_VERSION=$(echo ${EXPAT_VERSION} | sed -e 's|\.|_|g')
export FREEXL_VERSION=2.0.0
export SPATIALITE_VERSION=5.1.0
export CGAL_VERSION=5.6
export SFCGAL_VERSION=1.5.0
export LIBXCRYPT_VERSION=4.4.36

export PG_MAJOR_VERSION=$(echo ${PG_VERSION} | cut -f1 -d'.')
export PG_MINOR_VERSION=$(echo ${PG_VERSION} | cut -f2 -d'.')


export PGBOUNCER_VERSION=1.23.1
export PGPOOL_VERSION=4.5.4
export HAPROXY_VERSION=2.8
export LIBFFI_VERSION=3.4.2
export PERL_VERSION=5.38.2
export PERL_MAJOR_VERSION=5.0
export PYTHON_VERSION=3.12.3
export TCL_VERSION=8.6.16
export ETCD_VERSION=3.5.16
export POSTGIS_VERSION=3.3.7

export PARENT_DIR="$(dirname "$(readlink -f "$0")")"
export BUILD_STAGING=${PARENT_DIR}/pg_staging/linux-x64
export POSTGRESQL_PREFIX=${BUILD_STAGING}/server
export PGBOUNCER_PREFIX=${BUILD_STAGING}/percona-pgbouncer
export PGPOOL_PREFIX=${BUILD_STAGING}/percona-pgpool-II
export PGBACKREST_PREFIX=${BUILD_STAGING}/percona-pgbackrest
export PGBADGER_PREFIX=${BUILD_STAGING}/percona-pgbadger
export PATRONI_PREFIX=${BUILD_STAGING}/percona-patroni
export HAPROXY_PREFIX=${BUILD_STAGING}/percona-haproxy
export PYTHON_PREFIX=/opt/Percona/percona-languages/percona-python3
export PERL_PREFIX=/opt/Percona/percona-languages/percona-perl
export TCL_PREFIX=/opt/Percona/percona-languages/percona-tcl
export ETCD_PREFIX=${BUILD_STAGING}/percona-etcd
export PATH=${DEPENDENCY_LIBS_PATH}/bin:${PYTHON_PREFIX}/bin:${PERL_PREFIX}/bin:${TCL_PREFIX}/bin:$PATH

export PG_SOURCE_DIR=/source
export LANGUAGES_DIR=pg_staging/linux-x64
export PG_STAGING_DIR=pg_staging/linux-x64/server
export PG_BUILD_NUMBER=1
export PG_PACKAGE_VERSION=$PG_VERSION-$PG_BUILD_NUMBER

export INSTALLBUILDER_VERSION=24.11.1
export PG_INSTALLBUILDER_BIN=/opt/installbuilder/bin

CWD=$(pwd)

if (( ${PG_MAJOR_VERSION} > 16 )); then
	PG_SERVER_BRANCH=TDE_REL_${PG_MAJOR_VERSION}_STABLE
fi

PGAUDIT_BRANCH=REL_${PG_MAJOR_VERSION}_STABLE

if [ "${PGAUDIT_BRANCH}" = "REL_12_STABLE" ]; then
    PGAUDIT_BRANCH="1.4.3"
fi

SETUSER_BRANCH="REL4_1_0"
PG_REPACK_BRANCH="ver_1.5.1"
WAL2JSON_BRANCH="wal2json_2_6"
PG_STAT_MONITOR_BRANCH="2.1.0"
PGBACKREST_BRANCH="release/2.54.0"
PGBADGER_BRANCH="v12.4"
PATRONI_BRANCH="v4.0.3"
HAPROXY_BRANCH="v2.8.11"
PGVECTOR_BRANCH="v0.8.0"

create_build_environment(){

	RHEL=$(rpm --eval %rhel)

	sudo yum groupinstall -y "Development Tools"
	sudo yum install -y epel-release
	sudo yum config-manager --enable ol${RHEL}_codeready_builder
	sudo yum install -y vim python3-devel perl tcl-devel pam-devel tcl python3 flex bison wget bzip2-devel chrpath patchelf perl-Pod-Markdown readline-devel cmake sqlite-devel minizip-devel openssl-devel libffi-devel protobuf protobuf-devel
	sudo mkdir -p ${DEPENDENCY_LIBS_PATH}
	sudo chown -R $(whoami):$(id -gn) ${DEPENDENCY_LIBS_PATH}
	sudo mkdir -p /source
	sudo chown -R $(whoami):$(id -gn) /source
	sudo mkdir -p ${PYTHON_PREFIX}
	sudo chown -R $(whoami):$(id -gn) ${PYTHON_PREFIX}
	sudo mkdir -p ${PERL_PREFIX}
	sudo chown -R $(whoami):$(id -gn) ${PERL_PREFIX}
	sudo mkdir -p ${TCL_PREFIX}
	sudo chown -R $(whoami):$(id -gn) ${TCL_PREFIX}

	sudo mkdir -p ${BUILD_STAGING}
	sudo chown -R $(whoami):$(id -gn) ${BUILD_STAGING}
	sudo chown -R $(whoami):$(id -gn) ${PARENT_DIR}/pg_staging

	download_install_builder
}

build_openssl(){

	build_status "start" "openssl" 
	cd /source
	rm -rf openssl-${OPENSSL_VERSION}* || true
	wget https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz
	tar -xvzf openssl-${OPENSSL_VERSION}.tar.gz
	cd openssl-${OPENSSL_VERSION}
	./Configure --prefix=${DEPENDENCY_LIBS_PATH} --openssldir=${DEPENDENCY_LIBS_PATH} '-Wl,--enable-new-dtags,-rpath,$(LIBRPATH)'
	make
	make install
	build_status "ends" "openssl"
}

build_zlib(){

	build_status "start" "zlib"
	cd /source
	rm -rf zlib-${ZLIB_VERSION}*
	wget https://github.com/madler/zlib/releases/download/v${ZLIB_VERSION}/zlib-${ZLIB_VERSION}.tar.gz
	tar -xvzf zlib-${ZLIB_VERSION}.tar.gz
	cd zlib-${ZLIB_VERSION}
	./configure --prefix=${DEPENDENCY_LIBS_PATH}
	make
	make install
	build_status "ends" "zlib"
}

build_krb5(){

	build_status "start" "krb5"
	cd /source
	rm -rf krb5-${KRB5_VERSION}*
	wget https://fossies.org/linux/misc/krb5-${KRB5_VERSION}.tar.gz
	tar -xvzf krb5-${KRB5_VERSION}.tar.gz
	cd krb5-${KRB5_VERSION}/src
	./configure --prefix=${DEPENDENCY_LIBS_PATH}
	make
	make install
	build_status "ends" "krb5"
}

build_keyutils(){

	build_status "start" "keyutils"
        cd /source
        wget --no-check-certificate https://people.redhat.com/~dhowells/keyutils/keyutils-${KEYUTILS_VERSION}.tar.bz2
        tar -xvf keyutils-${KEYUTILS_VERSION}.tar.bz2
        cd keyutils-${KEYUTILS_VERSION}
        #./configure --prefix=${DEPENDENCY_LIBS_PATH}
        make
        make NO_ARLIB=1 LIBDIR=${DEPENDENCY_LIBS_PATH}/lib BINDIR=${DEPENDENCY_LIBS_PATH}/bin SBINDIR=${DEPENDENCY_LIBS_PATH}/sbin install
	build_status "ends" "keyutils"
}

build_ncurses(){

	build_status "start" "ncurses"
	cd /source
	rm -rf ncurses-${NCURSES_VERSION}*
	wget https://fossies.org/linux/misc/ncurses-${NCURSES_VERSION}.tar.gz
	tar -xvzf ncurses-${NCURSES_VERSION}.tar.gz
	cd ncurses-${NCURSES_VERSION}
	./configure --prefix=${DEPENDENCY_LIBS_PATH} --with-shared --disable-static
	make
	make install
	build_status "ends" "ncurses"
}

build_libedit(){

	build_status "start" "libedit"
	cd /source
	rm -rf libedit*
	wget "https://osdn.net/frs/g_redir.php?m=jaist&f=libedit%2Flibedit%2Flibedit-${LIBEDIT_VERSION}%2Flibedit-${LIBEDIT_VERSION}.tar.gz" -O libedit-${LIBEDIT_VERSION}.tar.gz
	tar -xvzf libedit-${LIBEDIT_VERSION}.tar.gz
	cd libedit
	./configure --prefix=${DEPENDENCY_LIBS_PATH} --enable-shared=yes --enable-ssl=${SSL_INSTALL_PATH} --includedir=${DEPENDENCY_LIBS_PATH}/include
	#vim Makefile              # Add -fPIC
	sed -i "s|CFLAGS=-g -O2|CFLAGS=-g -O2 -fPIC -I${DEPENDENCY_LIBS_PATH}/include -I${DEPENDENCY_LIBS_PATH}/include/ncurses|g" Makefile
	sed -i 's|-ltermcap|-lncurses|g' Makefile
	make
	make install
	build_status "ends" "libedit"
}

build_libuuid(){

	build_status "start" "libuuid"
	cd /source
	wget https://sourceforge.net/projects/libuuid/files/libuuid-${LIBUUID_VERSION}.tar.gz/download -O libuuid-${LIBUUID_VERSION}.tar.gz
	tar -xvzf libuuid-${LIBUUID_VERSION}.tar.gz
	cd libuuid-${LIBUUID_VERSION}
	./configure --prefix=${DEPENDENCY_LIBS_PATH} --enable-shared=yes
	make
	make install
	build_status "ends" "libuuid"
}

build_libxml2(){

	build_status "start" "libxml2"
	cd /source
	wget https://download.gnome.org/sources/libxml2/${LIBXML2_MAJOR_VERSION}/libxml2-${LIBXML2_VERSION}.tar.xz
	tar -Jxvf libxml2-${LIBXML2_VERSION}.tar.xz
	#wget https://download.gnome.org/sources/libxml2/${LIBXML2_MAJOR_VERSION}/libxml2-${LIBXML2_VERSION}.tar.gz
	#tar -xvzf libxml2-${LIBXML2_VERSION}.tar.gz
	cd libxml2-${LIBXML2_VERSION}
	#sed -z -i 's/xmlXPathObjectPtr\s*\n\s*load_xpath_expr/static xmlXPathObjectPtr load_xpath_expr/' testC14N.c
	#sed -i "s|void print_xpath_nodes(xmlNodeSetPtr nodes);|static void print_xpath_nodes(xmlNodeSetPtr nodes);|g" testC14N.c
	#sed -i "s|xmlChar \*\*parse_list(xmlChar \*str);|static xmlChar \*\*parse_list(xmlChar \*str);|g" testC14N.c

	#vim configure.ac           # Correct version to 1.16.1 for RHEL8 and 1.13.4 for RHEL7
	sed -i 's|1.16.3|1.16.1|g' configure.ac
	./autogen.sh 
	./configure --prefix=${DEPENDENCY_LIBS_PATH} --enable-shared=yes
	make
	make install
	build_status "ends" "libxml2"
}

build_libxslt(){

	build_status "start" "libxslt"
	cd /source
	wget https://download.gnome.org/sources/libxslt/${LIBXSLT_MAJOR_VERSION}/libxslt-${LIBXSLT_VERSION}.tar.xz
	tar -Jxvf libxslt-${LIBXSLT_VERSION}.tar.xz
	cd libxslt-${LIBXSLT_VERSION}
	sed -i 's|1.16.3|1.16.1|g' configure.ac
	#./autogen.sh --prefix=${DEPENDENCY_LIBS_PATH} --with-libxml-prefix=${DEPENDENCY_LIBS_PATH}
	./configure --prefix=${DEPENDENCY_LIBS_PATH} --with-libxml-prefix=${DEPENDENCY_LIBS_PATH}
	make
	make install
	build_status "ends" "libxslt"
}

build_libiconv(){

	build_status "start" "libiconv"
	cd /source
	wget https://mirror.freedif.org/GNU/libiconv/libiconv-${LIBICONV_VERSION}.tar.gz
	tar -xvzf libiconv-${LIBICONV_VERSION}.tar.gz
	cd libiconv-${LIBICONV_VERSION}
	./configure --prefix=${DEPENDENCY_LIBS_PATH}
	make
	make install
	build_status "ends" "libiconv"
}

build_ldap(){

	build_status "start" "libldap"
	cd /source
	wget https://www.openldap.org/software/download/OpenLDAP/openldap-release/openldap-${OPENLDAP_VERSION}.tgz
	tar -xvzf openldap-${OPENLDAP_VERSION}.tgz
	cd openldap-${OPENLDAP_VERSION}

	if [ "$USE_SYSTEM_SSL" != "1" ]; then
		./configure --prefix=${DEPENDENCY_LIBS_PATH} \
			CPPFLAGS="-I${DEPENDENCY_LIBS_PATH}/include" \
			LDFLAGS="-L${DEPENDENCY_LIBS_PATH}/lib64 -L${DEPENDENCY_LIBS_PATH}/lib -L/usr/local/lib -Wl,-rpath,/usr/local/lib"
	else
		./configure --prefix=${DEPENDENCY_LIBS_PATH} \
			CPPFLAGS="-I/usr/local/include -I${DEPENDENCY_LIBS_PATH}/include" \
			LDFLAGS="-L/usr/local/lib -Wl,-rpath,/usr/local/lib"
	fi

	make
	make install
	build_status "ends" "libldap"
}

build_cyrus_sasl(){

	build_status "start" "cyrus_sasl"
	cd /source
	wget https://github.com/cyrusimap/cyrus-sasl/releases/download/cyrus-sasl-${CYRUS_SASL_VERSION}/cyrus-sasl-${CYRUS_SASL_VERSION}.tar.gz
	tar -xvzf cyrus-sasl-${CYRUS_SASL_VERSION}.tar.gz
	cd cyrus-sasl-${CYRUS_SASL_VERSION}
	LD_LIBRARY_PATH=${DEPENDENCY_LIBS_PATH}/lib64:${DEPENDENCY_LIBS_PATH}/lib:$LD_LIBRARY_PATH ./configure --prefix=${DEPENDENCY_LIBS_PATH}
	LD_LIBRARY_PATH=${DEPENDENCY_LIBS_PATH}/lib64:${DEPENDENCY_LIBS_PATH}/lib:$LD_LIBRARY_PATH make
	LD_LIBRARY_PATH=${DEPENDENCY_LIBS_PATH}/lib64:${DEPENDENCY_LIBS_PATH}/lib:$LD_LIBRARY_PATH make install
	build_status "ends" "cyrus_sasl"
}

build_curl(){

	build_status "start" "curl"
	cd /source
	wget https://curl.se/download/curl-${CURL_VERSION}.tar.gz
	tar -xvzf curl-${CURL_VERSION}.tar.gz
	cd curl-${CURL_VERSION}
	LD_LIBRARY_PATH=${DEPENDENCY_LIBS_PATH}/lib64:${DEPENDENCY_LIBS_PATH}/lib:$LD_LIBRARY_PATH ./configure --prefix=${DEPENDENCY_LIBS_PATH} --with-ssl=${SSL_INSTALL_PATH} --with-zlib=${DEPENDENCY_LIBS_PATH}
	LD_LIBRARY_PATH=${DEPENDENCY_LIBS_PATH}/lib64:${DEPENDENCY_LIBS_PATH}/lib:$LD_LIBRARY_PATH make
	make install
	build_status "ends" "curl"
}

build_icu(){

	build_status "start" "icu"
	cd /source
	wget https://github.com/unicode-org/icu/archive/refs/tags/release-${ICU_VERSION}.tar.gz -O icu-release-${ICU_VERSION}.tar.gz
	tar -xvzf icu-release-${ICU_VERSION}.tar.gz 
	cd icu-release-${ICU_VERSION}/icu4c/source/
	./configure --prefix=${DEPENDENCY_LIBS_PATH} --enable-rpath
	make
	make install
	build_status "ends" "icu"
}

build_libevent(){

	build_status "start" "libevent"
	cd /source
        wget https://github.com/libevent/libevent/releases/download/release-${LIBEVENT_VERSION}-stable/libevent-${LIBEVENT_VERSION}-stable.tar.gz
        tar -xvzf libevent-${LIBEVENT_VERSION}-stable.tar.gz
        cd libevent-${LIBEVENT_VERSION}-stable
        PKG_CONFIG_PATH=${DEPENDENCY_LIBS_PATH}/lib64/pkgconfig ./configure --prefix=${DEPENDENCY_LIBS_PATH}
        make
        make install
	build_status "ends" "libevent"
}

build_libmemcached(){

	build_status "start" "libmemcached"
        cd /source
	wget https://launchpad.net/libmemcached/${LIBMEMCACHED_MAJOR_VERSION}/${LIBMEMCACHED_VERSION}/+download/libmemcached-${LIBMEMCACHED_VERSION}.tar.gz
        tar -xvzf libmemcached-${LIBMEMCACHED_VERSION}.tar.gz
        cd libmemcached-${LIBMEMCACHED_VERSION}
	sed -i 's|if (opt_servers == false)|if (opt_servers == NULL)|g' clients/memflush.cc
	./configure --prefix=${DEPENDENCY_LIBS_PATH}
        make
        make install
	build_status "ends" "libmemcached"
}

build_uuid(){

	build_status "start" "uuid"
	# uuid_export symbol is part of this package and it is required for PG
        cd /source
	wget https://src.fedoraproject.org/repo/pkgs/uuid/uuid-${UUID_VERSION}.tar.gz/5db0d43a9022a6ebbbc25337ae28942f/uuid-${UUID_VERSION}.tar.gz
        tar -xvzf uuid-${UUID_VERSION}.tar.gz
        cd uuid-${UUID_VERSION}

	ARCH=$(uname -m)

	BUILD_TYPE=""

	if [ "$ARCH" = "aarch64" ]; then
		BUILD_TYPE="--build=aarch64-unknown-linux-gnu"
	fi

	./configure --prefix=${DEPENDENCY_LIBS_PATH} ${BUILD_TYPE}
        make
        make install
	build_status "ends" "uuid"
}

build_libyaml(){

	build_status "start" "libyaml"
        mkdir -p /source
        cd /source
        git clone https://github.com/yaml/libyaml.git
        cd libyaml
        ./bootstrap
        ./configure --prefix=${DEPENDENCY_LIBS_PATH}
        make
        make install
	build_status "ends" "libyaml"
}

build_libmd(){

        build_status "start" "libmd"
        cd /source
       
        wget https://libbsd.freedesktop.org/releases/libmd-${LIBMD_VERSION}.tar.xz
	tar -xvf libmd-${LIBMD_VERSION}.tar.xz
	cd libmd-${LIBMD_VERSION}
	./configure --prefix=${DEPENDENCY_LIBS_PATH}
        make
	make install
        build_status "ends" "libmd"
}

build_libbsd(){

        build_status "start" "libbsd"
        cd /source
	wget https://libbsd.freedesktop.org/releases/libbsd-${LIBBSD_VERSION}.tar.xz
        tar -xf libbsd-${LIBBSD_VERSION}.tar.xz 
        cd libbsd-${LIBBSD_VERSION}

        LD_LIBRARY_PATH=${DEPENDENCY_LIBS_PATH}/lib64:${DEPENDENCY_LIBS_PATH}/lib:$LD_LIBRARY_PATH ./configure --prefix=${DEPENDENCY_LIBS_PATH} --enable-shared --disable-static LDFLAGS="-L${DEPENDENCY_LIBS_PATH}/lib -lmd" CPPFLAGS="-I${DEPENDENCY_LIBS_PATH}/include"
        LD_LIBRARY_PATH=${DEPENDENCY_LIBS_PATH}/lib64:${DEPENDENCY_LIBS_PATH}/lib:$LD_LIBRARY_PATH make
        LD_LIBRARY_PATH=${DEPENDENCY_LIBS_PATH}/lib64:${DEPENDENCY_LIBS_PATH}/lib:$LD_LIBRARY_PATH make install

	rm -f ${DEPENDENCY_LIBS_PATH}/lib/libbsd.so
	ln -s ${DEPENDENCY_LIBS_PATH}/lib/libbsd.so.0 ${DEPENDENCY_LIBS_PATH}/lib/libbsd.so

	build_status "ends" "libbsd"
}

build_minizip(){

        build_status "start" "minizip"
        mkdir -p /source
        cd /source
        wget https://github.com/nmoinvaz/minizip/archive/refs/tags/${MINIZIP_VERSION}.tar.gz -O minizip-${MINIZIP_VERSION}.tar.gz

        tar -xvzf minizip-${MINIZIP_VERSION}.tar.gz
        cd minizip-ng-${MINIZIP_VERSION}
        mkdir build
        cd build/
        LD_LIBRARY_PATH=${DEPENDENCY_LIBS_PATH}/lib64:${DEPENDENCY_LIBS_PATH}/lib:$LD_LIBRARY_PATH cmake -DCMAKE_INSTALL_PREFIX=${DEPENDENCY_LIBS_PATH} -DBUILD_SHARED_LIBS=ON -DCMAKE_C_FLAGS="-L${DEPENDENCY_LIBS_PATH}/lib -lbsd" -DCMAKE_INSTALL_RPATH="${DEPENDENCY_LIBS_PATH}/lib64" ..
       	LD_LIBRARY_PATH=${DEPENDENCY_LIBS_PATH}/lib64:${DEPENDENCY_LIBS_PATH}/lib:$LD_LIBRARY_PATH cmake --build .
        LD_LIBRARY_PATH=${DEPENDENCY_LIBS_PATH}/lib64:${DEPENDENCY_LIBS_PATH}/lib:$LD_LIBRARY_PATH cmake --build . --target install

        build_status "ends" "minizip"
}

build_geos(){

	build_status "start" "geos"
	mkdir -p /source
        cd /source/
        wget https://download.osgeo.org/geos/geos-${GEOS_VERSION}.tar.bz2
        tar -xvf geos-${GEOS_VERSION}.tar.bz2
        cd geos-${GEOS_VERSION}
        mkdir _build
        cmake \
                -DCMAKE_BUILD_TYPE=Release \
		-DBUILD_SHARED_LIBS=ON \
                -DCMAKE_INSTALL_PREFIX=${DEPENDENCY_LIBS_PATH}
        make
        make install
	build_status "ends" "geos"
}

build_libtiff(){

	build_status "start" "libtiff"
	mkdir -p /source
        cd /source
        wget https://gitlab.com/libtiff/libtiff/-/archive/v${LIBTIFF_VERSION}/libtiff-v${LIBTIFF_VERSION}.tar.gz
        wget https://gitlab.com/libtiff/libtiff/-/archive/branch-${LIBTIFF_VERSION}/libtiff-branch-${LIBTIFF_VERSION}.tar.gz
        tar -xvzf libtiff-v${LIBTIFF_VERSION}.tar.gz
        cd libtiff-v${LIBTIFF_VERSION}

        ./autogen.sh
        ./configure --prefix=${DEPENDENCY_LIBS_PATH} --enable-rpath
        make
        make install
	build_status "ends" "libtiff"
}

build_proj(){

	build_status "start" "proj"
        mkdir -p /source
        cd /source
        wget https://download.osgeo.org/proj/proj-${LIBPROJ_VERSION}.tar.gz

        tar -xvzf proj-${LIBPROJ_VERSION}.tar.gz
        cd proj-${LIBPROJ_VERSION}
        mkdir build
        cd build/
        LD_LIBRARY_PATH=${DEPENDENCY_LIBS_PATH}/lib64:${DEPENDENCY_LIBS_PATH}/lib:$LD_LIBRARY_PATH cmake -DCMAKE_INSTALL_PREFIX=${DEPENDENCY_LIBS_PATH} -DCMAKE_INSTALL_RPATH="${DEPENDENCY_LIBS_PATH}/lib64" ..
        LD_LIBRARY_PATH=${DEPENDENCY_LIBS_PATH}/lib64:${DEPENDENCY_LIBS_PATH}/lib:$LD_LIBRARY_PATH cmake --build . 
	LD_LIBRARY_PATH=${DEPENDENCY_LIBS_PATH}/lib64:${DEPENDENCY_LIBS_PATH}/lib:$LD_LIBRARY_PATH cmake --build . --target install

	build_status "ends" "proj"
}

build_libgeotiff(){

	build_status "start" "libgeotiff"
	mkdir -p /source
	cd /source
	wget https://download.osgeo.org/geotiff/libgeotiff/libgeotiff-${LIBGEOTIFF_VERSION}.tar.gz

	tar -xvzf libgeotiff-${LIBGEOTIFF_VERSION}.tar.gz
	cd "libgeotiff-${LIBGEOTIFF_VERSION}"
	mkdir build
	cd build/
	LD_LIBRARY_PATH=${DEPENDENCY_LIBS_PATH}/lib64:${DEPENDENCY_LIBS_PATH}/lib:$LD_LIBRARY_PATH cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=${DEPENDENCY_LIBS_PATH} -DCMAKE_INSTALL_RPATH="${DEPENDENCY_LIBS_PATH}/lib64" ..
	LD_LIBRARY_PATH=${DEPENDENCY_LIBS_PATH}/lib64:${DEPENDENCY_LIBS_PATH}/lib:$LD_LIBRARY_PATH cmake --build .
	LD_LIBRARY_PATH=${DEPENDENCY_LIBS_PATH}/lib64:${DEPENDENCY_LIBS_PATH}/lib:$LD_LIBRARY_PATH cmake --build . --target install

	build_status "ends" "libgeotiff"
}

build_libpng(){

        build_status "start" "libpng"
        mkdir -p /source
        cd /source
        wget https://download.sourceforge.net/libpng/libpng-${LIBPNG_VERSION}.tar.gz

        tar -xvzf libpng-${LIBPNG_VERSION}.tar.gz
        cd "libpng-${LIBPNG_VERSION}"
        mkdir build
        cd build/
        LD_LIBRARY_PATH=${DEPENDENCY_LIBS_PATH}/lib64:${DEPENDENCY_LIBS_PATH}/lib:$LD_LIBRARY_PATH cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=${DEPENDENCY_LIBS_PATH} -DCMAKE_INSTALL_RPATH="${DEPENDENCY_LIBS_PATH}/lib64" ..
        LD_LIBRARY_PATH=${DEPENDENCY_LIBS_PATH}/lib64:${DEPENDENCY_LIBS_PATH}/lib:$LD_LIBRARY_PATH cmake --build .
        LD_LIBRARY_PATH=${DEPENDENCY_LIBS_PATH}/lib64:${DEPENDENCY_LIBS_PATH}/lib:$LD_LIBRARY_PATH cmake --build . --target install

        build_status "ends" "libpng"
}

build_libjpeg(){

        build_status "start" "libjpeg"
        mkdir -p /source
        cd /source
        wget https://github.com/libjpeg-turbo/libjpeg-turbo/archive/refs/tags/${LIBJPEG_VERSION}.tar.gz -O "libjpeg-turbo-${LIBJPEG_VERSION}.tar.gz"

        tar -xvzf libjpeg-turbo-${LIBJPEG_VERSION}.tar.gz
        cd "libjpeg-turbo-${LIBJPEG_VERSION}"
        mkdir build
        cd build/
        LD_LIBRARY_PATH=${DEPENDENCY_LIBS_PATH}/lib64:${DEPENDENCY_LIBS_PATH}/lib:$LD_LIBRARY_PATH cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=${DEPENDENCY_LIBS_PATH} -DCMAKE_INSTALL_RPATH="${DEPENDENCY_LIBS_PATH}/lib64" ..
        LD_LIBRARY_PATH=${DEPENDENCY_LIBS_PATH}/lib64:${DEPENDENCY_LIBS_PATH}/lib:$LD_LIBRARY_PATH cmake --build .
        LD_LIBRARY_PATH=${DEPENDENCY_LIBS_PATH}/lib64:${DEPENDENCY_LIBS_PATH}/lib:$LD_LIBRARY_PATH cmake --build . --target install

        build_status "ends" "libjpeg"
}

build_libqhull(){

        build_status "start" "libqhull"
        mkdir -p /source
        cd /source
        wget https://github.com/qhull/qhull/archive/refs/tags/${LIBQHULL_VERSION}.tar.gz -O "qhull-${LIBQHULL_VERSION}.tar.gz"

        tar -xvzf qhull-${LIBQHULL_VERSION}.tar.gz
        cd "qhull-${LIBQHULL_VERSION}"
        mkdir build
        cd build/
        LD_LIBRARY_PATH=${DEPENDENCY_LIBS_PATH}/lib64:${DEPENDENCY_LIBS_PATH}/lib:$LD_LIBRARY_PATH cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=${DEPENDENCY_LIBS_PATH} -DCMAKE_INSTALL_RPATH="${DEPENDENCY_LIBS_PATH}/lib64" ..
        LD_LIBRARY_PATH=${DEPENDENCY_LIBS_PATH}/lib64:${DEPENDENCY_LIBS_PATH}/lib:$LD_LIBRARY_PATH cmake --build .
        LD_LIBRARY_PATH=${DEPENDENCY_LIBS_PATH}/lib64:${DEPENDENCY_LIBS_PATH}/lib:$LD_LIBRARY_PATH cmake --build . --target install

        build_status "ends" "libqhull"
}

build_sqlite(){

        build_status "start" "sqlite"
        cd /source
        rm -rf sqlite-autoconf-${SQLITE_VERSION}*
	wget https://sqlite.org/2025/sqlite-autoconf-${SQLITE_VERSION}.tar.gz
	tar -xvzf sqlite-autoconf-${SQLITE_VERSION}.tar.gz
        cd sqlite-autoconf-${SQLITE_VERSION}
        ./configure --prefix=${DEPENDENCY_LIBS_PATH}
        make
        make install
        build_status "ends" "sqlite"
}

build_jsonc(){

        build_status "start" "jsonc"
        mkdir -p /source
        cd /source
        wget https://s3.amazonaws.com/json-c_releases/releases/json-c-${JSONC_VERSION}.tar.gz

        tar -xvzf json-c-${JSONC_VERSION}.tar.gz
        cd "json-c-${JSONC_VERSION}"
        mkdir build
        cd build/
        LD_LIBRARY_PATH=${DEPENDENCY_LIBS_PATH}/lib64:${DEPENDENCY_LIBS_PATH}/lib:$LD_LIBRARY_PATH cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=${DEPENDENCY_LIBS_PATH} -DCMAKE_INSTALL_RPATH="${DEPENDENCY_LIBS_PATH}/lib64" ..
        LD_LIBRARY_PATH=${DEPENDENCY_LIBS_PATH}/lib64:${DEPENDENCY_LIBS_PATH}/lib:$LD_LIBRARY_PATH cmake --build .
        LD_LIBRARY_PATH=${DEPENDENCY_LIBS_PATH}/lib64:${DEPENDENCY_LIBS_PATH}/lib:$LD_LIBRARY_PATH cmake --build . --target install

        build_status "ends" "jsonc"
}

build_gdal(){

	build_status "start" "gdal"
        mkdir -p /source
        cd /source
        wget https://github.com/OSGeo/gdal/releases/download/v${GDAL_VERSION}/gdal-${GDAL_VERSION}.tar.gz
        tar -xvzf gdal-${GDAL_VERSION}.tar.gz
        cd gdal-${GDAL_VERSION}
        mkdir build
        cd build/
	if [ "$USE_SYSTEM_SSL" != "1" ]; then
        	LD_LIBRARY_PATH=${DEPENDENCY_LIBS_PATH}/lib64:${DEPENDENCY_LIBS_PATH}/lib:$LD_LIBRARY_PATH cmake -DCMAKE_INSTALL_PREFIX=${DEPENDENCY_LIBS_PATH} -DCMAKE_INSTALL_RPATH="${DEPENDENCY_LIBS_PATH}/lib64" -DOPENSSL_ROOT_DIR=${DEPENDENCY_LIBS_PATH} -DOPENSSL_LIBRARIES=${DEPENDENCY_LIBS_PATH}/lib64 -DOPENSSL_INCLUDE_DIR=${DEPENDENCY_LIBS_PATH}/include -DSQLite3_LIBRARY=${DEPENDENCY_LIBS_PATH}/lib/libsqlite3.so -DSQLite3_INCLUDE_DIR=${DEPENDENCY_LIBS_PATH}/include -DACCEPT_MISSING_SQLITE3_MUTEX_ALLOC=ON ..
	else
		LD_LIBRARY_PATH=${DEPENDENCY_LIBS_PATH}/lib64:${DEPENDENCY_LIBS_PATH}/lib:$LD_LIBRARY_PATH cmake -DCMAKE_INSTALL_PREFIX=${DEPENDENCY_LIBS_PATH} -DCMAKE_INSTALL_RPATH="${DEPENDENCY_LIBS_PATH}/lib64" -DOPENSSL_ROOT_DIR=/usr -DOPENSSL_LIBRARIES=/usr/lib64 -DSQLite3_LIBRARY=${DEPENDENCY_LIBS_PATH}/lib/libsqlite3.so -DSQLite3_INCLUDE_DIR=${DEPENDENCY_LIBS_PATH}/include -DACCEPT_MISSING_SQLITE3_MUTEX_ALLOC=ON ..
	fi
	LD_LIBRARY_PATH=${DEPENDENCY_LIBS_PATH}/lib64:${DEPENDENCY_LIBS_PATH}/lib:$LD_LIBRARY_PATH cmake --build . 
        LD_LIBRARY_PATH=${DEPENDENCY_LIBS_PATH}/lib64:${DEPENDENCY_LIBS_PATH}/lib:$LD_LIBRARY_PATH cmake --build . --target install

	build_status "ends" "gdal"
}

build_protobuf(){

        build_status "start" "protobuf"
        mkdir -p /source
        cd /source
	wget https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOBUF_VERSION}/protobuf-${PROTOBUF_VERSION}.tar.gz
        tar -xvzf protobuf-${PROTOBUF_VERSION}.tar.gz
        cd protobuf-${PROTOBUF_VERSION}
	mkdir build
        cd build/
        LD_LIBRARY_PATH=${DEPENDENCY_LIBS_PATH}/lib64:${DEPENDENCY_LIBS_PATH}/lib:$LD_LIBRARY_PATH cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=${DEPENDENCY_LIBS_PATH} -DCMAKE_INSTALL_RPATH="${DEPENDENCY_LIBS_PATH}/lib64" ..
        LD_LIBRARY_PATH=${DEPENDENCY_LIBS_PATH}/lib64:${DEPENDENCY_LIBS_PATH}/lib:$LD_LIBRARY_PATH cmake --build .
        LD_LIBRARY_PATH=${DEPENDENCY_LIBS_PATH}/lib64:${DEPENDENCY_LIBS_PATH}/lib:$LD_LIBRARY_PATH cmake --build . --target install

        build_status "ends" "protobuf"
}

build_protobuf_c(){

        build_status "start" "protobuf_c"
        mkdir -p /source
        cd /source
	wget https://github.com/protobuf-c/protobuf-c/releases/download/v${PROTOBUF_C_VERSION}/protobuf-c-${PROTOBUF_C_VERSION}.tar.gz
        tar -xvzf protobuf-c-${PROTOBUF_C_VERSION}.tar.gz
        cd protobuf-c-${PROTOBUF_C_VERSION}
	PATH=${DEPENDENCY_LIBS_PATH}/bin:$PATH ./configure --prefix=${DEPENDENCY_LIBS_PATH}
        make
        make install

        build_status "ends" "protobuf_c"
}

build_gmp(){

	build_status "start" "gmp"
        mkdir -p /source
        cd /source
        wget https://gmplib.org/download/gmp/gmp-${GMP_VERSION}.tar.xz
        tar -Jxvf gmp-${GMP_VERSION}.tar.xz
        cd gmp-${GMP_VERSION}
        ./configure --prefix=${DEPENDENCY_LIBS_PATH}
        make
        make install
	build_status "ends" "gmp"
}

build_mpfr(){

	build_status "start" "mpfr"
        mkdir -p /source
        cd /source
        wget https://www.mpfr.org/mpfr-current/mpfr-${MPFR_VERSION}.tar.xz
        tar -Jxvf mpfr-${MPFR_VERSION}.tar.xz
        cd mpfr-${MPFR_VERSION}
        ./configure --prefix=${DEPENDENCY_LIBS_PATH} --with-gmp=${DEPENDENCY_LIBS_PATH} --enable-shared=yes --enable-static=no
        make
        make install
	build_status "ends" "mpfr"
}

build_libboost(){

    build_status "start" "libboost"
    mkdir -p /source
    cd /source

    # Download Boost
    wget https://github.com/boostorg/boost/releases/download/boost-${BOOST_VERSION}/boost-${BOOST_VERSION}.tar.gz
    tar -xvzf boost-${BOOST_VERSION}.tar.gz
    cd boost-${BOOST_VERSION}

    # Boost build and install using b2 instead of cmake
    ./bootstrap.sh --prefix=${DEPENDENCY_LIBS_PATH}
    ./b2 install --prefix=${DEPENDENCY_LIBS_PATH}

    build_status "ends" "libboost"
}

build_expat(){

	build_status "start" "libexpat"
        mkdir -p /source
        cd /source

        wget https://github.com/libexpat/libexpat/archive/refs/tags/R_${EXPAT_HYPHEN_VERSION}.tar.gz -O libexpat-R_${EXPAT_HYPHEN_VERSION}.tar.gz
        tar -xvzf libexpat-R_${EXPAT_HYPHEN_VERSION}.tar.gz
        cd libexpat-R_${EXPAT_HYPHEN_VERSION}/expat
        cmake \
                -DCMAKE_BUILD_TYPE=Release \
                -DBUILD_SHARED_LIBS=ON \
                -DCMAKE_INSTALL_PREFIX=${DEPENDENCY_LIBS_PATH}
	make
	make install
	build_status "ends" "libexpat"
}

build_freexl(){

	build_status "start" "freexl"
        mkdir -p /source
        cd /source

        wget https://www.gaia-gis.it/gaia-sins/freexl-${FREEXL_VERSION}.tar.gz
        tar -xvzf freexl-${FREEXL_VERSION}.tar.gz
        cd freexl-${FREEXL_VERSION}
	#wget -O config.sub https://git.savannah.gnu.org/cgit/config.git/plain/config.sub
	#wget -O config.guess https://git.savannah.gnu.org/cgit/config.git/plain/config.guess
	#chmod +x config.sub config.guess

        ARCH=$(uname -m)

        if [[ "$ARCH" == "aarch64" ]]; then
                HOST_ARG="--host=aarch64-linux-gnu"
                BUILD_ARG="--build=aarch64-linux-gnu"
        else
                HOST_ARG=""
                BUILD_ARG=""
        fi

        LD_LIBRARY_PATH=${DEPENDENCY_LIBS_PATH}/lib64:${DEPENDENCY_LIBS_PATH}/lib:$LD_LIBRARY_PATH CFLAGS="-I${DEPENDENCY_LIBS_PATH}/include/" LDFLAGS="-L${DEPENDENCY_LIBS_PATH}/lib64 -L${DEPENDENCY_LIBS_PATH}/lib" LIBS="-L${DEPENDENCY_LIBS_PATH}/lib -liconv" ./configure --prefix=${DEPENDENCY_LIBS_PATH} --enable-shared=yes --enable-static=no ${HOST_ARG} ${BUILD_ARG}

        make
	make install

	build_status "ends" "freexl"
}

build_spatialite(){

	build_status "start" "spatialite"
        mkdir -p /source
        cd /source

        wget https://www.gaia-gis.it/gaia-sins/libspatialite-sources/libspatialite-${SPATIALITE_VERSION}.tar.gz
        tar -xvzf libspatialite-${SPATIALITE_VERSION}.tar.gz

        cd libspatialite-${SPATIALITE_VERSION}

	#cp /backup/config.h.in /source/libspatialite-5.1.0/
	#cp /backup/configure.ac /source/libspatialite-5.1.0/

	#aclocal && autoconf

        LD_LIBRARY_PATH=${DEPENDENCY_LIBS_PATH}/lib64:${DEPENDENCY_LIBS_PATH}/lib:$LD_LIBRARY_PATH PKG_CONFIG_PATH=${DEPENDENCY_LIBS_PATH}/lib64/pkgconfig LIBXML2_CFLAGS="-I${DEPENDENCY_LIBS_PATH}/include/ -I${DEPENDENCY_LIBS_PATH}/include/libxml2" LIBXML2_LIBS="-L${DEPENDENCY_LIBS_PATH}/lib -lxml2" LIBS="-L${DEPENDENCY_LIBS_PATH}/lib -liconv" CFLAGS="-I${DEPENDENCY_LIBS_PATH}/include" ./configure --prefix=${DEPENDENCY_LIBS_PATH} \
		    --disable-proj --disable-freexl --disable-rttopo --disable-gcp \
                    --with-geosconfig=${DEPENDENCY_LIBS_PATH}/bin/geos-config 
	#sed -i 's|examples||g' Makefile

	LD_LIBRARY_PATH=${DEPENDENCY_LIBS_PATH}/lib64:${DEPENDENCY_LIBS_PATH}/lib:$LD_LIBRARY_PATH CFLAGS="-I${DEPENDENCY_LIBS_PATH}/include" make 
        LD_LIBRARY_PATH=${DEPENDENCY_LIBS_PATH}/lib64:${DEPENDENCY_LIBS_PATH}/lib:$LD_LIBRARY_PATH CFLAGS="-I${DEPENDENCY_LIBS_PATH}/include" make install

	build_status "ends" "spatialite"
}

build_cgal(){

	build_status "start" "cgal"
        mkdir -p /source
        cd /source
        wget https://github.com/CGAL/cgal/archive/refs/tags/v${CGAL_VERSION}.tar.gz -O cgal-${CGAL_VERSION}.tar.gz
        tar -xvzf cgal-${CGAL_VERSION}.tar.gz
        cd cgal-${CGAL_VERSION}
        mkdir build
        cd build/
        LD_LIBRARY_PATH=${DEPENDENCY_LIBS_PATH}/lib64:${DEPENDENCY_LIBS_PATH}/lib:$LD_LIBRARY_PATH cmake -DCMAKE_INSTALL_PREFIX=${DEPENDENCY_LIBS_PATH} -DCMAKE_BUILD_TYPE=Release ..

	#LD_LIBRARY_PATH=${DEPENDENCY_LIBS_PATH}/lib64:${DEPENDENCY_LIBS_PATH}/lib:$LD_LIBRARY_PATH make
	#make install
	LD_LIBRARY_PATH=${DEPENDENCY_LIBS_PATH}/lib64:${DEPENDENCY_LIBS_PATH}/lib:$LD_LIBRARY_PATH cmake --build .
	LD_LIBRARY_PATH=${DEPENDENCY_LIBS_PATH}/lib64:${DEPENDENCY_LIBS_PATH}/lib:$LD_LIBRARY_PATH cmake --build . --target install
	#cp -rp /usr/local/lib64/cmake/CGAL ${DEPENDENCY_LIBS_PATH}/lib64/cmake/
	#cp -rp /source/cgal-${CGAL_VERSION}/Installation/include/CGAL ${DEPENDENCY_LIBS_PATH}/include/
	#cp -rp /source/cgal-${CGAL_VERSION}/Installation/lib/cmake ${DEPENDENCY_LIBS_PATH}/lib
	#cp -rp /source/cgal-${CGAL_VERSION}/Installation/cmake ${DEPENDENCY_LIBS_PATH}/
	#cp -rp /source/cgal-${CGAL_VERSION}/Kernel_23/include/CGAL/* ${DEPENDENCY_LIBS_PATH}/include/CGAL/

	build_status "ends" "cgal"
}

build_sfcgal(){

	build_status "start" "sfcgal"
        mkdir -p /source
        cd /source
        wget https://gitlab.com/SFCGAL/SFCGAL/-/archive/v${SFCGAL_VERSION}/SFCGAL-v${SFCGAL_VERSION}.tar.gz
        tar -xvzf SFCGAL-v${SFCGAL_VERSION}.tar.gz
        cd SFCGAL-v${SFCGAL_VERSION}
        mkdir -p build
        cd build/
	#LD_LIBRARY_PATH=${DEPENDENCY_LIBS_PATH}/lib64:${DEPENDENCY_LIBS_PATH}/lib:$LD_LIBRARY_PATH cmake --build .
        LD_LIBRARY_PATH=${DEPENDENCY_LIBS_PATH}/lib64:${DEPENDENCY_LIBS_PATH}/lib:$LD_LIBRARY_PATH cmake -DCMAKE_INSTALL_PREFIX=${DEPENDENCY_LIBS_PATH} -DCMAKE_INSTALL_RPATH="${DEPENDENCY_LIBS_PATH}/lib64" ..
        LD_LIBRARY_PATH=${DEPENDENCY_LIBS_PATH}/lib64:${DEPENDENCY_LIBS_PATH}/lib:$LD_LIBRARY_PATH cmake --build .
        LD_LIBRARY_PATH=${DEPENDENCY_LIBS_PATH}/lib64:${DEPENDENCY_LIBS_PATH}/lib:$LD_LIBRARY_PATH cmake --build . --target install

	build_status "ends" "sfcgal"
}

build_lua(){

	build_status "start" "lua"
	mkdir -p /source
	cd /source

	wget https://www.lua.org/ftp/lua-${LUA_VERSION}.tar.gz
	tar xvzf lua-${LUA_VERSION}.tar.gz
	cd lua-${LUA_VERSION}
	sed -i '10s/-O2/-O2 -fPIC/' src/Makefile

	make INSTALL_TOP=${DEPENDENCY_LIBS_PATH} linux install
	make linux install

	#mv /usr/local/bin/lua* /usr/bin
	#mv /usr/local/include/lua* /usr/include
	#mv /usr/local/lib/liblua.a /usr/lib

	build_status "ends" "lua"
}


build_pcre(){

	build_status "start" "pcre"
	mkdir -p /source
	cd /source
	wget https://github.com/PCRE2Project/pcre2/releases/download/pcre2-${PCRE2_VERSION}/pcre2-${PCRE2_VERSION}.tar.bz2

	tar -xvf pcre2-${PCRE2_VERSION}.tar.bz2
	cd pcre2-${PCRE2_VERSION}

	./configure --prefix=${DEPENDENCY_LIBS_PATH} \
            --docdir=${DEPENDENCY_LIBS_PATH}/share/doc/pcre2-${PCRE2_VERSION}   \
            --enable-unicode-properties         \
            --enable-pcre216                     \
            --enable-pcre232                     \
            --enable-pcre2grep-libz              \
            --enable-pcre2grep-libbz2            \
            --enable-pcre2test-libreadline       \
            --disable-static
	make
	make install
	build_status "ends" "pcre"
}

build_libxcrypt(){

        build_status "start" "libxcrypt"

        mkdir -p /source
        cd /source
        wget https://github.com/besser82/libxcrypt/releases/download/v${LIBXCRYPT_VERSION}/libxcrypt-${LIBXCRYPT_VERSION}.tar.xz
        tar -xf libxcrypt-${LIBXCRYPT_VERSION}.tar.xz
        cd libxcrypt-${LIBXCRYPT_VERSION}

        ./autogen.sh
        ./configure --prefix=${DEPENDENCY_LIBS_PATH}
        make
        make install

        build_status "ends" "libxcrypt"
}

build_perl(){

	build_status "start" "Perl"

	mkdir -p /source
        cd /source/
	wget https://www.cpan.org/src/${PERL_MAJOR_VERSION}/perl-${PERL_VERSION}.tar.gz
	tar -xvzf perl-${PERL_VERSION}.tar.gz
	cd perl-${PERL_VERSION}
	./Configure -des -Duseshrplib -Dprefix=${PERL_PREFIX}
	make
	make install

	ARCH=$(uname -m)
	cp -rp ${DEPENDENCY_LIBS_PATH}/lib/libcrypt.so* ${PERL_PREFIX}/lib/${PERL_VERSION}/${ARCH}-linux/CORE
	cp -rp ${DEPENDENCY_LIBS_PATH}/lib/libxcrypt.so* ${PERL_PREFIX}/lib/${PERL_VERSION}/${ARCH}-linux/CORE
	cp -rp ${DEPENDENCY_LIBS_PATH}/lib/libowcrypt.so* ${PERL_PREFIX}/lib/${PERL_VERSION}/${ARCH}-linux/CORE

	chmod 755 ${PERL_PREFIX}/lib/${PERL_VERSION}/${ARCH}-linux/CORE/*.so*
	build_status "ends" "Perl"
}

build_libffi() {

	yum install -y make autoconf automake libtool

	build_status "start" "libffi"

        mkdir -p /source
        cd /source/
	wget https://github.com/libffi/libffi/releases/download/v${LIBFFI_VERSION}/libffi-${LIBFFI_VERSION}.tar.gz
	tar -xzf libffi-${LIBFFI_VERSION}.tar.gz
	cd libffi-${LIBFFI_VERSION}

	# Build libffi in a custom location to avoid conflict with other libraries
	./configure --prefix=${DEPENDENCY_LIBS_PATH}
	make
	make install
	build_status "ends" "libffi"
}

build_python(){

        build_status "start" "Python"

	PYTHON_SSL_PATH=/usr/lib64
	PYTHON_SSL_INCLUDE=/usr/include
	if [ "$USE_SYSTEM_SSL" != "1" ]; then
		yum install -y openssl3 openssl3-devel
		PYTHON_SSL_PATH=/usr/lib64/openssl3
		PYTHON_SSL_INCLUDE=/usr/include/openssl3
		export PKG_CONFIG_PATH="/usr/lib64/pkgconfig"
	fi

        mkdir -p /source
        cd /source/
	wget https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tar.xz
	tar xvf Python-${PYTHON_VERSION}.tar.xz
        cd Python-${PYTHON_VERSION}
	CFLAGS="-fPIC -I${PYTHON_SSL_INCLUDE}" LDFLAGS="-fPIC -L${PYTHON_SSL_PATH}" ./configure --with-openssl=/usr --enable-shared --prefix=${PYTHON_PREFIX}
	make
	make install

	export LD_LIBRARY_PATH=${PYTHON_PREFIX}/lib:${PYTHON_SSL_PATH}:${LD_LIBRARY_PATH}

	ln -s ${PYTHON_PREFIX}/bin/python$(echo ${PYTHON_VERSION} | cut -d. -f1-2) ${PYTHON_PREFIX}/bin/python3
	ln -s ${PYTHON_PREFIX}/bin/pip$(echo ${PYTHON_VERSION} | cut -d. -f1-2) ${PYTHON_PREFIX}/bin/pip3

	# Copy libffi.so installed on system because python builds successfully with it.
	cp -rp /usr/lib64/libffi.so* ${PYTHON_PREFIX}/lib/

	# Set RPATH in _ctypes.cpython-312-x86_64-linux-gnu.so to libffi.so
	cd ${PYTHON_PREFIX}/lib/python$(echo ${PYTHON_VERSION} | cut -d. -f1-2)/lib-dynload/

	ARCH=$(uname -m)
	patchelf --force-rpath --set-rpath "${PYTHON_PREFIX}/lib" _ctypes.cpython-$(echo ${PYTHON_VERSION} | cut -d. -f1-2 | sed -e 's|\.||g')-${ARCH}-linux-gnu.so
	cd -

	${PYTHON_PREFIX}/bin/python3 -m ensurepip
	${PYTHON_PREFIX}/bin/python3 -m pip install --upgrade pip setuptools
	${PYTHON_PREFIX}/bin/python3 -c "import _ctypes"

	${PYTHON_PREFIX}/bin/pip3 install python-dateutil
	${PYTHON_PREFIX}/bin/pip3 install urllib3
	${PYTHON_PREFIX}/bin/pip3 install psycopg
	${PYTHON_PREFIX}/bin/pip3 install psycopg2-binary
	${PYTHON_PREFIX}/bin/pip3 install psutil
	${PYTHON_PREFIX}/bin/pip3 install pyyaml
	${PYTHON_PREFIX}/bin/pip3 install boto3
	${PYTHON_PREFIX}/bin/pip3 install click
	${PYTHON_PREFIX}/bin/pip3 install prettytable
	${PYTHON_PREFIX}/bin/pip3 install python-etcd

        build_status "ends" "Python"
}

build_ydiff(){

	build_status "start" "ydiff"
	mkdir -p /source
	cd /source/
	git clone https://github.com/ymattw/ydiff.git
	cd ydiff/
	LD_LIBRARY_PATH=${PYTHON_PREFIX}/lib:$LD_LIBRARY_PATH ${PYTHON_PREFIX}/bin/python3 setup.py build
	LD_LIBRARY_PATH=${PYTHON_PREFIX}/lib:$LD_LIBRARY_PATH ${PYTHON_PREFIX}/bin/python3 setup.py install || true
	cp -rp ydiff.egg-info ${PYTHON_PREFIX}/lib/python$(echo ${PYTHON_VERSION} | cut -d. -f1-2)/site-packages/

	build_status "ends" "ydiff"
}

build_pysyncobj(){

	build_status "start" "pysyncobj"

	mkdir -p /source
	cd /source/
	git clone https://github.com/bakwc/PySyncObj.git
	cd PySyncObj/
	LD_LIBRARY_PATH=${PYTHON_PREFIX}/lib:$LD_LIBRARY_PATH ${PYTHON_PREFIX}/bin/python3 setup.py build
	LD_LIBRARY_PATH=${PYTHON_PREFIX}/lib:$LD_LIBRARY_PATH ${PYTHON_PREFIX}/bin/python3 setup.py install
	cp -rp pysyncobj.egg-info ${PYTHON_PREFIX}/lib/python$(echo ${PYTHON_VERSION} | cut -d. -f1-2)/site-packages/
	cp -rp pysyncobj ${PYTHON_PREFIX}/lib/python$(echo ${PYTHON_VERSION} | cut -d. -f1-2)/site-packages/

	build_status "ends" "pysyncobj"
}

build_tcl(){

        build_status "start" "Tcl"

        mkdir -p /source
        cd /source/
        wget https://fossies.org/linux/misc/tcl${TCL_VERSION}-src.tar.gz
        tar xvf tcl${TCL_VERSION}-src.tar.gz
        cd tcl${TCL_VERSION}/unix
        ./configure --prefix=${TCL_PREFIX} --enable-shared=yes
        make
        make install
        build_status "ends" "Tcl"
}

build_postgres_server(){

	build_status "start" "PostgreSQL Server"

	rm -rf /source/postgresql-${PG_VERSION}
	mkdir -p /source
	cd /source/

	if (( ${PG_MAJOR_VERSION} > 16 )); then
		git clone https://github.com/Percona-Lab/postgres.git postgresql-${PG_VERSION}
		retval=$?
		if [ $retval != 0 ]
		then
			echo "There were some issues during repo cloning from github. Please retry one more time"
			exit 1
		fi
		cd postgresql-${PG_VERSION}
		if [ ! -z "${PG_SERVER_BRANCH}" ]
		then
			git reset --hard
			git clean -xdf
			git checkout "${PG_SERVER_BRANCH}"
			git submodule update --init --recursive
		fi
		cd contrib/pg_tde
		git fetch
		git reset --hard origin/main
		cd -
	else
		wget https://ftp.postgresql.org/pub/source/v${PG_VERSION}/postgresql-${PG_VERSION}.tar.gz
		tar -xvzf postgresql-${PG_VERSION}.tar.gz
		cd postgresql-${PG_VERSION}
	fi

	CFLAGS='-O2 -DMAP_HUGETLB=0x40000' ICU_LIBS="-L${DEPENDENCY_LIBS_PATH}/lib -licuuc -licudata -licui18n" ICU_CFLAGS="-I${DEPENDENCY_LIBS_PATH}/include" ./configure --with-icu --enable-debug --with-libs=${DEPENDENCY_LIBS_PATH}/lib:${DEPENDENCY_LIBS_PATH}/lib64 --with-includes=${DEPENDENCY_LIBS_PATH}/include/libxml2:${DEPENDENCY_LIBS_PATH}/include/readline:${DEPENDENCY_LIBS_PATH}/include:${SSL_INSTALL_PATH}/include/openssl --prefix=${POSTGRESQL_PREFIX} --with-ldap --with-openssl --with-perl --with-python --with-tcl --with-pam --enable-thread-safety --with-libxml --with-ossp-uuid --docdir=${POSTGRESQL_PREFIX}/doc/postgresql --with-libxslt --with-libedit-preferred --with-gssapi LD_LIBRARY_PATH=${DEPENDENCY_LIBS_PATH}/lib:${DEPENDENCY_LIBS_PATH}/lib64:${PYTHON_PREFIX}/lib:${PERL_PREFIX}/lib:${TCL_PREFIX}/lib
	LD_LIBRARY_PATH=${DEPENDENCY_LIBS_PATH}/lib64:${DEPENDENCY_LIBS_PATH}/lib:${PYTHON_PREFIX}/lib:${PERL_PREFIX}/lib:${TCL_PREFIX}/lib:$LD_LIBRARY_PATH make
	cd src/backend
	LD_LIBRARY_PATH=${DEPENDENCY_LIBS_PATH}/lib64:${DEPENDENCY_LIBS_PATH}/lib:${PYTHON_PREFIX}/lib:${PERL_PREFIX}/lib:${TCL_PREFIX}/lib:$LD_LIBRARY_PATH MAKELEVEL=0 make submake-generated-headers
	cd ../..
	LD_LIBRARY_PATH=${DEPENDENCY_LIBS_PATH}/lib64:${DEPENDENCY_LIBS_PATH}/lib:${PYTHON_PREFIX}/lib:${PERL_PREFIX}/lib:${TCL_PREFIX}/lib:$LD_LIBRARY_PATH MAKELEVEL=0 make -j4 all
	LD_LIBRARY_PATH=${DEPENDENCY_LIBS_PATH}/lib64:${DEPENDENCY_LIBS_PATH}/lib:${PYTHON_PREFIX}/lib:${PERL_PREFIX}/lib:${TCL_PREFIX}/lib:$LD_LIBRARY_PATH make -j4 -C contrib all
	LD_LIBRARY_PATH=${DEPENDENCY_LIBS_PATH}/lib64:${DEPENDENCY_LIBS_PATH}/lib:${PYTHON_PREFIX}/lib:${PERL_PREFIX}/lib:${TCL_PREFIX}/lib:$LD_LIBRARY_PATH make -j4 -C contrib/uuid-ossp all
	pushd doc/src
	LD_LIBRARY_PATH=${DEPENDENCY_LIBS_PATH}/lib64:${DEPENDENCY_LIBS_PATH}/lib:${PYTHON_PREFIX}/lib:${PERL_PREFIX}/lib:${TCL_PREFIX}/lib:$LD_LIBRARY_PATH make all
	popd
	LD_LIBRARY_PATH=${DEPENDENCY_LIBS_PATH}/lib64:${DEPENDENCY_LIBS_PATH}/lib:${PYTHON_PREFIX}/lib:${PERL_PREFIX}/lib:${TCL_PREFIX}/lib:$LD_LIBRARY_PATH make install
	pushd src/pl/plpython
	LD_LIBRARY_PATH=${DEPENDENCY_LIBS_PATH}/lib64:${DEPENDENCY_LIBS_PATH}/lib:${PYTHON_PREFIX}/lib:${PERL_PREFIX}/lib:${TCL_PREFIX}/lib:$LD_LIBRARY_PATH make install
	popd
	LD_LIBRARY_PATH=${DEPENDENCY_LIBS_PATH}/lib64:${DEPENDENCY_LIBS_PATH}/lib:${PYTHON_PREFIX}/lib:${PERL_PREFIX}/lib:${TCL_PREFIX}/lib:$LD_LIBRARY_PATH make -C contrib install
	LD_LIBRARY_PATH=${DEPENDENCY_LIBS_PATH}/lib64:${DEPENDENCY_LIBS_PATH}/lib:${PYTHON_PREFIX}/lib:${PERL_PREFIX}/lib:${TCL_PREFIX}/lib:$LD_LIBRARY_PATH make -C contrib/uuid-ossp install

	cp -rp ${DEPENDENCY_LIBS_PATH}/lib/libicuuc.so* ${POSTGRESQL_PREFIX}/lib/
	cp -rp ${DEPENDENCY_LIBS_PATH}/lib/libldap.* ${POSTGRESQL_PREFIX}/lib/
	cp -rp ${DEPENDENCY_LIBS_PATH}/lib/liblber* ${POSTGRESQL_PREFIX}/lib/
	cp -rp ${DEPENDENCY_LIBS_PATH}/lib/libicudata.so* ${POSTGRESQL_PREFIX}/lib/
	cp -rp ${DEPENDENCY_LIBS_PATH}/lib/libedit.* ${POSTGRESQL_PREFIX}/lib/
	cp -rp ${DEPENDENCY_LIBS_PATH}/lib/libicui18n.so* ${POSTGRESQL_PREFIX}/lib/
	cp -rp ${DEPENDENCY_LIBS_PATH}/lib64/libssl.* ${POSTGRESQL_PREFIX}/lib/
	cp -rp ${DEPENDENCY_LIBS_PATH}/lib64/libcrypto.* ${POSTGRESQL_PREFIX}/lib/
	cp -rp ${DEPENDENCY_LIBS_PATH}/lib/libgssapi_krb5.so* ${POSTGRESQL_PREFIX}/lib/
	cp -rp ${DEPENDENCY_LIBS_PATH}/lib/libcom_err.so* ${POSTGRESQL_PREFIX}/lib/
	cp -rp ${DEPENDENCY_LIBS_PATH}/lib/libkrb*.so* ${POSTGRESQL_PREFIX}/lib/
	cp -rp ${DEPENDENCY_LIBS_PATH}/lib/libk5crypto.so* ${POSTGRESQL_PREFIX}/lib/
	cp -rp ${DEPENDENCY_LIBS_PATH}/lib/libxml2.so* ${POSTGRESQL_PREFIX}/lib/
	cp -rp ${DEPENDENCY_LIBS_PATH}/lib/libkeyutils.so* ${POSTGRESQL_PREFIX}/lib/
	cp -rp ${DEPENDENCY_LIBS_PATH}/lib/libxslt.so* ${POSTGRESQL_PREFIX}/lib/
	cp -rp ${DEPENDENCY_LIBS_PATH}/lib/libuuid.so* ${POSTGRESQL_PREFIX}/lib/
	cp -rp ${DEPENDENCY_LIBS_PATH}/lib/libcrypt.so* ${POSTGRESQL_PREFIX}/lib/
	cp -rp ${DEPENDENCY_LIBS_PATH}/lib/libxcrypt.so* ${POSTGRESQL_PREFIX}/lib/
	cp -rp ${DEPENDENCY_LIBS_PATH}/lib/libowcrypt.so* ${POSTGRESQL_PREFIX}/lib/
	cp -rp ${TCL_PREFIX}/lib/libtcl*.so* ${POSTGRESQL_PREFIX}/lib/
	cp -rp ${PYTHON_PREFIX}/lib/libpython*.so* ${POSTGRESQL_PREFIX}/lib/
	ARCH=$(uname -m)
	cp -rp ${PERL_PREFIX}/lib/${PERL_VERSION}/${ARCH}-linux/CORE/libperl.so* ${POSTGRESQL_PREFIX}/lib/

	chmod 755 ${POSTGRESQL_PREFIX}/lib/*.so*
	build_status "ends" "PostgreSQL Server"
}

build_pgbouncer(){

	build_status "start" "pgBouncer"
        mkdir -p /source
        cd /source
        wget https://www.pgbouncer.org/downloads/files/${PGBOUNCER_VERSION}/pgbouncer-${PGBOUNCER_VERSION}.tar.gz
        tar -xvzf pgbouncer-${PGBOUNCER_VERSION}.tar.gz
        cd pgbouncer-${PGBOUNCER_VERSION}
        LIBEVENT_LIBS="-L${DEPENDENCY_LIBS_PATH}/lib -levent" LIBEVENT_CFLAGS=-I${DEPENDENCY_LIBS_PATH}/include/ LDFLAGS=-L${DEPENDENCY_LIBS_PATH}/lib64 ./configure \
                    --prefix=${PGBOUNCER_PREFIX} \
                    --with-openssl=${SSL_INSTALL_PATH}

        make -j4 V=1
        make install

	mkdir -p ${PGBOUNCER_PREFIX}/lib
	cp -rp ${DEPENDENCY_LIBS_PATH}/lib64/libssl.* ${PGBOUNCER_PREFIX}/lib
	cp -rp ${DEPENDENCY_LIBS_PATH}/lib64/libcrypto.* ${PGBOUNCER_PREFIX}/lib
	cp -rp ${DEPENDENCY_LIBS_PATH}/lib/libevent* ${PGBOUNCER_PREFIX}/lib
	chmod 755 ${PGBOUNCER_PREFIX}/lib/*.so*

        mkdir -p ${PGBOUNCER_PREFIX}/etc
        cp -rp etc/*.ini ${PGBOUNCER_PREFIX}/etc/
        cp -rp etc/userlist.txt ${PGBOUNCER_PREFIX}/etc/

	build_status "ends" "pgBouncer"
}

build_pgpool(){

	build_status "start" "pgPool-II"
        mkdir -p /source
        cd /source
        wget https://www.pgpool.net/mediawiki/download.php?f=pgpool-II-${PGPOOL_VERSION}.tar.gz -O pgpool-II-${PGPOOL_VERSION}.tar.gz
        tar -xvzf pgpool-II-${PGPOOL_VERSION}.tar.gz
        cd pgpool-II-${PGPOOL_VERSION}
        export PATH=${POSTGRESQL_PREFIX}/bin:$PATH

        CFLAGS="-I${DEPENDENCY_LIBS_PATH}/include/ -I${POSTGRESQL_PREFIX}/include" LDFLAGS="-L${DEPENDENCY_LIBS_PATH}/lib64 -L${DEPENDENCY_LIBS_PATH}/lib -L${POSTGRESQL_PREFIX}/lib" ./configure --prefix=${PGPOOL_PREFIX} \
                    --sysconfdir=${PGPOOL_PREFIX}/etc/pgpool2 \
                    --bindir=${PGPOOL_PREFIX}/bin \
                    --includedir=${PGPOOL_PREFIX}/include/pgpool2 \
                    --disable-rpath \
                    --with-ldap \
                    --with-openssl \
                    --with-pam \
                    --with-memcached=${DEPENDENCY_LIBS_PATH}/include/libmemcached

        make -j4
        make -j4 -C doc
        make install
        make install -C src/sql/pgpool-recovery
        make install -C src/sql/pgpool-regclass
        make install -C src/sql/pgpool_adm

	cp -rp ${DEPENDENCY_LIBS_PATH}/lib64/libcrypto.so* ${PGPOOL_PREFIX}/lib/
	cp -rp ${DEPENDENCY_LIBS_PATH}/lib64/libssl.* ${PGPOOL_PREFIX}/lib/
	cp -rp ${POSTGRESQL_PREFIX}/lib/libpq.* ${PGPOOL_PREFIX}/lib/
	cp -rp ${DEPENDENCY_LIBS_PATH}/lib/libldap.* ${PGPOOL_PREFIX}/lib/
	cp -rp ${DEPENDENCY_LIBS_PATH}/lib/liblber* ${PGPOOL_PREFIX}/lib/
	cp -rp ${DEPENDENCY_LIBS_PATH}/lib/libmemcached.* ${PGPOOL_PREFIX}/lib/
	cp -rp ${PGPOOL_PREFIX}/lib/libpcp.so* ${POSTGRESQL_PREFIX}/lib/
	cp -rp ${DEPENDENCY_LIBS_PATH}/lib/libmemcached.* ${POSTGRESQL_PREFIX}/lib/
	cp -rp ${DEPENDENCY_LIBS_PATH}/lib/libcrypt.so* ${PGPOOL_PREFIX}/lib/
	cp -rp ${DEPENDENCY_LIBS_PATH}/lib/libxcrypt.so* ${PGPOOL_PREFIX}/lib/
	cp -rp ${DEPENDENCY_LIBS_PATH}/lib/libowcrypt.so* ${PGPOOL_PREFIX}/lib/
	chmod 755 ${PGPOOL_PREFIX}/lib/*.so*

	build_status "ends" "pgPool-II"
}

build_pgaudit(){

	build_status "start" "pgAudit"
        mkdir -p /source
        cd /source
        git clone https://github.com/pgaudit/pgaudit.git

        cd pgaudit
        if [ ! -z "${PGAUDIT_BRANCH}" ]
        then
          git reset --hard
          git clean -xdf
          git checkout "${PGAUDIT_BRANCH}"
        fi

        export PATH=${POSTGRESQL_PREFIX}/bin:$PATH
        make USE_PGXS=1 -j4
        make USE_PGXS=1 -j4 install
	build_status "ends" "pgAudit"
}

build_pgaudit_set_user(){

	build_status "start" "set_user"
        mkdir -p /source
        cd /source
        git clone https://github.com/pgaudit/set_user.git
        cd set_user

        if [ ! -z "${SETUSER_BRANCH}" ]
        then
          git reset --hard
          git clean -xdf
          git checkout "${SETUSER_BRANCH}"
        fi

        export PATH=${POSTGRESQL_PREFIX}/bin:$PATH
        make USE_PGXS=1 -j4
        make USE_PGXS=1 -j4 install
	build_status "ends" "set_user"
}

build_pgrepack(){

	build_status "start" "pg_repack"
        mkdir -p /source
        cd /source
        git clone https://github.com/reorg/pg_repack.git
        cd pg_repack

	if [ ! -z "${PG_REPACK_BRANCH}" ]
        then
          git reset --hard
          git clean -xdf
          git checkout "${PG_REPACK_BRANCH}"
        fi

        export PATH=${POSTGRESQL_PREFIX}/bin:$PATH
        make USE_PGXS=1 -j4
        make USE_PGXS=1 -j4 install
	build_status "ends" "pg_repack"
}

build_wal2json(){

	build_status "start" "wal2json"
        mkdir -p /source
        cd /source
        git clone https://github.com/eulerto/wal2json.git
        cd wal2json

        if [ ! -z "${WAL2JSON_BRANCH}" ]
        then
          git reset --hard
          git clean -xdf
          git checkout "${WAL2JSON_BRANCH}"
        fi

        export PATH=${POSTGRESQL_PREFIX}/bin:$PATH
        make USE_PGXS=1 -j4
        make USE_PGXS=1 -j4 install
	build_status "ends" "wal2json"
}

build_pg_stat_monitor(){

	build_status "start" "pg_stat_monitor"
        mkdir -p /source
        cd /source
        git clone https://github.com/percona/pg_stat_monitor.git
        cd pg_stat_monitor

        if [ ! -z "${PG_STAT_MONITOR_BRANCH}" ]
        then
          git reset --hard
          git clean -xdf
          git checkout "${PG_STAT_MONITOR_BRANCH}"
        fi

        export PATH=${POSTGRESQL_PREFIX}/bin:$PATH
        make USE_PGXS=1 -j4
        make USE_PGXS=1 -j4 install
	build_status "ends" "pg_stat_monitor"
}

build_pg_gather(){

	build_status "start" "pg_gather"
        mkdir -p /source
        cd /source

        wget https://raw.githubusercontent.com/percona/support-snippets/master/postgresql/pg_gather/gather.sql
        wget https://raw.githubusercontent.com/percona/support-snippets/master/postgresql/pg_gather/README.md

        cp gather.sql ${POSTGRESQL_PREFIX}/bin
        chmod 755 ${POSTGRESQL_PREFIX}/bin/gather.sql
	build_status "ends" "pg_gather"
}

build_pgbackrest(){

	build_status "start" "pgbackrest"
        mkdir -p /source
        cd /source

        git clone https://github.com/pgbackrest/pgbackrest.git
        cd pgbackrest

        if [ ! -z "${PGBACKREST_BRANCH}" ]
        then
          git reset --hard
          git clean -xdf
          git checkout "${PGBACKREST_BRANCH}"
        fi

        wget https://raw.githubusercontent.com/percona/postgres-packaging/${PG_VERSION}/pgbackrest/pgbackrest.conf

        pushd src
        export CPPFLAGS="-I${POSTGRESQL_PREFIX}/include"
        export PATH=${POSTGRESQL_PREFIX}/bin/:$PATH
        LD_LIBRARY_PATH=${DEPENDENCY_LIBS_PATH}/lib64:${DEPENDENCY_LIBS_PATH}/lib:${PYTHON_PREFIX}/lib:${PERL_PREFIX}/lib:${TCL_PREFIX}/lib:$LD_LIBRARY_PATH CFLAGS="-I${DEPENDENCY_LIBS_PATH}/include -I${DEPENDENCY_LIBS_PATH}/include/libxml2" LDFLAGS="-L${DEPENDENCY_LIBS_PATH}/lib64 -L${DEPENDENCY_LIBS_PATH}/lib" ./configure --prefix=${PGBACKREST_PREFIX}
        LD_LIBRARY_PATH=${DEPENDENCY_LIBS_PATH}/lib64:${DEPENDENCY_LIBS_PATH}/lib:${POSTGRESQL_PREFIX}/lib:${PYTHON_PREFIX}/lib:${PERL_PREFIX}/lib:${TCL_PREFIX}/lib:$LD_LIBRARY_PATH make
        make install
        popd

        #mkdir -p ${PGBACKREST_PREFIX}/var/lib/pgbackrest
        #mkdir -p ${PGBACKREST_PREFIX}/var/log/pgbackrest
        #mkdir -p ${PGBACKREST_PREFIX}/var/spool/pgbackrest
        
	mkdir -p ${PGBACKREST_PREFIX}/lib
	cp -rp ${DEPENDENCY_LIBS_PATH}/lib64/libcrypto.* ${PGBACKREST_PREFIX}/lib/
	cp -rp ${DEPENDENCY_LIBS_PATH}/lib64/libssl.* ${PGBACKREST_PREFIX}/lib/
	cp -rp ${DEPENDENCY_LIBS_PATH}/lib/libldap.* ${PGBACKREST_PREFIX}/lib/
	cp -rp ${DEPENDENCY_LIBS_PATH}/lib/liblber* ${PGBACKREST_PREFIX}/lib/
	cp -rp ${POSTGRESQL_PREFIX}/lib/libpq.* ${PGBACKREST_PREFIX}/lib/
	chmod 755 ${PGBACKREST_PREFIX}/lib/*.so*

	mkdir -p ${PGBACKREST_PREFIX}/etc

        cp -rp /usr/share/perl5/vendor_perl ${PGBACKREST_PREFIX}/bin
        cp pgbackrest.conf ${PGBACKREST_PREFIX}/etc
        cp -a src/pgbackrest ${PGBACKREST_PREFIX}/bin
        cp LICENSE ${PGBACKREST_PREFIX}/pgbackrest_license

	build_status "ends" "pgbackrest"
}

build_pgbadger(){

	build_status "start" "pgbadger"
        mkdir -p /source
        mkdir -p ${PGBADGER_PREFIX}
        cd /source

        git clone https://github.com/darold/pgbadger.git
        cd pgbadger

        if [ ! -z "${PGBADGER_BRANCH}" ]
        then
          git reset --hard
          git clean -xdf
          git checkout "${PGBADGER_BRANCH}"
        fi

        perl Makefile.PL INSTALLDIRS=vendor
        make -j4

        make pure_install PERL_INSTALL_ROOT=${PGBADGER_PREFIX}

        #if [[ -n "${PGBADGER_PREFIX}" ]]; then

        #       mv ${PGBADGER_PREFIX}/usr/* ${PGBADGER_PREFIX}/
        #        rm -rf ${PGBADGER_PREFIX}/usr
        #fi

        cp README.md ${PGBADGER_PREFIX}/README.md
        cp LICENSE ${PGBADGER_PREFIX}/LICENSE
	build_status "ends" "pgbadger"
}

build_patroni(){

	build_status "start" "Patroni"
        mkdir -p /source
        mkdir -p ${PATRONI_PREFIX}
        cd /source
        git clone https://github.com/zalando/patroni.git
        cd patroni

        if [ ! -z "${PATRONI_BRANCH}" ]
        then
          git reset --hard
          git clean -xdf
          git checkout "${PATRONI_BRANCH}"
        fi

	LD_LIBRARY_PATH=${DEPENDENCY_LIBS_PATH}/lib64:${DEPENDENCY_LIBS_PATH}/lib:${PYTHON_PREFIX}/lib:${PERL_PREFIX}/lib:${TCL_PREFIX}/lib:$LD_LIBRARY_PATH pip3 install setuptools
	LD_LIBRARY_PATH=${DEPENDENCY_LIBS_PATH}/lib64:${DEPENDENCY_LIBS_PATH}/lib:${PYTHON_PREFIX}/lib:${PERL_PREFIX}/lib:${TCL_PREFIX}/lib:$LD_LIBRARY_PATH python3 setup.py build
	LD_LIBRARY_PATH=${DEPENDENCY_LIBS_PATH}/lib64:${DEPENDENCY_LIBS_PATH}/lib:${PYTHON_PREFIX}/lib:${PERL_PREFIX}/lib:${TCL_PREFIX}/lib:$LD_LIBRARY_PATH python3 setup.py install --root ${PATRONI_PREFIX} -O1 --skip-build

	mkdir -p ${PATRONI_PREFIX}/share/doc/patroni
	cp postgres0.yml postgres1.yml ${PATRONI_PREFIX}/share/doc/patroni
	cp LICENSE ${PATRONI_PREFIX}/patroni_license
	cp -rp docs ${PATRONI_PREFIX}/share/doc/patroni
	cp README.rst ${PATRONI_PREFIX}/share/doc/patroni

	cp -rp ${PATRONI_PREFIX}/${PYTHON_PREFIX}/lib/python$(echo ${PYTHON_VERSION} | cut -d. -f1-2)/site-packages/patroni* ${PYTHON_PREFIX}/lib/python$(echo ${PYTHON_VERSION} | cut -d. -f1-2)/site-packages/
	mkdir -p ${PATRONI_PREFIX}/bin
	mv ${PATRONI_PREFIX}/${PYTHON_PREFIX}/bin/patroni* ${PATRONI_PREFIX}/bin/
	rm -rf ${PATRONI_PREFIX}/opt

	build_status "ends" "Patroni"
}

build_haproxy(){

	build_status "start" "HAProxy"
        mkdir -p /source
        mkdir -p ${HAPROXY_PREFIX}
        cd /source

        git clone http://git.haproxy.org/git/haproxy-${HAPROXY_VERSION}.git
        cd haproxy-${HAPROXY_VERSION}

        if [ ! -z "${HAPROXY_BRANCH}" ]
        then
          git reset --hard
          git clean -xdf
          git checkout "${HAPROXY_BRANCH}"
        fi

        ARCH=$(uname -m)

        regparm_opts=""

        if [ "$ARCH" = "x86_64" ]; then
                regparm_opts="USE_REGPARM=1"
        fi

        CFLAGS+="-I${DEPENDENCY_LIBS_PATH}/include"
        export PCRE2_CONFIG=${DEPENDENCY_LIBS_PATH}/bin/pcre2-config

        sed -i "s|LDFLAGS = \$(ARCH_FLAGS) -g|LDFLAGS = \$(ARCH_FLAGS) -g -L${DEPENDENCY_LIBS_PATH}/lib64 -L${DEPENDENCY_LIBS_PATH}/lib|g" Makefile
        sed -i "s|COPTS  = -Iinclude|COPTS  = -I${DEPENDENCY_LIBS_PATH}/include -Iinclude|g" Makefile

        make -j4 CPU="generic" TARGET="linux-glibc" USE_OPENSSL=1 USE_PCRE2=1 USE_ZLIB=1 USE_LUA=1 USE_CRYPT_H=1 USE_LINUX_TPROXY=1 USE_GETADDRINFO=1 ${regparm_opts} ADDINC="-O2" USE_PROMEX=1 LUA_LIB=${DEPENDENCY_LIBS_PATH}/lib LUA_INC=${DEPENDENCY_LIBS_PATH}/include
        make admin/halog/halog OPTIMIZE="-O2"
        make admin/iprange/iprange OPTIMIZE="-O2"
        make install-bin PREFIX=${HAPROXY_PREFIX} TARGET="linux2628"
        make install-man PREFIX=${HAPROXY_PREFIX}

        mkdir -p ${HAPROXY_PREFIX}/etc/haproxy
        mkdir -p ${HAPROXY_PREFIX}/etc/logrotate.d
        mkdir -p ${HAPROXY_PREFIX}/etc/sysconfig/haproxy
        mkdir -p ${HAPROXY_PREFIX}/share/man/man1
        mkdir -p ${HAPROXY_PREFIX}/share
        mkdir -p ${HAPROXY_PREFIX}/bin

	mkdir -p ${HAPROXY_PREFIX}/lib
	cp -rp ${DEPENDENCY_LIBS_PATH}/lib64/libcrypto.* ${HAPROXY_PREFIX}/lib/
	cp -rp ${DEPENDENCY_LIBS_PATH}/lib64/libssl.* ${HAPROXY_PREFIX}/lib/
	cp -rp ${DEPENDENCY_LIBS_PATH}/lib/libpcre2-* ${HAPROXY_PREFIX}/lib/
	cp -rp ${DEPENDENCY_LIBS_PATH}/lib/libcrypt.so* ${HAPROXY_PREFIX}/lib/
	cp -rp ${DEPENDENCY_LIBS_PATH}/lib/libxcrypt.so* ${HAPROXY_PREFIX}/lib/
	cp -rp ${DEPENDENCY_LIBS_PATH}/lib/libowcrypt.so* ${HAPROXY_PREFIX}/lib/
	chmod 755 ${HAPROXY_PREFIX}/lib/*.so*

        wget https://raw.githubusercontent.com/percona/haproxy-packaging/main/rpm/haproxy.cfg
        wget https://raw.githubusercontent.com/percona/haproxy-packaging/main/rpm/haproxy.logrotate
        wget https://raw.githubusercontent.com/percona/haproxy-packaging/main/rpm/haproxy.sysconfig
        wget https://raw.githubusercontent.com/percona/haproxy-packaging/main/rpm/halog.1

        mv haproxy.cfg ${HAPROXY_PREFIX}/etc/haproxy
        mv haproxy.logrotate ${HAPROXY_PREFIX}/etc/logrotate.d/
        mv haproxy.sysconfig ${HAPROXY_PREFIX}/etc/sysconfig/haproxy
        mv halog.1 ${HAPROXY_PREFIX}/share/man/man1

        cp ./admin/halog/halog ${HAPROXY_PREFIX}/bin
        cp ./admin/iprange/iprange ${HAPROXY_PREFIX}/bin
        cp ./examples/errorfiles/* ${HAPROXY_PREFIX}/share

        for httpfile in $(find ./examples/errorfiles/ -type f)
        do
            cp $httpfile ${HAPROXY_PREFIX}/share
        done

        rm -rf ./examples/errorfiles/
        find ./examples/* -type f ! -name "*.cfg" -exec rm -f "{}" \;

        for textfile in $(find ./ -type f -name '*.txt')
        do
                mv $textfile $textfile.old
                /usr/bin/iconv --from-code ISO8859-1 --to-code UTF-8 --output $textfile $textfile.old
                rm -f $textfile.old
        done

	build_status "ends" "HAProxy"
}

build_etcd(){

	build_status "start" "etcd"
	mkdir -p /source
	mkdir -p ${ETCD_PREFIX}/bin
	cd /source

	ARCH=$(uname -m)

	if [ "$ARCH" = "x86_64" ]; then
		ARCH="amd64"
	elif [ "$ARCH" = "aarch64" ]; then
		ARCH="arm64"
	fi

	wget https://github.com/etcd-io/etcd/releases/download/v${ETCD_VERSION}/etcd-v${ETCD_VERSION}-linux-${ARCH}.tar.gz
	tar -xvzf etcd-v${ETCD_VERSION}-linux-${ARCH}.tar.gz
	cp -rp etcd-v${ETCD_VERSION}-linux-${ARCH}/etcd* ${ETCD_PREFIX}/bin

	build_status "ends" "etcd"
}

build_pgvector(){

        build_status "start" "pgvector"
        mkdir -p /source
        cd /source
        git clone https://github.com/pgvector/pgvector.git
        cd pgvector

        if [ ! -z "${PGVECTOR_BRANCH}" ]
        then
          git reset --hard
          git clean -xdf
          git checkout "${PGVECTOR_BRANCH}"
        fi

        export PATH=${POSTGRESQL_PREFIX}/bin:$PATH
        make USE_PGXS=1 -j4
        make USE_PGXS=1 -j4 install
        build_status "ends" "pgvector"
}

build_postgis(){

        build_status "start" "postgis"
        mkdir -p /source
        cd /source
	wget "https://download.osgeo.org/postgis/source/postgis-${POSTGIS_VERSION}.tar.gz"
        tar -xvzf postgis-${POSTGIS_VERSION}.tar.gz
	cd postgis-${POSTGIS_VERSION}

        export PATH=${POSTGRESQL_PREFIX}/bin:${DEPENDENCY_LIBS_PATH}/bin:$PATH
        LD_LIBRARY_PATH=${DEPENDENCY_LIBS_PATH}/lib64:${DEPENDENCY_LIBS_PATH}/lib:${POSTGRESQL_PREFIX}/lib:$LD_LIBRARY_PATH CFLAGS="-I${DEPENDENCY_LIBS_PATH}/include" LDFLAGS="-L${DEPENDENCY_LIBS_PATH}/lib -L${DEPENDENCY_LIBS_PATH}/lib64" ./configure --with-pgconfig=${POSTGRESQL_PREFIX}/bin/pg_config \
        	--enable-lto \
        	--with-projdir=${DEPENDENCY_LIBS_PATH} \
        	--with-sfcgal=${DEPENDENCY_LIBS_PATH}/bin/sfcgal-config \
        	--with-gui \
        	--with-protobuf \
        	--with-geosconfig=${DEPENDENCY_LIBS_PATH}/bin/geos-config \
        	--with-gdalconfig=${DEPENDENCY_LIBS_PATH}/bin/gdal-config
	
	LD_LIBRARY_PATH=${DEPENDENCY_LIBS_PATH}/lib64:${DEPENDENCY_LIBS_PATH}/lib:${POSTGRESQL_PREFIX}/lib:$LD_LIBRARY_PATH make USE_PGXS=1 -j4
        LD_LIBRARY_PATH=${DEPENDENCY_LIBS_PATH}/lib64:${DEPENDENCY_LIBS_PATH}/lib:${POSTGRESQL_PREFIX}/lib:$LD_LIBRARY_PATH make USE_PGXS=1 -j4 install

	cp -rp ${DEPENDENCY_LIBS_PATH}/lib64/libgeos_c*.so* ${POSTGRESQL_PREFIX}/lib/
	cp -rp ${DEPENDENCY_LIBS_PATH}/lib64/libproj.so* ${POSTGRESQL_PREFIX}/lib/
	cp -rp ${DEPENDENCY_LIBS_PATH}/lib64/libSFCGAL.so* ${POSTGRESQL_PREFIX}/lib/
	cp -rp ${DEPENDENCY_LIBS_PATH}/lib/libiconv.so* ${POSTGRESQL_PREFIX}/lib/
	cp -rp ${DEPENDENCY_LIBS_PATH}/lib64/libgeos.so* ${POSTGRESQL_PREFIX}/lib/
	cp -rp ${DEPENDENCY_LIBS_PATH}/lib/libsqlite3* ${POSTGRESQL_PREFIX}/lib/
	cp -rp ${DEPENDENCY_LIBS_PATH}/lib/libtiff.so* ${POSTGRESQL_PREFIX}/lib/
	cp -rp ${DEPENDENCY_LIBS_PATH}/lib/libmpfr* ${POSTGRESQL_PREFIX}/lib/
	cp -rp ${DEPENDENCY_LIBS_PATH}/lib/libgmp* ${POSTGRESQL_PREFIX}/lib/
	cp -rp ${DEPENDENCY_LIBS_PATH}/lib/libqhull_r* ${POSTGRESQL_PREFIX}/lib/
	cp -rp ${DEPENDENCY_LIBS_PATH}/lib64/libjpeg.so* ${POSTGRESQL_PREFIX}/lib/
	cp -rp ${DEPENDENCY_LIBS_PATH}/lib64/libgeotiff* ${POSTGRESQL_PREFIX}/lib/
	cp -rp ${DEPENDENCY_LIBS_PATH}/lib64/libpng16* ${POSTGRESQL_PREFIX}/lib/
	cp -rp ${DEPENDENCY_LIBS_PATH}/lib/libpcre2-* ${POSTGRESQL_PREFIX}/lib/
	cp -rp ${DEPENDENCY_LIBS_PATH}/lib/libspatialit* ${POSTGRESQL_PREFIX}/lib/
	cp -rp ${DEPENDENCY_LIBS_PATH}/lib/libfreexl* ${POSTGRESQL_PREFIX}/lib/
	cp -rp ${DEPENDENCY_LIBS_PATH}/lib64/libjson-c* ${POSTGRESQL_PREFIX}/lib/
	cp -rp ${DEPENDENCY_LIBS_PATH}/lib/libprotobuf-c* ${POSTGRESQL_PREFIX}/lib/
	cp -rp ${DEPENDENCY_LIBS_PATH}/lib/libcurl* ${POSTGRESQL_PREFIX}/lib/
	cp -rp ${DEPENDENCY_LIBS_PATH}/lib/libboost_* ${POSTGRESQL_PREFIX}/lib/
	cp -rp ${DEPENDENCY_LIBS_PATH}/lib64/libgdal.so* ${POSTGRESQL_PREFIX}/lib/
        cp -rp ${DEPENDENCY_LIBS_PATH}/lib64/libminizip.* ${POSTGRESQL_PREFIX}/lib/
	cp -rp ${DEPENDENCY_LIBS_PATH}/lib/libmd.* ${POSTGRESQL_PREFIX}/lib/
	cp -rp ${DEPENDENCY_LIBS_PATH}/lib/libbsd* ${POSTGRESQL_PREFIX}/lib/

	build_status "ends" "postgis"
}

set_rpath(){

        directory="$1"  # Change this to your target directory
        new_rpath="$2"

        # Check if the directory exists
        if [ ! -d "$directory" ]; then
                echo "Error: Directory not found."
                exit 1
        fi

        # Iterate over each binary in the directory
        for binary in "$directory"/*; do

                # Check if the file is a binary (not a directory)
                if [ -f "$binary" ] && [ -x "$binary" ]; then
                        echo "Changing RPATH for $binary..."

                        # Use patchelf to set the new RPATH
                        patchelf --set-rpath "$new_rpath" "$binary"
                        echo "------------------------"
                fi
        done
}

set_rpath_all_products(){

	ARCH=$(uname -m)
	# Set rpath of all binaries in tarball
	set_rpath "${POSTGRESQL_PREFIX}/bin" "\${ORIGIN}/../lib:${PYTHON_PREFIX}/lib:${PERL_PREFIX}/lib/${PERL_VERSION}/${ARCH}-linux/CORE:${TCL_PREFIX}/lib"
	set_rpath "${PGBOUNCER_PREFIX}/bin" "\${ORIGIN}/../lib"
	set_rpath "${PGPOOL_PREFIX}/bin" "\${ORIGIN}/../lib"
	set_rpath "${PGBACKREST_PREFIX}/bin" "\${ORIGIN}/../lib"
	set_rpath "${HAPROXY_PREFIX}/sbin" "\${ORIGIN}/../lib"
	set_rpath "${PYTHON_PREFIX}/bin" "\${ORIGIN}/../lib"
	set_rpath "${PERL_PREFIX}/bin" "\${ORIGIN}/../lib/${PERL_VERSION}/${ARCH}-linux/CORE"
	set_rpath "${TCL_PREFIX}/bin" "\${ORIGIN}/../lib"

	set_rpath "${POSTGRESQL_PREFIX}/lib" "\${ORIGIN}:${PYTHON_PREFIX}/lib:${PYTHON_PREFIX}/lib:${PERL_PREFIX}/lib/${PERL_VERSION}/${ARCH}-linux/CORE:${TCL_PREFIX}/lib"
        set_rpath "${PGBOUNCER_PREFIX}/lib" "\${ORIGIN}"
        set_rpath "${PGPOOL_PREFIX}/lib" "\${ORIGIN}"
        set_rpath "${PGBACKREST_PREFIX}/lib" "\${ORIGIN}"
        set_rpath "${HAPROXY_PREFIX}/lib" "\${ORIGIN}"
	set_rpath "${PYTHON_PREFIX}/lib" "\${ORIGIN}"
	set_rpath "${PERL_PREFIX}/lib/${PERL_VERSION}/${ARCH}-linux/CORE" "\${ORIGIN}"
	set_rpath "${TCL_PREFIX}/lib" "\${ORIGIN}"
}

build_status(){

	action=$1
	component=$2

	if [ "${action}" = "start" ]; then
		message="Starting ${component} build"
	elif [ "${action}" = "ends" ]; then
		message="${component} build completed"
	fi	
        echo "======================================="
        echo "${message}"
        echo "======================================="
}

create_tarball(){

	mkdir -p ${CWD}/tarballs-${PG_VERSION}
        pushd /opt
	ARCH=$(uname -m)
        find . \( -type d -name 'percona-*' \) -exec tar czvf ${CWD}/tarballs-${PG_VERSION}/percona-postgresql-${PG_VERSION}-${SSL_VERSION}-linux-${ARCH}.tar.gz {} +
        popd
}

replacePlaceHolder() {
	
	if [ -z "$3" ]; then
		echo "Error: Some parameter value is empty."
		exit
	fi
	sed -e "s^$1^$2^g" $3 > "/tmp/$$.tmp"
	mv /tmp/$$.tmp $3
}

setPermissions() {

	permissionsDirectory="pg_staging/$1/"

	if [ "x$2" != "x" ];
	then
		permissionsDirectory="$2"
	fi

	# Set 644 for all files and folders
	find $permissionsDirectory -type f | xargs -I{} chmod 644 {}

	# Set Permissions for links and folders
	find $permissionsDirectory -xtype l | xargs -I{} chmod 777 {}
	find $permissionsDirectory -type d | xargs -I{} chmod 755 {}

	# " executable" requires a ' ' prefix to ensure it is not a filename
	find $permissionsDirectory -type f | xargs -I{} file {} | grep -i " executable" | cut -f1 -d":" | xargs -I{} chmod +x {}
	find $permissionsDirectory -type f | xargs -I{} file {} | grep "ELF" | cut -f1 -d":" | xargs -I{} chmod +x {}
	find $permissionsDirectory -type f | xargs -I{} file {} | grep "Mach-O" | cut -f1 -d":" | xargs -I{} chmod +x {}

}

download_install_builder(){

	if [ ! -d "${PG_INSTALLBUILDER_BIN}" ]; then

		ARCH=$(uname -m)

		if [ "$ARCH" = "x86_64" ]; then
			ARCH="x64"
		elif [ "$ARCH" = "aarch64" ]; then
			ARCH="arm64"
		fi
		
		wget https://releases.installbuilder.com/installbuilder/installbuilder-qt-enterprise-${INSTALLBUILDER_VERSION}-linux-${ARCH}-installer.run -O installbuilder.run
		chmod 755 installbuilder.run
		sudo ./installbuilder.run --prefix /opt/installbuilder --mode unattended
	fi
}

generate_installer_xml() {
	
	PLATFORM=$1
	if [ -n $PLATFORM ]; then
		PLATFORM_SUFFIX="-$PLATFORM"
	else
		echo "PLATFORM variable not defined"
		PLATFORM_SUFFIX=""
	fi

	# Get the catalog version number
	PG_CATALOG_VERSION=`cat $PG_SOURCE_DIR/postgresql-${PG_VERSION}/src/include/catalog/catversion.h |grep "#define CATALOG_VERSION_NO" | awk '{print $3}'`
	PG_CONTROL_VERSION=`cat $PG_SOURCE_DIR/postgresql-${PG_VERSION}/src/include/catalog/pg_control.h |grep "#define PG_CONTROL_VERSION" | awk '{print $3}'`

	echo "PG_CATALOG_VERSION=$PG_CATALOG_VERSION"
	echo "PG_CONTROL_VERSION=$PG_CONTROL_VERSION"

	#wget https://raw.githubusercontent.com/percona/postgres-packaging/${PG_VERSION}/postgres/installer.xml.in
	#wget https://raw.githubusercontent.com/percona/postgres-packaging/${PG_VERSION}/postgres/pgserver.xml.in

	#mkdir -p i18n
	#cd i18n
	#wget https://raw.githubusercontent.com/percona/postgres-packaging/${PG_VERSION}/postgres/i18n/en.lng
	#cd -

	for file in {installer,pgserver}
	do
		filename=${file}${PLATFORM_SUFFIX}.xml
		if [ -f $filename ]; then
			rm -f $filename
		fi

		if [ ! -z $PLATFORM ]; then
			cp ${file}.xml.in $filename
			replacePlaceHolder @@PLATFORM@@ "$PLATFORM" $filename
		else
			cp ${file}.xml.in $filename
		fi

		#WIN64MODE="1"
		#SERVICESUFFIX="-x64"
		#replacePlaceHolder @@WINDIR@@ $PLATFORM $filename
		#replacePlaceHolder @@VCREDIST_BUNDLED_VER@@ $VCREDIST_VERSION $filename
		#pg_catlog_version_file="$PG_SOURCE_DIR/postgresql-${PG_VERSION}/src/include/catalog/catversion.h"
		#PG_CATALOG_VERSION=`cat $pg_catlog_version_file |grep "#define CATALOG_VERSION_NO" | awk '{print $3}'`
		#pg_control_file="$PG_SOURCE_DIR/postgresql-${PG_VERSION}/src/include/catalog/pg_control.h"
		#PG_CONTROL_VERSION=`cat $pg_control_file |grep "#define PG_CONTROL_VERSION" | awk '{print $3}'`
		replacePlaceHolder PG_MAJOR_VERSION $PG_MAJOR_VERSION $filename
		replacePlaceHolder PG_MINOR_VERSION $PG_MINOR_VERSION $filename
		replacePlaceHolder PG_PACKAGE_VERSION $PG_PACKAGE_VERSION $filename
		replacePlaceHolder PG_STAGING_DIR $PG_STAGING_DIR $filename
		replacePlaceHolder PG_CATALOG_VERSION $PG_CATALOG_VERSION $filename
		replacePlaceHolder PG_CONTROL_VERSION $PG_CONTROL_VERSION $filename
		#replacePlaceHolder PERL_PACKAGE_VERSION $PERL_PACKAGE_VERSION  $filename
		#replacePlaceHolder PERL_PACKAGE_VERSION_WINDOWS64 $PERL_PACKAGE_VERSION_WINDOWS64  $filename
		#replacePlaceHolder PYTHON_PACKAGE_VERSION $PYTHON_PACKAGE_VERSION $filename
		#replacePlaceHolder TCL_PACKAGE_VERSION $TCL_PACKAGE_VERSION $filename

		if [ ! -z $PLATFORM ]; then
			PG_DATETIME_SETTING="64-bit integers"
			replacePlaceHolder @@PG_DATETIME_SETTING@@ "$PG_DATETIME_SETTING" $filename
			#replacePlaceHolder @@WIN64MODE@@ "$WIN64MODE" $filename
			#replacePlaceHolder @@SERVICE_SUFFIX@@ "$SERVICESUFFIX" $filename
		fi
	done
}

build_installer(){

	cd $PARENT_DIR

	mkdir -p $PG_STAGING_DIR/doc/postgresql/html
	cd $PG_STAGING_DIR/doc
	rm -f installation-notes.html
	wget https://raw.githubusercontent.com/percona/postgres-packaging/${PG_VERSION}/postgres/resources/installation-notes.html
	cd -
	cd $PG_STAGING_DIR/doc/postgresql/html
	rm -f index.html
	rm -f release.html
	wget https://raw.githubusercontent.com/percona/postgres-packaging/${PG_VERSION}/postgres/resources/index.html
	wget https://raw.githubusercontent.com/percona/postgres-packaging/${PG_VERSION}/postgres/resources/release.html
	cd -

	# Complete the staging and prepare the installer
	mkdir -p $PG_STAGING_DIR/installer/server
	cd $PG_STAGING_DIR
	rm -f server_license.txt
	wget https://raw.githubusercontent.com/percona/postgres-packaging/${PG_VERSION}/postgres/server_license.txt
	cd -

	cd $PARENT_DIR

	# Setup the installer scripts.
	mkdir -p $PG_STAGING_DIR/installer/server

	cd scripts/getlocales
	ARCH=$(uname -m)
	gcc -o getlocales.${ARCH} -O0 getlocales.c
	cd -

	cp $PARENT_DIR/scripts/getlocales/getlocales.${ARCH} $PG_STAGING_DIR/installer/server/getlocales
	chmod ugo+x $PG_STAGING_DIR/installer/server/getlocales

	cd $PG_STAGING_DIR/installer
	wget https://raw.githubusercontent.com/percona/postgres-packaging/${PG_VERSION}/postgres/scripts/linux/prerun_checks.sh .
	cd -
	chmod ugo+x $PG_STAGING_DIR/installer/prerun_checks.sh

	cd $PG_STAGING_DIR/installer/server
	wget https://raw.githubusercontent.com/percona/postgres-packaging/${PG_VERSION}/postgres/scripts/linux/runpgcontroldata.sh .
	chmod ugo+x $PG_STAGING_DIR/installer/server/runpgcontroldata.sh

	wget https://raw.githubusercontent.com/percona/postgres-packaging/${PG_VERSION}/postgres/scripts/linux/createuser.sh .
	chmod ugo+x $PG_STAGING_DIR/installer/server/createuser.sh
	wget https://raw.githubusercontent.com/percona/postgres-packaging/${PG_VERSION}/postgres/scripts/linux/initcluster.sh .
	chmod ugo+x $PG_STAGING_DIR/installer/server/initcluster.sh
	wget https://raw.githubusercontent.com/percona/postgres-packaging/${PG_VERSION}/postgres/scripts/linux/startupcfg.sh .
	chmod ugo+x $PG_STAGING_DIR/installer/server/startupcfg.sh
	wget https://raw.githubusercontent.com/percona/postgres-packaging/${PG_VERSION}/postgres/scripts/linux/createshortcuts.sh .
	chmod ugo+x $PG_STAGING_DIR/installer/server/createshortcuts.sh

	wget https://raw.githubusercontent.com/percona/postgres-packaging/${PG_VERSION}/postgres/scripts/linux/createshortcuts_server.sh .
	chmod ugo+x $PG_STAGING_DIR/installer/server/createshortcuts_server.sh

	wget https://raw.githubusercontent.com/percona/postgres-packaging/${PG_VERSION}/postgres/scripts/linux/createshortcuts_clt.sh .
	chmod ugo+x $PG_STAGING_DIR/installer/server/createshortcuts_clt.sh
	wget https://raw.githubusercontent.com/percona/postgres-packaging/${PG_VERSION}/postgres/scripts/linux/removeshortcuts_clt.sh .
	chmod ugo+x $PG_STAGING_DIR/installer/server/removeshortcuts_clt.sh

	wget https://raw.githubusercontent.com/percona/postgres-packaging/${PG_VERSION}/postgres/scripts/linux/removeshortcuts.sh .
	chmod ugo+x $PG_STAGING_DIR/installer/server/removeshortcuts.sh
	wget https://raw.githubusercontent.com/percona/postgres-packaging/${PG_VERSION}/postgres/scripts/linux/startserver.sh .
	chmod ugo+x $PG_STAGING_DIR/installer/server/startserver.sh
	wget https://raw.githubusercontent.com/percona/postgres-packaging/${PG_VERSION}/postgres/scripts/linux/loadmodules.sh .
	chmod ugo+x $PG_STAGING_DIR/installer/server/loadmodules.sh

	wget https://raw.githubusercontent.com/percona/postgres-packaging/${PG_VERSION}/postgres/scripts/linux/config_libs.sh .
	chmod ugo+x $PG_STAGING_DIR/installer/server/config_libs.sh
	wget https://raw.githubusercontent.com/percona/postgres-packaging/${PG_VERSION}/postgres/scripts/linux/removeshortcuts_server.sh .
	chmod ugo+x $PG_STAGING_DIR/installer/server/removeshortcuts_server.sh
	cd -

	# Copy the XDG scripts
	mkdir -p $PG_STAGING_DIR/installer/xdg
	cd $PG_STAGING_DIR/installer/xdg

	wget https://raw.githubusercontent.com/percona/postgres-packaging/${PG_VERSION}/postgres/scripts/xdg/xdg-desktop-icon .
	wget https://raw.githubusercontent.com/percona/postgres-packaging/${PG_VERSION}/postgres/scripts/xdg/xdg-desktop-menu .
	wget https://raw.githubusercontent.com/percona/postgres-packaging/${PG_VERSION}/postgres/scripts/xdg/xdg-icon-resource .

	find . -name "xdg*" -exec chmod ugo+x {} \;
	cd -

	# Version string, for the xdg filenames
	PG_VERSION_STR=`echo $PG_MAJOR_VERSION | sed 's/\./_/g'`

	# Copy in the menu pick images and XDG items
	mkdir -p $PG_STAGING_DIR/scripts/images

	cd $PG_STAGING_DIR/scripts/images

	wget https://raw.githubusercontent.com/percona/postgres-packaging/${PG_VERSION}/postgres/resources/pg-help.png .
	mv pg-help.png pg-help-$PG_VERSION_STR.png
	wget https://raw.githubusercontent.com/percona/postgres-packaging/${PG_VERSION}/postgres/resources/pg-postgresql.png .
        mv pg-postgresql.png pg-postgresql-$PG_VERSION_STR.png
	wget https://raw.githubusercontent.com/percona/postgres-packaging/${PG_VERSION}/postgres/resources/pg-psql.png .
        mv pg-psql.png pg-psql-$PG_VERSION_STR.png
	wget https://raw.githubusercontent.com/percona/postgres-packaging/${PG_VERSION}/postgres/resources/pg-reload.png .
        mv pg-reload.png pg-reload-$PG_VERSION_STR.png
	cd -
	mkdir -p $PG_STAGING_DIR/scripts/xdg

	cd $PG_STAGING_DIR/scripts/xdg
	wget https://raw.githubusercontent.com/percona/postgres-packaging/${PG_VERSION}/postgres/resources/xdg/pg-postgresql.directory .
        mv pg-postgresql.directory pg-postgresql-$PG_VERSION_STR.directory
	wget https://raw.githubusercontent.com/percona/postgres-packaging/${PG_VERSION}/postgres/resources/xdg/pg-documentation.directory .
        mv pg-documentation.directory pg-documentation-$PG_VERSION_STR.directory

	wget https://raw.githubusercontent.com/percona/postgres-packaging/${PG_VERSION}/postgres/resources/xdg/pg-doc-installationnotes.desktop .
        mv pg-doc-installationnotes.desktop pg-doc-installationnotes-$PG_VERSION_STR.desktop
	wget https://raw.githubusercontent.com/percona/postgres-packaging/${PG_VERSION}/postgres/resources/xdg/pg-doc-postgresql-releasenotes.desktop .
        mv pg-doc-postgresql-releasenotes.desktop pg-doc-postgresql-releasenotes-$PG_VERSION_STR.desktop 
	wget https://raw.githubusercontent.com/percona/postgres-packaging/${PG_VERSION}/postgres/resources/xdg/pg-doc-postgresql.desktop .
        mv pg-doc-postgresql.desktop pg-doc-postgresql-$PG_VERSION_STR.desktop 
	wget https://raw.githubusercontent.com/percona/postgres-packaging/${PG_VERSION}/postgres/resources/xdg/pg-psql.desktop .
        mv pg-psql.desktop pg-psql-$PG_VERSION_STR.desktop
	wget https://raw.githubusercontent.com/percona/postgres-packaging/${PG_VERSION}/postgres/resources/xdg/pg-reload.desktop .
        mv pg-reload.desktop pg-reload-$PG_VERSION_STR.desktop 
	cd -

	# Copy the launch scripts
	cd $PG_STAGING_DIR/scripts
	wget https://raw.githubusercontent.com/percona/postgres-packaging/${PG_VERSION}/postgres/scripts/linux/launchpsql.sh .
	chmod ugo+x $PG_STAGING_DIR/scripts/launchpsql.sh
	wget https://raw.githubusercontent.com/percona/postgres-packaging/${PG_VERSION}/postgres/scripts/linux/launchsvrctl.sh .
	chmod ugo+x $PG_STAGING_DIR/scripts/launchsvrctl.sh
	wget https://raw.githubusercontent.com/percona/postgres-packaging/${PG_VERSION}/postgres/scripts/linux/serverctl.sh .
	chmod ugo+x $PG_STAGING_DIR/scripts/serverctl.sh
	wget https://raw.githubusercontent.com/percona/postgres-packaging/${PG_VERSION}/postgres/scripts/linux/runpsql.sh .
	chmod ugo+x $PG_STAGING_DIR/scripts/runpsql.sh

	wget https://raw.githubusercontent.com/percona/postgres-packaging/${PG_VERSION}/postgres/scripts/linux/launchbrowser.sh .
	chmod ugo+x $PG_STAGING_DIR/scripts/launchbrowser.sh
	cd -

	# Prepare the installer XML file
	generate_installer_xml "linux-x64"

	# Copy plLanguages.config
	mkdir -p $PG_STAGING_DIR/etc/sysconfig
	cd $PG_STAGING_DIR/etc/sysconfig
	wget https://raw.githubusercontent.com/percona/postgres-packaging/${PG_VERSION}/postgres/scripts/common/plLanguages.config .
	wget https://raw.githubusercontent.com/percona/postgres-packaging/${PG_VERSION}/postgres/scripts/common/loadplLanguages.sh .
	cd -

	# Copy percona-languages to staging directory
	rm -rf $LANGUAGES_DIR/percona-languages
	cp -rp /opt/Percona/percona-languages $LANGUAGES_DIR/

	replacePlaceHolder PERL_PACKAGE_VERSION $PERL_VERSION $PG_STAGING_DIR/etc/sysconfig/plLanguages.config
	replacePlaceHolder PYTHON_PACKAGE_VERSION $PYTHON_VERSION $PG_STAGING_DIR/etc/sysconfig/plLanguages.config
	replacePlaceHolder TCL_PACKAGE_VERSION $TCL_VERSION $PG_STAGING_DIR/etc/sysconfig/plLanguages.config

	# Set permissions to all files and folders in staging
	setPermissions linux-x64

	# Build the installer
	"$PG_INSTALLBUILDER_BIN/builder" build installer-linux-x64.xml linux-x64

	cd $PARENT_DIR
}


################
#     Main     #
################

create_build_environment

if [ "${BUILD_DEPENDENCIES}" = "1" ]; then

	if [ "$USE_SYSTEM_SSL" != "1" ]; then
		build_openssl
	fi
	build_zlib
	build_krb5
	build_keyutils
	build_ncurses
	build_libedit
	build_libuuid
	build_libxml2
	build_libxslt
	build_libiconv
	build_ldap
	build_cyrus_sasl
	build_curl
	build_icu
	build_libevent
	build_libmemcached
	build_uuid
	build_libyaml
	build_lua
	build_pcre
	build_libmd
	build_libbsd
	build_minizip
	build_geos
	build_libtiff
	build_proj
	build_libgeotiff
	build_libpng
	build_libjpeg
	build_libqhull
	build_sqlite
	build_jsonc
	build_gmp
	build_mpfr
	build_libboost
	build_expat
	build_freexl
	#build_protobuf
	build_protobuf_c
	build_spatialite
	build_gdal
	build_cgal
	build_sfcgal
	build_libxcrypt
	build_perl
	build_libffi
	build_python
	build_ydiff
	build_pysyncobj
	build_tcl
else
	# Check if the directory exists
	if [ ! -d "${DEPENDENCY_LIBS_PATH}" ]; then
  		echo "Error: Directory ${DEPENDENCY_LIBS_PATH} not found. Use --build_dependencies=1 switch to build dependency packages."
  		exit 1
	fi

	# Check if the directory is empty
	if [ -z "$(ls -A "${DEPENDENCY_LIBS_PATH}")" ]; then
		echo "Error: Directory ${DEPENDENCY_LIBS_PATH} is empty. Use --build_dependencies=1 switch to build dependency packages."
		exit 1
	fi
fi

build_postgres_server
build_pgbouncer
build_pgpool
build_pgaudit
build_pgaudit_set_user
build_pgrepack
build_wal2json
build_pg_stat_monitor
build_pg_gather
build_pgbackrest
build_pgbadger
build_patroni
build_haproxy
build_etcd
build_pgvector
build_postgis
set_rpath_all_products
create_tarball

build_installer

