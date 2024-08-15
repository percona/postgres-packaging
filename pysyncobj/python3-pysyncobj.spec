%global         debug_package %{nil}

%define         name python3-pysyncobj
%define         version 0.3.10
%define         unmangled_version 0.3.10
%define         release 1

Summary: A library for replicating your python class between multiple servers, based on raft protocol
Name:           %{name}
Version:        %{version}
Release:        %{release}%{?dist}
Source0:        %{name}-%{unmangled_version}.tar.gz
License:        MIT
Group:          Development/Libraries
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-buildroot
Prefix:         %{_prefix}
BuildArch:      noarch
Vendor:         Filipp Ozinov <fippo@mail.ru>
Url:            https://github.com/bakwc/PySyncObj
BuildRequires:  python3-devel

%description
A library for replicating your python class between multiple servers, based on raft protocol

%prep
%setup -n %{name}-%{unmangled_version} -n %{name}-%{unmangled_version}

%build
python3 setup.py build

%install
python3 setup.py install --single-version-externally-managed -O1 --root=$RPM_BUILD_ROOT --record=INSTALLED_FILES

%clean
rm -rf $RPM_BUILD_ROOT

%files -f INSTALLED_FILES
%defattr(-,root,root)

%changelog
* Fri May 6 2022 Vadim Yalovets <vadim.yalovets@percona.com> - 0.3.10-1
- Initial build.
