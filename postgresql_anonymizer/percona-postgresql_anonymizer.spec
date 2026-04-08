%global sname	postgresql_anonymizer
%global extname	anon
%global pgmajorversion %{pgmajor}

# pgrx version required by this release
%global pgrx_version 0.16.1

Summary:	Anonymization & Data Masking for PostgreSQL
Name:		percona-%{sname}_%{pgmajorversion}
Version:	%{version}
Release:	%{release}%{?dist}
License:	PostgreSQL
Source0:	percona-%{sname}_%{pgmajorversion}-%{version}.tar.gz
Packager:	Percona Development Team <https://jira.percona.com>
Vendor:		Percona, LLC
URL:		https://gitlab.com/dalibo/postgresql_anonymizer
BuildRequires:	percona-postgresql%{pgmajorversion}-devel
BuildRequires:	gcc clang-devel openssl-devel pkg-config rust cargo
Requires:	percona-postgresql%{pgmajorversion}-server

%description
PostgreSQL Anonymizer is an extension to mask or replace personally
identifiable information (PII) or commercially sensitive data from a
PostgreSQL database. The project relies on a declarative approach of
anonymization. This means you can declare the masking rules using the
PostgreSQL Data Definition Language (DDL).

%prep
%setup -q -n percona-%{sname}_%{pgmajorversion}-%{version}

%build
export PATH=%{pginstdir}/bin:$PATH

cargo install cargo-pgrx --version %{pgrx_version} --locked
cargo pgrx init --pg%{pgmajorversion}=%{pginstdir}/bin/pg_config

cargo pgrx package --pg-config %{pginstdir}/bin/pg_config --features pg%{pgmajorversion}

PGRX_TARGET=target/release/%{extname}-pg%{pgmajorversion}
mkdir -p ${PGRX_TARGET}%{pginstdir}/share/extension/%{extname}/
install data/*.csv ${PGRX_TARGET}%{pginstdir}/share/extension/%{extname}/
install data/en_US/fake/*.csv ${PGRX_TARGET}%{pginstdir}/share/extension/%{extname}/

%install
%{__rm} -rf %{buildroot}
PGRX_TARGET=target/release/%{extname}-pg%{pgmajorversion}

%{__mkdir} -p %{buildroot}%{pginstdir}/lib
%{__mkdir} -p %{buildroot}%{pginstdir}/share/extension

install -m 755 ${PGRX_TARGET}%{pginstdir}/lib/%{extname}.so %{buildroot}%{pginstdir}/lib/
cp -a ${PGRX_TARGET}%{pginstdir}/share/extension/%{extname}.control %{buildroot}%{pginstdir}/share/extension/
cp -a ${PGRX_TARGET}%{pginstdir}/share/extension/%{extname}--*.sql %{buildroot}%{pginstdir}/share/extension/
cp -a ${PGRX_TARGET}%{pginstdir}/share/extension/%{extname}/ %{buildroot}%{pginstdir}/share/extension/%{extname}/

%files
%defattr(-,root,root,-)
%doc README.md
%{pginstdir}/lib/%{extname}.so
%{pginstdir}/share/extension/%{extname}.control
%{pginstdir}/share/extension/%{extname}--*.sql
%{pginstdir}/share/extension/%{extname}/

%changelog
* Wed Apr 08 2026 Surabhi Bhat <surabhi.bhat@percona.com> - 3.0.13-1
- Initial build
