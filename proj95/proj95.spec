%global _vpath_builddir .
%global sname proj

%pgdg_set_gis_variables

Name:           %{sname}95
Version:        9.5.1
Release:        1%{?dist}
Epoch:          0
Summary:        Cartographic projection software (PROJ)

License:        MIT
URL:            https://proj.org
Source0:        https://download.osgeo.org/%{sname}/%{sname}-%{version}.tar.gz
Source2:        %{name}-pgdg-libs.conf

BuildRequires:  sqlite-devel >= 3.7 libcurl-devel cmake
BuildRequires:  libtiff-devel pgdg-srpm-macros >= 1.0.44 chrpath

%if 0%{?suse_version} >= 1315
BuildRequires:  gcc12-c++
Requires:       sqlite3-devel >= 3.7
%else
BuildRequires:  gcc-c++
Requires:       sqlite-libs >= 3.7
%endif

%package devel
Summary:        Development files for PROJ
Requires:       %{name} = %{version}-%{release}

%description
Proj and invproj perform respective forward and inverse transformation of
cartographic data to or from cartesian data with a wide range of selectable
projection functions. Proj docs: http://www.remotesensing.org/dl/new_docs/

%description devel
This package contains libproj and the appropriate header files and man pages.

%prep
%setup -q -n %{sname}-%{version}

%build
%{__install} -d build
pushd build

# Fix RPATH: use $ORIGIN/../lib64 only (no absolute paths)
LDFLAGS="-Wl,-rpath,'\$ORIGIN/../lib64' ${LDFLAGS}" ; export LDFLAGS
SHLIB_LINK="$SHLIB_LINK -Wl,-rpath,'\$ORIGIN/../lib64'" ; export SHLIB_LINK

# Workaround: reduce debug symbol size and memory use
RPM_OPT_FLAGS="${RPM_OPT_FLAGS/-g /-g1 }"
CXXFLAGS="${RPM_OPT_FLAGS} -fno-var-tracking-assignments" ; export CXXFLAGS
CFLAGS="${RPM_OPT_FLAGS}" ; export CFLAGS

# Optional: switch to newer compiler on SUSE
%if 0%{?suse_version} >= 1315
export CXX=/usr/bin/g++-12
%endif

# Run CMake
%if 0%{?suse_version}
%if 0%{?suse_version} >= 1315
cmake .. \
%endif
%else
cmake3 .. \
%endif
    -DCMAKE_INSTALL_PREFIX:PATH=%{proj95instdir} \
    -DCMAKE_BUILD_WITH_INSTALL_RPATH=ON \
    -DCMAKE_INSTALL_RPATH="\$ORIGIN/../lib64" \
    -DCMAKE_INSTALL_RPATH_USE_LINK_PATH=OFF \
    -DCMAKE_SKIP_RPATH=OFF \
    -DCMAKE_C_FLAGS="${CFLAGS}" \
    -DCMAKE_CXX_FLAGS="${CXXFLAGS}" \
    -DENABLE_TESTS=OFF  # Disable memory-hungry test builds on OL8

# Limit parallelism on memory-constrained OL8
%if 0%{?rhel} == 8
%make_build -j2
%else
%{__make} -C "%{_vpath_builddir}" %{?_smp_mflags}
%endif

popd

%install
pushd build
%{__make} -C "%{_vpath_builddir}" %{?_smp_mflags} install/fast DESTDIR=%{buildroot}
popd

# Clean up or fix RPATHs (if CMake missed anything)
find %{buildroot}%{proj95instdir}/bin -type f -exec chrpath -r '$ORIGIN/../lib64' {} + 2>/dev/null || true
find %{buildroot}%{proj95instdir}/lib64 -name "*.so*" -exec chrpath -r '$ORIGIN/../lib64' {} + 2>/dev/null || true

%{__install} -d %{buildroot}%{proj95instdir}/share/%{sname}
%{__install} -d %{buildroot}%{proj95instdir}/share/doc/
%{__install} -p -m 0644 NEWS.md AUTHORS.md COPYING README.md ChangeLog %{buildroot}%{proj95instdir}/share/doc/

# Install linker config file
%{__mkdir} -p %{buildroot}%{_sysconfdir}/ld.so.conf.d/
%{__install} %{SOURCE2} %{buildroot}%{_sysconfdir}/ld.so.conf.d/

%post
/sbin/ldconfig

%postun
/sbin/ldconfig

%files
%defattr(-,root,root,-)
%doc %{proj95instdir}/share/doc/*
%{proj95instdir}/bin/*
%{proj95instdir}/share/man/man1/*.1
%{proj95instdir}/share/proj/*
%{proj95instdir}/lib64/libproj.so.25*
%config(noreplace) %attr (644,root,root) %{_sysconfdir}/ld.so.conf.d/%{name}-pgdg-libs.conf

%files devel
%defattr(-,root,root,-)
%{proj95instdir}/share/man/man1/*.1
%{proj95instdir}/include/*.h
%{proj95instdir}/include/proj/*
%{proj95instdir}/lib64/*.so
%attr(0755,root,root) %{proj95instdir}/lib64/pkgconfig/%{sname}.pc
%{proj95instdir}/lib64/cmake/%{sname}/*cmake
%{proj95instdir}/lib64/cmake/%{sname}4/*cmake

%changelog
* Mon Jul 7 2025 Evgeniy Patlan <evgeniy.patlan@percona.com> - 0:9.5.1
- Initial build