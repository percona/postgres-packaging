%global         debug_package %{nil}

%{expand: %%global py3ver %(python3 -c 'import sys;print(sys.version[0:3])')}
%global __ospython %{_bindir}/python3
%global python3_sitelib %(%{__ospython} -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())")

%global sname patroni

Summary:        A Template for PostgreSQL HA with ZooKeeper, etcd or Consul
Name:           percona-patroni
Version:        2.1.4
Release:        2%{?dist}
License:        MIT
Source0:        %{name}-%{version}.tar.gz
Source1:        %{sname}.service
URL:            https://github.com/zalando/%{sname}

BuildRequires:  python3-setuptools python3-psycopg2 >= 2.5.4

Requires:       python3-psutil >= 2.0.0
Requires:       python3-psycopg2 >= 2.5.4
Requires:       python3-psutil >= 2.0.0 python3-psycopg2 >= 2.5.4
Requires:       python3-ydiff >= 1.2
Requires:       python3-pysyncobj >= 0.3.10

%if 0%{?rhel} == 7
Requires:       python36-click >= 4.1 python36-six >= 1.7
Requires:       python36-dateutil python36-prettytable >= 0.7
Requires:       python36-PyYAML
%else
Requires:       python3-click >= 4.1 python3-six >= 1.7
Requires:       python3-dateutil python3-prettytable >= 0.7
Requires:       python3-pyyaml
%endif

%if 0%{?rhel} > 7
Requires:      python3-pyyaml, python3-urllib3, python3-prettytable, python3-six python3-dateutil python3-click python3-psutil python3-PyYAML python3-psycopg2
%else
Requires:      python36-six python2-pyyaml python36-urllib3 python36-prettytable python36-dateutil python36-click python36-psutil python36-PyYAML python36-psycopg2
%endif
Requires:      python3, libffi, postgresql-server, libyaml, python3-ydiff, ydiff, python3-pysyncobj
Requires:      /usr/bin/python3.6, libffi, postgresql-server, libyaml, postgresql13-server
BuildRequires: prelink libyaml-devel gcc
Provides:      patroni
Epoch:         1
Packager:       Percona Development Team <https://jira.percona.com>
Vendor:         Percona, LLC

%description
Patroni is a template for you to create your own customized,
high-availability solution using Python and - for maximum accessibility - a
distributed configuration store like ZooKeeper, etcd, Consul or Kubernetes.
Database engineers, DBAs, DevOps engineers, and SREs who are looking to
quickly deploy HA PostgreSQL in the datacenter-or anywhere else-will
hopefully find it useful.

We call Patroni a "template" because it is far from being a
one-size-fits-all or plug-and-play replication system. It will have its own
caveats. Use wisely.

%prep
%setup -q
%build
%{__ospython} setup.py build

%install
%{__rm} -rf %{buildroot}
%{__ospython} setup.py install --root %{buildroot} -O1 --skip-build

# Install sample yml files:
%{__mkdir} -p %{buildroot}%{docdir}/%{sname}
%{__cp} postgres0.yml postgres1.yml %{buildroot}%{docdir}/%{sname}


# Install unit file:
%{__install} -d %{buildroot}%{_unitdir}
%{__install} -m 644 %{SOURCE1} %{buildroot}%{_unitdir}/%{sname}.service

# We don't need to ship this file, per upstream:
%{__rm} -f %{buildroot}%{_bindir}/patroni_wale_restore

%post
if [ $1 -eq 1 ] ; then
   /bin/systemctl daemon-reload >/dev/null 2>&1 || :
fi

%preun
if [ $1 -eq 0 ] ; then
        # Package removal, not upgrade
        /bin/systemctl --no-reload disable %{sname}.service >/dev/null 2>&1 || :
        /bin/systemctl stop %{sname}.service >/dev/null 2>&1 || :
fi

%postun
 /bin/systemctl daemon-reload >/dev/null 2>&1 || :
if [ $1 -ge 1 ] ; then
        # Package upgrade, not uninstall
        /bin/systemctl try-restart %{sname}.service >/dev/null 2>&1 || :
fi

%clean
%{__rm} -rf %{buildroot}

%files
%defattr(644,root,root,755)
%license LICENSE
%doc docs README.rst postgres0.yml postgres1.yml
%attr (755,root,root) %{_bindir}/patroni
%attr (755,root,root) %{_bindir}/patronictl
%attr (755,root,root) %{_bindir}/patroni_raft_controller
%attr (755,root,root) %{_bindir}/patroni_aws
%{_unitdir}/%{sname}.service
%{python3_sitelib}/%{sname}*.egg-info
%dir %{python3_sitelib}/%{sname}/
%{python3_sitelib}/%{sname}/*


%changelog
* Fri Apr 16 2021 Evgeniy Patlan <evgeniy.patlan@percona.com> - 2.0.2-2
- Initial build
