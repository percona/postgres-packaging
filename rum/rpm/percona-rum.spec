
%global debug_package %{nil}
%global pgmajorversion %{pgmajor}
%global pname rum
%global sname percona-rum_%{pgmajorversion}

%{!?llvm:%global llvm 1}

Summary:	RUM access method - inverted index with additional information in posting lists
Name:		  %{sname}
Version:	%{version}
Release:	%{release}%{?dist}
License:	PostgreSQL
Source0:	%{sname}-%{version}.tar.gz
URL:		  https://github.com/postgrespro/%{pname}/
Packager:   Percona Development Team <https://jira.percona.com>
Vendor:     Percona, LLC

BuildRequires:	percona-postgresql%{pgmajorversion}-devel percona-postgresql%{pgmajorversion}
Requires:	percona-postgresql%{pgmajorversion}

%description
The rum module provides access method to work with RUM index.
It is based on the GIN access methods code.

%package devel
Summary:	RUM access method development header files
Requires:	%{name}%{?_isa} = %{version}-%{release}

%description devel
This package includes the development headers for the rum extension.

%if %llvm
%package llvmjit
Summary:	Just-in-time compilation support for rum
Requires:	%{name}%{?_isa} = %{version}-%{release}
%if 0%{?suse_version} == 1500
BuildRequires:	llvm17-devel clang17-devel
Requires:	llvm17
%endif
%if 0%{?suse_version} == 1600
BuildRequires:	llvm19-devel clang19-devel
Requires:	llvm19
%endif
%if 0%{?fedora} || 0%{?rhel} >= 8
BuildRequires:	llvm-devel >= 19.0 clang-devel >= 19.0
Requires:	llvm >= 19.0
%endif

%description llvmjit
This package provides JIT support for rum
%endif

%prep
%setup -q -n %{sname}-%{version}

%build
USE_PGXS=1 PATH=%{pginstdir}/bin/:$PATH %{__make} %{?_smp_mflags}

%install
%{__rm} -rf %{buildroot}
%{__install} -d %{buildroot}%{pginstdir}/include/server
%{__install} -m 644 src/rum*.h %{buildroot}%{pginstdir}/include/server/
USE_PGXS=1 PATH=%{pginstdir}/bin/:$PATH %{__make} %{?_smp_mflags} DESTDIR=%{buildroot} install
# Install README and howto file under PostgreSQL installation directory:
%{__install} -d %{buildroot}%{pginstdir}/doc/extension
%{__install} -m 644 README.md %{buildroot}%{pginstdir}/doc/extension/README-%{pname}.md
%{__rm} -f %{buildroot}%{pginstdir}/doc/extension/README.md

%files
%defattr(-,root,root,-)
%doc %{pginstdir}/doc/extension/README-%{pname}.md
%{pginstdir}/lib/%{pname}.so
%{pginstdir}/share/extension/%{pname}*.sql
%{pginstdir}/share/extension/%{pname}.control

%if %llvm
%files llvmjit
  %{pginstdir}/lib/bitcode/%{pname}*.bc
  %{pginstdir}/lib/bitcode/%{pname}/src/*.bc
%endif

%files devel
%defattr(-,root,root,-)
%{pginstdir}/include/server/rum*.h

%changelog
* Wed Apr 08 2026 Manika Singhal <manika.singhal@percona.com> 1.3.15
- Initial build
