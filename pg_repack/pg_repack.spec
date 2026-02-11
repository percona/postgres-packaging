%global _default_patch_fuzz 2
%global debug_package %{nil}
%global sname   percona-pg_repack
%global pgmajorversion %{pgmajor}
%global pginstdir /usr/pgsql-%{pgmajorversion}

%{!?llvm:%global llvm 1}

Summary:        Reorganize tables in PostgreSQL databases without any locks
Name:           %{sname}%{pgmajorversion}
Version:        %{version}
Release:        %{release}%{?dist}
Epoch:          1
License:        BSD
Group:          Applications/Databases
Source0:        %{sname}-%{version}.tar.gz
Patch0:         pg_repack-pg%{pgmajorversion}-makefile-pgxs.patch
URL:            https://pgxn.org/dist/pg_repack/
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-%(%{__id_u} -n)
Packager:       Percona Development Team <https://jira.percona.com>
Vendor:         Percona, LLC

BuildRequires:  percona-postgresql%{pgmajorversion}-devel, percona-postgresql%{pgmajorversion}

BuildRequires:        readline-devel zlib-devel
# lz4 dependency
%if 0%{?suse_version} >= 1500
BuildRequires:        liblz4-devel
Requires:        liblz4-1
%endif
%if 0%{?rhel} || 0%{?fedora}
BuildRequires:        lz4-devel
Requires:        lz4-libs
%endif
# zstd dependency
%if 0%{?suse_version} >= 1500
BuildRequires:        libzstd-devel >= 1.4.0
Requires:        libzstd1 >= 1.4.0
%endif
%if 0%{?rhel} || 0%{?fedora}
BuildRequires:        libzstd-devel >= 1.4.0
Requires:        libzstd >= 1.4.0
%endif
%if 0%{?suse_version} >= 1500
Requires:        libopenssl3
BuildRequires:        libopenssl-3-devel
%endif
%if 0%{?fedora} >= 41 || 0%{?rhel} >= 8
Requires:        openssl-libs >= 1.1.1k
BuildRequires:        openssl-devel
%endif

Requires:       postgresql%{pgmajorversion}
Provides: pg_repack
Obsoletes:        %{sname}%{pgmajorversion} < 1.4.6-2

%description
pg_repack can re-organize tables on a postgres database without any locks so that
you can retrieve or update rows in tables being reorganized.
The module is developed to be a better alternative of CLUSTER and VACUUM FULL.

%if %llvm
%package llvmjit
Summary:        Just-in-time compilation support for pg_repack
Requires:        %{name}%{?_isa} = %{version}-%{release}
%if 0%{?suse_version} == 1500
BuildRequires:        llvm17-devel clang17-devel
Requires:        llvm17
%endif
%if 0%{?suse_version} == 1600
BuildRequires:        llvm19-devel clang19-devel
Requires:        llvm19
%endif
%if 0%{?fedora} || 0%{?rhel} >= 8
BuildRequires:        llvm-devel >= 19.0 clang-devel >= 19.0
Requires:        llvm >= 19.0
%endif

%description llvmjit
This package provides JIT support for pg_repack
%endif

%prep
%setup -q -n %{sname}-%{version}
%patch -P 0 -p0

%build
USE_PGXS=1 PATH=%{pginstdir}/bin/:$PATH %{__make} %{?_smp_mflags}

%install
%{__rm} -rf %{buildroot}
USE_PGXS=1 PATH=%{pginstdir}/bin/:$PATH %{__make} DESTDIR=%{buildroot} install

%post
update-alternatives --install /usr/bin/pg_repack pg_repack %{pginstdir}/bin/pg_repack 100

%postun
update-alternatives --remove pg_repack %{pginstdir}/bin/pg_repack

%files
%defattr(644,root,root)
%doc COPYRIGHT doc/pg_repack.rst
%attr (755,root,root) %{pginstdir}/bin/pg_repack
%attr (755,root,root) %{pginstdir}/lib/pg_repack.so
%{pginstdir}/share/extension/pg_repack--%{version}.sql
%{pginstdir}/share/extension/pg_repack.control

%if %llvm
%files llvmjit
  %{pginstdir}/lib/bitcode/pg_repack*.bc
  %{pginstdir}/lib/bitcode/pg_repack/*.bc
  %{pginstdir}/lib/bitcode/pg_repack/pgut/*.bc
%endif

%clean
%{__rm} -rf %{buildroot}

%changelog
* Tue May  5 2020 Evgeniy Patlan <evgeniy.patlan@percona.com> - 1.4.5-2
- Initial build
