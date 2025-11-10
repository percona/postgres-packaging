%global sname   percona-ppg-server
%global pgmajorversion %{pgmajor}
%global version %{pgminorversion}

Summary:        Percona base selection of PostgreSQL%{pgmajorversion} components
Name:           %{sname}%{pgmajorversion}
Version:        %{pgmajorversion}.%{pgminorversion}
Release:        %{release}%{?dist}
License:        PostgreSQL
Group:          Applications/Databases
URL:            https://www.percona.com/software/postgresql-distribution
Packager:       Percona Development Team <https://jira.percona.com>
Vendor:         Percona, LLC
Epoch:		1
Requires:       percona-postgresql%{pgmajorversion}-server
Requires:       percona-postgresql-common >= %{pgmajorversion}.%{pgminorversion}
Requires:       percona-postgresql%{pgmajorversion}-contrib
Requires:       percona-pg-stat-monitor%{pgmajorversion}
Requires:       percona-pgaudit%{pgmajorversion} >= %{pgmajorversion}.%{pgminorversion}
Requires:       percona-pg_repack%{pgmajorversion}
Requires:       percona-wal2json%{pgmajorversion}

%description
Essential / key PostgreSQL17 components.
Percona Distribution for PostgreSQL features core components, tools and add-ons 
from the community, tested to work together in demanding enterprise environments.

%files

%changelog
* Thu May 08 2025 Muhammad Aqeel <muhammad.aqeel@percona.com> 17.5-1
- Update version for ppg-server meta-package
* Thu Feb 20 2025 Muhammad Aqeel <muhammad.aqeel@percona.com> 17.4-1
- Update version for ppg-server meta-package
* Thu Nov 21 2024 Muhammad Aqeel <muhammad.aqeel@percona.com> 17.2-1
- Update version for ppg-server meta-package
* Thu Nov 14 2024 Muhammad Aqeel <muhammad.aqeel@percona.com> 17.1-1
- Update version for ppg-server meta-package
* Wed Jul 03 2024 Muhammad Aqeel <muhammad.aqeel@percona.com> 17.0-1
- Initial build
