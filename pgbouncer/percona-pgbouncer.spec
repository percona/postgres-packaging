%global systemd_enabled 1
%global sname pgbouncer

Name:		percona-pgbouncer
Version:	1.24.0
Release:	1%{?dist}
Summary:	Lightweight connection pooler for PostgreSQL
License:	MIT and BSD
URL:		https://www.pgbouncer.org/
Packager:       Percona Development Team <https://jira.percona.com>
Vendor:         Percona, LLC
Source0:	%{name}-%{version}.tar.gz
Source1:        %{sname}.init
Source2:	%{sname}.sysconfig
Source3:	%{sname}.logrotate
Source4:	%{sname}.service
Source5:	%{sname}.service.rhel7
Patch0:		%{sname}-ini.patch

BuildRequires:	libevent-devel libtool pandoc
Requires:	libevent-devel
Requires:	python3-psycopg2
BuildRequires:	openssl-devel pam-devel

%if %{systemd_enabled}
BuildRequires:		systemd
Requires:		systemd
Requires(post):		systemd-sysv
Requires(post):		systemd
Requires(preun):	systemd
Requires(postun):	systemd
%endif
Requires:	/usr/sbin/useradd
Provides:   pgbouncer
Epoch:		1

%description
pgbouncer is a lightweight connection pooler for PostgreSQL.
pgbouncer uses libevent for low-level socket handling.


%prep
%setup -q
%patch0 -p0


%build
./autogen.sh
sed -i.fedora \
 -e 's|-fomit-frame-pointer||' \
 -e '/BININSTALL/s|-s||' \
 configure

%configure \
        --datadir=%{_datadir} \
%if 0%{?rhel} >= 9
        --with-cares --disable-evdns \
%else
        --without-cares \
%endif
        --with-systemd \
        --with-pam

%{__make} %{?_smp_mflags} V=1

%install
%{__rm} -rf %{buildroot}
%{__make} install DESTDIR=%{buildroot}
%{__install} -p -d %{buildroot}%{_sysconfdir}/%{sname}/
%{__install} -p -d %{buildroot}%{_sysconfdir}/sysconfig
%{__install} -p -m 644 %{SOURCE2} %{buildroot}%{_sysconfdir}/sysconfig/%{sname}
%{__install} -p -m 644 etc/pgbouncer.ini %{buildroot}%{_sysconfdir}/%{sname}
%{__install} -p -m 700 etc/mkauth.py %{buildroot}%{_sysconfdir}/%{sname}/

%if %{systemd_enabled}
%{__install} -d %{buildroot}%{_unitdir}
%if 0%{?rhel} == 7
%{__install} -m 644 %{SOURCE5} %{buildroot}%{_unitdir}/%{sname}.service
%else
%{__install} -m 644 %{SOURCE4} %{buildroot}%{_unitdir}/%{sname}.service
%endif

%{__mkdir} -p %{buildroot}%{_tmpfilesdir}
cat > %{buildroot}%{_tmpfilesdir}/%{sname}.conf <<EOF
d %{_rundir}/%{sname} 0700 pgbouncer pgbouncer -
EOF

%else
%{__install} -p -d %{buildroot}%{_initrddir}
%{__install} -p -m 755 %{SOURCE1} %{buildroot}%{_initrddir}/%{sname}
%endif

%{__install} -d -m 755 %{buildroot}/var/run/%{sname}
%{__install} -p -d %{buildroot}%{_sysconfdir}/logrotate.d
%{__install} -p -m 644 %{SOURCE3} %{buildroot}%{_sysconfdir}/logrotate.d/%{sname}


%post
%if %{systemd_enabled}
%systemd_post %{sname}.service
%endif
if [ ! -d %{_localstatedir}/log/pgbouncer ] ; then
%{__mkdir} -m 700 %{_localstatedir}/log/pgbouncer
fi
%{__chown} -R pgbouncer:pgbouncer %{_localstatedir}/log/pgbouncer
%{__chown} -R pgbouncer:pgbouncer %{_rundir}/%{sname} >/dev/null 2>&1 || :

%pre
groupadd -r pgbouncer >/dev/null 2>&1 || :
useradd -m -g pgbouncer -r -s /bin/bash \
	-c "PgBouncer Server" pgbouncer >/dev/null 2>&1 || :

%preun
%if %{systemd_enabled}
%systemd_preun %{sname}.service
%endif

%postun
if [ $1 -eq 0 ]; then
%{__rm} -rf %{_rundir}/%{sname}
fi
%if %{systemd_enabled}
%systemd_postun_with_restart %{sname}.service
%endif

%clean
%{__rm} -rf %{buildroot}

%files
%doc %{_defaultdocdir}/pgbouncer
%if %{systemd_enabled}
%license COPYRIGHT
%endif
%dir %{_sysconfdir}/%{sname}
%{_bindir}/%{sname}
%config(noreplace) %{_sysconfdir}/%{sname}/%{sname}.ini
%if %{systemd_enabled}
%ghost %{_rundir}/%{sname}
%{_tmpfilesdir}/%{sname}.conf
%attr(644,root,root) %{_unitdir}/%{sname}.service
%else
%{_initrddir}/%{sname}
%endif
%config(noreplace) %{_sysconfdir}/sysconfig/%{sname}
%config(noreplace) %{_sysconfdir}/logrotate.d/%{sname}
%{_mandir}/man1/%{sname}.*
%{_mandir}/man5/%{sname}.*
%{_sysconfdir}/%{sname}/mkauth.py*
%attr(755,pgbouncer,pgbouncer) %dir /var/run/%{sname}

%changelog
* Fri Feb  5 2021 Evgeniy Patlan <evgeniy.patlan@percona.com> - 1.15.5-1
- Initial build
