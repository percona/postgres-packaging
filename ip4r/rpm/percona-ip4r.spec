%global debug_package %{nil}
%global pgmajorversion %{pgmajor}
%global pname ip4r
%global sname percona-ip4r_%{pgmajorversion}

%{!?llvm:%global llvm 1}

Summary:	IPv4/v6 and IPv4/v6 range index type for PostgreSQL
Name:		  %{sname}
Version:	%{version}
Release:	%{release}%{?dist}
License:	PostgreSQL
Source0:	%{sname}-%{version}.tar.gz
URL:		  https://github.com/RhodiumToad/ip4r
Packager:   Percona Development Team <https://jira.percona.com>
Vendor:     Percona, LLC

BuildRequires:	percona-postgresql%{pgmajorversion}-devel
Requires:	percona-postgresql%{pgmajorversion}-server

Provides:	percona-postgresql-ip4r = %{version}-%{release}
Obsoletes:	%{pname}%{pgmajorversion} < 2.4.1-2

%description
ip4r is IPv4/v6 and IPv4/v6 range index type for PostgreSQL. ip4, ip4r, ip6,
ip6r, ipaddress and iprange are types that contain a single IPv4/IPv6 address
and a range of IPv4/IPv6 addresses respectively. They can be used as a more
flexible, indexable version of the cidr type.

%if %llvm
%package llvmjit
Summary:	Just-in-time compilation support for ip4r
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
This package provides JIT support for ip4r
%endif

%prep
%setup -q -n %{sname}-%{version}

%build
USE_PGXS=1 PATH=%{pginstdir}/bin/:$PATH %{__make} %{?_smp_mflags}

%install
%{__rm} -rf %{buildroot}
USE_PGXS=1 PATH=%{pginstdir}/bin/:$PATH %{__make} %{?_smp_mflags} install DESTDIR=%{buildroot}

%{__rm} -f %{buildroot}%{pginstdir}/include/server/extension/ip4r/ipr.h

%files
%defattr(644,root,root,755)
%doc %{pginstdir}/doc/extension/README.ip4r
%{pginstdir}/lib/ip4r.so
%{pginstdir}/share/extension/ip4r*

%if %llvm
%files llvmjit
   %{pginstdir}/lib/bitcode/%{pname}*.bc
   %{pginstdir}/lib/bitcode/%{pname}/src/*.bc
%endif

%changelog
* Thu Apr 09 2026 Manika Singhal <manika.singhal@percona.com> 2.4.2
- Initial build
