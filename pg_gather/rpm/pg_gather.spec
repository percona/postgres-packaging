%global sname   percona-pg_gather
%global version 31
%global pgmajorversion 14
%global pginstdir /usr/pgsql-14

Summary:        sql-only script to gather performance and configuration data from PostgreSQL databases
Name:           percona-pg_gather
Version:        %{version}
Release:        1%{?dist}
License:        GPLv3
Group:          Applications/Databases
Source0:        %{sname}-%{version}.tar.gz
Packager:       Percona Development Team <https://jira.percona.com>
Vendor:         Percona, LLC

Requires:       percona-postgresql%{pgmajorversion}

%description
pg_gather consists of one sql-only script (gather.sql) for gathering performance and configuration data from PostgreSQL databases.

%prep
%setup -q -n %{sname}-%{version}

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/%{_bindir} $RPM_BUILD_ROOT/%{pginstdir}
%{__install} -p -D -m 0755 gather.sql %{buildroot}%{_bindir}/gather.sql
%{__install} -p -D -m 0755 gather.sql %{buildroot}%{pginstdir}/bin/gather.sql

%files
%attr (755,root,root) %{pginstdir}/bin/gather.sql
%{_bindir}/gather.sql

%clean
rm -rf $RPM_BUILD_ROOT

%changelog
* Wed Aug 09 2023 Surabhi Bhat <surabhi.bhat@percona.com> - 21-1
- Initial build
