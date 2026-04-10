
#!/usr/bin/env bash
set -x
# Versions and other variables
source versions.sh "ip4r"
# Common functions
source common-functions.sh

get_sources(){
    cd "${WORKDIR}"
    if [ "${SOURCE}" = 0 ]
    then
        echo "Sources will not be downloaded"
        return 0
    fi

    echo "PRODUCT=${IP4R_PRODUCT}" > ip4r.properties
    echo "PRODUCT_FULL=${IP4R_PRODUCT_FULL}" >> ip4r.properties
    echo "VERSION=${IP4R_PRODUCT_FULL}" >> ip4r.properties
    echo "BUILD_NUMBER=${BUILD_NUMBER}" >> ip4r.properties
    echo "BUILD_ID=${BUILD_ID}" >> ip4r.properties

    git clone "$IP4R_SRC_REPO" ${IP4R_PRODUCT_FULL}
    retval=$?
    if [ $retval != 0 ]
    then
        echo "There were some issues during repo cloning from github. Please retry one more time"
        exit 1
    fi
    cd ${IP4R_PRODUCT_FULL}
    if [ ! -z "$IP4R_SRC_BRANCH" ]
    then
        git reset --hard
        git clean -xdf
        git checkout "$IP4R_SRC_BRANCH"
        git submodule update --init
    fi
    REVISION=$(git rev-parse --short HEAD)
    echo "REVISION=${REVISION}" >> ${WORKDIR}/ip4r.properties
    rm -fr debian rpm

    #git clone "$IP4R_SRC_REPO_DEB" deb_packaging
    #mv deb_packaging/debian ./
    #cd debian/
    #for file in $(ls | grep ^ip4r | grep -v ip4r.conf); do
    #    mv $file "percona-$file"
    #done
    #rm -rf changelog
    #echo "$IP4R_PRODUCT (${IP4R_VERSION}-${IP4R_RELEASE}) unstable; urgency=low" >> changelog
    #echo "  * Initial Release." >> changelog
    #echo " -- EvgeniyPatlan <evgeniy.patlan@percona.com> $(date -R)" >> changelog
    #rm -f control rules
    #wget ${PKG_RAW_URL}/ip4r/control
    #wget ${PKG_RAW_URL}/ip4r/control.in
    #wget ${PKG_RAW_URL}/ip4r/rules
    #sed -i "s/@@PGMAJOR@@/${PG_MAJOR}/g" control control.in
    #echo ${PG_MAJOR} > pgversions
    #echo 10 > compat
    #cd ../
    #rm -rf deb_packaging
    mkdir rpm
    cd rpm
    wget ${PKG_RAW_URL}/ip4r/rpm/percona-ip4r.spec
    wget ${PKG_RAW_URL}/ip4r/rpm/ip4r-hamming.patch
    cd ${WORKDIR}
    #
    source ip4r.properties
    #

    tar --owner=0 --group=0 -czf ${IP4R_PRODUCT_FULL}.tar.gz ${IP4R_PRODUCT_FULL}
    DATE_TIMESTAMP=$(date +%F_%H-%M-%S)
    echo "UPLOAD=UPLOAD/experimental/BUILDS/${IP4R_PRODUCT}/${IP4R_PRODUCT_FULL}/${PSM_BRANCH}/${REVISION}/${DATE_TIMESTAMP}/${BUILD_ID}" >> ip4r.properties
    mkdir $WORKDIR/source_tarball
    mkdir $CURDIR/source_tarball
    cp ${IP4R_PRODUCT_FULL}.tar.gz $WORKDIR/source_tarball
    cp ${IP4R_PRODUCT_FULL}.tar.gz $CURDIR/source_tarball
    cd $CURDIR
    rm -rf percona-ip4r*
    return
}

#get_deb_sources(){
#    param=$1
#    echo $param
#    FILE=$(basename $(find $WORKDIR/source_deb -name "percona-*ip4r*.$param" | sort | tail -n1))
#    if [ -z $FILE ]
#    then
#        FILE=$(basename $(find $CURDIR/source_deb -name "percona-*ip4r*.$param" | sort | tail -n1))
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
    get_tar "source_tarball" "percona-ip4r"
    rm -fr rpmbuild
    ls | grep -v tar.gz | xargs rm -rf
    TARFILE=$(find . -name 'percona-ip4r*.tar.gz' | sort | tail -n1)
    SRC_DIR=${TARFILE%.tar.gz}
    
    mkdir -vp rpmbuild/{SOURCES,SPECS,BUILD,SRPMS,RPMS}
    tar vxzf ${WORKDIR}/${TARFILE} --wildcards '*/rpm' --strip=1
    
    cp -av rpm/* rpmbuild/SOURCES
    cp -av rpm/percona-ip4r.spec rpmbuild/SPECS
    
    mv -fv ${TARFILE} ${WORKDIR}/rpmbuild/SOURCES
    rpmbuild -bs \
        --define "_topdir ${WORKDIR}/rpmbuild" \
        --define "pginstdir /usr/pgsql-${PG_MAJOR}" \
        --define "dist .generic" \
        --define "pgmajor ${PG_MAJOR}" \
        --define "version ${IP4R_VERSION}" \
        --define "release ${IP4R_RELEASE}" \
        rpmbuild/SPECS/percona-ip4r.spec

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
    SRC_RPM=$(basename $(find $WORKDIR/srpm -name 'percona-ip4r*.src.rpm' | sort | tail -n1))
    if [ -z $SRC_RPM ]
    then
        SRC_RPM=$(basename $(find $CURDIR/srpm -name 'percona-ip4r*.src.rpm' | sort | tail -n1))
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
        --define "version ${IP4R_VERSION}" \
        --define "release ${IP4R_RELEASE}" \
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
#    rm -rf percona-ip4r*
#    get_tar "source_tarball" "percona-ip4r"
#    rm -f *.dsc *.orig.tar.gz *.debian.tar.gz *.changes
#    #
#    TARFILE=$(basename $(find . -name 'percona-*ip4r*.tar.gz' | sort | tail -n1))
#    DEBIAN=$(lsb_release -sc)
#    ARCH=$(echo $(uname -m) | sed -e 's:i686:i386:g')
#    tar zxf ${TARFILE}
#    BUILDDIR=${TARFILE%.tar.gz}
#    #
    
#    mv ${TARFILE} ${PRODUCT}_${VERSION}.orig.tar.gz
#    cd ${BUILDDIR}
  
#    dch -D unstable --force-distribution -v "${IP4R_VERSION}-${IP4R_RELEASE}" "Update to new ip4r version ${IP4R_VERSION}"
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
#    echo "DEBIAN=${DEBIAN}" >> ip4r.properties
#    echo "ARCH=${ARCH}" >> ip4r.properties

    #
#    DSC=$(basename $(find . -name '*.dsc' | sort | tail -n1))
#    #
#    dpkg-source -x ${DSC}
#    #
#    cd ${IP4R_PRODUCT_DEB}
#    dch -m -D "${DEBIAN}" --force-distribution -v "1:${IP4R_VERSION}-${IP4R_RELEASE}.${DEBIAN}" 'Update distribution'
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
VERSION_FILE=$CURDIR/ip4r.properties
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
    source install-deps.sh "ip4r"
fi

get_sources
build_srpm
#build_source_deb
build_rpm
#build_deb
