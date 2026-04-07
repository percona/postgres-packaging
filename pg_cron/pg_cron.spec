%define pgmajorversion %{pgmajor}
%define pginstdir /usr/pgsql-%{pgmajorversion}/
%global sname percona-pg_cron_%{pgmajorversion}

%{!?llvm:%global llvm 1}
Name:		%{sname}
Version:	%{version}
Release:	%{release}%{dist}
License:	AGPLv3
Source0:	%{sname}-%{version}.tar.gz
URL:		https://github.com/citusdata/pg_cron
BuildRequires:	percona-postgresql%{pgmajorversion}-devel libxml2-devel
Requires:	postgresql%{pgmajorversion}-server
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
PATH=%{pginstdir}/bin/:$PATH %{__make} %{?_smp_mflags}

%install
PATH=%{pginstdir}/bin/:$PATH %make_install
# Install documentation with a better name:
%{__mkdir} -p %{buildroot}%{pginstdir}/doc/extension
%{__cp} README.md %{buildroot}%{pginstdir}/doc/extension/README-pg_cron.md

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

