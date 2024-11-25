%undefine _debugsource_packages
%global postgismajorversion 3.4
%global postgissomajorversion 3
%global pgmajorversion 17
%global postgiscurrmajorversion %(echo %{postgismajorversion}|tr -d '.')
%global sname	postgis

%pgdg_set_gis_variables

# Override some variables. PostGIS 3.3 is best served with GeOS 3.11,
# GDAL 3.4 and PROJ 9.0:
%global geosfullversion %geos311fullversion
%global geosmajorversion %geos311majorversion
%global geosinstdir %geos311instdir
%global gdalfullversion %gdal35fullversion
%global gdalmajorversion %gdal35majorversion
%global gdalinstdir %gdal35instdir
%global projmajorversion %proj90majorversion
%global projfullversion %proj90fullversion
%global projinstdir %proj90instdir

# Override PROJ major version on RHEL 7.
# libspatialite 4.3 does not build against 8.0.0 as of March 2021.
# Also use GDAL 3.4
%if 0%{?rhel} && 0%{?rhel} == 7
%global gdalfullversion %gdal34fullversion
%global gdalmajorversion %gdal34majorversion
%global gdalinstdir %gdal34instdir
%global projmajorversion 72
%global projfullversion 7.2.1
%global projinstdir /usr/proj%{projmajorversion}
%endif

%if 0%{?rhel} == 7 || 0%{?suse_version} >= 1315
%global libspatialitemajorversion	43
%else
%global libspatialitemajorversion	50
%endif

%ifarch ppc64 ppc64le s390 s390x armv7hl
 %if 0%{?rhel} && 0%{?rhel} == 7
  %{!?llvm:%global llvm 0}
 %else
  %{!?llvm:%global llvm 1}
 %endif
%else
 %{!?llvm:%global llvm 1}
%endif

%{!?utils:%global	utils 1}
%{!?shp2pgsqlgui:%global	shp2pgsqlgui 1}
%if 0%{?suse_version} >= 1315
%{!?raster:%global     raster 0}
%else
%{!?raster:%global     raster 1}
%endif

%if 0%{?fedora} >= 30 || 0%{?rhel} >= 7 || 0%{?suse_version} >= 1315
%ifnarch ppc64 ppc64le
# TODO
%{!?sfcgal:%global     sfcgal 1}
%else
%{!?sfcgal:%global     sfcgal 0}
%endif
%else
%{!?sfcgal:%global    sfcgal 0}
%endif

Summary:	Geographic Information Systems Extensions to PostgreSQL
Name:		percona-postgis%{postgiscurrmajorversion}_%{pgmajorversion}
Version:	%{postgismajorversion}.0
Release:	1%{?dist}
License:	GPLv2+
Source0:	percona-postgis-%{version}.tar.gz
Source2:        https://download.osgeo.org/postgis/docs/postgis-%{version}-en.pdf
Source4:	%{sname}%{postgiscurrmajorversion}-filter-requires-perl-Pg.sh

URL:		https://www.postgis.net/

BuildRequires:	percona-postgresql%{pgmajorversion}-devel geos%{geosmajorversion}-devel >= %{geosfullversion}
BuildRequires:	libgeotiff%{libgeotiffmajorversion}-devel
BuildRequires:	pgdg-srpm-macros >= 1.0.25 pcre-devel gmp-devel
%if 0%{?suse_version} >= 1500
Requires:	libgmp10
%else
Requires:	gmp
%endif
%if 0%{?suse_version}
%if 0%{?suse_version} >= 1315
BuildRequires:	libjson-c-devel proj%{projmajorversion}-devel >= %{projfullversion}
%endif
%else
BuildRequires:	proj%{projmajorversion}-devel >= %{projfullversion} flex json-c-devel
%endif
BuildRequires:	libxml2-devel
%if %{shp2pgsqlgui}
BuildRequires:	gtk2-devel > 2.8.0
%endif
%if %{sfcgal}
BuildRequires:	SFCGAL-devel SFCGAL
Requires:	SFCGAL
%endif
%if %{raster}
BuildRequires:	gdal%{gdalmajorversion}-devel >= %{gdalfullversion}
%endif


