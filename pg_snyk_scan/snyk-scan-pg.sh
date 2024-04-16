#!/bin/bash

prepare_snyk_env(){
  apt-get update
  apt-get install -y curl wget lsb-release git python3-pip

  curl https://static.snyk.io/cli/latest/snyk-linux -o snyk
  chmod +x ./snyk
  mv ./snyk /usr/local/bin/
  snyk auth ${SNYK_TOKEN}
}

message(){

  component="$1"
  echo "============================="
  echo "Scanning $component" 
  echo "============================="
}

scan_product(){

  COMPONENT_NAME="$1"
  COMPONENT_VERSION="$2"
  COMPONENT_REPO="$3"
  COMPONENT_BRANCH="$4"

  OPTIONS="--unmanaged"

  message "${COMPONENT_NAME} ${COMPONENT_BRANCH}"

  if [ "x${COMPONENT_NAME}" = "xpg_gather" ]; then
    mkdir -p ${COMPONENT_NAME}-${COMPONENT_VERSION}
    pushd ${COMPONENT_NAME}-${COMPONENT_VERSION}
    wget https://raw.githubusercontent.com/percona/${COMPONENT_REPO}/${COMPONENT_BRANCH}/postgresql/pg_gather/gather.sql .
  else
    git clone ${COMPONENT_REPO} ${COMPONENT_NAME}-${COMPONENT_VERSION}
    pushd ${COMPONENT_NAME}-${COMPONENT_VERSION}

    if [ "x${COMPONENT_NAME}" = "xpgbouncer" ]; then
      git submodule update --init 
    fi
    git checkout ${COMPONENT_BRANCH}
  fi

  if [ "x${COMPONENT_NAME}" = "xpatroni" ]; then
    pip3 install -r requirements.txt
    OPTIONS="--command=python3"
  fi

  snyk monitor ${OPTIONS} -d --org=${SNYK_ORG_TOKEN} --project-name=${COMPONENT_NAME}-${COMPONENT_VERSION} --print-dep-paths
  popd

}

################
# Main
################
# PostgreSQL
PG_REPO="git://git.postgresql.org/git/postgresql.git"
PG16_VERSION=16.2
PG16_BRANCH_VERSION=$(echo $PG16_VERSION | sed -e 's|\.|_|g')
PG16_BRANCH="REL_${PG16_BRANCH_VERSION}"

PG15_VERSION=15.6
PG15_BRANCH_VERSION=$(echo $PG15_VERSION | sed -e 's|\.|_|g')
PG15_BRANCH="REL_${PG15_BRANCH_VERSION}"

PG14_VERSION=14.11
PG14_BRANCH_VERSION=$(echo $PG14_VERSION | sed -e 's|\.|_|g')
PG14_BRANCH="REL_${PG14_BRANCH_VERSION}"

PG13_VERSION=13.14
PG13_BRANCH_VERSION=$(echo $PG13_VERSION | sed -e 's|\.|_|g')
PG13_BRANCH="REL_${PG13_BRANCH_VERSION}"

PG12_VERSION=12.18
PG12_BRANCH_VERSION=$(echo $PG12_VERSION | sed -e 's|\.|_|g')
PG12_BRANCH="REL_${PG12_BRANCH_VERSION}"

# Patroni
PATRONI_REPO="https://github.com/zalando/patroni.git"
PATRONI_VERSION=3.2.2
PATRONI_BRANCH="v${PATRONI_VERSION}"

# pg_cron
PG_CRON_REPO="https://github.com/citusdata/pg_cron.git"
PG_CRON_VERSION=1.6.2
PG_CRON_BRANCH="main"

# pg_gather
PG_GATHER_REPO_NAME="support-snippets"
PG_GATHER_VERSION=25
PG_GATHER_BRANCH="master"

# pg_repack
PG_REPACK_REPO="https://github.com/reorg/pg_repack.git"
PG_REPACK_VERSION=1.5.0
PG_REPACK_BRANCH="ver_1.5.0"

# pg_tde
PG_TDE_REPO="https://github.com/Percona-Lab/pg_tde.git"
PG_TDE_VERSION=1.0.0
PG_TDE_BRANCH="1.0.0-alpha"

# pgadmin
PG_ADMIN_REPO="https://github.com/postgres/pgadmin4.git"
PG_ADMIN_VERSION=5.0
PG_ADMIN_BRANCH="REL-5_0"

