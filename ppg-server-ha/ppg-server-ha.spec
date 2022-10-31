%global sname   percona-ppg-server-ha
%global pgmajorversion 13
%global version 8

Summary:        Percona selection of PostgreSQL%{pgmajorversion} HA components
Name:           %{sname}%{pgmajorversion}
Version:        %{pgmajorversion}.%{version}
Release:        1%{?dist}
License:        PostgreSQL
Group:          Applications/Databases
URL:            https://www.percona.com/software/postgresql-distribution
Packager:       Percona Development Team <https://jira.percona.com>
Vendor:         Percona, LLC
BuildArch:      noarch

Requires:       etcd
Requires:       percona-patroni
Requires:       percona-haproxy

%description
Essential / key PostgreSQL13 high availability components
Percona Distribution for PostgreSQL features core components, tools and add-ons
from the community, tested to work together in demanding enterprise environments

%files

%changelog
* Mon Oct 31 2022 Surabhi Bhat <surabhi.bhat> 13.8-1
- Update version for ppg-server-ha meta-package
* Mon Aug 08 2022 Kai Wagner <kai.wagner@percona.com> 13.7-1
- Initial build
