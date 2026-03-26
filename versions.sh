#!/usr/bin/env bash

PG_MAJOR=16
PG_MINOR=13
PG_VERSION=${PG_MAJOR}.${PG_MINOR}

TIMESCALEDB_VERSION=2.26.0
POSTGIS33_VERSION=3.3
POSTGIS33_MINOR=9

#-------------------------------------- COMMON URLs --------------------------------------

# Github Packaging Repo
PKG_GIT_REPO="https://github.com/percona/postgres-packaging.git"
PKG_GIT_BRANCH=${PG_VERSION}-extras
PGRPMS_GIT_REPO="https://git.postgresql.org/git/pgrpms.git"

# Raw files URLs
PKG_RAW_URL="https://raw.githubusercontent.com/percona/postgres-packaging/${PG_VERSION}-extras"

# Percona Repos
YUM_REPO="https://repo.percona.com/yum/percona-release-latest.noarch.rpm"
APT_REPO="https://repo.percona.com/apt/percona-release_latest.generic_all.deb"

case "$1" in
    timescaledb)
        # versions
        TIMESCALEDB_PRODUCT=percona-timescaledb_${PG_MAJOR}
        TIMESCALEDB_PRODUCT_DEB=percona-timescaledb-${PG_MAJOR}
        TIMESCALEDB_PRODUCT_FULL=${TIMESCALEDB_PRODUCT}_${TIMESCALEDB_VERSION}
        TIMESCALEDB_RELEASE='1'
        TIMESCALEDB_SRC_BRANCH="${TIMESCALEDB_VERSION}"
        TIMESCALEDB_RPM_RELEASE='1'
        TIMESCALEDB_DEB_RELEASE='1'

        # urls
        TIMESCALEDB_SRC_REPO="https://github.com/timescale/timescaledb.git"
        TIMESCALEDB_SRC_REPO_DEB="https://salsa.debian.org/postgresql/timescaledb.git"
    ;;


    postgis33)
        # versions
        POSTGIS_PRODUCT=percona-postgis
        POSTGIS_PRODUCT_FULL=${POSTGIS_PRODUCT}-${POSTGIS33_VERSION}.${POSTGIS33_MINOR}
        POSTGIS33_RELEASE='1'
        POSTGIS_SRC_BRANCH="${POSTGIS33_VERSION}.${POSTGIS33_MINOR}"
        POSTGIS_RPM_RELEASE='1'
        POSTGIS_DEB_RELEASE='1'

        # urls
        POSTGIS_SRC_REPO="https://github.com/postgis/postgis.git"
        POSTGIS_SRC_REPO_DEB="https://salsa.debian.org/debian-gis-team/postgis.git"
    ;;

    #pg_cron)
        # versions
    #    PG_CRON_PRODUCT=percona-pg_cron_${PG_MAJOR}
    #    PG_CRON_PRODUCT_DEB=percona-pg-cron_${PG_MAJOR}
    #    PG_CRON_PRODUCT_FULL=${PG_CRON_PRODUCT}-${PG_CRON_VERSION}
    #    PG_CRON_SRC_BRANCH="v${PG_CRON_VERSION}"
    #    PG_CRON_RPM_RELEASE='3'
    #    PG_CRON_DEB_RELEASE='3'
    #    PG_CRON_RELEASE='3'

        # urls
    #    PG_CRON_SRC_REPO="https://github.com/citusdata/pg_cron.git"
    #    PG_CRON_SRC_REPO_DEB="https://salsa.debian.org/postgresql/pg-cron.git"
    #;;

esac
