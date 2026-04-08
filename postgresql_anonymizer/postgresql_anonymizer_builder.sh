#!/usr/bin/env bash
set -x
# Versions and other variables
source versions.sh "anon"
# Common functions
source common-functions.sh

get_sources(){
    cd "${WORKDIR}"
    if [ "${SOURCE}" = 0 ]
    then
        echo "Sources will not be downloaded"
        return 0
    fi

    echo "PRODUCT=${ANON_PRODUCT}" > percona-postgresql_anonymizer.properties
    echo "PRODUCT_FULL=${ANON_PRODUCT_FULL}" >> percona-postgresql_anonymizer.properties
    echo "VERSION=${ANON_VERSION}" >> percona-postgresql_anonymizer.properties
    echo "BUILD_NUMBER=${BUILD_NUMBER}" >> percona-postgresql_anonymizer.properties
    echo "BUILD_ID=${BUILD_ID}" >> percona-postgresql_anonymizer.properties
    git clone "${ANON_SRC_REPO}"
    retval=$?
    if [ $retval != 0 ]
    then
        echo "There were some issues during repo cloning from gitlab. Please retry one more time"
        exit 1
    fi
    mv postgresql_anonymizer ${ANON_PRODUCT_FULL}
    cd ${ANON_PRODUCT_FULL}
    if [ ! -z "${ANON_SRC_BRANCH}" ]
    then
        git reset --hard
        git clean -xdf
        git checkout "${ANON_SRC_BRANCH}"
    fi
    REVISION=$(git rev-parse --short HEAD)
    echo "REVISION=${REVISION}" >> ${WORKDIR}/percona-postgresql_anonymizer.properties
    rm -fr debian rpm

    mkdir rpm
    cd rpm
    wget ${PKG_RAW_URL}/postgresql_anonymizer/percona-postgresql_anonymizer.spec
    cd ../
    cd ${WORKDIR}
    #
    source percona-postgresql_anonymizer.properties
    #

    tar --owner=0 --group=0 --exclude=.git -czf ${ANON_PRODUCT_FULL}.tar.gz ${ANON_PRODUCT_FULL}
    DATE_TIMESTAMP=$(date +%F_%H-%M-%S)
    echo "UPLOAD=UPLOAD/experimental/BUILDS/${ANON_PRODUCT}/${ANON_PRODUCT_FULL}/${PSM_BRANCH}/${REVISION}/${DATE_TIMESTAMP}/${BUILD_ID}" >> percona-postgresql_anonymizer.properties
    mkdir $WORKDIR/source_tarball
    mkdir $CURDIR/source_tarball
    cp ${ANON_PRODUCT_FULL}.tar.gz $WORKDIR/source_tarball
    cp ${ANON_PRODUCT_FULL}.tar.gz $CURDIR/source_tarball
    cd $CURDIR
    rm -rf percona-postgresql_anonymizer*
    return
}

build_srpm(){
    if [ $SRPM = 0 ]
    then
        echo "SRC RPM will not be created"
        return;
    fi
    if [ "x$OS" = "xdeb" ]
    then
        echo "It is not possible to build src rpm here"
        exit 1
    fi
    cd $WORKDIR
    get_tar "source_tarball" "percona-postgresql_anonymizer"
    rm -fr rpmbuild
    ls | grep -v tar.gz | xargs rm -rf
    TARFILE=$(find . -name 'percona-postgresql_anonymizer*.tar.gz' | sort | tail -n1)
    SRC_DIR=${TARFILE%.tar.gz}
    #
    mkdir -vp rpmbuild/{SOURCES,SPECS,BUILD,SRPMS,RPMS}
    tar vxzf ${WORKDIR}/${TARFILE} --wildcards '*/rpm' --strip=1
    #
    cp -av rpm/* rpmbuild/SOURCES
    cp -av rpmbuild/SOURCES/percona-postgresql_anonymizer.spec rpmbuild/SPECS
    #
    mv -fv ${TARFILE} ${WORKDIR}/rpmbuild/SOURCES

    rpmbuild -bs \
        --define "_topdir ${WORKDIR}/rpmbuild" \
        --define "dist .generic" \
        --define "pgmajor ${PG_MAJOR}" \
        --define "version ${ANON_VERSION}" \
        --define "release ${ANON_RELEASE}" \
        --define "pginstdir /usr/pgsql-$PG_MAJOR" \
        rpmbuild/SPECS/percona-postgresql_anonymizer.spec
    mkdir -p ${WORKDIR}/srpm
    mkdir -p ${CURDIR}/srpm
    cp rpmbuild/SRPMS/*.src.rpm ${CURDIR}/srpm
    cp rpmbuild/SRPMS/*.src.rpm ${WORKDIR}/srpm
    return
}

build_rpm(){
    if [ $RPM = 0 ]
    then
        echo "RPM will not be created"
        return;
    fi
    if [ "x$OS" = "xdeb" ]
    then
        echo "It is not possible to build rpm here"
        exit 1
    fi
    SRC_RPM=$(basename $(find $WORKDIR/srpm -name 'percona-postgresql_anonymizer*.src.rpm' | sort | tail -n1))
    if [ -z $SRC_RPM ]
    then
        SRC_RPM=$(basename $(find $CURDIR/srpm -name 'percona-postgresql_anonymizer*.src.rpm' | sort | tail -n1))
        if [ -z $SRC_RPM ]
        then
            echo "There is no src rpm for build"
            echo "You can create it using key --build_src_rpm=1"
            exit 1
        else
            cp $CURDIR/srpm/$SRC_RPM $WORKDIR
        fi
    else
        cp $WORKDIR/srpm/$SRC_RPM $WORKDIR
    fi
    cd $WORKDIR
    rm -fr rpmbuild
    mkdir -vp rpmbuild/{SOURCES,SPECS,BUILD,SRPMS,RPMS}
    cp $SRC_RPM rpmbuild/SRPMS/

    cd rpmbuild/SRPMS/
    #
    cd $WORKDIR
    RHEL=$(rpm --eval %rhel)
    ARCH=$(echo $(uname -m) | sed -e 's:i686:i386:g')

    rpmbuild \
        --define "_topdir ${WORKDIR}/rpmbuild" \
        --define "dist .$OS_NAME" \
        --define "pgmajor ${PG_MAJOR}" \
        --define "version ${ANON_VERSION}" \
        --define "release ${ANON_RELEASE}" \
        --define "pginstdir /usr/pgsql-$PG_MAJOR" \
        --rebuild rpmbuild/SRPMS/$SRC_RPM

    return_code=$?
    if [ $return_code != 0 ]; then
        exit $return_code
    fi
    mkdir -p ${WORKDIR}/rpm
    mkdir -p ${CURDIR}/rpm
    cp rpmbuild/RPMS/*/*.rpm ${WORKDIR}/rpm
    cp rpmbuild/RPMS/*/*.rpm ${CURDIR}/rpm
}

#main
CURDIR=$(pwd)
VERSION_FILE=$CURDIR/percona-postgresql_anonymizer.properties
args=
WORKDIR=
SRPM=0
SDEB=0
RPM=0
DEB=0
SOURCE=0
INSTALL=0
REVISION=0
DEBUG=0
parse_arguments PICK-ARGS-FROM-ARGV "$@"

check_workdir
get_system
#install_deps
if [ $INSTALL = 0 ]; then
    echo "Dependencies will not be installed"
else
    source install-deps.sh "anon"
fi
get_sources
build_srpm
build_rpm
