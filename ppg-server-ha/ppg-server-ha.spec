%global sname   percona-ppg-server-ha
%global pgmajorversion 14
%global version 16

Summary:        Percona selection of PostgreSQL%{pgmajorversion} HA components
Name:           %{sname}%{pgmajorversion}
Version:        %{pgmajorversion}.%{version}
Release:        1%{?dist}
License:        PostgreSQL
Group:          Applications/Databases
URL:            https://www.percona.com/software/postgresql-distribution
Packager:       Percona Development Team <https://jira.percona.com>
Vendor:         Percona, LLC

Requires:       etcd
Requires:       python3-etcd
Requires:       percona-patroni
Requires:       percona-haproxy

%description
Essential / key PostgreSQL14 high availability components
Percona Distribution for PostgreSQL features core components, tools and add-ons
from the community, tested to work together in demanding enterprise environments

%files

%changelog
* Thu Feb 13 2025 Muhammad Aqeel <muhammad.aqeel@percona.com> 14.16-1
- Update version for ppg-server-ha meta-package
* Thu Nov 21 2024 Muhammad Aqeel <muhammad.aqeel@percona.com> 14.15-1
- Update version for ppg-server-ha meta-package
* Thu Nov 14 2024 Muhammad Aqeel <muhammad.aqeel@percona.com> 14.14-1
- Update version for ppg-server-ha meta-package
* Thu Aug 08 2024 Muhammad Aqeel <muhammad.aqeel@percona.com> 14.13-1
- Update version for ppg-server-ha meta-package
* Wed May 08 2024 Muhammad Aqeel <muhammad.aqeel@percona.com> 14.12-1
- Update version for ppg-server-ha meta-package
* Wed Oct 26 2022 Surabhi Bhat <surabhi.bhat> 14.11-1
- Update version for ppg-server-ha meta-package
* Mon Aug 08 2022 Kai Wagner <kai.wagner@percona.com> 14.11-1
- Initial build
