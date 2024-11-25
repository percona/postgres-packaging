%define pgmajorversion 16
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
Release:	1%{?dist}
Summary:	PostgreSQL extension for transparent data encryption.
License:	PostgreSQL
URL:		https://github.com/%{sname}/%{sname}/
Source0:	%{name}-%{version}.tar.gz

BuildRequires:	percona-postgresql%{pgmajorversion}-devel json-c-devel libcurl-devel openssl-devel
Requires:	postgresql%{pgmajorversion}-server json-c curl openssl

%description
pg_tde is a PostgreSQL extension enabling transparent data encryption.
It seamlessly encrypts and decrypts data in PostgreSQL databases, ensuring security and compliance.

%if %llvm
%package llvmjit
Summary:	Just-in-time compilation support for pg_tde
Requires:	%{name}%{?_isa} = %{version}-%{release}
#%%if 0%%{?rhel} && 0%%{?rhel} == 7
#%%ifarch aarch64
#Requires:	llvm-toolset-7.0-llvm >= 7.0.1
#%%else
#Requires:	llvm5.0 >= 5.0
#%%endif
#%%endif
%if 0%{?suse_version} >= 1315 && 0%{?suse_version} <= 1499
BuildRequires:	llvm6-devel clang6-devel
#Requires:	llvm6
%endif
%if 0%{?suse_version} >= 1500
BuildRequires:	llvm15-devel clang15-devel
#Requires:	llvm15
%endif
#%%if 0%%{?fedora} || 0%%{?rhel} >= 8
#Requires:	llvm => 13.0
#%%endif

%description llvmjit
This packages provides JIT support for pg_tde
%endif

%prep
%setup -q -n %{sname}-%{version}

%build
%configure
sed -i 's:PG_CONFIG = pg_config:PG_CONFIG = /usr/pgsql-%{pgmajorversion}/bin/pg_config:' Makefile
USE_PGXS=1 PATH=%{pginstdir}/bin:$PATH %{__make} #%{?_smp_mflags}

%install
%{__rm} -rf %{buildroot}
USE_PGXS=1 PATH=%{pginstdir}/bin:$PATH %{__make} %{?_smp_mflags} install DESTDIR=%{buildroot}

#Remove header file, we don't need it right now:
#%{__rm} %{buildroot}%{pginstdir}/include/server/extension/%{pname}/%{pname}.h

%files
%doc README.md
%license LICENSE
%{pginstdir}/lib/%{pname}.so
%{pginstdir}/share/extension//%{pname}.control
%{pginstdir}/share/extension/%{pname}*sql
%if %llvm
%files llvmjit
   %{pginstdir}/lib/bitcode/%{pname}*.bc
   %{pginstdir}/lib/bitcode/%{pname}/src/*.bc
   %{pginstdir}/lib/bitcode/%{pname}/src/access/*.bc
   %{pginstdir}/lib/bitcode/%{pname}/src/catalog/*.bc
   %{pginstdir}/lib/bitcode/%{pname}/src/common/*.bc
   %{pginstdir}/lib/bitcode/%{pname}/src/encryption/*.bc
   %{pginstdir}/lib/bitcode/%{pname}/src/keyring/*.bc
   %{pginstdir}/lib/bitcode/%{pname}/src/transam/*.bc
   %{pginstdir}/lib/bitcode/%{pname}/src/smgr/*.bc
%endif

%changelog
* Tue Apr 2 2024 Muhammad Aqeel <muhammad.aqeel@percona.com> - 1.0.0-1
- Initial build 1.0.0