# pgaudit
PG_AUDIT_REPO="https://github.com/pgaudit/pgaudit.git"
PG_AUDIT16_VERSION=${PG16_VERSION}
PG_AUDIT16_BRANCH="REL_16_STABLE"

PG_AUDIT15_VERSION=${PG15_VERSION}
PG_AUDIT15_BRANCH="REL_15_STABLE"

PG_AUDIT14_VERSION=${PG14_VERSION}
PG_AUDIT14_BRANCH="REL_14_STABLE"

PG_AUDIT13_VERSION=${PG13_VERSION}
PG_AUDIT13_BRANCH="REL_13_STABLE"

PG_AUDIT12_VERSION=${PG12_VERSION}
PG_AUDIT12_BRANCH="REL_12_STABLE"

# set_user
PG_SET_USER_REPO="https://github.com/pgaudit/set_user.git"
PG_SET_USER_VERSION=4.0.1
PG_SET_USER_BRANCH="REL4_0_1"

# pgbackrest
PGBACKREST_REPO="https://github.com/pgbackrest/pgbackrest.git"
PGBACKREST_VERSION=2.50
PGBACKREST_BRANCH="release/2.50"

# pgbadger
PGBADGER_REPO="https://github.com/darold/pgbadger.git"
PGBADGER_VERSION=12.4
PGBADGER_BRANCH="v12.4"

# pgbouncer
PGBOUNCER_REPO="https://github.com/pgbouncer/pgbouncer.git"
PGBOUNCER_VERSION=1.22.0
PGBOUNCER_BRANCH="pgbouncer_1_22_0"

# pgpool-II
PGPOOL_REPO="https://git.postgresql.org/git/pgpool2.git"
PGPOOL_VERSION=4.5.0
PGPOOL_BRANCH="V4_5_0"

# pgvector
PGVECTOR_REPO="https://github.com/pgvector/pgvector.git"
PGVECTOR_VERSION=0.5.1
PGVECTOR_BRANCH="master"

# postgis
POSTGIS_REPO="https://github.com/postgis/postgis.git"
POSTGIS_VERSION=3.3.5
POSTGIS_BRANCH="stable-3.3"

# postgres-common
PG_COMMON_REPO="https://salsa.debian.org/postgresql/postgresql-common.git"
PG_COMMON_VERSION=256
PG_COMMON_BRANCH="debian/256"

# ppg-server-ha/ppg-server/postgres-packaging
POSTGRES_PACKAGING_REPO="https://github.com/percona/postgres-packaging.git"
POSTGRES16_PACKAGING_VERSION=${PG16_VERSION}
POSTGRES16_PACKAGING_BRANCH="${PG16_VERSION}"

POSTGRES15_PACKAGING_VERSION=${PG15_VERSION}
POSTGRES15_PACKAGING_BRANCH="${PG15_VERSION}"

POSTGRES14_PACKAGING_VERSION=${PG14_VERSION}
POSTGRES14_PACKAGING_BRANCH="${PG14_VERSION}"

POSTGRES13_PACKAGING_VERSION=${PG13_VERSION}
POSTGRES13_PACKAGING_BRANCH="${PG13_VERSION}"

POSTGRES12_PACKAGING_VERSION=${PG12_VERSION}
POSTGRES12_PACKAGING_BRANCH="${PG12_VERSION}"

# psycopg2
PSYCOPG2_REPO="https://github.com/psycopg/psycopg2.git"
PSYCOPG2_VERSION=2.9.5
PSYCOPG2_BRANCH="2_9_5"

# wal2json
WAL2JSON_REPO="https://github.com/eulerto/wal2json.git"
WAL2JSON_VERSION=2.5
WAL2JSON_BRANCH="wal2json_2_5"

#############################################

if [ -z "${SNYK_TOKEN}" ]; then
    echo "Error: SNYK_TOKEN variable is empty. Please specify SNYK_TOKEN value to authenticate."
    exit 1
fi

if [ -z "${SNYK_ORG_TOKEN}" ]; then
    echo "Error: SNYK_ORG_TOKEN variable is empty. Please specify SNYK_ORG_TOKEN value to authenticate."
    exit 1
fi

prepare_snyk_env

scan_product "postgresql16" "${PG16_VERSION}" "${PG_REPO}" "${PG16_BRANCH}"
scan_product "postgresql15" "${PG15_VERSION}" "${PG_REPO}" "${PG15_BRANCH}"
scan_product "postgresql14" "${PG14_VERSION}" "${PG_REPO}" "${PG14_BRANCH}"
scan_product "postgresql13" "${PG13_VERSION}" "${PG_REPO}" "${PG13_BRANCH}"
scan_product "postgresql12" "${PG12_VERSION}" "${PG_REPO}" "${PG12_BRANCH}"

