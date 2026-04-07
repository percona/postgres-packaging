%global debug_package %{nil}
%global _vpath_builddir .
%global pgmajorversion %{pgmajor}
%global pgroutingmajorversion %{pgroutingmajor}
%global pname pgrouting
%global sname	percona-pgrouting_%{pgmajorversion}

Summary:	Routing functionality for PostGIS
Name:		%{sname}
Version:	%{version}
Release:	%{release}%{dist}
License:	GPLv2+
Source0:	%{sname}-%{version}.tar.gz
URL:		https://pgrouting.org/
Packager:       Percona Development Team <https://jira.percona.com>
Vendor:         Percona, LLC

BuildRequires:	cmake >= 3.12 boost-devel >= 1.56
BuildRequires:	gcc-c++ gmp-devel
%if 0%{?fedora} >= 42 || 0%{?rhel} >= 8 || 0%{?suse_version} <= 1500
BuildRequires:	perl-version
%endif
BuildRequires:	percona-postgresql%{pgmajorversion}-devel
Requires:	percona-postgresql%{pgmajorversion} percona-postgis

%description
pgRouting extends the PostGIS / PostgreSQL geospatial database to
provide geospatial routing functionality.

Advantages of the database routing approach are:

- Data and attributes can be modified by many clients, like QGIS and
uDig through JDBC, ODBC, or directly using Pl/pgSQL. The clients can
either be PCs or mobile devices)
- Data changes can be reflected instantaneously through the routing
engine. There is no need for precalculation.
- The “cost” parameter can be dynamically calculated through SQL and its
value can come from multiple fields or tables.

%prep
%setup -q -n %{sname}-%{version}

%build
%{__install} -d build
pushd build
%if 0%{?suse_version} >= 1500
cmake .. \
%else
%cmake .. \
%endif
	-DCMAKE_INSTALL_PREFIX=%{_prefix} \
	-DPOSTGRESQL_BIN=%{pginstdir}/bin \
	-DCMAKE_BUILD_TYPE=Release \
	-DBUILD_HTML=OFF -DBUILD_DOXY=OFF \
	-DLIB_SUFFIX=64

popd

%{__make} -C "%{_vpath_builddir}" %{?_smp_mflags} build

%install
%{__rm} -rf %{buildroot}
pushd build
%{__make} -C "%{_vpath_builddir}" %{?_smp_mflags} install \
	DESTDIR=%{buildroot}
popd

%post	-p /sbin/ldconfig
%postun	-p /sbin/ldconfig

%files
%defattr(644,root,root,755)
%license LICENSE
%doc README.md BOOST_LICENSE_1_0.txt
%attr(755,root,root) %{pginstdir}/lib/libpgrouting-%{pgroutingmajorversion}.so
%{pginstdir}/share/extension/%{pname}*

%changelog
* Wed Apr 01 2026 Manika Singhal <manika.singhal@percona.com> 4.0.1
- Initial build