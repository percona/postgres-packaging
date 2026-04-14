#!/usr/bin/env bash
set -x

shell_quote_string() {
  echo "$1" | sed -e 's,\([^a-zA-Z0-9/_.=-]\),\\\1,g'
}

usage () {
    cat <<EOF
Usage: $0 [OPTIONS]
    The following options may be given :
        --builddir=DIR      Absolute path to the dir where all actions will be performed
        --repo_component=COMP    Repo to be used like testing, experimental, release
        --install_deps      Install build dependencies(root privilages are required)
        --nightly           If it is set - nightly build will be performed
        --get_sources       Source will be downloaded from github
        --build_src_rpm     If it is set - src rpm will be built
        --build_src_deb     If it is set - source deb package will be built
        --build_rpm         If it is set - rpm will be built
        --build_deb         If it is set - deb will be built
        --pg_major          Postgres major version for which package will be built
        --help) usage ;;
Example $0 --builddir=/tmp/BUILD --get_sources=1 --build_src_rpm=1 --build_rpm=1
EOF
        exit 1
}

append_arg_to_args () {
  args="$args "$(shell_quote_string "$1")
}

parse_arguments() {
    pick_args=
    if test "$1" = PICK-ARGS-FROM-ARGV
    then
        pick_args=1
        shift
    fi

    for arg do
        val=$(echo "$arg" | sed -e 's;^--[^=]*=;;')
        case "$arg" in
            --builddir=*) WORKDIR="$val" ;;
            --repo_component=*) REPO_COMP="$val" ;;
            --install_deps=*) INSTALL="$val" ;;
            --nightly=*) NIGHTLY="$val" ;;
            --get_sources=*) SOURCE="$val" ;;
            --build_src_rpm=*) SRPM="$val" ;;
            --build_src_deb=*) SDEB="$val" ;;
            --build_rpm=*) RPM="$val" ;;
            --build_deb=*) DEB="$val" ;;
            --pg_major=*) PG_MAJOR="$val" ;;
            --help) usage ;;
            *)
              if test -n "$pick_args"
              then
                  append_arg_to_args "$arg"
              fi
              ;;
        esac
    done
}

check_workdir(){
    if [ "x$WORKDIR" = "x$CURDIR" ]
    then
        echo >&2 "Current directory cannot be used for building!"
        exit 1
    else
        if ! test -d "$WORKDIR"
        then
            echo >&2 "$WORKDIR is not a directory."
            exit 1
        fi
    fi
    return
}

switch_to_vault_repo() {
    sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-Linux-*
    sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-Linux-*
}

add_percona_yum_repo(){
    yum -y install ${YUM_REPO}
    percona-release disable all
    percona-release enable ppg-${PG_VERSION} ${REPO_COMP}
    return
}

add_percona_apt_repo(){
    wget ${APT_REPO}
    dpkg -i percona-release_latest.generic_all.deb
    rm -f percona-release_latest.generic_all.deb
    percona-release disable all
    percona-release enable ppg-${PG_VERSION} ${REPO_COMP}
    return
}

get_system(){
    COMPONENT=$1
    if [ -f /etc/redhat-release ]; then
        if [ "$COMPONENT" = "pgpool2" ]; then
            GLIBC_VER_TMP="$(rpm glibc -qa --qf %{VERSION})"
        fi
        RHEL=$(rpm --eval %rhel)
        ARCH=$(echo $(uname -m) | sed -e 's:i686:i386:g')
        OS_NAME="el$RHEL"
        OS="rpm"
    else
        if [ "$COMPONENT" = "pgpool2" ]; then
            GLIBC_VER_TMP="$(dpkg-query -W -f='${Version}' libc6 | awk -F'-' '{print $1}')"
        fi
        ARCH=$(uname -m)
        apt-get -y update
        apt-get -y install lsb-release
        OS_NAME="$(lsb_release -sc)"
        OS="deb"
    fi
    return
}

get_tar(){
    TARBALL=$1
    COMPONENT=$2
    TARFILE=$(basename $(find $WORKDIR/$TARBALL -name "$COMPONENT*.tar.gz" | sort | tail -n1))

    if [ -z $TARFILE ]
    then
        TARFILE=$(basename $(find $CURDIR/$TARBALL -name "$COMPONENT*.tar.gz" | sort | tail -n1))
	if [ -z $TARFILE ]
        then
            echo "There is no $TARBALL for build"
            exit 1
        else
            cp $CURDIR/$TARBALL/$TARFILE $WORKDIR/$TARFILE
        fi
    else
        cp $WORKDIR/$TARBALL/$TARFILE $WORKDIR/$TARFILE
    fi
    return
}