%if 0%{?fedora} >= 31 || 0%{?rhel} >= 8
BuildRequires:	protobuf-c-devel >= 1.1.0
%endif

Requires:	percona-postgresql%{pgmajorversion} geos%{geosmajorversion} >= %{geosfullversion}
Requires:	percona-postgresql%{pgmajorversion}-contrib proj%{projmajorversion} >= %{projfullversion}
Requires:	libgeotiff%{libgeotiffmajorversion}
Requires:	hdf5

%if %{raster}
Requires:	gdal%{gdalmajorversion}-libs >= %{gdalfullversion}
%endif

Requires:	pcre
%if 0%{?suse_version} >= 1315
Requires:	libjson-c5
Requires:	libxerces-c-3_1
%else
Requires:	json-c xerces-c
%endif
Requires(post):	%{_sbindir}/update-alternatives

%if 0%{?fedora} >= 31 || 0%{?rhel} >= 8
Requires:	protobuf-c >= 1.1.0
%endif

Provides:	%{sname} = %{version}-%{release}
Obsoletes:	%{sname}3_%{pgmajorversion} <= %{postgismajorversion}.0-1
Provides:	%{sname}3_%{pgmajorversion} => %{postgismajorversion}.0

%description
PostGIS adds support for geographic objects to the PostgreSQL object-relational
database. In effect, PostGIS "spatially enables" the PostgreSQL server,
allowing it to be used as a backend spatial database for geographic information
systems (GIS), much like ESRI's SDE or Oracle's Spatial extension. PostGIS
follows the OpenGIS "Simple Features Specification for SQL" and has been
certified as compliant with the "Types and Functions" profile.

%package client
Summary:	Client tools and their libraries of PostGIS
Requires:	%{name}%{?_isa} = %{version}-%{release}
Provides:	%{sname}-client = %{version}-%{release}
Obsoletes:	%{sname}2_%{pgmajorversion}-client <= %{postgismajorversion}.2-1
Provides:	%{sname}2_%{pgmajorversion}-client => %{postgismajorversion}.0

%description client
The %{name}-client package contains the client tools and their libraries
of PostGIS.

%package devel
Summary:	Development headers and libraries for PostGIS
Requires:	%{name}%{?_isa} = %{version}-%{release}
Provides:	%{sname}-devel = %{version}-%{release}
Obsoletes:	%{sname}2_%{pgmajorversion}-devel <= %{postgismajorversion}.2-1
Provides:	%{sname}2_%{pgmajorversion}-devel => %{postgismajorversion}.0

%description devel
The %{name}-devel package contains the header files and libraries
needed to compile C or C++ applications which will directly interact
with PostGIS.

%package docs
Summary:	Extra documentation for PostGIS
Obsoletes:	%{sname}2_%{pgmajorversion}-docs <= %{postgismajorversion}.2-1
Provides:	%{sname}2_%{pgmajorversion}-docs => %{postgismajorversion}.0

%description docs
The %{name}-docs package includes PDF documentation of PostGIS.

%if %{shp2pgsqlgui}
%package	gui
Summary:	GUI for PostGIS
Requires:	%{name}%{?_isa} = %{version}-%{release}

%description	gui
The %{name}-gui package provides a gui for PostGIS.
%endif

%if %utils
%package utils
Summary:	The utils for PostGIS
Requires:	%{name} = %{version}-%{release} perl-DBD-Pg
Provides:	%{sname}-utils = %{version}-%{release}
Obsoletes:	%{sname}2_%{pgmajorversion}-utils <= %{postgismajorversion}.2-1
Provides:	%{sname}2_%{pgmajorversion}-utils => %{postgismajorversion}.0

%description utils
The %{name}-utils package provides the utilities for PostGIS.
%endif

%global __perl_requires %{SOURCE4}

