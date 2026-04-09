
#!/usr/bin/env bash
set -x
# Versions and other variables
source versions.sh "postgresql-unit"
# Common functions
source common-functions.sh

get_sources(){
    cd "${WORKDIR}"
    if [ "${SOURCE}" = 0 ]
    then
        echo "Sources will not be downloaded"
        return 0
    fi

    echo "PRODUCT=${POSTGRESQL_UNIT_PRODUCT}" > postgresql-unit.properties
    echo "PRODUCT_FULL=${POSTGRESQL_UNIT_PRODUCT_FULL}" >> postgresql-unit.properties
    echo "VERSION=${POSTGRESQL_UNIT_PRODUCT_FULL}" >> postgresql-unit.properties
    echo "BUILD_NUMBER=${BUILD_NUMBER}" >> postgresql-unit.properties
    echo "BUILD_ID=${BUILD_ID}" >> postgresql-unit.properties

    git clone "$POSTGRESQL_UNIT_SRC_REPO" ${POSTGRESQL_UNIT_PRODUCT_FULL}
    retval=$?
    if [ $retval != 0 ]
    then
        echo "There were some issues during repo cloning from github. Please retry one more time"
        exit 1
    fi
    cd ${POSTGRESQL_UNIT_PRODUCT_FULL}
    if [ ! -z "$POSTGRESQL_UNIT_SRC_BRANCH" ]
    then
        git reset --hard
        git clean -xdf
        git checkout "$POSTGRESQL_UNIT_SRC_BRANCH"
        git submodule update --init
    fi
    REVISION=$(git rev-parse --short HEAD)
    echo "REVISION=${REVISION}" >> ${WORKDIR}/postgresql-unit.properties
    rm -fr debian rpm

    #git clone "$POSTGRESQL_UNIT_SRC_REPO_DEB" deb_packaging
    #mv deb_packaging/debian ./
    #cd debian/
    #for file in $(ls | grep ^postgresql-unit | grep -v postgresql-unit.conf); do
    #    mv $file "percona-$file"
    #done
    #rm -rf changelog
    #echo "$POSTGRESQL_UNIT_PRODUCT (${POSTGRESQL_UNIT_VERSION}-${POSTGRESQL_UNIT_RELEASE}) unstable; urgency=low" >> changelog
    #echo "  * Initial Release." >> changelog
    #echo " -- EvgeniyPatlan <evgeniy.patlan@percona.com> $(date -R)" >> changelog
    #rm -f control rules
    #wget ${PKG_RAW_URL}/postgresql-unit/control
    #wget ${PKG_RAW_URL}/postgresql-unit/control.in
    #wget ${PKG_RAW_URL}/postgresql-unit/rules
    #sed -i "s/@@PGMAJOR@@/${PG_MAJOR}/g" control control.in
    #echo ${PG_MAJOR} > pgversions
    #echo 10 > compat
    #cd ../
    #rm -rf deb_packaging
    mkdir rpm
    cd rpm
    wget ${PKG_RAW_URL}/postgresql-unit/rpm/percona-postgresql-unit.spec
    wget ${PKG_RAW_URL}/postgresql-unit/rpm/postgresql-unit-hamming.patch
    cd ${WORKDIR}
    #
    source postgresql-unit.properties
    #

    tar --owner=0 --group=0 -czf ${POSTGRESQL_UNIT_PRODUCT_FULL}.tar.gz ${POSTGRESQL_UNIT_PRODUCT_FULL}
    DATE_TIMESTAMP=$(date +%F_%H-%M-%S)
    echo "UPLOAD=UPLOAD/experimental/BUILDS/${POSTGRESQL_UNIT_PRODUCT}/${POSTGRESQL_UNIT_PRODUCT_FULL}/${PSM_BRANCH}/${REVISION}/${DATE_TIMESTAMP}/${BUILD_ID}" >> postgresql-unit.properties
    mkdir $WORKDIR/source_tarball
    mkdir $CURDIR/source_tarball
    cp ${POSTGRESQL_UNIT_PRODUCT_FULL}.tar.gz $WORKDIR/source_tarball
    cp ${POSTGRESQL_UNIT_PRODUCT_FULL}.tar.gz $CURDIR/source_tarball
    cd $CURDIR
    rm -rf percona-postgresql-unit*
    return
}

