%global         debug_package %{nil}

%if 0%{?rhel} && 0%{?rhel} >= 8
%global __ospython        %{_bindir}/python3.12
%global python3_pkgprefix python3.12
%global python3_buildversion 3.12
%global __requires_exclude ^python3\\.12dist
%else
%global __ospython        %{_bindir}/python3
%global python3_pkgprefix python3
%global python3_buildversion 3
%endif
%{expand: %%global py3ver %(echo `%{__ospython} -c "import sys; print(f'{sys.version_info[0]}.{sys.version_info[1]}')" `)}
%global python3_sitelib %(%{__ospython} -Esc "import sysconfig; print(sysconfig.get_path('purelib', vars={'platbase': '/usr', 'base': '%{_prefix}'}))")

%define         name python3-pysyncobj

Summary: A library for replicating your python class between multiple servers, based on raft protocol
Name:           %{name}
Version:        %{version}
Release:        %{pysyncobj_release}%{?dist}
Source0:        %{name}-%{version}.tar.gz
License:        MIT
Group:          Development/Libraries
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-buildroot
Prefix:         %{_prefix}
BuildArch:      noarch
Vendor:         Filipp Ozinov <fippo@mail.ru>
Url:            https://github.com/bakwc/PySyncObj
BuildRequires:  python%{python3_buildversion}-devel
%if 0%{?suse_version} || (0%{?rhel} && 0%{?rhel} >= 8)
BuildRequires:  %{python3_pkgprefix}-setuptools
%endif

%description
A library for replicating your python class between multiple servers, based on raft protocol

%prep
%setup -n %{name}-%{version} -n %{name}-%{version}

%build
%{__ospython} setup.py build

%install
%{__ospython} setup.py install --single-version-externally-managed -O1 --root=$RPM_BUILD_ROOT --record=INSTALLED_FILES

%clean
rm -rf $RPM_BUILD_ROOT

%files -f INSTALLED_FILES
%defattr(-,root,root)
%dir %{python3_sitelib}/pysyncobj
%dir %{python3_sitelib}/pysyncobj/__pycache__
%dir %{python3_sitelib}/pysyncobj-%{version}-py%{py3ver}.egg-info

%changelog
* Fri May 6 2022 Vadim Yalovets <vadim.yalovets@percona.com> - 0.3.10-1
- Initial build.
