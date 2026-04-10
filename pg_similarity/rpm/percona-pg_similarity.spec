%global debug_package %{nil}
%global pgmajorversion %{pgmajor}
%global pname pg_similarity
%global sname percona-pg_similarity_%{pgmajorversion}

%{!?llvm:%global llvm 1}

Summary:	   Set of functions and operators for executing similarity queries for PostgreSQL
Name:		   %{sname}
Version:	   %{version}
Release:	   %{release}%{?dist}
URL:		   https://github.com/eulerto/%{pname}
Source0:	   %{sname}-%{version}.tar.gz
Patch0:		%{pname}-hamming.patch
License:	   BSD
Packager:   Percona Development Team <https://jira.percona.com>
Vendor:     Percona, LLC

BuildRequires:	percona-postgresql%{pgmajorversion}-devel
Requires:	percona-postgresql%{pgmajorversion}-server

%description
pg_similarity is an extension to support similarity queries on PostgreSQL.
The implementation is tightly integrated in the RDBMS in the sense that it
defines operators so instead of the traditional operators (= and <>) you can
use ~~~ and ! (any of these operators represents a similarity function).

%if %llvm
%package llvmjit
Summary:	Just-in-time compilation support for pg_similarity
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
This package provides JIT support for pg_similarity
%endif

%prep
%setup -q -n %{sname}-%{version}
%patch -P 0 -p0

%build
PATH=%{pginstdir}/bin:$PATH %{__make} USE_PGXS=1 %{?_smp_mflags}

%install
%{__rm} -rf %{buildroot}
PATH=%{pginstdir}/bin:$PATH %{__make} USE_PGXS=1 %{?_smp_mflags} DESTDIR=%{buildroot} install

# Install sample config file under the PostgreSQL extension directory:
%{__cp} pg_similarity.conf.sample %{buildroot}%{pginstdir}/share/extension/

# Install README file under PostgreSQL installation directory:
%{__install} -d %{buildroot}%{pginstdir}/doc/extension
%{__install} -m 755 README.md %{buildroot}%{pginstdir}/doc/extension/README-%{pname}.md

%post -p /sbin/ldconfig
%postun -p /sbin/ldconfig

%files
%defattr(-,root,root)
%config %{pginstdir}/share/extension/%{pname}.conf.sample
%doc %{pginstdir}/doc/extension/README-%{pname}.md
%{pginstdir}/lib/%{pname}.so
%{pginstdir}/share/extension/%{pname}*.sql
%{pginstdir}/share/extension/%{pname}.control

%if %llvm
%files llvmjit
   %{pginstdir}/lib/bitcode/%{pname}*.bc
   %{pginstdir}/lib/bitcode/%{pname}/*.bc
%endif

%changelog
* Tue Apr 07 2026 Manika Singhal <manika.singhal@percona.com> 1.0
- Initial build
