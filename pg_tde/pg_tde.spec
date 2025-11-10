
%define pgmajorversion %{pgmajor}
%define pginstdir /usr/pgsql-%{pgmajorversion}/
%global pname pg_tde
%global sname percona-pg_tde_%{pgmajorversion}

%ifarch ppc64 ppc64le s390 s390x armv7hl
 %if 0%{?rhel} && 0%{?rhel} == 7
  %{!?llvm:%global llvm 0}
 %else
  %{!?llvm:%global llvm 1}
 %endif
%else
 %{!?llvm:%global llvm 1}
%endif

Name:		%{sname}
Version:	%{version}
Release:	%{release}%{?dist}
Summary:	PostgreSQL extension for transparent data encryption.
License:	PostgreSQL
URL:		https://github.com/%{sname}/%{sname}/
Source0:	%{name}-%{version}.tar.gz

BuildRequires:	percona-postgresql%{pgmajorversion}-devel chrpath json-c-devel openssl-devel libcurl-devel lz4-devel zlib-devel libzstd-devel libxml2-devel libxslt-devel libselinux-devel pam-devel krb5-devel readline-devel

Requires:	postgresql%{pgmajorversion}-server json-c curl openssl

%description
pg_tde is a PostgreSQL extension enabling transparent data encryption.
It seamlessly encrypts and decrypts data in PostgreSQL databases, ensuring security and compliance.

%if %llvm
%package llvmjit
Summary:	Just-in-time compilation support for pg_tde
Requires:	%{name}%{?_isa} = %{version}-%{release}
%if 0%{?suse_version} >= 1315 && 0%{?suse_version} <= 1499
BuildRequires:	llvm6-devel clang6-devel
%endif
%if 0%{?suse_version} >= 1500
BuildRequires:	llvm15-devel clang15-devel
%endif

%description llvmjit
This packages provides JIT support for pg_tde
%endif

%prep
%setup -q -n %{sname}-%{version}

%build
sed -i 's:PG_CONFIG = pg_config:PG_CONFIG = /usr/pgsql-%{pgmajorversion}/bin/pg_config:' Makefile
USE_PGXS=1 PATH=%{pginstdir}/bin:$PATH %{__make}

%install
%{__rm} -rf %{buildroot}
USE_PGXS=1 PATH=%{pginstdir}/bin:$PATH %{__make} %{?_smp_mflags} install DESTDIR=%{buildroot}
find %{buildroot}%{pginstdir} -type f \( -name '*.so' -o -name 'pg_tde_*' \) -exec chrpath --delete {} \; 2>/dev/null || true

#Remove header file, we don't need it right now:
#%{__rm} %{buildroot}%{pginstdir}/include/server/extension/%{pname}/%{pname}.h

%files
%doc README.md
%license COPYRIGHT
%{pginstdir}/bin/pg_tde_change_key_provider
%{pginstdir}/bin/pg_tde_archive_decrypt
%{pginstdir}/bin/pg_tde_restore_encrypt
%{pginstdir}/lib/%{pname}.so
%{pginstdir}/share/extension//%{pname}.control
%{pginstdir}/share/extension/%{pname}*sql
%{pginstdir}/bin/pg_tde_basebackup
%{pginstdir}/bin/pg_tde_checksums
%{pginstdir}/bin/pg_tde_resetwal
%{pginstdir}/bin/pg_tde_rewind
%{pginstdir}/bin/pg_tde_waldump
%{pginstdir}/lib/bitcode/pg_tde.index.bc
%{pginstdir}/lib/bitcode/pg_tde/src/access/pg_tde_tdemap.bc
%{pginstdir}/lib/bitcode/pg_tde/src/access/pg_tde_xlog.bc
%{pginstdir}/lib/bitcode/pg_tde/src/access/pg_tde_xlog_keys.bc
%{pginstdir}/lib/bitcode/pg_tde/src/access/pg_tde_xlog_smgr.bc
%{pginstdir}/lib/bitcode/pg_tde/src/catalog/tde_keyring.bc
%{pginstdir}/lib/bitcode/pg_tde/src/catalog/tde_keyring_parse_opts.bc
%{pginstdir}/lib/bitcode/pg_tde/src/catalog/tde_principal_key.bc
%{pginstdir}/lib/bitcode/pg_tde/src/common/pg_tde_utils.bc
%{pginstdir}/lib/bitcode/pg_tde/src/encryption/enc_aes.bc
%{pginstdir}/lib/bitcode/pg_tde/src/encryption/enc_tde.bc
%{pginstdir}/lib/bitcode/pg_tde/src/keyring/keyring_api.bc
%{pginstdir}/lib/bitcode/pg_tde/src/keyring/keyring_curl.bc
%{pginstdir}/lib/bitcode/pg_tde/src/keyring/keyring_file.bc
%{pginstdir}/lib/bitcode/pg_tde/src/keyring/keyring_kmip.bc
%{pginstdir}/lib/bitcode/pg_tde/src/keyring/keyring_kmip_impl.bc
%{pginstdir}/lib/bitcode/pg_tde/src/keyring/keyring_vault.bc
%{pginstdir}/lib/bitcode/pg_tde/src/libkmip/libkmip/src/kmip.bc
%{pginstdir}/lib/bitcode/pg_tde/src/libkmip/libkmip/src/kmip_bio.bc
%{pginstdir}/lib/bitcode/pg_tde/src/libkmip/libkmip/src/kmip_locate.bc
%{pginstdir}/lib/bitcode/pg_tde/src/libkmip/libkmip/src/kmip_memset.bc
%{pginstdir}/lib/bitcode/pg_tde/src/pg_tde.bc
%{pginstdir}/lib/bitcode/pg_tde/src/pg_tde_event_capture.bc
%{pginstdir}/lib/bitcode/pg_tde/src/pg_tde_guc.bc
%{pginstdir}/lib/bitcode/pg_tde/src/smgr/pg_tde_smgr.bc



%changelog
* Wed Nov 5 2025 Manika Singhal <manika.singhal@percona.com> - 2.1-1
- Update 2.1

* Tue Apr 2 2024 Muhammad Aqeel <muhammad.aqeel@percona.com> - 1.0.0-1
- Initial build 1.0.0
