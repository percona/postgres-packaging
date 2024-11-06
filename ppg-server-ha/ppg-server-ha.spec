%global sname   percona-ppg-server-ha
%global pgmajorversion 17
%global version 1

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
Essential / key PostgreSQL17 high availability components
Percona Distribution for PostgreSQL features core components, tools and add-ons
from the community, tested to work together in demanding enterprise environments

%files

%changelog
* Thu Nov 14 2024 Muhammad Aqeel <muhammad.aqeel@percona.com> 17.1-1
- Update version for ppg-server-ha meta-package
* Wed Jul 03 2024 Muhammad Aqeel <muhammad.aqeel@percona.com> 17.0-1
- Initial build
