%global sname   percona-ppg-server
%global pgmajorversion 12
%global version 19

Summary:        Percona base selection of PostgreSQL%{pgmajorversion} components
Name:           %{sname}%{pgmajorversion}
Version:        %{pgmajorversion}.%{version}
Release:        1%{?dist}
License:        PostgreSQL
Group:          Applications/Databases
URL:            https://www.percona.com/software/postgresql-distribution
Packager:       Percona Development Team <https://jira.percona.com>
Vendor:         Percona, LLC

Requires:       percona-postgresql%{pgmajorversion}-server
Requires:       percona-postgresql-common >= 12.19
Requires:       percona-postgresql%{pgmajorversion}-contrib
Requires:       percona-pg-stat-monitor%{pgmajorversion}
Requires:       percona-postgresql-common > 12.0
Requires:       percona-pgaudit12 > 12.0
Requires:       percona-pg_repack%{pgmajorversion}
Requires:       percona-wal2json%{pgmajorversion}

%description
Essential / key PostgreSQL12 components.
Percona Distribution for PostgreSQL features core components, tools and add-ons 
from the community, tested to work together in demanding enterprise environments.

%files

%changelog
* Wed May 08 2024 Muhammad Aqeel <muhammad.aqeel@percona.com> 12.19-1
- Update version for ppg-server meta-package
* Mon Oct 31 2022 Surabhi Bhat <surabhi.bhat> 12.18-1
- Update version for ppg-server meta-package
* Fri Aug 05 2022 Kai Wagner <kai.wagner@percona.com> 12.18-1
- Initial build
