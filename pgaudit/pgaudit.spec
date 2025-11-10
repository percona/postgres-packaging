%define pginstdir /usr/pgsql-%{pgmajorversion}/

Name:           percona-pgaudit%{pgmajorversion}
Version:        %{version}
Release:        %{release}%{?dist}
Summary:        PostgreSQL Audit Extension
Packager:       Percona Development Team <https://jira.percona.com>
Vendor:         Percona, LLC

License:        PostgreSQL
URL:            http://pgaudit.org
Epoch:          1
Source0:        percona-pgaudit-%{version}.tar.gz
Patch0:		all.patch

BuildRequires:  gcc
BuildRequires:  percona-postgresql%{pgmajorversion}-server
BuildRequires:  percona-postgresql%{pgmajorversion}-devel
BuildRequires:  openssl-devel 

Requires:       postgresql%{pgmajorversion}
Requires:       postgresql%{pgmajorversion}-libs
Requires:       postgresql%{pgmajorversion}-server

Provides:       pgaudit pgaudit%{pgmajorversion}
%description
The PostgreSQL Audit extension (pgaudit) provides detailed session
and/or object audit logging via the standard PostgreSQL logging
facility.

The goal of the PostgreSQL Audit extension (pgaudit) is to provide
PostgreSQL users with capability to produce audit logs often required to
comply with government, financial, or ISO certifications.

An audit is an official inspection of an individual's or organization's
accounts, typically by an independent body. The information gathered by
the PostgreSQL Audit extension (pgaudit) is properly called an audit
trail or audit log. The term audit log is used in this documentation.


%prep
%setup -q -n percona-pgaudit-%{version}
%patch0

%build
sed -i 's:PG_CONFIG = pg_config:PG_CONFIG = /usr/pgsql-%{pgmajorversion}/bin/pg_config:' Makefile
%{__make} USE_PGXS=1 %{?_smp_mflags}


%install
%{__make}  USE_PGXS=1 %{?_smp_mflags} DESTDIR=%{buildroot} install
# Install README and howto file under PostgreSQL installation directory:
%{__install} -d %{buildroot}%{pginstdir}/doc/extension
%{__install} -m 644 README.md %{buildroot}%{pginstdir}/doc/extension/README-pgaudit.md
%{__rm} -f %{buildroot}%{pginstdir}/doc/extension/README.md



%files
%defattr(-,root,root,-)
%doc %{pginstdir}/doc/extension/README-pgaudit.md
%{pginstdir}/lib/pgaudit.so
%{pginstdir}/share/extension/pgaudit--1.6*.sql
%{pginstdir}/lib/bitcode/pgaudit*.bc
%{pginstdir}/lib/bitcode/pgaudit/pgaudit*.bc
%{pginstdir}/share/extension/pgaudit.control


%changelog
* Tue Oct 13 2020 Evgeniy Patlan <evgeniy.patlan@percona.com> - 1.6.0-1
- Initial build
