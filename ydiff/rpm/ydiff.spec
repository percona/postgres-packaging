%global        debug_package %{nil}

%if 0%{?fedora} && 0%{?fedora} == 43
%global __ospython %{_bindir}/python3.14
%global python3_pkgversion 3.14
%endif
%if 0%{?fedora} && 0%{?fedora} <= 42
%global        __ospython %{_bindir}/python3.13
%global        python3_pkgversion 3.13
%endif
%if 0%{?rhel} && 0%{?rhel} == 8
%global __ospython %{_bindir}/python3
%global python3_pkgversion 3
%endif
%if 0%{?rhel} && 0%{?rhel} >= 9
%global	__ospython %{_bindir}/python3.12
%global	python3_pkgversion 3.12
%endif
%if 0%{?suse_version} == 1500
%global        __ospython %{_bindir}/python3.11
%global        python3_pkgversion 311
%endif
%if 0%{?suse_version} == 1600
%global        __ospython %{_bindir}/python3.13
%global        python3_pkgversion 313
%endif
%{expand: %%global py3ver %(echo `%{__ospython} -c "import sys; print(f'{sys.version_info[0]}.{sys.version_info[1]}')" `)}
%global python3_sitelib %(%{__ospython} -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())")

Name:           ydiff
Version:        %{version}
Release:        %{release}%{?dist}
Summary:        View colored, incremental diff
URL:            https://github.com/ymattw/ydiff
License:        BSD
Source0:        %{name}-%{version}.tar.gz
BuildRequires:  python%{python3_pkgversion}-devel
Requires:        less
Requires:       python%{python3_pkgversion}-%{name}

Provides:        python%{python3_pkgversion}dist(ydiff)

%description
Term based tool to view colored, incremental diff in a Git/Mercurial/Svn
workspace or from stdin, with side by side (similar to diff -y) and auto
pager support.


%package -n     python3-%{name}
Summary:        %{summary}
%if 0%{?fedora} >= 40 || 0%{?rhel} >= 9 || 0%{?suse_version} >= 1500
%{?python_provide:%python_provide python3-%{name}}
%endif
%description -n python3-%{name}
Python library that implements API used by ydiff tool.


%prep
%autosetup -n %{name}-%{version}
/usr/bin/sed -i '/#!\/usr\/bin\/env python/d' ydiff.py


%build
%{__ospython} setup.py build


%install
%{__rm} -rf %{buildroot}
%{__ospython} setup.py install --root %{buildroot} -O1 --skip-build


%files
%doc README.rst
%license LICENSE
%{_bindir}/ydiff


%files -n python3-%{name}
%{python3_sitelib}/__pycache__/*
%{python3_sitelib}/%{name}.py
%{python3_sitelib}/%{name}-%{version}-py%{py3ver}.egg-info


%changelog
* Fri Apr 16 2021 Evgeniy Patlan <evgeniy.patlan@percona.com> - 1.2-10
- Initial build.
