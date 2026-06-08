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

BuildRequires:  gcc cmake libtool

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
%{__install} -d build
pushd build
%if 0%{?suse_version} >= 1315
cmake -DCMAKE_INSTALL_PREFIX:PATH=/usr -DCMAKE_BUILD_TYPE=Release \
	-DBUILD_SHARED_LIBS:BOOL=ON -DENABLE_LINTING=OFF ..
%else
%cmake -DCMAKE_BUILD_TYPE=Release -DENABLE_LINTING=OFF ..
%endif
%cmake_build
popd

%install
%{__rm} -rf %{buildroot}
pushd build
%cmake_install
popd
%{__mv} %{buildroot}/%{_includedir}/h3/h3api.h %{buildroot}/%{_includedir}/
%{__cp} src/h3lib/include/linkedGeo.h %{buildroot}/%{_includedir}/
%{__cp} src/h3lib/include/latLng.h %{buildroot}/%{_includedir}/
%{__cp} src/h3lib/include/bbox.h %{buildroot}/%{_includedir}/

%post	-p /sbin/ldconfig
%postun	-p /sbin/ldconfig

%files
%license LICENSE
%doc README.md
%{_bindir}/cellToBoundary
%{_bindir}/cellToBoundaryHier
%{_bindir}/cellToLatLng
%{_bindir}/cellToLatLngHier
%{_bindir}/cellToLocalIj
%{_bindir}/gridDisk
%{_bindir}/gridDiskUnsafe
%{_bindir}/%{sname}
%{_bindir}/h3ToComponents
%{_bindir}/h3ToHier
%{_bindir}/latLngToCell
%{_bindir}/localIjToCell
%{_libdir}/libh3.so*

%files devel
%{_includedir}/bbox.h
%{_includedir}/h3api.h
%{_includedir}/latLng.h
%{_includedir}/linkedGeo.h
%{_libdir}/cmake/%{sname}/*.cmake
%{_libdir}/pkgconfig/%{sname}.pc

%changelog
* Tue Mar 31 2026 Manika Singhal <manika.singhal@percona.com> 4.4.1
- Initial build