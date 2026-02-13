#!/usr/bin/env bash
set -x
# Versions and other variables
source versions.sh "pgpool2"
# Common functions
source common-functions.sh

set_changelog(){
    if [ -z $1 ]
    then
        echo "No spec file is provided"
        return
    else
        start_line=0
        while read -r line; do
            (( start_line++ ))
            if [ "$line" = "%changelog" ]
            then
                (( start_line++ ))
                echo "$start_line"
                current_date=$(date +"%a %b %d %Y")
                sed -i "$start_line,$ d" $1
                echo "* $current_date Percona Build/Release Team <eng-build@percona.com> - ${PGPOOL2_VERSION}-${PGPOOL2_RPM_RELEASE}" >> $1
                echo "- Release ${PGPOOL2_VERSION}-${PGPOOL2_RPM_RELEASE}" >> $1
                echo >> $1
                return
            fi
        done <$1
    fi
}

get_sources(){
    cd "${WORKDIR}"
    if [ "${SOURCE}" = 0 ]
    then
        echo "Sources will not be downloaded"
        return 0
    fi

    PRODUCT=percona-pgpool-II-pg${PG_VERSION}
    PRODUCT_CUT=percona-pgpool-II-${PGPOOL2_VERSION}
    PRODUCT_FULL=${PRODUCT}-${PGPOOL2_VERSION}

    echo "PRODUCT=${PRODUCT}" > pgpool2.properties
    echo "PRODUCT_FULL=${PRODUCT_FULL}" >> pgpool2.properties
    echo "PRODUCT_CUT=${PRODUCT_CUT}" >> pgpool2.properties
    echo "VERSION=${PGPOOL2_VERSION}" >> pgpool2.properties
    echo "BRANCH_NAME=$(echo ${PGPOOL2_SRC_BRANCH} | awk -F '/' '{print $(NF)}')" >> pgpool2.properties
    echo "BUILD_BRANCH=$(echo ${PGPOOL2_BUILD_BRANCH} | awk -F '/' '{print $(NF)}')" >> pgpool2.properties
    echo "BUILD_NUMBER=${BUILD_NUMBER}" >> pgpool2.properties
    echo "BUILD_ID=${BUILD_ID}" >> pgpool2.properties
    echo "PG_RELEASE=${PG_VERSION}" >> pgpool2.properties
    echo "RPM_RELEASE=${PGPOOL2_RPM_RELEASE}" >> pgpool2.properties
    echo "DEB_RELEASE=${PGPOOL2_DEB_RELEASE}" >> pgpool2.properties

    cat pgpool2.properties

    git clone "$PGPOOL2_SRC_REPO" ${PRODUCT_CUT}
    retval=$?
    if [ $retval != 0 ]
    then
        echo "There were some issues during repo cloning from github. Please retry one more time"
        exit 1
    fi
    cd ${PRODUCT_CUT}
    if [ ! -z "$PGPOOL2_SRC_BRANCH" ]
    then
        git reset --hard
        git clean -xdf
        git checkout "$PGPOOL2_SRC_BRANCH"
    fi
    REVISION=$(git rev-parse --short HEAD)
    echo "REVISION=${REVISION}" >> ${WORKDIR}/pgpool2.properties

    # get files for deb
    GIT_SSL_NO_VERIFY=true git clone ${PGPOOL2_SRC_REPO_DEB} ../pgpool2
    mv ../pgpool2/debian/ .
    wget $(echo ${PKG_GIT_REPO} | sed -re 's|github.com|raw.githubusercontent.com|; s|\.git$||')/${PGPOOL2_BUILD_BRANCH}/pgpool2/pgpool2-debian-config.patch -O debian/patches/pgpool2-debian-config.patch

    sed -i "s:PGVERSION:${PG_MAJOR}:g" debian/control.in
    sed -i "s:Source\: pgpool2:Source\: percona-pgpool2:g" debian/control.in
    sed -i "s:Package\: pgpool2:Package\: percona-pgpool2:g" debian/control.in
    sed -i "/Vcs-Git/d" debian/control.in
    sed -i "/Vcs-Browser/d" debian/control.in
    sed -i "s:Debian PostgreSQL Maintainers <team+postgresql@tracker.debian.org>:Percona Development Team <info@percona.com>:g" debian/control.in
    sed -i '/Uploaders/{N;N;N;d;}' debian/control.in
    sed -i "0,/pgpool2/ s/pgpool2.*/percona-pgpool2 (${PGPOOL2_VERSION}-${PGPOOL2_DEB_RELEASE}) stable; urgency=medium/" debian/changelog
    sed -i "84s:${PG_VERSION}:${PG_MAJOR}:" debian/control.in
    sed -i "90s:${PG_VERSION}:${PG_MAJOR}:" debian/control
    sed -i "84s:postgresql-${PG_MAJOR}:postgresql-${PG_MAJOR}|percona-postgresql-${PG_MAJOR}:" debian/control.in
    sed -i "90s:postgresql-${PG_MAJOR}:postgresql-${PG_MAJOR}|percona-postgresql-${PG_MAJOR}:" debian/control
    #sed -i 's:debhelper-compat (= 13):debhelper-compat:' debian/control
    #sed -i 's:debhelper-compat (= 13):debhelper-compat:' debian/control.in

    sed -i '/debhelper-compat (= 13)/d' debian/control
    sed -i '/debhelper-compat (= 13)/d' debian/control.in

    sed -i 's:./configure --prefix=/usr:autoreconf --force --install; ./configure --prefix=/usr:g' debian/rules

    echo "10" > debian/compat

    DEBEDITFILES=$(ls debian | grep ^pgpool2\.)
    for file in $DEBEDITFILES; do 
        cp debian/$file debian/percona-$file; 
    done 
    cat <<EOT >> debian/rules

override_dh_builddeb:
	dh_builddeb -- -Zgzip
EOT
    mv -f "debian/percona-pgpool2.tmpfile" "debian/percona-pgpool2.tmpfiles"
    echo "etc/pgpool2/aws_eip_if_cmd.sh.sample            usr/share/doc/pgpool2/examples" >> debian/percona-pgpool2.install
    echo "etc/pgpool2/aws_rtb_if_cmd.sh.sample            usr/share/doc/pgpool2/examples" >> debian/percona-pgpool2.install 

    sed -i "s:pgpool-II:percona-pgpool-II:g" src/pgpool.spec
    sed -i "s:short_name  percona-pgpool-II:short_name  pgpool-II:g" src/pgpool.spec
    sed -i "s:pgdg::g" src/pgpool.spec
    sed -i "/mv doc.ja/d" src/pgpool.spec

    sed -i "s:%patch1 -p0:#%patch1 -p0:g" src/pgpool.spec
    sed -i "s:%configure --with-pgsql=%{pghome}:libtoolize; autoreconf --force --install; %configure --with-pgsql=%{pghome}:g" src/pgpool.spec

    sed -i "s:make %{?_smp_mflags}:make:g" src/pgpool.spec

    #EDITFILES="debian/control debian/control.in debian/rules rpm/pgpool.spec"
    #for file in $EDITFILES; do
    #    sed -i "s:@@PG_REL@@:${PG_RELEASE}:g" "$file"
    #done

    #sed -i "s:@@RPM_RELEASE@@:${RPM_RELEASE}:g" rpm/pgpool.spec
    #sed -i "s:@@VERSION@@:${VERSION}:g" rpm/pgpool.spec

    set_changelog src/pgpool.spec

    sed -i 's/SPFLAGS = /SPFLAGS = -E0 /g' doc.ja/src/sgml/Makefile.am
    sed -i 's/SPFLAGS = /SPFLAGS = -E0 /g' doc.ja/src/sgml/Makefile.in
    rm src/sample/pgpool.conf.sample
    mv src/sample/pgpool.conf.sample-stream src/sample/pgpool.conf.sample

    sed -i "s|#port = 9999|#port = 5433|g" src/sample/pgpool.conf.sample
    sed -i "s|#unix_socket_directories = '/tmp'|#unix_socket_directories = '/var/run/postgresql'|g" src/sample/pgpool.conf.sample
    sed -i "s|#pcp_socket_dir = '/tmp'|#pcp_socket_dir = '/var/run/postgresql'|g" src/sample/pgpool.conf.sample
    sed -i "s|#pid_file_name = '/var/run/pgpool/pgpool.pid'|#pid_file_name = '/var/run/postgresql/pgpool.pid'|g" src/sample/pgpool.conf.sample

    cd ${WORKDIR}
    #
    source pgpool2.properties
    #
    tar --owner=0 --group=0 --exclude=.* -czf ${PRODUCT_CUT}.tar.gz ${PRODUCT_CUT}
    DATE_TIMESTAMP=$(date +%F_%H-%M-%S)
    echo "UPLOAD=UPLOAD/experimental/BUILDS/${PRODUCT}/${PRODUCT_FULL}/${PGPOOL2_SRC_BRANCH}/${REVISION}/${DATE_TIMESTAMP}/${BUILD_ID}" >> pgpool2.properties
    mkdir $WORKDIR/source_tarball
    mkdir $CURDIR/source_tarball
    cp percona-pgpool-II-*.tar.gz $WORKDIR/source_tarball
    cp percona-pgpool-II-*.tar.gz $CURDIR/source_tarball
    cd $CURDIR
    rm -rf percona-pgpool-II*
    return
}

