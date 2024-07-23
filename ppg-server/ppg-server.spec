%global sname   percona-ppg-server
%global pgmajorversion 14
%global version 13

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
Requires:       percona-postgresql-common >= 14.13
Requires:       percona-postgresql%{pgmajorversion}-contrib
Requires:       percona-pg-stat-monitor%{pgmajorversion}
Requires:       percona-pgaudit14 >= 14.13
Requires:       percona-pg_repack%{pgmajorversion}
Requires:       percona-wal2json%{pgmajorversion}

%description
Essential / key PostgreSQL14 components.
Percona Distribution for PostgreSQL features core components, tools and add-ons 
from the community, tested to work together in demanding enterprise environments.

%files

%changelog
* Thu Aug 08 2024 Muhammad Aqeel <muhammad.aqeel@percona.com> 14.13-1
- Update version for ppg-server meta-package
* Wed May 08 2024 Muhammad Aqeel <muhammad.aqeel@percona.com> 14.12-1
- Update version for ppg-server meta-package
* Wed Oct 26 2022 Surabhi Bhat <surabhi.bhat> 14.11-1
- Update version for ppg-server meta-package
* Wed Jul 20 2022 Kai Wagner <kai.wagner@percona.com> 14.11-1
- Initial build
