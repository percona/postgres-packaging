%global sname	hll
%global pgmajorversion %{pgmajor}

%{!?llvm:%global llvm 1}

Summary:	PostgreSQL extension adding HyperLogLog data structures as a native data type
Name:		percona-%{sname}_%{pgmajorversion}
Version:	%{version}
Release:	%{release}%{?dist}
License:	Apache
Source0:	percona-%{sname}_%{pgmajorversion}-%{version}.tar.gz
Packager:       Percona Development Team <https://jira.percona.com>
Vendor:         Percona, LLC
URL:		https://github.com/citusdata/postgresql-%{sname}
BuildRequires:	percona-postgresql%{pgmajorversion}-devel libxml2-devel
Requires:	percona-postgresql%{pgmajorversion}-server

%description
This Postgres module introduces a new data type hll which is a
HyperLogLog data structure. HyperLogLog is a fixed-size, set-like
structure used for distinct value counting with tunable precision. For
example, in 1280 bytes hll can estimate the count of tens of billions of
distinct values with only a few percent error.

%if %llvm
%package llvmjit
Summary:	Just-in-time compilation support for hll
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
This packages provides JIT support for hll
%endif

%prep
%setup -q -n percona-%{sname}_%{pgmajorversion}-%{version}

%build
PG_CONFIG=%{pginstdir}/bin/pg_config %{__make} %{?_smp_mflags}

%install
PG_CONFIG=%{pginstdir}/bin/pg_config %make_install
%{__mkdir} -p %{buildroot}%{pginstdir}/doc/extension
%{__cp} README.md %{buildroot}%{pginstdir}/doc/extension/README-%{sname}.md

%files
%defattr(-,root,root,-)
%doc CHANGELOG.md
%doc %{pginstdir}/doc/extension/README-%{sname}.md
%{pginstdir}/lib/%{sname}.so
%{pginstdir}/share/extension/%{sname}-*.sql
%{pginstdir}/share/extension/%{sname}.control

%if %llvm
%files llvmjit
   %{pginstdir}/lib/bitcode/%{sname}*.bc
   %{pginstdir}/lib/bitcode/%{sname}/src/*.bc
%endif

%changelog
* Mon Apr 07 2026 Surabhi Bhat <surabhi.bhat@percona.com> - 2.19-1
- Initial build
