%global debug_package %{nil}
%global pgmajorversion %{pgmajor}
%global pname	h3-pg
%global sname	percona-h3-pg_%{pgmajorversion}

%{!?llvm:%global llvm 1}

%if 0%{?rhel} && 0%{?rhel} == 9
%global gts_version 14
%endif

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

BuildRequires:	cmake >= 3.20 h3-devel >= 4.5.0-1
BuildRequires:	percona-postgresql%{pgmajorversion}-devel
%if 0%{?gts_version}
BuildRequires:  gcc-toolset-%{gts_version}-gcc gcc-toolset-%{gts_version}-gcc-c++ gcc-toolset-%{gts_version}-annobin-plugin-gcc
%endif

Requires:	percona-postgresql%{pgmajorversion} h3 >= 4.5.0-1

%description
This library provides PostgreSQL bindings for the H3 Core Library.

%if %llvm
%package llvmjit
Summary:	Just-in-time compilation support for h3-pg
Requires:	%{name}%{?_isa} = %{version}-%{release}
%if 0%{?suse_version} == 1500
BuildRequires:	llvm17-devel clang17-devel
Requires:	llvm17
%endif
%if 0%{?suse_version} == 1600
BuildRequires:	llvm19-devel clang19-devel
Requires:	llvm19
%endif
%if 0%{?fedora} || 0%{?rhel} >= 8
BuildRequires:	llvm-devel >= 19.0 clang-devel >= 19.0
Requires:	llvm >= 19.0
%endif

%description llvmjit
This package provides JIT support for h3-pg
%endif

%prep
%setup -q -n %{sname}-%{version}
%patch -P 0 -p0

%build
%if 0%{?gts_version}
	source /opt/rh/gcc-toolset-14/enable
%endif
%{__install} -d build
pushd build
# h3-pg cannot find the header file on Fedora, so export CFLAGS:
%if 0%{?fedora}
CFLAGS="$CFLAGS -I%{_includedir}/h3"; export CFLAGS
%endif
%if 0%{?suse_version} >= 1500
cmake -DCMAKE_BUILD_TYPE=Release .. \
%else
%cmake .. -DCMAKE_BUILD_TYPE=Release .. \
%endif
	-DPostgreSQL_CONFIG=%{pginstdir}/bin/pg_config
%cmake_build
popd

%install
%{__rm} -rf %{buildroot}
pushd build
%cmake_install
popd

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

%if %llvm
%files llvmjit
    %{pginstdir}/lib/bitcode/h3*.bc
    %{pginstdir}/lib/bitcode/h3/src/*.bc
    %{pginstdir}/lib/bitcode/h3/src/binding/*.bc
    %{pginstdir}/lib/bitcode/h3_postgis/src/*.bc
%endif

%changelog
* Mon Mar 30 2026 Manika Singhal <manika.singhal@percona.com> 4.2.3
- Initial build
