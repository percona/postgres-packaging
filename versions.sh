#!/usr/bin/env bash

#-------------------------------------- VERSIONS OF ALL COMPONENTS --------------------------------------

PG_MAJOR=18
PG_MINOR=3
PG_VERSION=${PG_MAJOR}.${PG_MINOR}

#PG_CRON_VERSION=1.6.2
TIMESCALEDB_VERSION=2.26.0

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
    postgresql)
        # versions
        PPG_PRODUCT=percona-postgresql
        PPG_PRODUCT_FULL=${PPG_PRODUCT}-${PG_VERSION}
        PG_RELEASE='1'
        PG_SRC_BRANCH="REL_${PG_MAJOR}_${PG_MINOR}"
        PG_RPM_RELEASE='1'
        PG_DEB_RELEASE='1'

        # urls
        PG_SRC_REPO="https://git.postgresql.org/git/postgresql.git"
        PG_SRC_REPO_DEB="https://salsa.debian.org/postgresql/postgresql.git"
        PG_DOC="https://www.postgresql.org/files/documentation/pdf/${PG_MAJOR}/postgresql-${PG_MAJOR}-A4.pdf"
    ;;


    #pg_cron)
    #    # versions
    #    PG_CRON_PRODUCT=percona-pg_cron_${PG_MAJOR}
    #    PG_CRON_PRODUCT_DEB=percona-pg-cron_${PG_MAJOR}
    #    PG_CRON_PRODUCT_FULL=${PG_CRON_PRODUCT}-${PG_CRON_VERSION}
    #    PG_CRON_SRC_BRANCH="v${PG_CRON_VERSION}"
    #    PG_CRON_RPM_RELEASE='3'
    #    PG_CRON_DEB_RELEASE='3'
    #    PG_CRON_RELEASE='2'

        # urls
    #    PG_CRON_SRC_REPO="https://github.com/citusdata/pg_cron.git"
    #    PG_CRON_SRC_REPO_DEB="https://salsa.debian.org/postgresql/pg-cron.git"
    #;;


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
esac
