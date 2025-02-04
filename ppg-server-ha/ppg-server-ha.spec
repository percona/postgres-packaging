%global sname   percona-ppg-server-ha
%global pgmajorversion 16
%global version 7

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
Essential / key PostgreSQL16 high availability components
Percona Distribution for PostgreSQL features core components, tools and add-ons
from the community, tested to work together in demanding enterprise environments

%files

%changelog
* Thu Feb 13 2025 Muhammad Aqeel <muhammad.aqeel@percona.com> 16.7-1
- Update version for ppg-server-ha meta-package
* Thu Nov 21 2024 Muhammad Aqeel <muhammad.aqeel@percona.com> 16.6-1
- Update version for ppg-server-ha meta-package
* Thu Nov 14 2024 Muhammad Aqeel <muhammad.aqeel@percona.com> 16.5-1
- Update version for ppg-server-ha meta-package
* Thu Aug 08 2024 Muhammad Aqeel <muhammad.aqeel@percona.com> 16.4-1
- Update version for ppg-server-ha meta-package
* Wed May 08 2024 Muhammad Aqeel <muhammad.aqeel@percona.com> 16.3-1
- Update version for ppg-server-ha meta-package
* Thu Oct 27 2022 Surabhi Bhat <surabhi.bhat> 16.2-1
- Update version for ppg-server-ha meta-package
* Mon Aug 08 2022 Kai Wagner <kai.wagner@percona.com> 16.2-1
- Initial build
