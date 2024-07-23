%global sname	timescaledb
%global pgmajorversion 12

Summary:	PostgreSQL based time-series database
Name:		percona-%{sname}_%{pgmajorversion}
Version:	2.15.3
Release:	1%{?dist}
License:	Apache
Source0:	percona-%{sname}-%{version}.tar.gz	
Packager:       Percona Development Team <https://jira.percona.com>
Vendor:         Percona, LLC

%if 0%{?rhel} && 0%{?rhel} == 7
Patch1:		%{sname}-cmake3-rhel7.patch
%endif
URL:		https://github.com/timescale/timescaledb
BuildRequires:	percona-postgresql%{pgmajorversion}-devel
BuildRequires:	openssl-devel
%if 0%{?rhel} && 0%{?rhel} == 7
BuildRequires:	cmake3
%else
BuildRequires:	cmake >= 3.4
%endif

Requires:	percona-postgresql%{pgmajorversion}-server

%description
TimescaleDB is an open-source database designed to make SQL scalable for
time-series data. It is engineered up from PostgreSQL, providing automatic
partitioning across time and space (partitioning key), as well as full SQL
support.

%prep
%setup -q -n percona-%{sname}-%{version}
%if 0%{?rhel} && 0%{?rhel} == 7
%patch -P 1 -p0
%endif

# Build only the portions that have Apache Licence, and disable telemetry:
export PATH=%{pginstdir}/bin:$PATH
./bootstrap -DAPACHE_ONLY=1 -DSEND_TELEMETRY_DEFAULT=NO \
	-DPROJECT_INSTALL_METHOD=pgdg -DREGRESS_CHECKS=OFF

%build
export PATH=%{pginstdir}/bin:$PATH
%ifarch ppc64 ppc64le
%if 0%{?rhel} && 0%{?rhel} == 7
	CFLAGS="-O3 -mcpu=$PPC_MCPU -mtune=$PPC_MTUNE"
%endif
%else
	CFLAGS="$RPM_OPT_FLAGS -fPIC -pie"
	CXXFLAGS="$RPM_OPT_FLAGS -fPIC -pie"
	export CFLAGS
	export CXXFLAGS
%endif

cd build; %{__make}

%install
export PATH=%{pginstdir}/bin:$PATH
cd build; %{__make} DESTDIR=%{buildroot} install
%{__rm} -f %{buildroot}/%{pginstdir}/lib/pgxs/src/test/perl/*pm

%files
%defattr(-, root, root)
%doc README.md
%license LICENSE-APACHE
%{pginstdir}/lib/%{sname}*.so
%{pginstdir}/share/extension/%{sname}--*.sql
%{pginstdir}/share/extension/%{sname}.control

%changelog
* Wed Jun  26 2024 Muhammad Aqeel <muhammad.aqeel@percona.com> 2.15.2
- Initial build