#get_deb_sources(){
#    param=$1
#    echo $param
#    FILE=$(basename $(find $WORKDIR/source_deb -name "percona-*postgresql-unit*.$param" | sort | tail -n1))
#    if [ -z $FILE ]
#    then
#        FILE=$(basename $(find $CURDIR/source_deb -name "percona-*postgresql-unit*.$param" | sort | tail -n1))
#        if [ -z $FILE ]
#        then
#            echo "There is no sources for build"
#            exit 1
#        else
#            cp $CURDIR/source_deb/$FILE $WORKDIR/
#        fi
#    else
#        cp $WORKDIR/source_deb/$FILE $WORKDIR/
#    fi
#    return
#}

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
    get_tar "source_tarball" "percona-postgresql-unit"
    rm -fr rpmbuild
    ls | grep -v tar.gz | xargs rm -rf
    TARFILE=$(find . -name 'percona-postgresql-unit*.tar.gz' | sort | tail -n1)
    SRC_DIR=${TARFILE%.tar.gz}
    
    mkdir -vp rpmbuild/{SOURCES,SPECS,BUILD,SRPMS,RPMS}
    tar vxzf ${WORKDIR}/${TARFILE} --wildcards '*/rpm' --strip=1
    
    cp -av rpm/* rpmbuild/SOURCES
    cp -av rpm/percona-postgresql-unit.spec rpmbuild/SPECS
    
    mv -fv ${TARFILE} ${WORKDIR}/rpmbuild/SOURCES
    rpmbuild -bs \
        --define "_topdir ${WORKDIR}/rpmbuild" \
        --define "pginstdir /usr/pgsql-${PG_MAJOR}" \
        --define "dist .generic" \
        --define "pgmajor ${PG_MAJOR}" \
        --define "version ${POSTGRESQL_UNIT_VERSION}" \
        --define "release ${POSTGRESQL_UNIT_RELEASE}" \
        rpmbuild/SPECS/percona-postgresql-unit.spec

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
    SRC_RPM=$(basename $(find $WORKDIR/srpm -name 'percona-postgresql-unit*.src.rpm' | sort | tail -n1))
    if [ -z $SRC_RPM ]
    then
        SRC_RPM=$(basename $(find $CURDIR/srpm -name 'percona-postgresql-unit*.src.rpm' | sort | tail -n1))
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

    export LIBPQ_DIR=/usr/pgsql-${PG_MAJOR}/
    export LIBRARY_PATH=/usr/pgsql-${PG_MAJOR}/lib/:/usr/pgsql-${PG_MAJOR}/include/
    rpmbuild \
        --define "_topdir ${WORKDIR}/rpmbuild" \
        --define "pginstdir /usr/pgsql-${PG_MAJOR}" \
        --define "dist .$OS_NAME" \
        --define "pgmajor ${PG_MAJOR}" \
        --define "version ${POSTGRESQL_UNIT_VERSION}" \
        --define "release ${POSTGRESQL_UNIT_RELEASE}" \
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

#build_source_deb(){
#    if [ $SDEB = 0 ]
#    then
#        echo "source deb package will not be created"
#        return;
#    fi
#    if [ "x$OS" = "xrpm" ]
#    then
#        echo "It is not possible to build source deb here"
#        exit 1
#    fi
#    rm -rf percona-postgresql-unit*
#    get_tar "source_tarball" "percona-postgresql-unit"
#    rm -f *.dsc *.orig.tar.gz *.debian.tar.gz *.changes
#    #
#    TARFILE=$(basename $(find . -name 'percona-*postgresql-unit*.tar.gz' | sort | tail -n1))
#    DEBIAN=$(lsb_release -sc)
#    ARCH=$(echo $(uname -m) | sed -e 's:i686:i386:g')
#    tar zxf ${TARFILE}
#    BUILDDIR=${TARFILE%.tar.gz}
#    #
    
#    mv ${TARFILE} ${PRODUCT}_${VERSION}.orig.tar.gz
#    cd ${BUILDDIR}
  
#    dch -D unstable --force-distribution -v "${POSTGRESQL_UNIT_VERSION}-${POSTGRESQL_UNIT_RELEASE}" "Update to new postgresql-unit version ${POSTGRESQL_UNIT_VERSION}"
#    dpkg-buildpackage -S
#    cd ../
#    mkdir -p $WORKDIR/source_deb
#    mkdir -p $CURDIR/source_deb
#    cp *.debian.tar.* $WORKDIR/source_deb
#    cp *_source.changes $WORKDIR/source_deb
#    cp *.dsc $WORKDIR/source_deb
#    cp *.orig.tar.gz $WORKDIR/source_deb
#    cp *.debian.tar.* $CURDIR/source_deb
#    cp *_source.changes $CURDIR/source_deb
#    cp *.dsc $CURDIR/source_deb
#    cp *.orig.tar.gz $CURDIR/source_deb
#}

#build_deb(){
#    if [ $DEB = 0 ]
#    then
#        echo "source deb package will not be created"
#        return;
#    fi
#    if [ "x$OS" = "xrmp" ]
#    then
#        echo "It is not possible to build source deb here"
#        exit 1
#    fi
#    for file in 'dsc' 'orig.tar.gz' 'changes' 'debian.tar*'
#    do
#        get_deb_sources $file
#    done
#    cd $WORKDIR
#    rm -fv *.deb
#    #
#    export DEBIAN=$(lsb_release -sc)
#    export ARCH=$(echo $(uname -m) | sed -e 's:i686:i386:g')
#    #
#    echo "DEBIAN=${DEBIAN}" >> postgresql-unit.properties
#    echo "ARCH=${ARCH}" >> postgresql-unit.properties

    #
#    DSC=$(basename $(find . -name '*.dsc' | sort | tail -n1))
#    #
#    dpkg-source -x ${DSC}
#    #
#    cd ${POSTGRESQL_UNIT_PRODUCT_DEB}
#    dch -m -D "${DEBIAN}" --force-distribution -v "1:${POSTGRESQL_UNIT_VERSION}-${POSTGRESQL_UNIT_RELEASE}.${DEBIAN}" 'Update distribution'
#    unset $(locale|cut -d= -f1)
#    dpkg-buildpackage -rfakeroot -us -uc -b
#    mkdir -p $CURDIR/deb
#    mkdir -p $WORKDIR/deb
#    cd $WORKDIR/
#    for file in $(ls | grep ddeb); do
#        mv "$file" "${file%.ddeb}.deb";
#    done
#    cp $WORKDIR/*.*deb $WORKDIR/deb
#    cp $WORKDIR/*.*deb $CURDIR/deb
#}

#main

CURDIR=$(pwd)
VERSION_FILE=$CURDIR/postgresql-unit.properties
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
    source install-deps.sh "postgresql-unit"
fi

get_sources
build_srpm
#build_source_deb
build_rpm
#build_deb
