%global debug_package %{nil}
%global pgmajorversion %{pgmajor}
%global pname postgresql-unit
%global sname percona-postgresql-unit_%{pgmajorversion}

%{!?llvm:%global llvm 1}

Summary:	SI Units for PostgreSQL
Name:		  %{sname}
Version:	%{version}
Release:	%{release}%{?dist}
License:	BSD
Source0:	%{sname}-%{version}.tar.gz
URL:		https://github.com/ChristophBerg/%{pname}
Packager:   Percona Development Team <https://jira.percona.com>
Vendor:     Percona, LLC

BuildRequires:	percona-postgresql%{pgmajorversion}-devel flex
Requires:	percona-postgresql%{pgmajorversion}-server

%description
postgresql-unit implements a PostgreSQL datatype for SI units, plus byte.
The base units can be combined to named and unnamed derived units using
operators defined in the PostgreSQL type system. SI prefixes are used for
input and output, and quantities can be converted to arbitrary scale.

%if %llvm
%package llvmjit
Summary:	Just-in-time compilation support for postgresql-unit
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
This package provides JIT support for postgresql-unit
%endif

%prep
%setup -q -n %{sname}-%{version}

%build
USE_PGXS=1 PATH=%{pginstdir}/bin/:$PATH %{__make} %{?_smp_mflags}

%install
%{__rm} -rf %{buildroot}
USE_PGXS=1 PATH=%{pginstdir}/bin/:$PATH %{__make} %{?_smp_mflags} install DESTDIR=%{buildroot}
# Install README and howto file under PostgreSQL installation directory:
%{__install} -d %{buildroot}%{pginstdir}/doc/extension
%{__install} -m 644 README.md %{buildroot}%{pginstdir}/doc/extension/README-%{pname}.md

%files
%defattr(644,root,root,755)
%doc %{pginstdir}/doc/extension/README-%{pname}.md
%{pginstdir}/lib/unit.so
%{pginstdir}/share/extension/unit*.sql
%{pginstdir}/share/extension/unit.control
%{pginstdir}/share/extension/unit_prefixes.data
%{pginstdir}/share/extension/unit_units.data

%if %llvm
%files llvmjit
   %{pginstdir}/lib/bitcode/uni*.bc
   %{pginstdir}/lib/bitcode/unit/*.bc
%endif

%changelog
* Wed Apr 08 2026 Manika Singhal <manika.singhal@percona.com> 7.10
- Initial build