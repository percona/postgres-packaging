#!/usr/bin/env bash

#-------------------------------------- VERSIONS OF ALL COMPONENTS --------------------------------------

PG_MAJOR=18
PG_MINOR=3
PG_VERSION=${PG_MAJOR}.${PG_MINOR}

PG_CRON_VERSION=1.6.7
TIMESCALEDB_VERSION=2.26.0
H3_PG_VERSION=4.2.3
PGROUTING_MAJOR=4.0
PGROUTING_MINOR=1
PGVECTORSCALE_VERSION=0.9.0
HLL_VERSION=2.19
PG_SIMILARITY_VERSION=1.0
RUM_VERSION=1.3.15
POSTGRESQL_UNIT_VERSION=7.10

#-------------------------------------- COMMON URLs --------------------------------------

# Github Packaging Repo
PKG_GIT_REPO="https://github.com/percona/postgres-packaging.git"
PKG_GIT_BRANCH=${PG_VERSION}-extras
PGRPMS_GIT_REPO="https://git.postgresql.org/git/pgrpms.git"

# Raw files URLs
PKG_RAW_URL="https://raw.githubusercontent.com/percona/postgres-packaging/${PKG_GIT_BRANCH}"

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


    pg_cron)
        # versions
        PG_CRON_PRODUCT=percona-pg_cron_${PG_MAJOR}
        PG_CRON_PRODUCT_DEB=percona-pg-cron_${PG_MAJOR}
        PG_CRON_PRODUCT_FULL=${PG_CRON_PRODUCT}-${PG_CRON_VERSION}
        PG_CRON_SRC_BRANCH="v${PG_CRON_VERSION}"
        PG_CRON_RPM_RELEASE='1'
        PG_CRON_DEB_RELEASE='1'
        PG_CRON_RELEASE='1'

        # urls
        PG_CRON_SRC_REPO="https://github.com/citusdata/pg_cron.git"
        PG_CRON_SRC_REPO_DEB="https://salsa.debian.org/postgresql/pg-cron.git"
    ;;


    timescaledb)
        # versions
        TIMESCALEDB_PRODUCT=percona-timescaledb_${PG_MAJOR}
        TIMESCALEDB_PRODUCT_FULL=${TIMESCALEDB_PRODUCT}-${TIMESCALEDB_VERSION}
        TIMESCALEDB_RELEASE='1'
        TIMESCALEDB_SRC_BRANCH="${TIMESCALEDB_VERSION}"
        TIMESCALEDB_RPM_RELEASE='1'

        # urls
        TIMESCALEDB_SRC_REPO="https://github.com/timescale/timescaledb.git"
    ;;

    h3-pg)
        # versions
        H3_PG_PRODUCT=percona-h3-pg_${PG_MAJOR}
        H3_PG_PRODUCT_FULL=${H3_PG_PRODUCT}-${H3_PG_VERSION}
        H3_PG_RELEASE='1'
        H3_PG_SRC_BRANCH="v${H3_PG_VERSION}"
        H3_PG_RPM_RELEASE='1'

        # urls
        H3_PG_SRC_REPO="https://github.com/postgis/h3-pg.git"
    ;;

    pgrouting)
        # versions
        PGROUTING_PRODUCT=percona-pgrouting_${PG_MAJOR}
        PGROUTING_VERSION=${PGROUTING_MAJOR}.${PGROUTING_MINOR}
        PGROUTING_PRODUCT_FULL=${PGROUTING_PRODUCT}-${PGROUTING_VERSION}
        PGROUTING_RELEASE='1'
        PGROUTING_SRC_BRANCH="v${PGROUTING_VERSION}"
        PGROUTING_RPM_RELEASE='1'

        # urls
        PGROUTING_SRC_REPO="https://github.com/pgRouting/pgrouting.git"
    ;;

    pgvectorscale)
        # versions
        PGVECTORSCALE_PRODUCT=percona-pgvectorscale_${PG_MAJOR}
        PGVECTORSCALE_PRODUCT_FULL=${PGVECTORSCALE_PRODUCT}-${PGVECTORSCALE_VERSION}
        PGVECTORSCALE_RELEASE='1'
        PGVECTORSCALE_SRC_BRANCH="${PGVECTORSCALE_VERSION}"
        PGVECTORSCALE_RPM_RELEASE='1'

        # urls
        PGVECTORSCALE_SRC_REPO="https://github.com/timescale/pgvectorscale.git"
    ;;
        
    hll)
        # versions
        HLL_PRODUCT=percona-hll_${PG_MAJOR}
        HLL_PRODUCT_FULL=${HLL_PRODUCT}-${HLL_VERSION}
        HLL_RELEASE='1'
        HLL_SRC_BRANCH="v${HLL_VERSION}"
        HLL_RPM_RELEASE='1'

        # urls
        HLL_SRC_REPO="https://github.com/citusdata/postgresql-hll.git"
    ;;

    pg_similarity)
        # versions
        PG_SIMILARITY_PRODUCT=percona-pg_similarity_${PG_MAJOR}
        PG_SIMILARITY_PRODUCT_FULL=${PG_SIMILARITY_PRODUCT}-${PG_SIMILARITY_VERSION}
        PG_SIMILARITY_RELEASE='1'
        PG_SIMILARITY_SRC_BRANCH="pg_similarity_${PG_SIMILARITY_VERSION//./_}"
        PG_SIMILARITY_RPM_RELEASE='1'

        # urls
        PG_SIMILARITY_SRC_REPO="https://github.com/eulerto/pg_similarity.git"
    ;;

    rum)
        # versions
        RUM_PRODUCT=percona-rum_${PG_MAJOR}
        RUM_PRODUCT_FULL=${RUM_PRODUCT}-${RUM_VERSION}
        RUM_RELEASE='1'
        RUM_SRC_BRANCH="${RUM_VERSION}"
        RUM_RPM_RELEASE='1'

        # urls
        RUM_SRC_REPO="https://github.com/postgrespro/rum.git"
    ;;

    postgresql-unit)
        # versions
        POSTGRESQL_UNIT_PRODUCT=percona-postgresql-unit_${PG_MAJOR}
        POSTGRESQL_UNIT_PRODUCT_FULL=${POSTGRESQL_UNIT_PRODUCT}-${POSTGRESQL_UNIT_VERSION}
        POSTGRESQL_UNIT_RELEASE='1'
        POSTGRESQL_UNIT_SRC_BRANCH="${POSTGRESQL_UNIT_VERSION}"
        POSTGRESQL_UNIT_RPM_RELEASE='1'

        # urls
        POSTGRESQL_UNIT_SRC_REPO="https://github.com/df7cb/postgresql-unit.git"
    ;;
esac
