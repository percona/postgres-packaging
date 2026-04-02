%global debug_package %{nil}
%global pgmajorversion %{pgmajor}
%global pname	h3-pg
%global sname	percona-h3-pg_%{pgmajorversion}

Summary:	Uber's H3 Hexagonal Hierarchical Geospatial Indexing System in PostgreSQL
Name:		%{sname}
Version:	%{version}
Release:	%{release}%{dist}
License:	Apache
URL:		https://github.com/postgis/%{pname}
Packager:       Percona Development Team <https://jira.percona.com>
Vendor:         Percona, LLC
Source0:	%{sname}-%{version}.tar.gz
Patch0:		%{pname}-useosh3.patch

BuildRequires:	cmake >= 3.20 h3-devel >= 4.2.0-3
BuildRequires:	percona-postgresql%{pgmajorversion}-devel

Requires:	percona-postgresql%{pgmajorversion} h3 >= 4.2.0-3

%description
This library provides PostgreSQL bindings for the H3 Core Library.

%prep
%setup -q -n %{sname}-%{version}
%patch -P 0 -p0

%build
export CFLAGS="$CFLAGS -I%{_includedir}/h3"

%cmake \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_SHARED_LIBS=ON \
  -DPostgreSQL_CONFIG=%{pginstdir}/bin/pg_config

%cmake_build

%install
%{__rm} -rf %{buildroot}
%cmake_install

%post	-p /sbin/ldconfig
%postun	-p /sbin/ldconfig

%files
%defattr(644,root,root,755)
%license LICENSE
%doc README.md
%{pginstdir}/lib/h3.so
%{pginstdir}/lib/h3_postgis.so
%{pginstdir}/share/extension/h3*.sql
%{pginstdir}/share/extension/h3.control
%{pginstdir}/share/extension/h3_postgis.control

%changelog
* Mon Mar 30 2026 Manika Singhal <manika.singhal@percona.com> 4.2.3
- Initial build
