%global debug_package %{nil}
%global pgmajorversion %{pgmajor}
%global sname	h3

Name:           %{sname}
Version:        %{version}
Release:        %{release}%{?dist}
Summary:        Uber H3 geospatial indexing library
Packager:       Percona Development Team <https://jira.percona.com>
Vendor:         Percona, LLC

License:        Apache-2.0
URL:            https://github.com/uber/%{sname}
Source0:        %{name}-%{version}.tar.gz

BuildRequires:  cmake
BuildRequires:  gcc
BuildRequires:  make

%description
H3 is a hexagonal hierarchical geospatial indexing system.

%package devel
Summary: Development files for h3
Requires: %{name}%{?_isa} = %{version}-%{release}

%description devel
Header files and development libraries for h3.

%prep
%setup -q

%build
mkdir build
cd build
cmake .. \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_SHARED_LIBS=ON \
  -DCMAKE_INSTALL_PREFIX=%{_prefix} \
  -DCMAKE_INSTALL_LIBDIR=lib64
make %{?_smp_mflags}

%install
rm -rf %{buildroot}
cd build
make DESTDIR=%{buildroot} install

%files
%license LICENSE
%{_libdir}/libh3.so*
%{_bindir}/*

%files devel
%{_includedir}/h3/
%{_libdir}/libh3.so
%{_libdir}/cmake/h3/

%post -p /sbin/ldconfig
%postun -p /sbin/ldconfig

%changelog
* Tue Mar 31 2026 Manika Singhal <manika.singhal@percona.com> 4.4.1
- Initial build