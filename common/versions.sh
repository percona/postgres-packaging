#!/usr/bin/env bash

#PG_VERSION=@@PG_VERSION@@

ETCD_VERSION=3.5.26
PGBADGER_VERSION=13.2
PGBOUNCER_VERSION=1.25.1
PYSYNCOBJ_VERSION=0.3.10
YDIFF_VERSION=1.4.2
H3_VERSION=4.4.1

#-------------------------------------- COMMON URLs --------------------------------------

# Github Packaging Repo
PKG_GIT_REPO="https://github.com/percona/postgres-packaging.git"
PKG_GIT_BRANCH=main
PGRPMS_GIT_REPO="https://git.postgresql.org/git/pgrpms.git"

# Raw files URLs
PKG_RAW_URL="https://raw.githubusercontent.com/Manika-Percona/postgres-packaging/${PKG_GIT_BRANCH}"

# Percona Repos
YUM_REPO="https://repo.percona.com/yum/percona-release-latest.noarch.rpm"
APT_REPO="https://repo.percona.com/apt/percona-release_latest.generic_all.deb"

case "$1" in
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


    pysyncobj)
        # versions
        PYSYNCOBJ_PRODUCT=python3-pysyncobj
        PYSYNCOBJ_PRODUCT_FULL=${PYSYNCOBJ_PRODUCT}-${PYSYNCOBJ_VERSION}
        PYSYNCOBJ_SRC_BRANCH="${PYSYNCOBJ_VERSION}"
        PYSYNCOBJ_RPM_RELEASE='2'
        PYSYNCOBJ_DEB_RELEASE='2'
        PYSYNCOBJ_RELEASE='3'

        # urls
        PYSYNCOBJ_SRC_REPO="https://github.com/bakwc/PySyncObj.git"
        PYSYNCOBJ_PERCONA_REPO="https://github.com/Percona-Lab/python3-pysyncobj.git"
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

    h3)
        # versions
        H3_PRODUCT=h3
        H3_PRODUCT_FULL=${H3_PRODUCT}-${H3_VERSION}
        H3_SRC_BRANCH="v${H3_VERSION}"
        H3_RPM_RELEASE='1'
        H3_DEB_RELEASE='1'
        H3_RELEASE='1'

        # urls
        H3_SRC_REPO="https://github.com/uber/h3.git"
    ;;
esac
