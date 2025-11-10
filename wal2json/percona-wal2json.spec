%global sname wal2json
%global pgmajorversion %{pgmajor}
%global _default_patch_fuzz 2

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
Provides:	%{name} %{sname}%{pgmajorversion}
Requires:	percona-postgresql%{pgmajorversion}-server
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
%{__make} %{?_smp_mflags}

%install
%{__rm} -rf %{buildroot}
%make_install DESTDIR=%{buildroot}
%{__install} -d %{buildroot}/%{pginstdir}/doc/extension/
%{__mv} README.md  %{buildroot}/%{pginstdir}/doc/extension/README-%{sname}.md

%postun -p /sbin/ldconfig
%post -p /sbin/ldconfig

%files
%doc %{pginstdir}/doc/extension/README-%{sname}.md
%{pginstdir}/lib/%{sname}.so
%{pginstdir}/lib/bitcode/%{sname}*.bc
%{pginstdir}/lib/bitcode/%{sname}/*.bc

%changelog
* Tue Feb  9 2021 Evgeniy Patlan <evgeniy.patlan@percona.com> 2.3-2
- Initial build

