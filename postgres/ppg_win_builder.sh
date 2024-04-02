#!/bin/bash

shell_quote_string() {
  echo "$1" | sed -e 's,\([^a-zA-Z0-9/_.=-]\),\\\1,g'
}

usage () {
    cat <<EOF
Usage: $0 [OPTIONS]
    The following options may be given :
        --version               PostgreSQL version
        --help) usage ;;
Example $0 --version=16.2
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
            --version=*) PG_VERSION="$val" ;;
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

parse_arguments PICK-ARGS-FROM-ARGV "$@"

if [ -z "$PG_VERSION" ]; then
    echo "Error: Please specify Postgresql version as <PG MAJOR VERSION>.<PG_MINOR_VERSION>. For example --version=16.2"
    usage
    exit 1
fi

clean_sources(){

  if [ -d "${PG_SOURCE_DIR}" ]; then 
    echo "Cleaning up ${PG_SOURCE_DIR}"
    rm -rf ${PG_SOURCE_DIR}
  fi

  if [ -d "${PG_STAGING_DIR}" ]; then
    echo "Cleaning up ${PG_STAGING_DIR}"
    rm -rf ${PG_STAGING_DIR}
  fi

  mkdir -p ${PG_SOURCE_DIR}
  mkdir -p ${PG_STAGING_DIR}

}

prepare_sources(){

  cd ${PG_SOURCE_DIR}
  rm -f postgresql-${PG_VERSION}.tar.gz
  wget https://ftp.postgresql.org/pub/source/v${PG_VERSION}/postgresql-${PG_VERSION}.tar.gz 
  tar -xvzf postgresql-${PG_VERSION}.tar.gz

  cat <<EOT > "${PG_SOURCE_DIR}/postgresql-${PG_VERSION}/src/tools/msvc/config.pl"
# Configuration arguments for vcbuild.
use strict;
use warnings;

our \$config = {
    asserts=>0,                         # --enable-cassert
    nls=>'${PG_DEPENDENCIES_WIN_PATH}',        # --enable-nls=<path>
    perl=>'${PG_PERL_WIN_PATH}',             # --with-perl
    python=>'${PG_PYTHON_WIN_PATH}',         # --with-python=<path>
    tcl=>'${PG_TCL_WIN_PATH}',            # --with-tls=<path>
    ldap=>1,                # --with-ldap
    openssl=>'${PG_DEPENDENCIES_WIN_PATH}',     # --with-ssl=<path>
    xml=>'${PG_DEPENDENCIES_WIN_PATH}',
    xslt=>'${PG_DEPENDENCIES_WIN_PATH}',
    iconv=>'${PG_DEPENDENCIES_WIN_PATH}',
    zlib=>'${PG_DEPENDENCIES_WIN_PATH}',        # --with-zlib=<path>
    icu=>'${PG_DEPENDENCIES_WIN_PATH}',        # --with-icu=<path>
    uuid=>'${PG_DEPENDENCIES_WIN_PATH}',       # --with-uuid-ossp
    lz4=>'${PG_DEPENDENCIES_WIN_PATH}',        # --with-lz4=<path>
    zstd=>'${PG_DEPENDENCIES_WIN_PATH}'        # --with-zstd=<path>
};

1;
EOT

  cat <<EOT > "${PG_SOURCE_DIR}/postgresql-${PG_VERSION}/src/tools/msvc/buildenv.pl"
use strict;
use warnings;

\$ENV{VSINSTALLDIR} = '$PG_VS_INSTALLDIR_WIN_PATH';
\$ENV{VCINSTALLDIR} = '$PG_VS_INSTALLDIR_WIN_PATH\VC';
\$ENV{DevEnvDir} = '$PG_DEV_ENV_DIR_WIN_PATH';
\$ENV{M4} = '${PG_M4_WIN_PATH}\bin\m4.exe';
\$ENV{FLEX} = '${PG_FLEX_PATH}\bin\flex.exe';
\$ENV{CONFIG} = 'Release /p:PlatformToolset=${PLATFORM_TOOLSET}';

\$ENV{PATH} = join
(
    ';' ,
    '$PG_MSBUILDDIR_WIN_PATH\bin',
    '$PG_DEV_ENV_DIR_WIN_PATH',
    '$PG_VS_INSTALLDIR_WIN_PATH\\\\VC\\\\Tools\\\\MSVC\\\\${MSVC_TOOLSET_VERSION}\\\\bin\\\\Hostx64\\\\x64',
    '$PG_DEPENDENCIES_WIN_PATH\bin',
    '$PG_DEPENDENCIES_WIN_PATH\bin',
    '$PG_PERL_WIN_PATH\bin',
    '$PG_FLEX_PATH\bin',
    '$PG_PYTHON_WIN_PATH',
    '$PG_TCL_WIN_PATH\bin',
    \$ENV{PATH}
);

\$ENV{INCLUDE} = join
(
    ';',
    '$PG_VS_INSTALLDIR_WIN_PATH\\\\VC\\\\Tools\\\\MSVC\\\\${MSVC_TOOLSET_VERSION}\\\\altmfc\\\\include',
    '$PG_VS_INSTALLDIR_WIN_PATH\\\\VC\\\\Tools\\\\MSVC\\\\${MSVC_TOOLSET_VERSION}\\\\include',
    '$PG_DEPENDENCIES_WIN_PATH\include',
    '$PG_DEPENDENCIES_WIN_PATH\include',
    \$ENV{INCLUDE}
);

\$ENV{LIB} = join
(
    ';',
    '$PG_VS_INSTALLDIR_WIN_PATH\\\\VC\\\\Tools\\\\MSVC\\\\${MSVC_TOOLSET_VERSION}\\\\altmfc\lib',
    '$PG_VS_INSTALLDIR_WIN_PATH\\\\VC\\\\Tools\\\\MSVC\\\\${MSVC_TOOLSET_VERSION}\\\\lib\onecore\x64',
    '$PG_DEPENDENCIES_WIN_PATH\lib',
    '$PG_DEPENDENCIES_WIN_PATH\lib',
    \$ENV{LIB}
);

\$ENV{LIBPATH} = join
(
    ';',
    '$PG_VS_INSTALLDIR_WIN_PATH\\\\VC\\\\Tools\\\\MSVC\\\\${MSVC_TOOLSET_VERSION}\\\\altmfc\lib'
);

1;
EOT

}

