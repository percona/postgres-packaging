#!/usr/bin/env bash

PG_MAJOR=17
PG_MINOR=9
PG_VERSION=${PG_MAJOR}.${PG_MINOR}

PPG_COMMON_MAJOR=289
PPG_COMMON_MINOR=1
PG_TDE_VERSION=2.1.2
ETCD_VERSION=3.5.26
PATRONI_VERSION=4.1.0
PG_CRON_VERSION=1.6.2
PG_GATHER_VERSION=32
PG_REPACK_VERSION=1.5.3
PGAUDIT_VERSION=17.1
SET_USER_VERSION=4.2.0
PG_BCKREST_VERSION=2.58.0
PGBADGER_VERSION=13.2
PGBOUNCER_VERSION=1.25.1
PGPOOL2_VERSION=4.7.0
PGVECTOR_VERSION=0.8.1
POSTGIS35_VERSION=3.5
POSTGIS35_MINOR=5
PYSYNCOBJ_VERSION=0.3.10
WAL2JSON_VERSION=2.6
YDIFF_VERSION=1.4.2

#-------------------------------------- COMMON URLs --------------------------------------

# Github Packaging Repo
PKG_GIT_REPO="https://github.com/percona/postgres-packaging.git"
PKG_GIT_BRANCH=${PG_VERSION}
PGRPMS_GIT_REPO="https://git.postgresql.org/git/pgrpms.git"

# Raw files URLs
PKG_RAW_URL="https://raw.githubusercontent.com/percona/postgres-packaging/${PG_VERSION}"

# Percona Repos
YUM_REPO="https://repo.percona.com/yum/percona-release-latest.noarch.rpm"
APT_REPO="https://repo.percona.com/apt/percona-release_latest.generic_all.deb"

