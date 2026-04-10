%global debug_package %{nil}
%global pgmajorversion %{pgmajor}
%global pname pgvectorscale
%global sname	percona-pgvectorscale_%{pgmajorversion}

Summary:        Vector scaling extension for PostgreSQL
Name:           %{sname}
Version:        %{version}
Release:        %{release}%{?dist}
License:        PostgreSQL
URL:            https://github.com/timescale/pgvectorscale
Source0:        %{sname}-%{version}.tar.gz
Packager:       Percona Development Team <https://jira.percona.com>
Vendor:         Percona, LLC

BuildRequires:  rust-toolset cargo jq clang llvm-devel
BuildRequires:  percona-postgresql%{pgmajorversion}-devel

Requires:       percona-postgresql%{pgmajorversion}-server
Requires:       percona-pgvector_%{pgmajorversion}

%description
pgvectorscale enhances pgvector with scalable indexing and storage.

%prep
%setup -q -n %{sname}-%{version}

%build
cd pgvectorscale
PGRX_VERSION=$(cargo metadata --format-version 1 | jq -r '.packages[] | select(.name == "pgrx") | .version')
cargo install --locked cargo-pgrx --version ${PGRX_VERSION}
cargo pgrx init --pg%{pgmajorversion}=%{pginstdir}/bin/pg_config
cargo build --release --no-default-features --features pg%{pgmajorversion}

%install
rm -rf %{buildroot}
install -d %{buildroot}
cd pgvectorscale
cargo pgrx package --no-default-features --features pg%{pgmajorversion} --pg-config %{pginstdir}/bin/pg_config
cp -r ../target/release/vectorscale-pg%{pgmajorversion}/* %{buildroot}/

%files
%{pginstdir}/lib/vectorscale*.so
%{pginstdir}/share/extension/vectorscale*
%license LICENSE

%changelog
* Tue Apr 07 2026 Manika Singhal <manika.singhal@percona.com> 0.9.0
- Initial build