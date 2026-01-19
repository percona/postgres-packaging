#!/usr/bin/env bash
set -x
# Versions and other variables
source versions.sh "patroni"
# Common functions
source common-functions.sh

get_sources(){
    cd "${WORKDIR}"
    if [ "${SOURCE}" = 0 ]
    then
        echo "Sources will not be downloaded"
        return 0
    fi

    echo "PRODUCT=${PATRONI_PRODUCT}" > patroni.properties
    GIT_USER=$(echo ${PATRONI_SRC_REPO} | awk -F'/' '{print $4}')
    echo "PRODUCT_FULL=${PATRONI_PRODUCT_FULL}" >> patroni.properties
    echo "VERSION=${PSM_VER}" >> patroni.properties
    echo "BUILD_NUMBER=${BUILD_NUMBER}" >> patroni.properties
    echo "BUILD_ID=${BUILD_ID}" >> patroni.properties

    git clone ${PATRONI_SRC_REPO} ${PATRONI_PRODUCT_FULL}
    retval=$?
    if [ $retval != 0 ]
    then
        echo "There were some issues during repo cloning from github. Please retry one more time"
        exit 1
    fi
    cd ${PATRONI_PRODUCT_FULL}
    if [ ! -z "$PATRONI_SRC_BRANCH" ]
    then
        git reset --hard
        git clean -xdf
        git checkout "$PATRONI_SRC_BRANCH"
    fi
    REVISION=$(git rev-parse --short HEAD)
    echo "REVISION=${REVISION}" >> ${WORKDIR}/patroni.properties
    rm -fr debian rpm
    git clone ${PATRONI_SRC_REPO_DEB} all_packaging
    cd all_packaging
        git reset --hard
        git clean -xdf
        git checkout "1.6.5-1"
    cd ../
    mv all_packaging/DEB/debian ./
    cd debian
    rm -f rules
    wget ${PKG_RAW_URL}/patroni/rules
    rm -f control
    rm -f postinst
    wget ${PKG_RAW_URL}/patroni/control
    sed -i "s/@@PGMAJOR@@/${PG_MAJOR}/g" control
    sed -i 's:service-info-only-in-pretty-format.patch::' patches/series
    sed -i 's:patronictl-reinit-wait-rebased-1.6.0.patch::' patches/series
    sed -i "s:'sphinx_github_style':#'sphinx_github_style':g" ../docs/conf.py
    sed -i 's:-/usr/bin/sudo /:-+/:' patches/better-startup-script.patch

    export DEBIAN=$(lsb_release -sc)
    if [ "x${DEBIAN}" = "xbuster" ]; then
      sed -i 's|"members": True|"members": "True"|g' ../docs/conf.py
    fi

    git apply patches/add-sample-config.patch
    sed -i "s|9.6|${PG_MAJOR}|g" patroni.yml.sample
    mv install percona-patroni.install
    sed -i 's|patroni.yml.sample|debian/patroni.yml.sample|g' percona-patroni.install
    echo "debian/tmp/usr/lib" >> percona-patroni.install
    echo "debian/tmp/usr/bin" >> percona-patroni.install
    echo "docs/README.rst" >> percona-patroni-doc.install
    cd ../
    mkdir rpm
    mv all_packaging/RPM/* rpm/
    cd rpm
    rm -f patroni.spec
    wget ${PKG_RAW_URL}/patroni/patroni.spec
    sed -i 's:/opt/app:/opt:g' patroni.2.service
    sed -i 's:/opt/patroni/bin:/usr/bin:' patroni.2.service
    sed -i 's:/opt/patroni/etc/:/etc/patroni/:' patroni.2.service
    mv patroni.2.service patroni.service
    tar -czf patroni-customizations.tar.gz patroni.service patroni-watchdog.service postgres-telia.yml
    cd ../
    rm -rf all_packaging
    cd ${WORKDIR}
    #
    source patroni.properties
    #

    tar --owner=0 --group=0 --exclude=.* -czf ${PATRONI_PRODUCT_FULL}.tar.gz ${PATRONI_PRODUCT_FULL}
    DATE_TIMESTAMP=$(date +%F_%H-%M-%S)
    echo "UPLOAD=UPLOAD/experimental/BUILDS/${PATRONI_PRODUCT}/${PATRONI_PRODUCT_FULL}/${PATRONI_SRC_BRANCH}/${REVISION}/${DATE_TIMESTAMP}/${BUILD_ID}" >> patroni.properties
    mkdir $WORKDIR/source_tarball
    mkdir $CURDIR/source_tarball
    cp ${PATRONI_PRODUCT_FULL}.tar.gz $WORKDIR/source_tarball
    cp ${PATRONI_PRODUCT_FULL}.tar.gz $CURDIR/source_tarball
    cd $CURDIR
    rm -rf percona-patroni*
    return
}

get_deb_sources(){
    param=$1
    echo $param
    FILE=$(basename $(find $WORKDIR/source_deb -name "percona-patroni*.$param" | sort | tail -n1))
    if [ -z $FILE ]
    then
        FILE=$(basename $(find $CURDIR/source_deb -name "percona-patroni*.$param" | sort | tail -n1))
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
    get_tar "source_tarball" "percona-patroni"
    rm -fr rpmbuild
    ls | grep -v tar.gz | xargs rm -rf
    TARFILE=$(find . -name 'percona-patroni*.tar.gz' | sort | tail -n1)
    SRC_DIR=${TARFILE%.tar.gz}
    #
    mkdir -vp rpmbuild/{SOURCES,SPECS,BUILD,SRPMS,RPMS}
    tar vxzf ${WORKDIR}/${TARFILE} --wildcards '*/rpm' --strip=1
    #
    cp -av rpm/* rpmbuild/SOURCES
    cp -av rpm/patroni.spec rpmbuild/SPECS
    cp -av rpm/patches/* rpmbuild/SOURCES
    #
    mv -fv ${TARFILE} ${WORKDIR}/rpmbuild/SOURCES
    sed -i 's:.rhel7:%{dist}:' ${WORKDIR}/rpmbuild/SPECS/patroni.spec
    rpmbuild -bs \
        --define "_topdir ${WORKDIR}/rpmbuild" \
        --define "dist .generic" \
        --define "pgmajor ${PG_MAJOR}" \
        --define "version ${PATRONI_VERSION}" \
        --define "release ${PATRONI_RELEASE}" \
        rpmbuild/SPECS/patroni.spec
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
    SRC_RPM=$(basename $(find $WORKDIR/srpm -name 'percona-patroni*.src.rpm' | sort | tail -n1))
    if [ -z $SRC_RPM ]
    then
        SRC_RPM=$(basename $(find $CURDIR/srpm -name 'percona-patroni*.src.rpm' | sort | tail -n1))
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
    rm -fr rb
    mkdir -vp rb/{SOURCES,SPECS,BUILD,SRPMS,RPMS,BUILDROOT}
    cp $SRC_RPM rb/SRPMS/

    cd rb/SRPMS/
    #
    cd $WORKDIR
    RHEL=$(rpm --eval %rhel)
    ARCH=$(echo $(uname -m) | sed -e 's:i686:i386:g')
    rpmbuild \
        --define "_topdir ${WORKDIR}/rb" \
        --define "dist .$OS_NAME" \
        --define "pgmajor ${PG_MAJOR}" \
        --define "version ${PATRONI_VERSION}" \
        --define "release ${PATRONI_RELEASE}" \
        --rebuild rb/SRPMS/$SRC_RPM

    return_code=$?
    if [ $return_code != 0 ]; then
        exit $return_code
    fi
    mkdir -p ${WORKDIR}/rpm
    mkdir -p ${CURDIR}/rpm
    cp rb/RPMS/*/*.rpm ${WORKDIR}/rpm
    cp rb/RPMS/*/*.rpm ${CURDIR}/rpm
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
    rm -rf percona-patroni*
    get_tar "source_tarball" "percona-patroni"
    rm -f *.dsc *.orig.tar.gz *.debian.tar.gz *.changes
    #
    TARFILE=$(basename $(find . -name 'percona-patroni*.tar.gz' | sort | tail -n1))
    DEBIAN=$(lsb_release -sc)
    ARCH=$(echo $(uname -m) | sed -e 's:i686:i386:g')
    tar zxf ${TARFILE}
    BUILDDIR=${TARFILE%.tar.gz}
    #
    
    mv ${TARFILE} ${PATRONI_PRODUCT}_${PATRONI_VERSION}.orig.tar.gz
    cd ${BUILDDIR}

    cd debian
    rm -rf changelog
    echo "percona-patroni (${PATRONI_VERSION}-${PATRONI_RELEASE}) unstable; urgency=low" >> changelog
    echo "  * Initial Release." >> changelog
    echo " -- EvgeniyPatlan <evgeniy.patlan@percona.com> $(date -R)" >> changelog

    cd ../
    
    dch -D unstable --force-distribution -v "${PATRONI_VERSION}-${PATRONI_RELEASE}" "Update to new patroni version ${PATRONI_VERSION}"
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
    rm -rf percona-patroni*
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
    echo "DEBIAN=${DEBIAN}" >> patroni.properties
    echo "ARCH=${ARCH}" >> patroni.properties

    #
    DSC=$(basename $(find . -name '*.dsc' | sort | tail -n1))
    #
    dpkg-source -x ${DSC}
    #
    cd ${PATRONI_PRODUCT_FULL}
    sed -i 's:ExecStart=/bin/patroni /etc/patroni.yml:ExecStart=/opt/patroni/bin/patroni /etc/patroni/patroni.yml:' extras/startup-scripts/patroni.service
    dch -m -D "${DEBIAN}" --force-distribution -v "1:${PATRONI_VERSION}-${PATRONI_RELEASE}.${DEBIAN}" 'Update distribution'
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
export GIT_SSL_NO_VERIFY=1
CURDIR=$(pwd)
VERSION_FILE=$CURDIR/patroni.properties
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
    source install-deps.sh "patroni"
fi
get_sources
build_srpm
build_source_deb
build_rpm
build_deb