case "$1" in
    postgresql)
        # versions
        PPG_PRODUCT=percona-postgresql
        PPG_PRODUCT_FULL=${PPG_PRODUCT}-${PG_VERSION}
        PG_RELEASE='1'
        PG_SRC_BRANCH="release-${PG_MAJOR}.${PG_MINOR}.${PG_RELEASE}"
        PG_SRC_BRANCH_NIGHTLY="TDE_REL_${PG_MAJOR}_STABLE"
        PG_RPM_RELEASE='1'
        PG_DEB_RELEASE='1'

        # urls
        PG_SRC_REPO="https://github.com/Percona-Lab/postgres.git"
        PG_SRC_REPO_DEB="https://salsa.debian.org/postgresql/postgresql.git"
        PG_DOC="https://www.postgresql.org/files/documentation/pdf/${PG_MAJOR}/postgresql-${PG_MAJOR}-A4.pdf"
    ;;


    postgresql-common)
        # versions
        PPG_COMMON_PRODUCT=percona-postgresql-common
        PPG_COMMON_PRODUCT_FULL=${PPG_COMMON_PRODUCT}-${PPG_COMMON_MAJOR}
        PPG_COMMON_RELEASE='1'
        PPG_COMMON_SRC_BRANCH="debian/${PPG_COMMON_MAJOR}"
        PPG_COMMON_RPM_RELEASE='1'
        PPG_COMMON_DEB_RELEASE='1'

        # urls
        PPG_COMMON_SRC_REPO="https://salsa.debian.org/postgresql/postgresql-common.git"
    ;;


    pg_tde)
        # versions
        PG_TDE_PRODUCT=percona-pg_tde${PG_MAJOR}
        PG_TDE_PRODUCT_DEB=percona-pg-tde${PG_MAJOR}
        PG_TDE_PRODUCT_FULL=${PG_TDE_PRODUCT}-${PG_TDE_VERSION}
        PG_TDE_RELEASE='1'
        PG_TDE_SRC_BRANCH="release-${PG_TDE_VERSION}"
        PG_TDE_RPM_RELEASE='1'
        PG_TDE_DEB_RELEASE='1'
        # urls
        PG_TDE_SRC_REPO="https://github.com/percona/pg_tde.git"
    ;;


    etcd)
        # versions
        ETCD_PRODUCT=etcd
        ETCD_PRODUCT_FULL=${ETCD_PRODUCT}-${ETCD_VERSION}
        ETCD_RPM_RELEASE='1'
        ETCD_DEB_RELEASE='1'
        ETCD_RELEASE='1'

        # urls
        ETCD_SRC_REPO="https://github.com/etcd-io/etcd/releases/download/v${ETCD_VERSION}"
        ETCD_SRC_REPO_DEB="https://github.com/EvgeniyPatlan/etcd-packaging.git"
    ;;


    patroni)
        # versions
        PATRONI_PRODUCT=percona-patroni
        PATRONI_PRODUCT_FULL=${PATRONI_PRODUCT}-${PATRONI_VERSION}
        PATRONI_SRC_BRANCH="v${PATRONI_VERSION}"
        PATRONI_RPM_RELEASE='1'
        PATRONI_DEB_RELEASE='1'
        PATRONI_RELEASE='1'

        # urls
        PATRONI_SRC_REPO="https://github.com/zalando/patroni.git"
        PATRONI_SRC_REPO_DEB="https://github.com/cybertec-postgresql/patroni-packaging.git"
    ;;


    pg_cron)
        # versions
        PG_CRON_PRODUCT=percona-pg_cron_${PG_MAJOR}
        PG_CRON_PRODUCT_DEB=percona-pg-cron_${PG_MAJOR}
        PG_CRON_PRODUCT_FULL=${PG_CRON_PRODUCT}-${PG_CRON_VERSION}
        PG_CRON_SRC_BRANCH="v${PG_CRON_VERSION}"
        PG_CRON_RPM_RELEASE='3'
        PG_CRON_DEB_RELEASE='3'
        PG_CRON_RELEASE='3'

        # urls
        PG_CRON_SRC_REPO="https://github.com/citusdata/pg_cron.git"
        PG_CRON_SRC_REPO_DEB="https://salsa.debian.org/postgresql/pg-cron.git"
    ;;


    pg_gather)
        # versions
        PG_GATHER_PRODUCT=percona-pg_gather
        PG_GATHER_PRODUCT_DEB=percona-pg-gather
        PG_GATHER_PRODUCT_FULL=${PG_GATHER_PRODUCT}-${PG_GATHER_VERSION}
        PG_GATHER_SRC_BRANCH=${PG_VERSION}
        PG_GATHER_RPM_RELEASE='1'
        PG_GATHER_RELEASE='1'

        # urls
        PG_GATHER_SRC_URL="https://raw.githubusercontent.com/percona/support-snippets/master/postgresql/pg_gather"
    ;;


    pg_repack)
        # versions
        PG_REPACK_PRODUCT=percona-pg_repack
        PG_REPACK_PRODUCT_DEB=percona-pg-repack
        PG_REPACK_PRODUCT_FULL=${PG_REPACK_PRODUCT}-${PG_REPACK_VERSION}
        PG_REPACK_SRC_BRANCH="ver_${PG_REPACK_VERSION}"
        PG_REPACK_RPM_RELEASE='3'
        PG_REPACK_DEB_RELEASE='3'
        PG_REPACK_RELEASE='3'

        # urls
        PG_REPACK_SRC_REPO="https://github.com/reorg/pg_repack.git"
        PG_REPACK_SRC_REPO_DEB="https://salsa.debian.org/postgresql/pg-repack.git"
    ;;


    pgaudit)
        # versions
        PGAUDIT_PRODUCT=percona-pgaudit
        PGAUDIT_PRODUCT_FULL=${PGAUDIT_PRODUCT}-${PGAUDIT_VERSION}
        PGAUDIT_SRC_BRANCH=${PGAUDIT_VERSION}
        PGAUDIT_RPM_RELEASE='2'
        PGAUDIT_DEB_RELEASE='2'
        PGAUDIT_RELEASE='2'

        # urls
        PGAUDIT_SRC_REPO="https://github.com/pgaudit/pgaudit.git"
        PGAUDIT_SRC_REPO_DEB="https://salsa.debian.org/postgresql/pgaudit.git"
    ;;


    pgaudit_set_user)
        # versions
        SET_USER_PRODUCT="percona-pgaudit${PG_MAJOR}_set_user"
        SET_USER_PRODUCT_DEB="percona-pgaudit${PG_MAJOR}-set-user"
        SET_USER_PRODUCT_FULL=${SET_USER_PRODUCT}-${SET_USER_VERSION}
        SET_USER_SRC_BRANCH="REL${SET_USER_VERSION//./_}"
        SET_USER_RPM_RELEASE='3'
        SET_USER_DEB_RELEASE='3'
        SET_USER_RELEASE='4'

        # urls
        SET_USER_SRC_REPO="https://github.com/pgaudit/set_user.git"
    ;;


    pgbackrest)
        # versions
        PG_BCKREST_PRODUCT=percona-pgbackrest
        PG_BCKREST_PRODUCT_FULL=${PG_BCKREST_PRODUCT}-${PG_BCKREST_VERSION}
        PG_BCKREST_SRC_BRANCH="release/${PG_BCKREST_VERSION}"
        PG_BCKREST_DEB_TAG="debian/${PG_BCKREST_VERSION}-1"
        PG_BCKREST_RPM_RELEASE='1'
        PG_BCKREST_DEB_RELEASE='1'
        PG_BCKREST_RELEASE='1'

        # urls
        PG_BCKREST_SRC_REPO="https://github.com/pgbackrest/pgbackrest.git"
        PG_BCKREST_SRC_REPO_DEB="https://salsa.debian.org/postgresql/pgbackrest.git"
    ;;


    pgbadger)
        # versions
        PGBADGER_PRODUCT=percona-pgbadger
        PGBADGER_PRODUCT_FULL=${PGBADGER_PRODUCT}-${PGBADGER_VERSION}
        PGBADGER_SRC_BRANCH="v${PGBADGER_VERSION}"
        PGBADGER_RPM_RELEASE='1'
        PGBADGER_DEB_RELEASE='1'
        PGBADGER_RELEASE='1'

        # urls
        PGBADGER_SRC_REPO="https://github.com/darold/pgbadger.git"
    ;;


    pgbouncer)
        # versions
        PGBOUNCER_PRODUCT=percona-pgbouncer
        PGBOUNCER_PRODUCT_FULL=${PGBOUNCER_PRODUCT}-${PGBOUNCER_VERSION}
        PGBOUNCER_SRC_BRANCH="pgbouncer_${PGBOUNCER_VERSION//./_}"
        PGBOUNCER_RPM_RELEASE='1'
        PGBOUNCER_DEB_RELEASE='1'
        PGBOUNCER_RELEASE='1'

        # urls
        PGBOUNCER_SRC_REPO="https://github.com/pgbouncer/pgbouncer.git"
        PGBOUNCER_SRC_REPO_DEB="https://salsa.debian.org/postgresql/pgbouncer.git"
    ;;


    pgpool2)
        # versions
        PGPOOL2_PRODUCT=percona-pgpool-II-pg${PG_VERSION}
        PGPOOL2_PRODUCT_FULL=${PGPOOL2_PRODUCT}-${PGPOOL2_VERSION}
        PGPOOL2_SRC_BRANCH="V${PGPOOL2_VERSION//./_}"
        PGPOOL2_BUILD_BRANCH=${PG_VERSION}
        PGPOOL2_RPM_RELEASE='1'
        PGPOOL2_DEB_RELEASE='1'

        # urls
        PGPOOL2_SRC_REPO="https://git.postgresql.org/git/pgpool2.git"
        PGPOOL2_SRC_REPO_DEB="https://salsa.debian.org/postgresql/pgpool2.git"
    ;;


    pgvector)
        # versions
        PGVECTOR_PRODUCT=percona-pgvector_${PG_MAJOR}
        PGVECTOR_PRODUCT_DEB=percona-pgvector
        PGVECTOR_PRODUCT_FULL=${PGVECTOR_PRODUCT}-${PGVECTOR_VERSION}
        PGVECTOR_SRC_BRANCH="v${PGVECTOR_VERSION}"
        PGVECTOR_RPM_RELEASE='4'
        PGVECTOR_DEB_RELEASE='4'
        PGVECTOR_RELEASE='4'

        # urls
        PGVECTOR_SRC_REPO="https://github.com/pgvector/pgvector.git"
        PGVECTOR_SRC_REPO_DEB="https://salsa.debian.org/postgresql/pgvector.git"
    ;;


    postgis35)
        # versions
        POSTGIS_PRODUCT=percona-postgis
        POSTGIS_PRODUCT_FULL=${POSTGIS_PRODUCT}-${POSTGIS35_VERSION}.${POSTGIS35_MINOR}
        POSTGIS35_RELEASE='1'
        POSTGIS_SRC_BRANCH="${POSTGIS35_VERSION}.${POSTGIS35_MINOR}"
        POSTGIS_RPM_RELEASE='1'
        POSTGIS_DEB_RELEASE='1'

        # urls
        POSTGIS_SRC_REPO="https://github.com/postgis/postgis.git"
        POSTGIS_SRC_REPO_DEB="https://salsa.debian.org/debian-gis-team/postgis.git"
    ;;


    ppg-server)
        # versions
        PPG_SERVER_PRODUCT=percona-ppg-server-${PG_MAJOR}
        PPG_SERVER_VERSION=${PG_VERSION}
        PPG_SERVER_PRODUCT_FULL=${PPG_SERVER_PRODUCT}-${PPG_SERVER_VERSION}
        PPG_SERVER_SRC_BRANCH=${PG_VERSION}
        PPG_SERVER_RPM_RELEASE='2'
        PPG_SERVER_DEB_RELEASE='2'
        PPG_SERVER_RELEASE='2'

        # urls
        PPG_SERVER_SRC_REPO=${PKG_GIT_REPO}
    ;;


    ppg-server-ha)
        # versions
        PPG_SERVER_HA_PRODUCT=percona-ppg-server-ha-${PG_MAJOR}
        PPG_SERVER_HA_VERSION=${PG_VERSION}
        PPG_SERVER_HA_PRODUCT_FULL=${PPG_SERVER_HA_PRODUCT}-${PPG_SERVER_HA_VERSION}
        PPG_SERVER_HA_SRC_BRANCH=${PG_VERSION}
        PPG_SERVER_HA_RPM_RELEASE='2'
        PPG_SERVER_HA_DEB_RELEASE='2'
        PPG_SERVER_HA_RELEASE='2'

        # urls
        PPG_SERVER_HA_SRC_REPO=${PKG_GIT_REPO}
    ;;


    pysyncobj)
        # versions
        PYSYNCOBJ_PRODUCT=python3-pysyncobj
        PYSYNCOBJ_PRODUCT_FULL=${PYSYNCOBJ_PRODUCT}-${PYSYNCOBJ_VERSION}
        PYSYNCOBJ_SRC_BRANCH="${PYSYNCOBJ_VERSION}"
        PYSYNCOBJ_RPM_RELEASE='2'
        PYSYNCOBJ_DEB_RELEASE='2'
        PYSYNCOBJ_RELEASE='2'

        # urls
        PYSYNCOBJ_SRC_REPO="https://github.com/bakwc/PySyncObj.git"
        PYSYNCOBJ_PERCONA_REPO="https://github.com/Percona-Lab/python3-pysyncobj.git"
    ;;


    wal2json)
        # versions
        WAL2JSON_PRODUCT=percona-wal2json
        WAL2JSON_PRODUCT_FULL=${WAL2JSON_PRODUCT}-${WAL2JSON_VERSION}
        WAL2JSON_SRC_BRANCH="wal2json_${WAL2JSON_VERSION//./_}"
        WAL2JSON_RPM_RELEASE='2'
        WAL2JSON_DEB_RELEASE='2'
        WAL2JSON_RELEASE='2'

        # urls
        WAL2JSON_SRC_REPO="https://github.com/eulerto/wal2json.git"
        WAL2JSON_SRC_REPO_DEB="https://salsa.debian.org/postgresql/wal2json.git"
    ;;


    ydiff)
        # versions
        YDIFF_PRODUCT=python3-ydiff
        YDIFF_PRODUCT_FULL=${YDIFF_PRODUCT}-${YDIFF_VERSION}
        YDIFF_SRC_BRANCH="${YDIFF_VERSION}"
        YDIFF_RPM_RELEASE='1'
        YDIFF_DEB_RELEASE='1'
        YDIFF_RELEASE='1'

        # urls
        YDIFF_SRC_REPO="https://github.com/ymattw/ydiff.git"
    ;;
esac