build_server(){

  cd ${PG_SOURCE_DIR}/postgresql-${PG_VERSION}/src/tools/msvc

  ./build.bat RELEASE
  ./install.bat ${PG_STAGING_DIR} 

  cp ${PG_DEPENDENCIES}/bin64/icu*.dll ${PG_STAGING_DIR}/bin/
  cp ${PG_DEPENDENCIES}/bin/libintl-9.dll ${PG_STAGING_DIR}/bin/
  cp ${PG_DEPENDENCIES}/bin/libcrypto-3-x64.dll ${PG_STAGING_DIR}/bin/
  cp ${PG_DEPENDENCIES}/bin/libssl-3-x64.dll ${PG_STAGING_DIR}/bin/
  cp ${PG_DEPENDENCIES}/bin/libwinpthread-1.dll ${PG_STAGING_DIR}/bin/
  cp ${PG_DEPENDENCIES}/bin/libiconv-2.dll ${PG_STAGING_DIR}/bin/
  cp ${PG_DEPENDENCIES}/bin/libxml2.dll ${PG_STAGING_DIR}/bin/
  cp ${PG_DEPENDENCIES}/bin/liblz4.dll ${PG_STAGING_DIR}/bin/
  cp ${PG_DEPENDENCIES}/bin/libzstd.dll ${PG_STAGING_DIR}/bin/
  cp ${PG_DEPENDENCIES}/bin/zlib1.dll ${PG_STAGING_DIR}/bin/

  mkdir -p ${PG_STAGING_DIR}/lib
  cp ${PG_DEPENDENCIES}/lib/liblz4.lib ${PG_STAGING_DIR}/lib
  cp ${PG_DEPENDENCIES}/lib/libssl.lib ${PG_STAGING_DIR}/lib
  cp ${PG_DEPENDENCIES}/lib/libcrypto.lib ${PG_STAGING_DIR}/lib
  cp ${PG_DEPENDENCIES}/lib/iconv.lib ${PG_STAGING_DIR}/lib
  cp ${PG_DEPENDENCIES}/lib/liblz4.lib ${PG_STAGING_DIR}/lib
  cp ${PG_DEPENDENCIES}/lib/libintl.lib ${PG_STAGING_DIR}/lib
  cp ${PG_DEPENDENCIES}/lib/libxml2.lib ${PG_STAGING_DIR}/lib
  cp ${PG_DEPENDENCIES}/lib/zlib.lib ${PG_STAGING_DIR}/lib
  cp ${PG_DEPENDENCIES}/lib/libcurl.lib ${PG_STAGING_DIR}/lib
  cp ${PG_DEPENDENCIES}/lib/libzstd.lib ${PG_STAGING_DIR}/lib

  # Copy the third party headers except GPL license headers
  mkdir -p ${PG_STAGING_CACHE}/3rdinclude/
  cp -rp ${PG_DEPENDENCIES}/include/*.h ${PG_STAGING_CACHE}/3rdinclude/ 
  find ${PG_STAGING_CACHE}/3rdinclude/ -name "*.h" -exec grep -rwl "GNU General Public License" {} \; -exec rm  {} \; || echo "ERROR: Failed to remove the header files with GPL license."
  cp -rp ${PG_STAGING_CACHE}/3rdinclude/* ${PG_STAGING_DIR}/include
  rm -rf ${PG_STAGING_CACHE}/3rdinclude

  mkdir -p ${PG_STAGING_DIR}/include/openssl
  cp -rp ${PG_DEPENDENCIES}/include/openssl/*.h ${PG_STAGING_DIR}/include/openssl/
  mkdir -p ${PG_STAGING_DIR}/include/libxml
  cp -rp ${PG_DEPENDENCIES}/include/libxml2/libxml/*.h ${PG_STAGING_DIR}/include/libxml/
  mkdir -p ${PG_STAGING_DIR}/include/libxslt
  cp -rp ${PG_DEPENDENCIES}/include/libxslt/*.h ${PG_STAGING_DIR}/include/libxslt/
  mkdir -p ${PG_STAGING_DIR}/include/unicode
  cp -rp ${PG_DEPENDENCIES}/include/unicode/*.h ${PG_STAGING_DIR}/include/unicode/
  cp -rp ${PG_DEPENDENCIES}/include/lz4.h ${PG_STAGING_DIR}/include/
  cp -rp ${PG_DEPENDENCIES}/include/zstd.h ${PG_STAGING_DIR}/include/

  mkdir -p ${PG_STAGING_DIR}/installer
  cp ${PG_DEPENDENCIES}/vcredist/vcredist_x64.exe ${PG_STAGING_DIR}/installer

}

build_installer_utilities(){

  cat <<EOT > "vc-build-x64.bat"
REM Setting Visual Studio Environment
CALL "$PG_VS_INSTALLDIR_WIN_PATH\VC\Auxiliary\Build\vcvarsall.bat" amd64

@SET PGBUILD=$PG_DEPENDENCIES_WIN_PATH
@SET OPENSSL=$PG_DEPENDENCIES_WIN_PATH
@SET INCLUDE=$PG_DEPENDENCIES_WIN_PATH\\include;%INCLUDE%
@SET LIB=$PG_DEPENDENCIES_WIN_PATH\\lib;%LIB%
@SET PGDIR=$PG_STAGING_DIR

REM batch file splits single argument containing "=" sign into two
REM Following code handles this scenario

IF "%2" == "UPGRADE" GOTO upgrade
IF "%~3" == "" ( SET VAR3=""
) ELSE (
SET VAR3="%3=%4"
)
msbuild %1 /p:Configuration=%2 %VAR3%
GOTO end

:upgrade
devenv /upgrade %1

:end

EOT

  mkdir -p ${PG_STAGING_DIR}/installer/server

  rm -rf createuser
  mkdir -p createuser
  cp vc-build-x64.bat createuser/
  cd createuser/
  wget https://raw.githubusercontent.com/percona/postgres-packaging/${PG_VERSION}/postgres/scripts/windows/createuser/createuser.vcproj
  wget https://raw.githubusercontent.com/percona/postgres-packaging/${PG_VERSION}/postgres/scripts/windows/createuser/createuser.cpp

  ./vc-build-x64.bat createuser.vcproj UPGRADE
  ./vc-build-x64.bat createuser.vcxproj Release
  mv x64/Release/createuser.exe ${PG_STAGING_DIR}/installer/server
  cd ../

  rm -rf validateuser
  mkdir -p validateuser
  cp vc-build-x64.bat validateuser/
  cd validateuser
  wget https://raw.githubusercontent.com/percona/postgres-packaging/${PG_VERSION}/postgres/scripts/windows/validateuser/validateuser.cpp
  wget https://raw.githubusercontent.com/percona/postgres-packaging/${PG_VERSION}/postgres/scripts/windows/validateuser/validateuser.vcproj

  ./vc-build-x64.bat validateuser.vcproj UPGRADE
  ./vc-build-x64.bat validateuser.vcxproj Release
  mv x64/Release/validateuser.exe ${PG_STAGING_DIR}/installer/server
  cd ..

  rm -rf getlocales
  mkdir -p getlocales
  cp vc-build-x64.bat getlocales/
  cd getlocales
  wget https://raw.githubusercontent.com/percona/postgres-packaging/${PG_VERSION}/postgres/scripts/windows/getlocales/getlocales.cpp
  wget https://raw.githubusercontent.com/percona/postgres-packaging/${PG_VERSION}/postgres/scripts/windows/getlocales/getlocales.vcproj

  ./vc-build-x64.bat getlocales.vcproj UPGRADE
  ./vc-build-x64.bat getlocales.vcxproj Release
  mv x64/Release/getlocales.exe ${PG_STAGING_DIR}/installer/server
  cd ..

  rm -f vc-build-x64.bat
}

replacePlaceHolder() {

  if [ -z "$3" ]; then
    echo "Error: Some parameter value is empty."
    exit
  fi
  sed -e "s^$1^$2^g" $3 > "/tmp/$$.tmp"
  mv /tmp/$$.tmp $3
}

generate_installer_xml() {

  PLATFORM=$1
  if [ ! -z $PLATFORM ]; then
    PLATFORM_SUFFIX="-$PLATFORM"
  else
    echo "PLATFORM variable not defined"
    PLATFORM_SUFFIX=""
  fi

  # Get the catalog version number
  PG_CATALOG_VERSION=`cat $PG_SOURCE_DIR/postgresql-${PG_VERSION}/src/include/catalog/catversion.h |grep "#define CATALOG_VERSION_NO" | awk '{print $3}'`
  PG_CONTROL_VERSION=`cat $PG_SOURCE_DIR/postgresql-${PG_VERSION}/src/include/catalog/pg_control.h |grep "#define PG_CONTROL_VERSION" | awk '{print $3}'`

  echo "PG_CATALOG_VERSION=$PG_CATALOG_VERSION"
  echo "PG_CONTROL_VERSION=$PG_CONTROL_VERSION"

  wget https://raw.githubusercontent.com/percona/postgres-packaging/${PG_VERSION}/postgres/installer.xml.in
  wget https://raw.githubusercontent.com/percona/postgres-packaging/${PG_VERSION}/postgres/pgserver.xml.in

  mkdir -p i18n
  cd i18n
  wget https://raw.githubusercontent.com/percona/postgres-packaging/${PG_VERSION}/postgres/i18n/en.lng
  cd -

  for file in {installer,pgserver}
  do
    filename=${file}${PLATFORM_SUFFIX}.xml
    if [ -f $filename ]; then
      rm -f $filename
    fi

    if [ ! -z $PLATFORM ]; then
      cp ${file}.xml.in $filename
      replacePlaceHolder @@PLATFORM@@ "$PLATFORM" $filename
    else
      cp ${file}.xml.in $filename
    fi

    WIN64MODE="1"        
    SERVICESUFFIX="-x64"
    replacePlaceHolder @@WINDIR@@ $PLATFORM $filename
    replacePlaceHolder @@VCREDIST_BUNDLED_VER@@ $VCREDIST_VERSION $filename
    pg_catlog_version_file="$PG_SOURCE_DIR/postgresql-${PG_VERSION}/src/include/catalog/catversion.h"
    PG_CATALOG_VERSION=`cat $pg_catlog_version_file |grep "#define CATALOG_VERSION_NO" | awk '{print $3}'`
    pg_control_file="$PG_SOURCE_DIR/postgresql-${PG_VERSION}/src/include/catalog/pg_control.h"
    PG_CONTROL_VERSION=`cat $pg_control_file |grep "#define PG_CONTROL_VERSION" | awk '{print $3}'`
    replacePlaceHolder PG_MAJOR_VERSION $PG_MAJOR_VERSION $filename
    replacePlaceHolder PG_MINOR_VERSION $PG_MINOR_VERSION $filename
    replacePlaceHolder PG_PACKAGE_VERSION $PG_PACKAGE_VERSION $filename
    replacePlaceHolder PG_STAGING_DIR $PG_STAGING_DIR $filename
    replacePlaceHolder PG_CATALOG_VERSION $PG_CATALOG_VERSION $filename
    replacePlaceHolder PG_CONTROL_VERSION $PG_CONTROL_VERSION $filename
    #replacePlaceHolder PERL_PACKAGE_VERSION $PERL_PACKAGE_VERSION  $filename
    #replacePlaceHolder PERL_PACKAGE_VERSION_WINDOWS64 $PERL_PACKAGE_VERSION_WINDOWS64  $filename
    #replacePlaceHolder PYTHON_PACKAGE_VERSION $PYTHON_PACKAGE_VERSION $filename
    #replacePlaceHolder TCL_PACKAGE_VERSION $TCL_PACKAGE_VERSION $filename
 

    if [ ! -z $PLATFORM ]; then
      PG_DATETIME_SETTING="64-bit integers"
      replacePlaceHolder @@PG_DATETIME_SETTING@@ "$PG_DATETIME_SETTING" $filename
      replacePlaceHolder @@WIN64MODE@@ "$WIN64MODE" $filename
      replacePlaceHolder @@SERVICE_SUFFIX@@ "$SERVICESUFFIX" $filename
    fi
  done
}

build_installer(){

  cd $WD
  if [[ -d "$PG_STAGING_DIR/symbols" ]]; then
    mv $PG_STAGING_DIR/symbols $PG_STAGING_DIR/debug_symbols
  fi
  
  # Setup the installer scripts.
  mkdir -p $PG_STAGING_DIR/installer/server
  cd $PG_STAGING_DIR/installer
  wget https://raw.githubusercontent.com/percona/postgres-packaging/${PG_VERSION}/postgres/scripts/windows/prerun_checks.vbs
  cd -
  cd $PG_STAGING_DIR/installer/server
  wget https://raw.githubusercontent.com/percona/postgres-packaging/${PG_VERSION}/postgres/scripts/windows/initcluster.vbs
  wget https://raw.githubusercontent.com/percona/postgres-packaging/${PG_VERSION}/postgres/scripts/windows/startupcfg.vbs
  wget https://raw.githubusercontent.com/percona/postgres-packaging/${PG_VERSION}/postgres/scripts/windows/createshortcuts_server.vbs
  wget https://raw.githubusercontent.com/percona/postgres-packaging/${PG_VERSION}/postgres/scripts/windows/createshortcuts_clt.vbs
  wget https://raw.githubusercontent.com/percona/postgres-packaging/${PG_VERSION}/postgres/scripts/windows/startserver.vbs
  wget https://raw.githubusercontent.com/percona/postgres-packaging/${PG_VERSION}/postgres/scripts/windows/loadmodules.vbs
  cd -

  cd $PG_STAGING_DIR
  wget https://raw.githubusercontent.com/percona/postgres-packaging/${PG_VERSION}/postgres/server_license.txt
  cd -

  mkdir -p $PG_STAGING_DIR/doc/postgresql/html
  cd $PG_STAGING_DIR/doc
  wget https://raw.githubusercontent.com/percona/postgres-packaging/${PG_VERSION}/postgres/resources/installation-notes.html
  cd -
  cd $PG_STAGING_DIR/doc/postgresql/html
  wget https://raw.githubusercontent.com/percona/postgres-packaging/${PG_VERSION}/postgres/resources/index.html
  wget https://raw.githubusercontent.com/percona/postgres-packaging/${PG_VERSION}/postgres/resources/release.html
  cd -

  # Copy in the menu pick images and XDG items
  mkdir -p $PG_STAGING_DIR/scripts/images
  cd $PG_STAGING_DIR/scripts/images
  wget https://raw.githubusercontent.com/percona/postgres-packaging/${PG_VERSION}/postgres/resources/pg-help.ico
  wget https://raw.githubusercontent.com/percona/postgres-packaging/${PG_VERSION}/postgres/resources/pg-reload.ico
  wget https://raw.githubusercontent.com/percona/postgres-packaging/${PG_VERSION}/postgres/resources/pg-psql.ico
  cd -

  rm -rf $WD/resources
  mkdir -p $WD/resources
  cd $WD/resources
  wget https://raw.githubusercontent.com/percona/postgres-packaging/${PG_VERSION}/postgres/resources/pg-splash.png
  wget https://raw.githubusercontent.com/percona/postgres-packaging/${PG_VERSION}/postgres/resources/pg-side.png
  cd -

  # Copy the launch scripts
  cd $PG_STAGING_DIR/scripts
  wget https://raw.githubusercontent.com/percona/postgres-packaging/${PG_VERSION}/postgres/scripts/windows/serverctl.vbs
  wget https://raw.githubusercontent.com/percona/postgres-packaging/${PG_VERSION}/postgres/scripts/windows/runpsql.bat
  cd -

  # Prepare the installer XML file
  generate_installer_xml "windows-x64"

  # Build the installer
  "$INSTALLBUILDER_BIN" build installer-windows-x64.xml windows

  # Rename the installer
  mv $WD/percona-build/percona-postgresql-$PG_PACKAGE_VERSION-windows-installer.exe $WD/percona-build/percona-postgresql-$PG_PACKAGE_VERSION-windows-x64.exe

  # Sign the installer
  #win32_sign "percona-postgresql-$PG_PACKAGE_VERSION-windows-x64.exe"
}

###################
# Main
###################
WD=`pwd`
PG_SOURCE_DIR=$WD/pg_sources/postgresql-server
PG_STAGING_DIR=$WD/pg_staging/windows-x64/server
PG_STAGING_CACHE=$WD/staging_cache

PG_DEPENDENCIES=/c/pg-dependencies
PG_DEPENDENCIES_WIN_PATH=C:\\\\pg-dependencies
PG_PERL_WIN_PATH=C:\\\\Users\\\\Administrator\\\\AppData\\\\Local\\\\ActiveState\\\\cache\\\\8d8aef4d
PG_PERL_MSYS_PATH=/C/pg-dependencies/bin:/C/Users/Administrator/AppData/Local/ActiveState/cache/8d8aef4d
PG_PYTHON_WIN_PATH=C:\\\\Users\\\\Administrator\\\\AppData\\\\Local\\\\ActiveState\\\\cache\\\\5997d1a4
PG_TCL_WIN_PATH=C:\\\\ActiveTcl

PG_NASM_MSYS_PATH=/C/NASM
VS_WINTOOLKIT_MSYS_PATH="'/C/Program Files (x86)'/Windows Kits/10/bin/10.0.22621.0/x64"

PG_MSBUILDDIR_WIN_PATH="C:\\\\Program Files\\\\Microsoft Visual Studio\\\\2022\\\\Community\\\\MSBuild\\\\Current"
PG_VS_INSTALLDIR_WIN_PATH="C:\\\\Program Files\\\\Microsoft Visual Studio\\\\2022\\\\Community"
PG_DEV_ENV_DIR_WIN_PATH=${PG_VS_INSTALLDIR_WIN_PATH}\\\\Common7\\\\IDE
PG_M4_WIN_PATH=C:\\\\m4
PG_FLEX_PATH=C:\\\\flex
PLATFORM_TOOLSET=v143
MSVC_TOOLSET_VERSION=14.39.33519
INSTALLBUILDER_BIN=/c/installbuilder/bin/builder
VCREDIST_VERSION=14.0.24247
#PG_VERSION=16.2
PG_BUILD_NUMBBER=1
PG_PACKAGE_VERSION=$PG_VERSION-$PG_BUILD_NUMBBER

PG_MAJOR_VERSION=$(echo $PG_VERSION | cut -f1 -d'.')
PG_MINOR_VERSION=$(echo $PG_VERSION | cut -f2 -d'.')

export PATH="${PG_PERL_MSYS_PATH}/bin:${PG_NASM_MSYS_PATH}:${VS_WINTOOLKIT_MSYS_PATH}:${PATH}"
clean_sources
prepare_sources
build_server

build_installer_utilities
build_installer
