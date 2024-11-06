%global sname   percona-ppg-server-ha
%global pgmajorversion 15
%global version 9

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
Essential / key PostgreSQL15 high availability components
Percona Distribution for PostgreSQL features core components, tools and add-ons
from the community, tested to work together in demanding enterprise environments

%files

%changelog
* Thu Nov 14 2024 Muhammad Aqeel <muhammad.aqeel@percona.com> 15.9-1
- Update version for ppg-server-ha meta-package
* Thu Aug 08 2024 Muhammad Aqeel <muhammad.aqeel@percona.com> 15.8-1
- Update version for ppg-server-ha meta-package
* Wed May 08 2024 Muhammad Aqeel <muhammad.aqeel@percona.com> 15.7-1
- Update version for ppg-server-ha meta-package
* Thu Oct 27 2022 Surabhi Bhat <surabhi.bhat> 15.6-1
- Update version for ppg-server-ha meta-package
* Mon Aug 08 2022 Kai Wagner <kai.wagner@percona.com> 15.6-1
- Initial build