%if %llvm
%package llvmjit
Summary:	Just-in-time compilation support for postgis33
Requires:	%{name}%{?_isa} = %{version}-%{release}
#%%if 0%%{?rhel} && 0%%{?rhel} == 7
#%%ifarch aarch64
#Requires:	llvm-toolset-7.0-llvm >= 7.0.1
#%%else
#Requires:	llvm5.0 >= 5.0
#%%endif
#%%endif
%if 0%{?suse_version} >= 1315 && 0%{?suse_version} <= 1499
BuildRequires:  llvm6-devel clang6-devel
#Requires:	llvm6
%endif
%if 0%{?suse_version} >= 1500
BuildRequires:  llvm13-devel clang13-devel
#Requires:	llvm13
%endif
#%%if 0%%{?fedora} || 0%%{?rhel} >= 8
#Requires:	llvm => 12.0
#%%endif

%description llvmjit
This packages provides JIT support for postgis33
%endif


%prep
%setup -q -n percona-postgis-%{version}
%{__cp} -p %{SOURCE2} .
# Copy .pdf file to top directory before installing.
%{__cp} -p %{SOURCE2} %{sname}-%{version}.pdf

%build
LDFLAGS="-Wl,-rpath,%{geosinstdir}/lib64 ${LDFLAGS}" ; export LDFLAGS
LDFLAGS="-Wl,-rpath,%{projinstdir}/lib ${LDFLAGS}" ; export LDFLAGS
LDFLAGS="-Wl,-rpath,%{libspatialiteinstdir}/lib ${LDFLAGS}" ; export LDFLAGS
SHLIB_LINK="$SHLIB_LINK -Wl,-rpath,%{geosinstdir}/lib64" ; export SHLIB_LINK
SFCGAL_LDFLAGS="$SFCGAL_LDFLAGS -L/usr/lib64"; export SFCGAL_LDFLAGS

LDFLAGS="$LDFLAGS -L%{geosinstdir}/lib64 -lgeos_c -L%{projinstdir}/lib64 -L%{gdalinstdir}/lib -L%{libgeotiffinstdir}/lib -ltiff -L/usr/lib64"; export LDFLAGS
CFLAGS="$CFLAGS -I%{gdalinstdir}/include"; export CFLAGS
export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:%{projinstdir}/lib64/pkgconfig

sh autogen.sh
autoconf

%configure --with-pgconfig=%{pginstdir}/bin/pg_config \
	--bindir=%{pginstdir}/bin/ \
	--with-projdir=%{projinstdir} \
	--datadir=%{pginstdir}/share/ \
	--enable-lto \
%if !%raster
	--without-raster \
%endif
%if %{sfcgal}
	--with-sfcgal=%{_bindir}/sfcgal-config \
%endif
%if %{shp2pgsqlgui}
	--with-gui \
%endif
%if 0%{?fedora} >= 31 || 0%{?rhel} >= 8
	--with-protobuf \
%else
	--without-protobuf \
%endif
	--enable-rpath --libdir=%{pginstdir}/lib \
	--with-geosconfig=%{geosinstdir}/bin/geos-config \
	--with-gdalconfig=%{gdalinstdir}/bin/gdal-config

SHLIB_LINK="$SHLIB_LINK" %{__make} LPATH=`%{pginstdir}/bin/pg_config --pkglibdir` shlib="%{sname}-%{postgissomajorversion}.so"

%{__make} %{?_smp_mflags} -C extensions

%if %utils
 SHLIB_LINK="$SHLIB_LINK" %{__make} %{?_smp_mflags} -C utils
%endif

%install
%{__rm} -rf %{buildroot}
SHLIB_LINK="$SHLIB_LINK" %{__make} %{?_smp_mflags} install DESTDIR=%{buildroot}

