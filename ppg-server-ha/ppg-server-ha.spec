%global sname   percona-ppg-server-ha
%global pgmajorversion 13
%global version 18

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
Essential / key PostgreSQL13 high availability components
Percona Distribution for PostgreSQL features core components, tools and add-ons
from the community, tested to work together in demanding enterprise environments

%files

%changelog
* Thu Nov 21 2024 Muhammad Aqeel <muhammad.aqeel@percona.com> 13.18-1
- Update version for ppg-server-ha meta-package
* Thu Nov 14 2024 Muhammad Aqeel <muhammad.aqeel@percona.com> 13.17-1
- Update version for ppg-server-ha meta-package
* Thu Aug 08 2024 Muhammad Aqeel <muhammad.aqeel@percona.com> 13.16-1
- Update version for ppg-server-ha meta-package
* Wed May 08 2024 Muhammad Aqeel <muhammad.aqeel@percona.com> 13.15-1
- Update version for ppg-server-ha meta-package
* Mon Oct 31 2022 Surabhi Bhat <surabhi.bhat> 13.14-1
- Update version for ppg-server-ha meta-package
* Mon Aug 08 2022 Kai Wagner <kai.wagner@percona.com> 13.14-1
- Initial build
