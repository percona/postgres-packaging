%{!?llvm:%global llvm 1}
%{!?runselftest:%global runselftest 0}

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

%if 0%{?rhel} >= 8 && 0%{?rhel} <= 9
%global gts_version 14
%endif
%global sname percona-credcheck
%global pginstdir /usr/pgsql-%{pgmajorversion}

Summary:        PostgreSQL username/password checks
Name:           %{sname}%{pgmajorversion}
Version:        %{version}
Release:        %{release}%{?dist}
License:        PostgreSQL
URL:            https://github.com/HexaCluster/credcheck
Source0:        %{sname}-%{version}.tar.gz
Epoch:          1
Packager:       Percona Development Team <https://jira.percona.com>
Vendor:         Percona, LLC

BuildRequires:  percona-postgresql%{pgmajorversion}-devel
BuildRequires:  krb5-devel
%if 0%{?gts_version}
BuildRequires:  gcc-toolset-%{gts_version}-gcc gcc-toolset-%{gts_version}-gcc-c++ gcc-toolset-%{gts_version}-annobin-plugin-gcc
%endif
%if 0%{?suse_version} >= 1500
Requires:       libopenssl3
BuildRequires:  libopenssl-3-devel
%endif
%if 0%{?fedora} >= 41 || 0%{?rhel} >= 8 || 0%{?amzn}
Requires:       openssl-libs >= 1.1.1k
BuildRequires:  openssl-devel
%endif

Requires:       percona-postgresql%{pgmajorversion}-server
%if %runselftest
BuildRequires:  percona-postgresql%{pgmajorversion}-server pgdg-srpm-macros >= 2.0.0
# prove and IPC::Run, for the TAP test
BuildRequires:  perl(Test::Harness) perl(IPC::Run)
%endif

%description
The credcheck PostgreSQL extension provides few general credential checks,
which will be evaluated during the user creation, during the password change
and user renaming. By using this extension, we can define a set of rules to
allow a specific set of credentials, and a set of rules to reject a certain
type of credentials. This extension is developed based on the PostgreSQL's
check_password_hook hook.

%if %llvm
%package llvmjit
Summary:        Just-in-time compilation support for credcheck
Requires:       %{name}%{?_isa} = %{epoch}:%{version}-%{release}
%if 0%{?suse_version} == 1500
BuildRequires:  llvm17-devel clang17-devel
Requires:       llvm17
%endif
%if 0%{?suse_version} == 1600
BuildRequires:  llvm19-devel clang19-devel
Requires:       llvm19
%endif
%if 0%{?suse_version} > 1600
BuildRequires:  llvm-devel clang-devel
%endif
%if ( 0%{?fedora} || 0%{?rhel} >= 8 ) && !0%{?amzn}
BuildRequires:  llvm-devel >= 19.0 clang-devel >= 19.0
Requires:       llvm >= 19.0
%endif

%description llvmjit
This package provides JIT support for credcheck
%endif


%prep
%setup -q -n %{sname}-%{version}


%build
%if 0%{?gts_version}
source /opt/rh/gcc-toolset-%{gts_version}/enable
%endif
USE_PGXS=1 PATH=%{pginstdir}/bin:$PATH %{__make} %{?_smp_mflags} %{with_llvm_arg}


%install
%{__rm} -rf %{buildroot}
USE_PGXS=1 PATH=%{pginstdir}/bin:$PATH %{__make} %{?_smp_mflags} install DESTDIR=%{buildroot} %{with_llvm_arg}


%check
%if %runselftest
# Some of the tests need credcheck in shared_preload_libraries
%pgdg_check_init
pgdg_check_start main "shared_preload_libraries = 'credcheck'"
pgdg_installcheck %{with_llvm_arg}
%endif


%files
%doc README.md
%license LICENSE
%dir %{pginstdir}
%dir %{pginstdir}/lib
%dir %{pginstdir}/share
%dir %{pginstdir}/share/extension
%{pginstdir}/lib/credcheck.so
%{pginstdir}/share/extension/credcheck.control
%{pginstdir}/share/extension/credcheck*.sql

%if %llvm
%files llvmjit
%dir %{pginstdir}/lib/bitcode
%dir %{pginstdir}/lib/bitcode/credcheck
%{pginstdir}/lib/bitcode/credcheck*.bc
%{pginstdir}/lib/bitcode/credcheck/*.bc
%endif


%changelog
* Mon Nov 09 2026 Percona Development Team <info@percona.com> - 6.0-1
- Initial build.
