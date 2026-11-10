%global  sname pgaudit%{pgmajorversion}_set_user
%define pginstdir /usr/pgsql-%{pgmajorversion}/

%if 0%{?rhel} >= 8 && 0%{?rhel} <= 9
%global gts_version 14
%endif

%{!?llvm:%global llvm 1}
%{!?runselftest:%global runselftest 0}
# Propagate %%llvm into the actual build: PGXS decides whether to invoke
# clang/llvm-config based on with_llvm from the installed postgresql*-devel's
# Makefile.global, not from this spec's %%llvm. Without passing with_llvm=no
# through to make, setting %%llvm 0 here only drops the llvm BuildRequires/
# files, while the build still tries to run clang regardless.
%if %llvm
%global with_llvm_arg %{nil}
%else
%global with_llvm_arg with_llvm=no
%endif

Name:		percona-%{sname}
Version:	%{version}
Release:	%{release}%{?dist}
Epoch:      1
Provides:	pgaudit%{pgmajorversion}_set_user = %{version}-%{release}
URL:        https://github.com/pgaudit/set_user.git
License:	PostgreSQL
Group:		Applications/Database
Source:		%{name}-%{version}.tar.gz
Summary:	pgaudit%{pgmajorversion}_set_user - PostgreSQL extension allowing privilege escalation with enhanced logging and control
Packager:       Percona Development Team <https://jira.percona.com>
Vendor:         Percona, LLC

BuildRequires:	percona-postgresql%{pgmajorversion}
BuildRequires:        percona-postgresql%{pgmajorversion}-devel
BuildRequires:        krb5-devel
BuildRequires:        openssl-devel
%if 0%{?gts_version}
BuildRequires:  gcc-toolset-%{gts_version}-gcc gcc-toolset-%{gts_version}-gcc-c++ gcc-toolset-%{gts_version}-annobin-plugin-gcc
%endif
%if %llvm
BuildRequires:        clang llvm
%endif

Requires:	percona-postgresql%{pgmajorversion}-server
%if %runselftest
BuildRequires:        percona-postgresql%{pgmajorversion}-server pgdg-srpm-macros >= 2.0.0
%endif

%description
This PostgreSQL extension allows switching users and optional privilege
escalation with enhanced logging and control. It provides an additional layer
of logging and control when unprivileged users must escalate themselves to
superuser or object owner roles in order to perform needed maintenance tasks.

%prep
%setup -q -n %{name}-%{version}

%build
%if 0%{?gts_version}
	source /opt/rh/gcc-toolset-%{gts_version}/enable
%endif
USE_PGXS=1 PATH=%{pginstdir}/bin/:$PATH %{__make} %{?_smp_mflags} %{with_llvm_arg}

%install
USE_PGXS=1 PATH=%{pginstdir}/bin/:$PATH %{__make} %{with_llvm_arg} DESTDIR=%{buildroot} install
# Install README under the PostgreSQL installation directory:
%{__install} -d %{buildroot}%{pginstdir}/doc/extension
%{__install} -m 644 README.md %{buildroot}%{pginstdir}/doc/extension/README-set_user.md

%clean
rm -rf ${RPM_BUILD_ROOT}

%check
%if %runselftest
# The tests need set_user in shared_preload_libraries
%pgdg_check_init
pgdg_check_start main "shared_preload_libraries = 'set_user'"
pgdg_installcheck %{with_llvm_arg}
%endif

%files
%defattr(-,root,root)
%{pginstdir}/lib/set_user.so
%{pginstdir}/lib/bitcode/src/set_user.index.bc
%{pginstdir}/lib/bitcode/src/set_user/src/set_user.bc
%{pginstdir}/include/set_user.h
%{pginstdir}/share/extension/set_user-*.sql
%{pginstdir}/share/extension/set_user.control
%license LICENSE
%doc %{pginstdir}/doc/extension/README-set_user.md
%if %llvm
%dir %{pginstdir}/lib/bitcode
%dir %{pginstdir}/lib/bitcode/src
%dir %{pginstdir}/lib/bitcode/src/set_user
%dir %{pginstdir}/lib/bitcode/src/set_user/src
%{pginstdir}/lib/bitcode/src/set_user.index.bc
%{pginstdir}/lib/bitcode/src/set_user/src/set_user.bc
%endif

%changelog
* Mon Feb 15 2021 Evgeniy Patlan <evgeniy.patlan@percona.com> - 2.0.0-1
- Initial build.