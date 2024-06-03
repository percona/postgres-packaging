%global        debug_package %{nil}

Name:           ydiff
Version:        1.2
Release:        10%{?dist}
Summary:        View colored, incremental diff
URL:            https://github.com/ymattw/ydiff
License:        BSD
Source0:        %{name}-%{version}.tar.gz
BuildRequires:  python3-devel
Requires:       python%{python3_pkgversion}-%{name}

%description
Term based tool to view colored, incremental diff in a Git/Mercurial/Svn
workspace or from stdin, with side by side (similar to diff -y) and auto
pager support.


%package -n     python3-%{name}
Summary:        %{summary}
%{?python_provide:%python_provide python3-%{name}}
%description -n python3-%{name}
Python library that implements API used by ydiff tool.


%prep
%autosetup -n %{name}-%{version}
/usr/bin/sed -i '/#!\/usr\/bin\/env python/d' ydiff.py


%build
%py3_build


%install
%py3_install


%files
%doc README.rst
%license LICENSE
%{_bindir}/ydiff


%files -n python3-%{name}
%{python3_sitelib}/__pycache__/*
%{python3_sitelib}/%{name}.py
%{python3_sitelib}/%{name}-%{version}-py%{python3_version}.egg-info


%changelog
* Fri Apr 16 2021 Evgeniy Patlan <evgeniy.patlan@percona.com> - 1.2-10
- Initial build.
