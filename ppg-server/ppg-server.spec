%global sname   percona-ppg-server
%global pgmajorversion 14
%global version 4

Summary:        Percona base selection of PostgreSQL%{pgmajorversion} components
Name:           %{sname}%{pgmajorversion}
Version:        %{version}
Release:        1%{?dist}
Epoch:          1
License:        PostgreSQL
Group:          Applications/Databases
URL:            https://www.percona.com/software/postgresql-distribution
Packager:       Percona Development Team <https://jira.percona.com>
Vendor:         Percona, LLC
BuildArch:      noarch

Requires:       percona-postgresql%{pgmajorversion}-server
Requires:       percona-postgresql-common
Requires:       percona-postgresql%{pgmajorversion}-contrib
Requires:       percona-pg-stat-monitor%{pgmajorversion}
Requires:       percona-pgaudit
Requires:       percona-pg_repack%{pgmajorversion}
Requires:       percona-wal2json%{pgmajorversion}

%description
This package provides the best and most critical Percona Distribution for PostgreSQL
enterprise components from the open-source community, in a single distribution,
designed and tested to work together.

%files