%if %utils
%{__install} -d %{buildroot}%{_datadir}/%{name}
%{__install} -m 644 utils/*.pl %{buildroot}%{_datadir}/%{name}
%endif

# Create alternatives entries for common binaries
%post client
%{_sbindir}/update-alternatives --install %{_bindir}/pgsql2shp postgis-pgsql2shp %{pginstdir}/bin/pgsql2shp %{pgmajorversion}0
%{_sbindir}/update-alternatives --install %{_bindir}/shp2pgsql postgis-shp2pgsql %{pginstdir}/bin/shp2pgsql %{pgmajorversion}0

# Drop alternatives entries for common binaries and man files
%postun client
if [ "$1" -eq 0 ]
  then
	# Only remove these links if the package is completely removed from the system (vs.just being upgraded)
	%{_sbindir}/update-alternatives --remove postgis-pgsql2shp	%{_bindir}/bin/pgsql2shp
	%{_sbindir}/update-alternatives --remove postgis-shp2pgsql	%{_bindir}/bin/shp2pgsql
fi

%clean
%{__rm} -rf %{buildroot}

%files
%defattr(-,root,root)
%doc COPYING CREDITS NEWS TODO README.%{sname} doc/html loader/README.* doc/%{sname}.xml doc/ZMSgeoms.txt
%license LICENSE.TXT
%{pginstdir}/bin/postgis
%{pginstdir}/bin/postgis_restore
%{pginstdir}/doc/extension/README.address_standardizer
%{pginstdir}/share/contrib/%{sname}-%{postgismajorversion}/postgis.sql
%{pginstdir}/share/contrib/%{sname}-%{postgismajorversion}/postgis_comments.sql
%{pginstdir}/share/contrib/%{sname}-%{postgismajorversion}/postgis_upgrade*.sql
%{pginstdir}/share/contrib/%{sname}-%{postgismajorversion}/uninstall_postgis.sql
%{pginstdir}/share/contrib/%{sname}-%{postgismajorversion}/legacy*.sql
%{pginstdir}/share/contrib/%{sname}-%{postgismajorversion}/*topology*.sql
%{pginstdir}/lib/%{sname}-%{postgissomajorversion}.so
%{pginstdir}/share/extension/%{sname}-*.sql
%if %{sfcgal}
%{pginstdir}/lib/%{sname}_sfcgal-%{postgissomajorversion}.so
%{pginstdir}/share/extension/%{sname}_sfcgal*.sql
%{pginstdir}/share/extension/%{sname}_sfcgal.control
%{pginstdir}/share/contrib/%{sname}-%{postgismajorversion}/sfcgal.sql
%{pginstdir}/share/contrib/%{sname}-%{postgismajorversion}/sfcgal_upgrade.sql
%{pginstdir}/share/contrib/%{sname}-%{postgismajorversion}/uninstall_sfcgal.sql
%endif
%{pginstdir}/share/extension/%{sname}.control
%{pginstdir}/lib/%{sname}_topology-%{postgissomajorversion}.so
%{pginstdir}/lib/address_standardizer-3.so
%{pginstdir}/share/extension/address_standardizer*.sql
%{pginstdir}/share/extension/address_standardizer*.control
%{pginstdir}/share/contrib/%{sname}-%{postgismajorversion}/sfcgal_comments.sql
%{pginstdir}/share/contrib/%{sname}-%{postgismajorversion}/raster_comments.sql
%{pginstdir}/share/contrib/%{sname}-%{postgismajorversion}/spatial*.sql
%{pginstdir}/share/extension/%{sname}_tiger_geocoder*.sql
%{pginstdir}/share/extension/%{sname}_tiger_geocoder.control
%{pginstdir}/share/extension/%{sname}_topology-*.sql
%{pginstdir}/share/extension/%{sname}_topology.control
%{pginstdir}/share/contrib/%{sname}-%{postgismajorversion}/uninstall_legacy.sql
%if %{raster}
%{pginstdir}/share/contrib/postgis-%{postgismajorversion}/rtpostgis.sql
%{pginstdir}/share/contrib/postgis-%{postgismajorversion}/rtpostgis_legacy.sql
%{pginstdir}/share/contrib/postgis-%{postgismajorversion}/rtpostgis_upgrade.sql
%{pginstdir}/share/contrib/postgis-%{postgismajorversion}/uninstall_rtpostgis.sql
%{pginstdir}/share/extension/postgis_raster*.sql
%{pginstdir}/lib/postgis_raster-%{postgissomajorversion}.so
%{pginstdir}/share/extension/%{sname}_raster.control
%endif
%{_mandir}/man1/%{sname}*

%files client
%defattr(644,root,root)
%attr(755,root,root) %{pginstdir}/bin/pgsql2shp
%if %{raster}
%attr(755,root,root) %{pginstdir}/bin/raster2pgsql
%endif
%attr(755,root,root) %{pginstdir}/bin/shp2pgsql
%attr(755,root,root) %{pginstdir}/bin/pgtopo_export
%attr(755,root,root) %{pginstdir}/bin/pgtopo_import
%{_mandir}/man1/pgsql2shp*
%{_mandir}/man1/pgtopo_*
%{_mandir}/man1/shp2pgsql*

%files devel
%defattr(644,root,root)

%files docs
%defattr(-,root,root)
%doc %{sname}-%{version}.pdf

%if %shp2pgsqlgui
%files gui
%defattr(-,root,root)
%{pginstdir}/bin/shp2pgsql-gui
%{pginstdir}/share/applications/shp2pgsql-gui.desktop
%{pginstdir}/share/icons/hicolor/*/apps/shp2pgsql-gui.png
%endif