scan_product "patroni" "${PATRONI_VERSION}" "${PATRONI_REPO}" "${PATRONI_BRANCH}"
scan_product "pg_cron" "${PG_CRON_VERSION}" "${PG_CRON_REPO}" "${PG_CRON_BRANCH}"
scan_product "pg_repack" "${PG_REPACK_VERSION}" "${PG_REPACK_REPO}" "${PG_REPACK_BRANCH}"
scan_product "pg_tde" "${PG_TDE_VERSION}" "${PG_TDE_REPO}" "${PG_TDE_BRANCH}"
scan_product "pg_gather" "${PG_GATHER_VERSION}" "${PG_GATHER_REPO_NAME}" "${PG_GATHER_BRANCH}"
#scan_product "pgadmin" "${PG_ADMIN_VERSION}" "${PG_ADMIN_REPO}" "${PG_ADMIN_BRANCH}"

scan_product "pgaudit16" "${PG_AUDIT16_VERSION}" "${PG_AUDIT_REPO}" "${PG_AUDIT16_BRANCH}"
scan_product "pgaudit15" "${PG_AUDIT15_VERSION}" "${PG_AUDIT_REPO}" "${PG_AUDIT15_BRANCH}"
scan_product "pgaudit14" "${PG_AUDIT14_VERSION}" "${PG_AUDIT_REPO}" "${PG_AUDIT14_BRANCH}"
scan_product "pgaudit13" "${PG_AUDIT13_VERSION}" "${PG_AUDIT_REPO}" "${PG_AUDIT13_BRANCH}"
scan_product "pgaudit12" "${PG_AUDIT12_VERSION}" "${PG_AUDIT_REPO}" "${PG_AUDIT12_BRANCH}"

scan_product "set_user" "${PG_SET_USER_VERSION}" "${PG_SET_USER_REPO}" "${PG_SET_USER_BRANCH}"
scan_product "pgbackrest" "${PGBACKREST_VERSION}" "${PGBACKREST_REPO}" "${PGBACKREST_BRANCH}"

scan_product "pgbadger" "${PGBADGER_VERSION}" "${PGBADGER_REPO}" "${PGBADGER_BRANCH}"
scan_product "pgbouncer" "${PGBOUNCER_VERSION}" "${PGBOUNCER_REPO}" "${PGBOUNCER_BRANCH}"
scan_product "pgpool-II" "${PGPOOL_VERSION}" "${PGPOOL_REPO}" "${PGPOOL_BRANCH}"
scan_product "pgvector" "${PGVECTOR_VERSION}" "${PGVECTOR_REPO}" "${PGVECTOR_BRANCH}"

scan_product "postgis" "${POSTGIS_VERSION}" "${POSTGIS_REPO}" "${POSTGIS_BRANCH}"
scan_product "postgres-common" "${PG_COMMON_VERSION}" "${PG_COMMON_REPO}" "${PG_COMMON_BRANCH}"
scan_product "postgres-packaging16" "${POSTGRES16_PACKAGING_VERSION}" "${POSTGRES_PACKAGING_REPO}" "${POSTGRES16_PACKAGING_BRANCH}"
scan_product "postgres-packaging15" "${POSTGRES15_PACKAGING_VERSION}" "${POSTGRES_PACKAGING_REPO}" "${POSTGRES15_PACKAGING_BRANCH}"
scan_product "postgres-packaging14" "${POSTGRES14_PACKAGING_VERSION}" "${POSTGRES_PACKAGING_REPO}" "${POSTGRES14_PACKAGING_BRANCH}"
scan_product "postgres-packaging13" "${POSTGRES13_PACKAGING_VERSION}" "${POSTGRES_PACKAGING_REPO}" "${POSTGRES13_PACKAGING_BRANCH}"
scan_product "postgres-packaging12" "${POSTGRES12_PACKAGING_VERSION}" "${POSTGRES_PACKAGING_REPO}" "${POSTGRES12_PACKAGING_BRANCH}"
#scan_product "psycopg2" "${PSYCOPG2_VERSION}" "${PSYCOPG2_REPO}" "${PSYCOPG2_BRANCH}"
scan_product "wal2json" "${WAL2JSON_VERSION}" "${WAL2JSON_REPO}" "${WAL2JSON_BRANCH}"

