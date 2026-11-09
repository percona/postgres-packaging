%global _default_patch_fuzz 2
%global debug_package %{nil}
%global sname   percona-pg_repack
%global pgmajorversion %{pgmajor}
%global pginstdir /usr/pgsql-%{pgmajorversion}

%if 0%{?rhel} >= 8 && 0%{?rhel} <= 9
%global gts_version 14
%endif

%{!?llvm:%global llvm 1}

# Propagate %%llvm into the actual build: PGXS decides whether to invoke
# clang/llvm-config based on with_llvm from the installed postgresql*-devel's
# Makefile.global, not from this spec's %%llvm. Without passing with_llvm=no
# through to make, setting %%llvm 0 here only drops the llvm BuildRequires/
# subpackage/files, while the build still tries to run clang regardless.
%if %llvm
%global with_llvm_arg %{nil}
%else
%global with_llvm_arg with_llvm=no
%endif

Summary:        Reorganize tables in PostgreSQL databases without any locks
Name:           %{sname}%{pgmajorversion}
Version:        %{version}
Release:        %{release}%{?dist}
Epoch:          1
License:        BSD
Group:          Applications/Databases
Source0:        %{sname}-%{version}.tar.gz
Patch0:         pg_repack-pg%{pgmajorversion}-makefile-pgxs.patch
URL:            https://github.com/reorg/pg_repack/
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-%(%{__id_u} -n)
Packager:       Percona Development Team <https://jira.percona.com>
Vendor:         Percona, LLC

BuildRequires:  percona-postgresql%{pgmajorversion}-devel, percona-postgresql%{pgmajorversion}
%if 0%{?gts_version}
BuildRequires:  gcc-toolset-%{gts_version}-gcc gcc-toolset-%{gts_version}-gcc-c++ gcc-toolset-%{gts_version}-annobin-plugin-gcc
%endif

BuildRequires:        readline-devel zlib-devel
%if 0%{?suse_version}
BuildRequires:        libnuma-devel
Requires:        libnuma1
%else
BuildRequires:        numactl-devel
Requires:        numactl-libs
%endif
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
Requires(post):         %{_sbindir}/update-alternatives
Requires(postun):       %{_sbindir}/update-alternatives
Provides: pg_repack
Obsoletes:        %{sname}%{pgmajorversion} < 1.4.6-2

%description
PostgreSQL extension which lets you remove bloat from tables and indexes, and
optionally restore the physical order of clustered indexes. Unlike CLUSTER and
VACUUM FULL it works online, without holding an exclusive lock on the
processed tables during processing. pg_repack is efficient to boot, with
performance comparable to using CLUSTER directly.

%if %llvm
%package llvmjit
Summary:        Just-in-time compilation support for pg_repack
Requires:        %{name}%{?_isa} = %{?epoch:%{epoch}:}%{version}-%{release}
%if 0%{?suse_version} == 1500
BuildRequires:        llvm17-devel clang17-devel
Requires:        llvm17
%endif
%if 0%{?suse_version} == 1600
BuildRequires:        llvm19-devel clang19-devel
Requires:        llvm19
%endif
%if 0%{?suse_version} > 1600
BuildRequires:        llvm-devel clang-devel
%endif
%if 0%{?amzn}
BuildRequires:        llvm-devel >= 15.0 clang-devel >= 15.0
Requires:        llvm >= 15.0
%endif
%if ( 0%{?fedora} || 0%{?rhel} >= 8 ) && !0%{?amzn}
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
%if 0%{?gts_version}
	source /opt/rh/gcc-toolset-14/enable
%endif
USE_PGXS=1 PATH=%{pginstdir}/bin/:$PATH %{__make} %{?_smp_mflags} %{with_llvm_arg}

%install
%{__rm} -rf %{buildroot}
USE_PGXS=1 PATH=%{pginstdir}/bin/:$PATH %{__make} %{with_llvm_arg} DESTDIR=%{buildroot} install

%post
update-alternatives --install /usr/bin/pg_repack pg_repack %{pginstdir}/bin/pg_repack 100

%postun
# Only on erase: on upgrade, the old package's %%postun runs after the new
# package's %%post and would remove the alternative the new one just set up.
if [ "$1" -eq 0 ]; then
    update-alternatives --remove pg_repack %{pginstdir}/bin/pg_repack
fi

%files
%defattr(644,root,root)
%doc COPYRIGHT doc/pg_repack.rst
%dir %{pginstdir}
%dir %{pginstdir}/bin
%dir %{pginstdir}/lib
%dir %{pginstdir}/share
%dir %{pginstdir}/share/extension
%attr (755,root,root) %{pginstdir}/bin/pg_repack
%attr (755,root,root) %{pginstdir}/lib/pg_repack.so
%{pginstdir}/share/extension/pg_repack--*.sql
%{pginstdir}/share/extension/pg_repack.control

%if %llvm
%files llvmjit
  %dir %{pginstdir}/lib/bitcode
  %dir %{pginstdir}/lib/bitcode/pg_repack
  %dir %{pginstdir}/lib/bitcode/pg_repack/pgut
  %{pginstdir}/lib/bitcode/pg_repack*.bc
  %{pginstdir}/lib/bitcode/pg_repack/*.bc
  %{pginstdir}/lib/bitcode/pg_repack/pgut/*.bc
%endif

%clean
%{__rm} -rf %{buildroot}

%changelog
* Tue May  5 2020 Evgeniy Patlan <evgeniy.patlan@percona.com> - 1.4.5-2
- Initial build