get_openjade_devel() {
    pushd /tmp
    apt-get update
    apt-get install sudo || true
    sudo apt-get -y install libosp-dev libperl4-corelibs-perl
    sudo apt -y install dh-buildinfo
    wget http://archive.ubuntu.com/ubuntu/pool/universe/o/openjade/openjade_1.4devel1-22.dsc http://archive.ubuntu.com/ubuntu/pool/universe/o/openjade/openjade_1.4devel1.orig.tar.gz http://archive.ubuntu.com/ubuntu/pool/universe/o/openjade/openjade_1.4devel1-22.diff.gz
    dpkg-source -x openjade_1.4devel1-22.dsc
    cd openjade-1.4devel1/
    dpkg-buildpackage -rfakeroot -uc -us -b
    cd ../
    ARCH=$(uname -m)
    if [ "$ARCH" = "x86_64" ]; then
        ARCH="amd64"
    elif [ "$ARCH" = "aarch64" ]; then
        ARCH="arm64"
    fi
    sudo apt -y --allow-downgrades install ./openjade_1.4devel1-22_${ARCH}.deb ./libostyle-dev_1.4devel1-22_${ARCH}.deb ./libostyle1c2_1.4devel1-22_${ARCH}.deb
    popd
}

get_deb_sources(){
    param=$1
    echo $param
    FILE=$(basename $(find $WORKDIR/source_deb -name "percona-pgpool2*.$param" | sort | tail -n1))
    if [ -z $FILE ]
    then
        FILE=$(basename $(find $CURDIR/source_deb -name "percona-pgpool2*.$param" | sort | tail -n1))
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
    get_tar "source_tarball" "percona-pgpool-II"
    rm -fr rpmbuild
    ls | grep -v tar.gz | xargs rm -rf
    TARFILE=$(find . -name 'percona-pgpool-II*.tar.gz' | sort | tail -n1)
    SRC_DIR=${TARFILE%.tar.gz}
    #
    mkdir -vp rpmbuild/{SOURCES,SPECS,BUILD,SRPMS,RPMS}
    cp ${TARFILE} rpmbuild/SOURCES
    tar vxzf ${WORKDIR}/${TARFILE} --wildcards '*/src' --strip=1
    #
    cp -av src/redhat/* rpmbuild/SOURCES
    cp -av src/*.spec rpmbuild/SPECS
    #
    mv -fv ${TARFILE} ${WORKDIR}/rpmbuild/SOURCES
    QA_RPATHS=$(( 0x0001|0x0002|0x0010 )) rpmbuild -bs \
        --define "_topdir ${WORKDIR}/rpmbuild" \
        --define "dist .generic" \
        --define "pgpool_version ${PGPOOL2_VERSION}" \
        --define "pg_version ${PG_MAJOR}" \
        --define "pghome /usr/pgsql-${PG_MAJOR}" \
        --define "pgsql_ver ${PG_MAJOR}0" \
        --define "with-pgsql-includedir /usr/pgsql-${PG_MAJOR}/include/" \
        ${WORKDIR}/rpmbuild/SPECS/pgpool.spec
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
    SRC_RPM=$(basename $(find $WORKDIR/srpm -name 'percona-pgpool-II*.src.rpm' | sort | tail -n1))
    if [ -z $SRC_RPM ]
    then
        SRC_RPM=$(basename $(find $CURDIR/srpm -name 'percona-pgpool-II*.src.rpm' | sort | tail -n1))
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
    export LIBPQ_DIR=/usr/pgsql-${PG_VERSION}/
    export LIBRARY_PATH=/usr/pgsql-${PG_VERSION}/lib/:/usr/pgsql-${PG_VERSION}/include/
    if [[ "${RHEL}" -eq 10 ]]; then
        export QA_RPATHS=$(( 0x0001 | 0x0002 ))
    fi
    rpmbuild \
        --define "_topdir ${WORKDIR}/rpmbuild" \
        --define "dist .$OS_NAME" \
        --define "version ${PGPOOL2_VERSION}" \
        --define "pgpool_version ${PGPOOL2_VERSION}" \
        --define "pg_version ${PG_MAJOR}" \
        --define "pghome /usr/pgsql-${PG_MAJOR}" \
        --define "pgsql_ver ${PG_MAJOR}0" \
        --define "with-pgsql-includedir /usr/pgsql-${PG_MAJOR}/include/" \
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
    rm -rf percona-pgpool2*
    get_tar "source_tarball" "percona-pgpool-II"
    rm -f *.dsc *.orig.tar.gz *.debian.tar.gz *.changes
    #
    TARFILE=$(basename $(find . -name 'percona-pgpool-II*.tar.gz' | sort | tail -n1))
    DEBIAN=$(lsb_release -sc)
    ARCH=$(echo $(uname -m) | sed -e 's:i686:i386:g')
    tar -zxf "${TARFILE}"
    BUILDDIR="${TARFILE%.tar.gz}"
    cd ${BUILDDIR}
    sed -i "s|#work_dir = '/tmp'|work_dir = '/var/run/postgresql'|g" src/sample/pgpool.conf.sample
    cd ..
    tar -zcf "${TARFILE}" "${BUILDDIR}"
    tar zxf ${TARFILE}
    BUILDDIR=${TARFILE%.tar.gz}
    #

    mv ${TARFILE} percona-pgpool2_${PGPOOL2_VERSION}.orig.tar.gz
    cd ${BUILDDIR}
    sed -i '/architecture-is-64-bit/d' debian/control
    sed -i '/architecture-is-64-bit/d' debian/control.in
    rm -rf .pc
    DEBEMAIL="info@percona.com"
    dch -D unstable --force-distribution -v "${PGPOOL2_VERSION}-${PGPOOL2_DEB_RELEASE}" "Update to new percona-pgpool2 pg${PG_VERSION} version ${PGPOOL2_VERSION}"
    pg_buildext updatecontrol
    rm .git-blame-ignore-revs
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
    export ARCH=$(echo $(uname -m) | sed -e 's:i686:i386:g')
    #
    echo "DEBIAN=${OS_NAME}" >> pgpool2.properties
    echo "ARCH=${ARCH}" >> pgpool2.properties
    #
    DSC=$(basename $(find . -name '*.dsc' | sort | tail -n1))
    #
    dpkg-source -x ${DSC}
    #
    cd percona-pgpool2-${PGPOOL2_VERSION}
    sed -i "s:\. :${WORKDIR}/percona-pgpool2-${PGPOOL2_VERSION} :g" debian/rules
    dch -m -D "${OS_NAME}" --force-distribution -v "1:${PGPOOL2_VERSION}-${PGPOOL2_DEB_RELEASE}.${OS_NAME}" 'Update distribution'
    unset $(locale|cut -d= -f1)
    pg_buildext updatecontrol
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

CURDIR=$(pwd)
VERSION_FILE=$CURDIR/percona-pgpool2.properties
args=
WORKDIR=
SRPM=0
SDEB=0
RPM=0
DEB=0
SOURCE=0
TARBALL=0
REVISION=0
INSTALL=0

parse_arguments PICK-ARGS-FROM-ARGV "$@"
check_workdir
get_system "pgpool2"
#install_deps
if [ $INSTALL = 0 ]; then
    echo "Dependencies will not be installed"
else
    source install-deps.sh "pgpool2"
fi
get_sources
build_srpm
build_source_deb
build_rpm
build_deb
