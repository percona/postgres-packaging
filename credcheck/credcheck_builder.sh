#!/usr/bin/env bash
set -x
# Versions and other variables
source versions.sh "credcheck"
# Common functions
source common-functions.sh

get_sources(){
    cd "${WORKDIR}"
    if [ "${SOURCE}" = 0 ]
    then
        echo "Sources will not be downloaded"
        return 0
    fi

    echo "PRODUCT=${CREDCHECK_PRODUCT}" > credcheck.properties
    echo "PRODUCT_FULL=${CREDCHECK_PRODUCT_FULL}" >> credcheck.properties
    echo "VERSION=${CREDCHECK_VERSION}" >> credcheck.properties
    echo "BUILD_NUMBER=${BUILD_NUMBER}" >> credcheck.properties
    echo "BUILD_ID=${BUILD_ID}" >> credcheck.properties

    git clone "$CREDCHECK_SRC_REPO" ${CREDCHECK_PRODUCT_FULL}
    retval=$?
    if [ $retval != 0 ]
    then
        echo "There were some issues during repo cloning from github. Please retry one more time"
        exit 1
    fi
    cd ${CREDCHECK_PRODUCT_FULL}
    if [ ! -z "$CREDCHECK_SRC_BRANCH" ]
    then
        git reset --hard
        git clean -xdf
        git checkout "$CREDCHECK_SRC_BRANCH"
    fi
    REVISION=$(git rev-parse --short HEAD)
    echo "REVISION=${REVISION}" >> ${WORKDIR}/credcheck.properties
    rm -fr debian rpm

    git clone ${CREDCHECK_SRC_REPO_DEB} deb_packaging
    cd deb_packaging
    git checkout debian/${CREDCHECK_VERSION}-1
    cd ../
    mv deb_packaging/debian ./
    wget ${PKG_RAW_URL}/credcheck/control
    wget ${PKG_RAW_URL}/credcheck/control.in
    wget ${PKG_RAW_URL}/credcheck/rules
    sed -i "s/@@PGMAJOR@@/${PG_MAJOR}/g" control control.in

    rm -rf debian/control*
    mv control* debian/
    mv rules debian/

    echo ${PG_MAJOR} > debian/pgversions
    rm -rf deb_packaging
    mkdir rpm
    cd rpm
    wget ${PKG_RAW_URL}/credcheck/percona-credcheck.spec
    cd ${WORKDIR}
    #
    source credcheck.properties
    #

    tar --owner=0 --group=0 --exclude=.* -czf ${CREDCHECK_PRODUCT_FULL}.tar.gz ${CREDCHECK_PRODUCT_FULL}
    DATE_TIMESTAMP=$(date +%F_%H-%M-%S)
    echo "UPLOAD=UPLOAD/experimental/BUILDS/${CREDCHECK_PRODUCT}/${CREDCHECK_PRODUCT_FULL}/${CREDCHECK_SRC_BRANCH}/${REVISION}/${DATE_TIMESTAMP}/${BUILD_ID}" >> credcheck.properties
    mkdir $WORKDIR/source_tarball
    mkdir $CURDIR/source_tarball
    cp ${CREDCHECK_PRODUCT_FULL}.tar.gz $WORKDIR/source_tarball
    cp ${CREDCHECK_PRODUCT_FULL}.tar.gz $CURDIR/source_tarball
    cd $CURDIR
    rm -rf credcheck*
    return
}

