%global         debug_package %{nil}

%{expand: %%global py3ver %(python3 -c 'import sys;print(sys.version[0:3])')}

%if 0%{?fedora} && 0%{?fedora} == 43
%global __ospython %{_bindir}/python3.14
%global python3_pkgversion 3.14
%endif
%if 0%{?fedora} && 0%{?fedora} <= 42
%global	__ospython %{_bindir}/python3.13
%global	python3_pkgversion 3.13
%endif
%if 0%{?rhel} && 0%{?rhel} <= 10
%global	__ospython %{_bindir}/python3.12
%global	python3_pkgversion 3.12
%endif
%if 0%{?suse_version} == 1500
%global	__ospython %{_bindir}/python3.11
%global	python3_pkgversion 311
%endif
%if 0%{?suse_version} == 1600
%global	__ospython %{_bindir}/python3.13
%global	python3_pkgversion 313
%endif
%global python3_sitelib %(%{__ospython} -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())")

%global sname patroni

Summary:        A Template for PostgreSQL HA with ZooKeeper, etcd or Consul
Name:           percona-patroni
Version:        %{version}
Release:        %{release}%{?dist}
License:        MIT
Source0:        %{name}-%{version}.tar.gz
Source1:        %{sname}.service
URL:            https://github.com/zalando/%{sname}

BuildRequires:  python%{python3_pkgversion}-setuptools python%{python3_pkgversion}-devel python%{python3_pkgversion}-psycopg2 >= 2.5.4

Requires:       python%{python3_pkgversion}-psutil >= 2.0.0 python%{python3_pkgversion}-six python%{python3_pkgversion}-dateutil
Requires:       python%{python3_pkgversion}-psycopg2 >= 2.5.4
Requires:       python%{python3_pkgversion}-psutil >= 2.0.0 python3-psycopg2 >= 2.5.4
Requires:       python%{python3_pkgversion}-ydiff >= 1.2
Requires:       python%{python3_pkgversion}-pysyncobj >= 0.3.10

%if 0%{?rhel} == 7
Requires:       python36-click >= 4.1 python36-six >= 1.7
Requires:       python36-dateutil python36-prettytable >= 0.7
Requires:       python36-PyYAML
%else
Requires:       python%{python3_pkgversion}-click >= 4.1 python%{python3_pkgversion}-six >= 1.7
Requires:       python%{python3_pkgversion}-dateutil python%{python3_pkgversion}-prettytable >= 0.7
Requires:       python%{python3_pkgversion}-pyyaml
%endif

%if 0%{?fedora} && 0%{?fedora} <= 43
Requires:        python%{python3_pkgversion}-click python%{python3_pkgversion}-cryptography >= 1.4 python%{python3_pkgversion}-psutil
Requires:        python%{python3_pkgversion}-prettytable python%{python3_pkgversion}-pyyaml
Requires:        python%{python3_pkgversion}-urllib3 >= 1.19.1 python%{python3_pkgversion}-psycopg2 python%{python3_pkgversion}-wcwidth
%endif

%if 0%{?rhel} > 7
Requires:      python%{python3_pkgversion}-pyyaml, python%{python3_pkgversion}-urllib3, python%{python3_pkgversion}-prettytable, python%{python3_pkgversion}-six python%{python3_pkgversion}-dateutil python%{python3_pkgversion}-click python%{python3_pkgversion}-psutil python%{python3_pkgversion}-PyYAML python%{python3_pkgversion}-psycopg2
%else
Requires:      python36-six python2-pyyaml python36-urllib3 python36-prettytable python36-dateutil python36-click python36-psutil python36-PyYAML python36-psycopg2
%endif

%if 0%{?rhel} && 0%{?rhel} <= 9
Requires:        python%{python3_pkgversion}-click >= 8.1.7
Requires:        python%{python3_pkgversion}-cryptography >= 1.4
Requires:        python%{python3_pkgversion}-prettytable
Requires:        python%{python3_pkgversion}-psutil
Requires:        python%{python3_pkgversion}-psycopg2
Requires:        python%{python3_pkgversion}-pyyaml
Requires:        python%{python3_pkgversion}-urllib3 >= 1.19.1
Requires:        python%{python3_pkgversion}-wcwidth
%endif

