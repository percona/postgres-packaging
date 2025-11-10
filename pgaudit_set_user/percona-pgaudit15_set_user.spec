%global  sname pgaudit%{pgmajorversion}_set_user
%define pginstdir /usr/pgsql-%{pgmajorversion}/

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

Requires:	postgresql%{pgmajorversion}

%description
PostgreSQL is an advanced Object-Relational database management system.
The PostgreSQL Audit extension (pgaudit) provides detailed session and/or 
object audit logging via the standard PostgreSQL logging facility. 
The set_user part of that extension allows for extra logging with regard
 to granting of superuser privileges, and also enforces 
 a superuser-request policy over direct superuser logins.

%prep
%setup -q -n %{name}-%{version}

%build
sed -i 's:PG_CONFIG = pg_config:PG_CONFIG = /usr/pgsql-%{pgmajorversion}/bin/pg_config:' Makefile
%{__make} USE_PGXS=1 %{?_smp_mflags}

%install
%{__make} USE_PGXS=1 DESTDIR=%{buildroot} install

%clean
rm -rf ${RPM_BUILD_ROOT}

%files
%defattr(-,root,root)
%{pginstdir}/lib/set_user.so
%{pginstdir}/lib/bitcode/src/set_user.index.bc
%{pginstdir}/lib/bitcode/src/set_user/src/set_user.bc
%{pginstdir}/include/set_user.h
%{pginstdir}/share/extension/set_user-*.sql
%{pginstdir}/share/extension/set_user.control
%doc LICENSE
%doc README.md

%changelog
* Mon Feb 15 2021 Evgeniy Patlan <evgeniy.patlan@percona.com> - 2.0.0-1
- Initial build.
