#!/bin/bash

shell_quote_string() {
  echo "$1" | sed -e 's,\([^a-zA-Z0-9/_.=-]\),\\\1,g'
}

usage () {
    cat <<EOF
Usage: $0 [OPTIONS]
    The following options may be given :
        --version               Tarball version
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

export LUA_VERSION=5.3.6
export PG_MAJOR_VERSION=$(echo ${PG_VERSION} | cut -f1 -d'.')
export PGBOUNCER_VERSION=1.25.0
export PGPOOL_VERSION=4.6.3
export HAPROXY_VERSION=2.8
export LIBFFI_VERSION=3.4.2
export PERL_VERSION=5.38.2
export PERL_MAJOR_VERSION=5.0
export PYTHON_VERSION=3.12.3
export TCL_VERSION=8.6.16
export ETCD_VERSION=3.5.24
export POSTGIS_VERSION=3.3.8
export POSTGIS35_VERSION=3.5.4

CWD=$(pwd)

if (( ${PG_MAJOR_VERSION} > 16 )); then
	PG_SERVER_BRANCH=release-${PG_VERSION}.1
else
	PG_SERVER_BRANCH=REL_${PG_MAJOR_VERSION}_STABLE
fi

PGAUDIT_BRANCH=REL_${PG_MAJOR_VERSION}_STABLE

if [ "${PGAUDIT_BRANCH}" = "REL_12_STABLE" ]; then
    PGAUDIT_BRANCH="1.4.3"
fi

SETUSER_BRANCH="REL4_2_0"
PG_REPACK_BRANCH="ver_1.5.3"
WAL2JSON_BRANCH="wal2json_2_6"
PG_STAT_MONITOR_BRANCH="release-2.3.1"
PGBACKREST_BRANCH="release/2.57.0"
PGBADGER_BRANCH="v13.1"
PATRONI_BRANCH="v4.1.0"
HAPROXY_BRANCH="v2.8.16"
PGVECTOR_BRANCH="v0.8.1"

create_build_environment(){

	RHEL=$(rpm --eval %rhel)

	yum groupinstall -y "Development Tools"
	yum install -y epel-release
	yum config-manager --enable ol${RHEL}_codeready_builder
	yum install -y vim python3-devel perl tcl-devel pam-devel tcl python3 flex bison wget bzip2-devel chrpath patchelf perl-Pod-Markdown readline-devel cmake sqlite-devel minizip-devel openssl-devel libffi-devel protobuf protobuf-devel
	rm -rf /source/*
	mkdir -p /source

}

build_lua(){

	build_status "start" "lua"
	mkdir -p /source
	cd /source

	wget https://www.lua.org/ftp/lua-${LUA_VERSION}.tar.gz
	tar xvzf lua-${LUA_VERSION}.tar.gz
	rm -f lua-${LUA_VERSION}.tar.gz
	build_status "ends" "lua"
}

build_ydiff(){

	build_status "start" "ydiff"
	mkdir -p /source
	cd /source/
	git clone https://github.com/ymattw/ydiff.git
	build_status "ends" "ydiff"
}

build_pysyncobj(){

	build_status "start" "pysyncobj"

	mkdir -p /source
	cd /source/
	git clone https://github.com/bakwc/PySyncObj.git
	build_status "ends" "pysyncobj"
}

build_postgres_server(){

	build_status "start" "PostgreSQL Server"

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
		cd /source
	else
                git clone https://git.postgresql.org/git/postgresql.git postgresql-${PG_VERSION}
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
                fi
	fi

	build_status "ends" "PostgreSQL Server"
}

build_pgbouncer(){

	build_status "start" "pgBouncer"
        mkdir -p /source
        cd /source
        wget https://www.pgbouncer.org/downloads/files/${PGBOUNCER_VERSION}/pgbouncer-${PGBOUNCER_VERSION}.tar.gz
        tar -xvzf pgbouncer-${PGBOUNCER_VERSION}.tar.gz
	rm -f pgbouncer-${PGBOUNCER_VERSION}.tar.gz
	build_status "ends" "pgBouncer"
}

build_pgpool(){

	build_status "start" "pgPool-II"
        mkdir -p /source
        cd /source
        wget https://www.pgpool.net/mediawiki/download.php?f=pgpool-II-${PGPOOL_VERSION}.tar.gz -O pgpool-II-${PGPOOL_VERSION}.tar.gz
        tar -xvzf pgpool-II-${PGPOOL_VERSION}.tar.gz
	rm -f pgpool-II-${PGPOOL_VERSION}.tar.gz
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

	build_status "ends" "pg_stat_monitor"
}

build_pg_gather(){

	build_status "start" "pg_gather"
        mkdir -p /source
        cd /source

        wget https://raw.githubusercontent.com/percona/support-snippets/master/postgresql/pg_gather/gather.sql

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

	build_status "ends" "pgbackrest"
}

build_pgbadger(){

	build_status "start" "pgbadger"
        mkdir -p /source
        cd /source

        git clone https://github.com/darold/pgbadger.git
        cd pgbadger

        if [ ! -z "${PGBADGER_BRANCH}" ]
        then
          git reset --hard
          git clean -xdf
          git checkout "${PGBADGER_BRANCH}"
        fi

	build_status "ends" "pgbadger"
}

build_patroni(){

	build_status "start" "Patroni"
        mkdir -p /source
        cd /source
        git clone https://github.com/zalando/patroni.git
        cd patroni

        if [ ! -z "${PATRONI_BRANCH}" ]
        then
          git reset --hard
          git clean -xdf
          git checkout "${PATRONI_BRANCH}"
        fi

	build_status "ends" "Patroni"
}

build_haproxy(){

	build_status "start" "HAProxy"
        mkdir -p /source
        cd /source

        git clone http://git.haproxy.org/git/haproxy-${HAPROXY_VERSION}.git
        cd haproxy-${HAPROXY_VERSION}

        if [ ! -z "${HAPROXY_BRANCH}" ]
        then
          git reset --hard
          git clean -xdf
          git checkout "${HAPROXY_BRANCH}"
        fi

	build_status "ends" "HAProxy"
}

build_etcd(){

	build_status "start" "etcd"
	mkdir -p /source
	cd /source

	wget https://github.com/etcd-io/etcd/archive/refs/tags/v${ETCD_VERSION}.tar.gz -O etcd-${ETCD_VERSION}.tar.gz
	tar -xvzf etcd-${ETCD_VERSION}.tar.gz
	rm -f etcd-${ETCD_VERSION}.tar.gz
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

        build_status "ends" "pgvector"
}

build_postgis(){

	build_status "start" "postgis"
	mkdir -p /source
	cd /source
	wget "https://download.osgeo.org/postgis/source/postgis-${POSTGIS_VERSION}.tar.gz"
	tar -xvzf postgis-${POSTGIS_VERSION}.tar.gz
	rm -f postgis-${POSTGIS_VERSION}.tar.gz

	build_status "ends" "postgis"
}

build_postgis35(){

	build_status "start" "postgis35"
	mkdir -p /source
	cd /source
	wget "https://download.osgeo.org/postgis/source/postgis-${POSTGIS35_VERSION}.tar.gz"
	tar -xvzf postgis-${POSTGIS35_VERSION}.tar.gz
	rm -f postgis-${POSTGIS35_VERSION}.tar.gz

	build_status "ends" "postgis35"
}

build_status(){

	action=$1
	component=$2

	if [ "${action}" = "start" ]; then
		message="Starting ${component} extraction"
	elif [ "${action}" = "ends" ]; then
		message="${component} extraction completed"
	fi	
        echo "======================================="
        echo "${message}"
        echo "======================================="
}

create_tarball(){

	mkdir -p ${CWD}/tarballs-${PG_VERSION}
        pushd /source
	find . -type d -name ".git" -exec rm -rf {} +
        tar czvf ${CWD}/tarballs-${PG_VERSION}/percona-postgresql-${PG_VERSION}-src.tar.gz *
        popd
}

################
#     Main     #
################

create_build_environment

build_lua
build_ydiff
build_pysyncobj
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
if [ "$PG_MAJOR_VERSION" -lt 18 ]; then
    build_postgis
fi
build_postgis35
create_tarball