%if 0%{?rhel} && 0%{?rhel} == 10
Requires:        python%{python3_pkgversion}-click python%{python3_pkgversion}-cryptography >= 1.4
Requires:        python%{python3_pkgversion}-prettytable python%{python3_pkgversion}-pyyaml python%{python3_pkgversion}-psutil
Requires:        python%{python3_pkgversion}-urllib3 >= 1.19.1 python%{python3_pkgversion}-psycopg2
Requires:        python%{python3_pkgversion}-wcwidth
%endif

%if 0%{?suse_version} >= 1500
Requires:        python%{python3_pkgversion}-click python%{python3_pkgversion}-cryptography >= 1.4
Requires:        python%{python3_pkgversion}-psycopg2
Requires:        python%{python3_pkgversion}-psutil python%{python3_pkgversion}-PyYAML
Requires:        python%{python3_pkgversion}-prettytable python%{python3_pkgversion}-urllib3 >= 1.19.1
Requires:        python%{python3_pkgversion}-wcwidth
%endif

Requires:      python%{python3_pkgversion}, libffi, postgresql-server, libyaml, python%{python3_pkgversion}-ydiff, ydiff, python%{python3_pkgversion}-pysyncobj
Requires:      libffi, postgresql-server, libyaml, postgresql%{pgmajor}-server
BuildRequires: libyaml-devel gcc
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

%package -n %{name}-consul
Summary:        Related components to use patroni with Consul
Requires:        %{name} = %{version}-%{release}
Requires:        consul py-consul >= 1.6.0
%if 0%{?fedora} && 0%{?fedora} <= 43
Requires:        python3-requests
%endif
%if 0%{?rhel} && 0%{?rhel} < 10
Requires:        python%{python3_pkgversion}-requests
%endif
%if 0%{?rhel} && 0%{?rhel} == 10
Requires:        python3-requests
%endif
%if 0%{?suse_version} >= 1500
Requires:        python%{python3_pkgversion}-requests
%endif
%description -n %{name}-consul
Meta package to pull consul related dependencies for patroni

%package -n %{name}-aws
Summary:        Related components to use patroni on AWS
Requires:        %{name} = %{version}-%{release}
%if 0%{?fedora} && 0%{?fedora} <= 43
Requires:        python3-boto3
%endif
%if 0%{?rhel} && 0%{?rhel} < 10
Requires:        python%{python3_pkgversion}-boto3
%endif
%if 0%{?rhel} && 0%{?rhel} == 10
Requires:        python3-boto3
%endif
%if 0%{?suse_version} >= 1500
Requires:        python%{python3_pkgversion}-boto3
%endif
%description -n %{name}-aws
Meta package to pull AWS related dependencies for patroni

%package -n %{name}-zookeeper
Summary:        Related components to use patroni with Zookeeper
Requires:        %{name} = %{version}-%{release}
%if 0%{?fedora} && 0%{?fedora} <= 43
Requires:        python3-kazoo >= 1.3.1
%endif
%if 0%{?rhel} && 0%{?rhel} <= 10
Requires:        python%{python3_pkgversion}-kazoo >= 1.3.1
%endif
%if 0%{?rhel} && 0%{?rhel} == 10
Requires:        python3-kazoo >= 1.3.1
%endif
%if 0%{?suse_version} >= 1500
Requires:        python%{python3_pkgversion}-kazoo >= 1.3.1
%endif
%description -n %{name}-zookeeper
Meta package to pull zookeeper related dependencies for patroni

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
%{__mkdir} -p /var/log/patroni
%{__mkdir} -p /etc/patroni/callbacks
touch /etc/patroni/callbacks/callbacks.sh
if [ $1 -eq 1 ] ; then
   /bin/systemctl daemon-reload >/dev/null 2>&1 || :
   %if 0%{?suse_version}
   %if 0%{?suse_version} >= 1500
   %service_add_pre %{sname}.service
   %endif
   %else
   %systemd_post %{sname}.service
   %endif
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
%attr (755,root,root) %{_bindir}/patroni_barman
%{_unitdir}/%{sname}.service
%{python3_sitelib}/%{sname}*.egg-info
%dir %{python3_sitelib}/%{sname}/
%{python3_sitelib}/%{sname}/*

%files -n %{name}-aws
%attr (755,root,root) %{_bindir}/patroni_aws
%files -n %{name}-consul
%files -n %{name}-zookeeper

%changelog
* Fri Apr 16 2021 Evgeniy Patlan <evgeniy.patlan@percona.com> - 2.0.2-2
- Initial build