get_deb_sources(){
    param=$1
    echo $param
    FILE=$(basename $(find $WORKDIR/source_deb -name "percona-credcheck*.$param" | sort | tail -n1))
    if [ -z $FILE ]
    then
        FILE=$(basename $(find $CURDIR/source_deb -name "percona-credcheck*.$param" | sort | tail -n1))
        if [ -z $FILE ]
        then
            echo "There is no sources for build"
            exit 1
        else
            cp $CURDIR/source_deb/$FILE $WORKDIR/
        fi
    else
        cp $WORKDIR/source_deb/$FILE $WORKDIR/
    fi
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
    get_tar "source_tarball" "percona-credcheck"
    rm -fr rpmbuild
    ls | grep -v tar.gz | xargs rm -rf
    TARFILE=$(find . -name 'percona-credcheck*.tar.gz' | sort | tail -n1)
    SRC_DIR=${TARFILE%.tar.gz}
    #
    mkdir -vp rpmbuild/{SOURCES,SPECS,BUILD,SRPMS,RPMS}
    tar vxzf ${WORKDIR}/${TARFILE} --wildcards '*/rpm' --strip=1
    #
    cp -av rpm/* rpmbuild/SOURCES
    cp -av rpm/percona-credcheck.spec rpmbuild/SPECS
    #
    mv -fv ${TARFILE} ${WORKDIR}/rpmbuild/SOURCES
    rpmbuild -bs \
        --define "_topdir ${WORKDIR}/rpmbuild" \
        --define "dist .generic" \
        --define "pgmajorversion ${PG_MAJOR}" \
        --define "version ${CREDCHECK_VERSION}" \
        --define "release ${CREDCHECK_RELEASE}" \
        rpmbuild/SPECS/percona-credcheck.spec
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
    SRC_RPM=$(basename $(find $WORKDIR/srpm -name 'percona-credcheck*.src.rpm' | sort | tail -n1))
    if [ -z $SRC_RPM ]
    then
        SRC_RPM=$(basename $(find $CURDIR/srpm -name 'percona-credcheck*.src.rpm' | sort | tail -n1))
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
    if [ -f /opt/rh/devtoolset-7/enable ]; then
        source /opt/rh/devtoolset-7/enable
        source /opt/rh/llvm-toolset-7/enable
    fi
    if [[ "${RHEL}" -eq 10 ]]; then
        export QA_RPATHS=0x0002
    fi
    rpmbuild \
        --define "_topdir ${WORKDIR}/rpmbuild" \
        --define "dist .$OS_NAME" \
        --define "pgmajorversion ${PG_MAJOR}" \
        --define "version ${CREDCHECK_VERSION}" \
        --define "release ${CREDCHECK_RELEASE}" \
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

build_source_deb(){
    if [ $SDEB = 0 ]
    then
        echo "source deb package will not be created"
        return;
    fi
    if [ "x$OS" = "xrpm" ]
    then
        echo "It is not possible to build source deb here"
        exit 1
    fi
    rm -rf percona-credcheck*
    get_tar "source_tarball" "percona-credcheck"
    rm -f *.dsc *.orig.tar.gz *.debian.tar.gz *.changes
    #
    TARFILE=$(basename $(find . -name 'percona-credcheck*.tar.gz' | sort | tail -n1))
    DEBIAN=$(lsb_release -sc)
    ARCH=$(echo $(uname -m) | sed -e 's:i686:i386:g')
    tar zxf ${TARFILE}
    BUILDDIR=${TARFILE%.tar.gz}

    mv ${TARFILE} ${CREDCHECK_PRODUCT}_${CREDCHECK_VERSION}.orig.tar.gz
    mv ${BUILDDIR} ${CREDCHECK_PRODUCT}_${CREDCHECK_VERSION}
    cd ${CREDCHECK_PRODUCT}_${CREDCHECK_VERSION}

    cd debian
    rm -rf changelog

    echo "percona-credcheck (${CREDCHECK_VERSION}-${CREDCHECK_RELEASE}) unstable; urgency=medium" > changelog
    echo "* Initial Release version ${CREDCHECK_VERSION}." >> changelog
    echo " -- Percona Development Team <info@percona.com>  $(date -R)" >> changelog

    cd ../

    dch -D unstable --force-distribution -v "${CREDCHECK_VERSION}-${CREDCHECK_RELEASE}" "Update to new credcheck version ${CREDCHECK_VERSION}"
    dpkg-buildpackage -S
    cd ../
    mkdir -p $WORKDIR/source_deb
    mkdir -p $CURDIR/source_deb
    cp *.debian.tar.* $WORKDIR/source_deb
    cp *_source.changes $WORKDIR/source_deb
    cp *.dsc $WORKDIR/source_deb
    cp *.orig.tar.gz $WORKDIR/source_deb
    cp *.debian.tar.* $CURDIR/source_deb
    cp *_source.changes $CURDIR/source_deb
    cp *.dsc $CURDIR/source_deb
    cp *.orig.tar.gz $CURDIR/source_deb
}

build_deb(){
    if [ $DEB = 0 ]
    then
        echo "source deb package will not be created"
        return;
    fi
    if [ "x$OS" = "xrmp" ]
    then
        echo "It is not possible to build source deb here"
        exit 1
    fi
    for file in 'dsc' 'orig.tar.gz' 'changes' 'debian.tar*'
    do
        get_deb_sources $file
    done
    cd $WORKDIR
    rm -fv *.deb
    #
    export DEBIAN=$(lsb_release -sc)
    export ARCH=$(echo $(uname -m) | sed -e 's:i686:i386:g')
    #
    echo "DEBIAN=${DEBIAN}" >> credcheck.properties
    echo "ARCH=${ARCH}" >> credcheck.properties

    #
    DSC=$(basename $(find . -name '*.dsc' | sort | tail -n1))
    #
    dpkg-source -x ${DSC}
    #
    cd ${CREDCHECK_PRODUCT}-${CREDCHECK_VERSION}
    dch -m -D "${DEBIAN}" --force-distribution -v "1:${CREDCHECK_VERSION}-${CREDCHECK_RELEASE}.${DEBIAN}" 'Update distribution'
    unset $(locale|cut -d= -f1)
    dpkg-buildpackage -rfakeroot -us -uc -b
    mkdir -p $CURDIR/deb
    mkdir -p $WORKDIR/deb
    cd $WORKDIR/
    for file in $(ls | grep ddeb); do
        mv "$file" "${file%.ddeb}.deb";
    done
    cp $WORKDIR/*.*deb $WORKDIR/deb
    cp $WORKDIR/*.*deb $CURDIR/deb
}
#main

CURDIR=$(pwd)
VERSION_FILE=$CURDIR/credcheck.properties
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
    source install-deps.sh "credcheck"
fi
get_sources
build_srpm
build_source_deb
build_rpm
build_deb
