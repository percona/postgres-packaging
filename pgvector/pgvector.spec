%define pgmajorversion %{pgmajor}
%define pginstdir /usr/pgsql-%{pgmajorversion}/
%global pname vector
%global sname percona-pgvector_%{pgmajorversion}

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
Summary:	Open-source vector similarity search for Postgres
License:	PostgreSQL
URL:		https://github.com/%{sname}/%{sname}/
Source0:	%{name}-%{version}.tar.gz

BuildRequires:	percona-postgresql%{pgmajorversion}-devel
Requires:	postgresql%{pgmajorversion}-server

%description
Open-source vector similarity search for Postgres. Supports L2 distance,
inner product, and cosine distance

%if %llvm
%package llvmjit
Summary:	Just-in-time compilation support for pgvector
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
This packages provides JIT support for pgvector
%endif

%prep
%setup -q -n %{sname}-%{version}

%build
sed -i 's:PG_CONFIG = pg_config:PG_CONFIG = /usr/pgsql-%{pgmajorversion}/bin/pg_config:' Makefile
USE_PGXS=1 PATH=%{pginstdir}/bin:$PATH %{__make} %{?_smp_mflags}

%install
%{__rm} -rf %{buildroot}
USE_PGXS=1 PATH=%{pginstdir}/bin:$PATH %{__make} %{?_smp_mflags} install DESTDIR=%{buildroot}

#Remove header file, we don't need it right now:
%{__rm} %{buildroot}%{pginstdir}/include/server/extension/%{pname}/%{pname}.h

%files
%doc README.md
%license LICENSE
%{pginstdir}/lib/%{pname}.so
%{pginstdir}/share/extension//%{pname}.control
%{pginstdir}/share/extension/%{pname}*sql
%dir %{pginstdir}/include/server/extension/vector/
%{pginstdir}/include/server/extension/vector/*.h

%if %llvm
%files llvmjit
   %{pginstdir}/lib/bitcode/%{pname}*.bc
   %{pginstdir}/lib/bitcode/%{pname}/src/*.bc
%endif

%changelog
* Thu Jun 27 2024 Muhammad Aqeel <muhammad.aqeel@percona.com> - 0.7.2-1
- Initial build 0.7.2

