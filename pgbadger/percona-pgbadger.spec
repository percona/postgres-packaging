%global debug_package %{nil}
%global sname pgbadger

Summary:	A fast PostgreSQL log analyzer
Name:		percona-pgbadger
Version:	%{version}
Release:	%{release}%{?dist}
License:	PostgreSQL
Source0:	%{name}-%{version}.tar.gz
URL:		https://github.com/darold/%{sname}
BuildRequires:        perl make
Requires:	perl-Text-CSV_XS perl
Provides:       pgbadger
Epoch:          1
Packager:       Percona Development Team <https://jira.percona.com>
Vendor:         Percona, LLC

%description
pgBadger is a PostgreSQL log analyzer build for speed with fully
detailed reports from your PostgreSQL log file. It's a single and small
Perl script that aims to replace and outperform the old php script
pgFouine.

pgBadger is written in pure Perl language. It uses a javascript library
to draw graphs so that you don't need additional Perl modules or any
other package to install. Furthermore, this library gives us more
features such as zooming.

pgBadger is able to autodetect your log file format (syslog, stderr or
csvlog). It is designed to parse huge log files as well as gzip
compressed file.

%prep
%setup -q

%build
%{__perl} Makefile.PL INSTALLDIRS=vendor
%{__make} %{?_smp_mflags}

%install
%{__rm} -rf %{buildroot}
%{__make} pure_install PERL_INSTALL_ROOT=%{buildroot}
%{__rm} -f %{buildroot}/%perl_vendorarch/auto/pgBadger/.packlist

%files
%doc README
%license LICENSE
%attr(755,root,root) %{_bindir}/%{sname}
%{_mandir}/man1/%{sname}.1p.gz

%changelog
* Wed Mar 10 2021 Evgeniy Patlan <evgeniy.patlan@percona.com> 11.5-1
- Initial build 

