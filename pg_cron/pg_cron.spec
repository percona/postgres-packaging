%define pgmajorversion %{pgmajor}
%define pginstdir /usr/pgsql-%{pgmajorversion}/
%global sname percona-pg_cron_%{pgmajorversion}

%if 0%{?rhel} && 0%{?rhel} <= 9
%global gts_version 14
%endif

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

Summary:	Run periodic jobs in PostgreSQL
Name:		%{sname}
Version:	%{version}
Release:	%{release}%{dist}
License:	AGPLv3
Source0:	%{sname}-%{version}.tar.gz
Packager:       Percona Development Team <https://jira.percona.com>
Vendor:         Percona, LLC
URL:		https://github.com/citusdata/pg_cron
BuildRequires:	percona-postgresql%{pgmajorversion}-devel libxml2-devel
%if 0%{?gts_version}
BuildRequires:  gcc-toolset-%{gts_version}-gcc gcc-toolset-%{gts_version}-gcc-c++ gcc-toolset-%{gts_version}-annobin-plugin-gcc
%endif
Requires:	postgresql%{pgmajorversion}-server
%if %runselftest
BuildRequires:        percona-postgresql%{pgmajorversion}-server pgdg-srpm-macros >= 2.0.0
%endif
Requires(post):	%{_sbindir}/update-alternatives
Requires(postun):	%{_sbindir}/update-alternatives

%if 0%{?suse_version} >= 1500
Requires:	libopenssl3
BuildRequires:	libopenssl-3-devel openldap2-devel
%endif
%if 0%{?fedora} >= 41 || 0%{?rhel} >= 8
Requires:	openssl-libs >= 1.1.1k
BuildRequires:	openssl-devel openldap-devel
%endif

%description
pg_cron is a simple cron-based job scheduler for PostgreSQL
(9.5 or higher) that runs inside the database as an extension.
It uses the same syntax as regular cron, but it allows you to
schedule PostgreSQL commands directly from the database.

%if %llvm
%package llvmjit
Summary:	Just-in-time compilation support for pg_cron
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
This packages provides JIT support for pg_cron
%endif

%prep
%setup -q -n %{sname}-%{version}

%build
%if 0%{?gts_version}
	source /opt/rh/gcc-toolset-%{gts_version}/enable
%endif
PATH=%{pginstdir}/bin/:$PATH %{__make} %{?_smp_mflags} %{with_llvm_arg}

%install
PATH=%{pginstdir}/bin/:$PATH %make_install %{with_llvm_arg}
# Install documentation with a better name:
%{__mkdir} -p %{buildroot}%{pginstdir}/doc/extension
%{__cp} README.md %{buildroot}%{pginstdir}/doc/extension/README-pg_cron.md

%check
%if %runselftest
# pg_cron's installcheck runs the tests in a temporary instance of its own,
# with pg_cron preloaded, so there is no need to start a server here.
%pgdg_check_init
pgdg_installcheck %{with_llvm_arg}
%endif

%files
%defattr(-,root,root,-)
%doc CHANGELOG.md
%license LICENSE
%doc %{pginstdir}/doc/extension/README-pg_cron.md
%{pginstdir}/lib/pg_cron.so
%{pginstdir}/share/extension/pg_cron-*.sql
%{pginstdir}/share/extension/pg_cron.control

%if %llvm
%files llvmjit
   %{pginstdir}/lib/bitcode/pg_cron*.bc
   %{pginstdir}/lib/bitcode/pg_cron/src/*.bc
%endif

%changelog
* Tue Apr 07 2026 Surabhi Bhat <surabhi.bhat@percona.com> - 1.6.7-1
- Update build to 1.6.7

* Tue Jan 16 2024 Muhammad Aqeel <muhammad.aqeel@percona.com> - 1.6.2-1
- Initial build of 1.6.2