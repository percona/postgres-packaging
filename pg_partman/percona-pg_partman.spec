%global sname	pg_partman
%global pgmajorversion %{pgmajor}

%{!?llvm:%global llvm 1}

Summary:	A PostgreSQL extension to manage partitioned tables by time or ID
Name:		percona-%{sname}_%{pgmajorversion}
Version:	%{version}
Release:	%{release}%{?dist}
License:	PostgreSQL
Source0:	percona-%{sname}_%{pgmajorversion}-%{version}.tar.gz
Packager:	Percona Development Team <https://jira.percona.com>
Vendor:		Percona, LLC
URL:		https://github.com/pgpartman/%{sname}
BuildRequires:	percona-postgresql%{pgmajorversion}-devel
Requires:	percona-postgresql%{pgmajorversion}-server
Requires:	python3-psycopg2

%description
pg_partman is an extension to create and manage both time-based and
number-based table partition sets. It uses the built-in declarative
partitioning features that PostgreSQL provides and builds upon those
with additional features and enhancements to make managing partitions
easier. A background worker (BGW) process is included to automatically
run partition maintenance without the need of an external scheduler.

%if %llvm
%package llvmjit
Summary:	Just-in-time compilation support for pg_partman
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
This packages provides JIT support for pg_partman
%endif

%prep
%setup -q -n percona-%{sname}_%{pgmajorversion}-%{version}

%build
find . -iname "*.py" -exec sed -i "s/\/usr\/bin\/env python/\/usr\/bin\/python3/g" {} \;

USE_PGXS=1 PATH=%{pginstdir}/bin/:$PATH %{__make} %{?_smp_mflags}

%install
%{__rm} -rf %{buildroot}

USE_PGXS=1 PATH=%{pginstdir}/bin/:$PATH %{__make} %{?_smp_mflags} install DESTDIR=%{buildroot}

%files
%defattr(644,root,root,755)
%doc %{pginstdir}/doc/extension/%{sname}.md
%doc %{pginstdir}/doc/extension/fix_missing_procedures.md
%doc %{pginstdir}/doc/extension/migrate_to_declarative.md
%doc %{pginstdir}/doc/extension/migrate_to_partman.md
%doc %{pginstdir}/doc/extension/pg_partman_*_upgrade.md
%doc %{pginstdir}/doc/extension/pg_partman_howto.md
%{pginstdir}/lib/%{sname}_bgw.so
%{pginstdir}/share/extension/%{sname}*.sql
%{pginstdir}/share/extension/%{sname}.control
%attr(755, root, -) %{pginstdir}/bin/check_unique_constraint.py
%attr(755, root, -) %{pginstdir}/bin/dump_partition.py
%attr(755, root, -) %{pginstdir}/bin/vacuum_maintenance.py

%if %llvm
%files llvmjit
   %{pginstdir}/lib/bitcode/src/pg_partman_bgw.index.bc
   %{pginstdir}/lib/bitcode/src/pg_partman_bgw/src/pg_partman_bgw.bc
%endif

%changelog
* Tue Apr 08 2026 Surabhi Bhat <surabhi.bhat@percona.com> - 5.4.3-1
- Initial build
