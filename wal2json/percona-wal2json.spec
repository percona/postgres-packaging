%global sname wal2json
%global pgmajorversion %{pgmajor}
%global _default_patch_fuzz 2

%if 0%{?rhel} >= 8 && 0%{?rhel} <= 9
%global gts_version 14
%endif

%{!?llvm:%global llvm 1}
%{!?runselftest:%global runselftest 0}
# Propagate %%llvm into the actual build: PGXS decides whether to invoke
# clang/llvm-config based on with_llvm from the installed postgresql*-devel's
# Makefile.global, not from this spec's %%llvm. Without passing with_llvm=no
# through to make, setting %%llvm 0 here only drops the llvm BuildRequires/
# files, while the build still tries to run clang regardless.
%if %llvm
%global with_llvm_arg %{nil}
%else
%global with_llvm_arg with_llvm=no
%endif

Summary:	JSON output plugin for changeset extraction
Name:		percona-%{sname}%{pgmajorversion}
Version:	%{version}
Release:	%{release}%{?dist}
Epoch:		1
License:	BSD
Source0:	percona-%{sname}-%{version}.tar.gz
Patch0:		%{sname}-pg%{pgmajorversion}-makefile-pgxs.patch
URL:		https://github.com/eulerto/wal2json
BuildRequires:	percona-postgresql%{pgmajorversion}-devel
%if %llvm
BuildRequires:        clang llvm
%endif
%if 0%{?gts_version}
BuildRequires:  gcc-toolset-%{gts_version}-gcc gcc-toolset-%{gts_version}-gcc-c++ gcc-toolset-%{gts_version}-annobin-plugin-gcc
%endif
Provides:	%{name} %{sname}%{pgmajorversion}
Requires:	percona-postgresql%{pgmajorversion}-server
%if %runselftest
BuildRequires:        percona-postgresql%{pgmajorversion}-server pgdg-srpm-macros >= 2.0.0
%endif
Packager:       Percona Development Team <https://jira.percona.com>
Vendor:         Percona, LLC

%description
wal2json is an output plugin for logical decoding. It means that the
plugin have access to tuples produced by INSERT and UPDATE. Also,
UPDATE/DELETE old row versions can be accessed depending on the
configured replica identity. Changes can be consumed using the streaming
protocol (logical replication slots) or by a special SQL API.

The wal2json output plugin produces a JSON object per transaction. All
of the new/old tuples are available in the JSON object. Also, there are
options to include properties such as transaction timestamp,
schema-qualified, data types, and transaction ids.

%prep
%setup -q -n percona-%{sname}-%{version}
%patch -P 0 -p0

%build
%if 0%{?gts_version}
	source /opt/rh/gcc-toolset-%{gts_version}/enable
%endif
USE_PGXS=1 PATH=%{pginstdir}/bin/:$PATH %{__make} %{?_smp_mflags} %{with_llvm_arg}

%install
%{__rm} -rf %{buildroot}
USE_PGXS=1 PATH=%{pginstdir}/bin/:$PATH %make_install %{with_llvm_arg} DESTDIR=%{buildroot}
%{__install} -d %{buildroot}/%{pginstdir}/doc/extension/
%{__mv} README.md  %{buildroot}/%{pginstdir}/doc/extension/README-%{sname}.md

%postun -p /sbin/ldconfig
%post -p /sbin/ldconfig

%check
%if %runselftest
# The tests create logical replication slots. Recent PostgreSQL minor
# releases only allow the output plugins listed in output_plugin_libraries,
# so add wal2json there when it exists.
%pgdg_check_init
opl=
if postgres --describe-config | grep -q '^output_plugin_libraries'; then
        opl="output_plugin_libraries = 'pgoutput, wal2json'"
fi
pgdg_check_start main "wal_level = logical" "max_replication_slots = 10" \
        ${opl:+"$opl"}
pgdg_installcheck %{with_llvm_arg}
%endif

%files
%doc %{pginstdir}/doc/extension/README-%{sname}.md
%{pginstdir}/lib/%{sname}.so
%if %llvm
%dir %{pginstdir}/lib/bitcode
%dir %{pginstdir}/lib/bitcode/%{sname}
%{pginstdir}/lib/bitcode/%{sname}*.bc
%{pginstdir}/lib/bitcode/%{sname}/*.bc
%endif

%changelog
* Tue Feb  9 2021 Evgeniy Patlan <evgeniy.patlan@percona.com> 2.3-2
- Initial build