%if %llvm
%files llvmjit
   %{pginstdir}/lib/bitcode/address_standardizer*.bc
   %{pginstdir}/lib/bitcode/address_standardizer-3/*.bc
   %{pginstdir}/lib/bitcode/postgis-%{postgissomajorversion}*.bc
   %{pginstdir}/lib/bitcode/postgis_topology-%{postgissomajorversion}/*.bc
   %{pginstdir}/lib/bitcode/postgis_topology-%{postgissomajorversion}*.bc
   %{pginstdir}/lib/bitcode/postgis-%{postgissomajorversion}/*.bc
   %if %raster
    %{pginstdir}/lib/bitcode/postgis_raster-%{postgissomajorversion}*.bc
    %{pginstdir}/lib/bitcode/postgis_raster-%{postgissomajorversion}/*.bc
   %endif
   %if %{sfcgal}
   %{pginstdir}/lib/bitcode/postgis_sfcgal-%{postgissomajorversion}.index.bc
   %{pginstdir}/lib/bitcode/postgis_sfcgal-%{postgissomajorversion}/lwgeom_sfcgal.bc
   %endif
%endif

%if %utils
%files utils
%defattr(-,root,root)
%doc utils/README
%attr(755,root,root) %{_datadir}/%{name}/*.pl
%endif

%changelog
* Mon Dec 05 2022 Devrim Gündüz <devrim@gunduz.org>-  3.3.2-2
- Get rid of AT and switch to GCC on RHEL 7 - ppc64le

* Sun Nov 13 2022 Devrim Gunduz <devrim@gunduz.org> - 3.3.2-1
- Update to 3.3.2, per changes described at:
  https://git.osgeo.org/gitea/postgis/postgis/raw/tag/3.3.2/NEWS

* Fri Oct 14 2022 Devrim Gunduz <devrim@gunduz.org> - 3.3.1-2
- Use GDAL 3.4 on RHEL 7

* Sat Sep 10 2022 Devrim Gunduz <devrim@gunduz.org> - 3.3.1-1
- Update to 3.3.1 (needed only for PostgreSQL 15 beta 4)

* Sun Aug 28 2022 Devrim Gunduz <devrim@gunduz.org> - 3.3.0-1
- Update to 3.3.0

* Tue Aug 23 2022 Devrim Gunduz <devrim@gunduz.org> - 3.3.0rc2-1
- Update to 3.3.0 rc2

* Fri Aug 19 2022 Devrim Gunduz <devrim@gunduz.org> - 3.3.0rc1-1
- Update to 3.3.0 rc1
- Use PROJ 9.0.X

* Thu Jul 14 2022 Devrim Gunduz <devrim@gunduz.org> - 3.3.0beta2-1
- Update to 3.3.0 beta2

* Wed Jul 13 2022 Devrim Gunduz <devrim@gunduz.org> - 3.3.0beta1-1
- Initial cut for PostGIS 3.3.0 beta 1
