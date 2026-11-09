%global debug_package %{nil}
%global pgmajorversion %{pgmajor}
%global pginstdir /usr/pgsql-%{pgmajorversion}

%{!?runselftest:%global runselftest 0}

# EL-10 and Fedora >= 44: ship a local SELinux policy module that lets
# sshd_session_t search/read the postgres user's home dir (postgresql_db_t),
# so that SSH pubkey auth via ~/.ssh/authorized_keys works:
%if 0%{?rhel} >= 10 || 0%{?fedora} >= 44
%global sshd_selinux 1
%else
%global sshd_selinux 0
%endif

# On RHEL, libssh2 comes from pgdg-libssh2 (EPEL is not needed), which does
# not provide its soname; it is found through the rpath:
%if 0%{?rhel}
%global __requires_exclude ^libssh2\\.so
%endif

%if 0%{?rhel} && 0%{?rhel} == 9
%global gts_version 14
%endif

%global sname pgbackrest

Summary:        Reliable PostgreSQL Backup & Restore
Name:           percona-pgbackrest
Version:        %{version}
Release:        %{release}%{dist}
License:        MIT
Group:          Applications/Databases
URL:            http://www.pgbackrest.org
Source:         %{name}-%{version}.tar.gz
Source1:        pgbackrest.conf
Source2:	pgbackrest-tmpfiles.d
Source3:	pgbackrest.logrotate
Source4:	pgbackrest.service
Source6:        pgbackrest-sysusers.conf
Source8:        pgbackrest-sshd-selinux.te
BuildRequires:	gcc openssl-devel zlib-devel percona-postgresql%{pgmajorversion}-devel
BuildRequires:	libzstd-devel libxml2-devel libyaml-devel libssh2-devel meson
BuildRequires:	python3 python3-pyyaml
%if 0%{?gts_version}
BuildRequires:  gcc-toolset-%{gts_version}-gcc gcc-toolset-%{gts_version}-gcc-c++ gcc-toolset-%{gts_version}-annobin-plugin-gcc
%endif

%if %sshd_selinux
BuildRequires:        selinux-policy-devel
%endif
%if %runselftest
# The smoke test runs a backup/restore cycle against the PostgreSQL it finds
BuildRequires:        percona-postgresql%{pgmajorversion}-server python3
%endif

%if 0%{?suse_version} >= 1500
Requires:	libopenssl3 libsystemd0
BuildRequires:	libopenssl-3-devel
%endif
%if 0%{?fedora} >= 42 || 0%{?rhel} >= 8
Requires:	openssl-libs >= 1.1.1k systemd-libs
BuildRequires:	openssl-devel
%endif

%if 0%{?fedora} >= 42 || 0%{?rhel} >= 8
Requires:	lz4-libs libzstd libssh2
BuildRequires:	lz4-devel bzip2-devel ninja-build
%endif
%if 0%{?suse_version} && 0%{?suse_version} >= 1500
Requires:	liblz4-1 libzstd1 libssh2-1 libsystemd0
BuildRequires:	liblz4-devel libbz2-devel ninja
%endif

Requires:	postgresql-libs
Requires(pre):	/usr/sbin/useradd /usr/sbin/groupadd

BuildRequires:		systemd, systemd-devel
# We require this to be present for %%{_prefix}/lib/tmpfiles.d
Requires:		systemd
Requires(post):		systemd
Requires(preun):	systemd
Requires(postun):	systemd

Epoch:		1
Packager:       Percona Development Team <https://jira.percona.com>
Vendor:         Percona, LLC

%description
pgBackRest aims to be a simple, reliable backup and restore system that can
seamlessly scale up to the largest databases and workloads.

Instead of relying on traditional backup tools like tar and rsync, pgBackRest
implements all backup features internally and uses a custom protocol for
communicating with remote systems. Removing reliance on tar and rsync allows
for better solutions to database-specific backup challenges. The custom remote
protocol allows for more flexibility and limits the types of connections that
are required to perform a backup which increases security.

%prep
%setup -q -n %{name}-%{version}

%build
%if 0%{?gts_version}
	source /opt/rh/gcc-toolset-14/enable
%endif
export PG_CONFIG=/usr/pgsql-%{pgmajorversion}/bin/pg_config
export PKG_CONFIG_LIBDIR=/usr/pgsql-%{pgmajorversion}/lib/pkgconfig:/usr/lib64/pkgconfig
unset PKG_CONFIG_PATH
%{__install} -d build
%meson
%meson_build

%if %sshd_selinux
checkmodule -M -m -o %{sname}_sshd_fix.mod %{SOURCE8}
semodule_package -o %{sname}_sshd_fix.pp -m %{sname}_sshd_fix.mod
%endif

%install
export PG_CONFIG=/usr/pgsql-%{pgmajorversion}/bin/pg_config
%meson_install
%{__install} -D -d -m 0755 %{buildroot}%{perl_vendorlib} %{buildroot}%{_bindir}
%{__install} -D -d -m 0700 %{buildroot}/%{_sharedstatedir}/pgbackrest
%{__install} -D -d -m 0700 %{buildroot}/var/log/pgbackrest
%{__install} -D -d -m 0700 %{buildroot}/var/spool/pgbackrest
%{__install} -D -d -m 0755 %{buildroot}%{_sysconfdir}
%{__install} %{SOURCE1} %{buildroot}/%{_sysconfdir}/pgbackrest.conf

# Install logrotate file:
%{__install} -p -d %{buildroot}%{_sysconfdir}/logrotate.d
%{__install} -p -m 644 %{SOURCE3} %{buildroot}%{_sysconfdir}/logrotate.d/pgbackrest

# ... and make a tmpfiles script to recreate it at reboot.
%{__mkdir} -p %{buildroot}/%{_tmpfilesdir}
%{__install} -m 0644 %{SOURCE2} %{buildroot}/%{_tmpfilesdir}/pgbackrest.conf

# Install unit file:
%{__install} -d %{buildroot}%{_unitdir}
%{__install} -m 644 %{SOURCE4} %{buildroot}%{_unitdir}/pgbackrest.service

%{__install} -m 0644 -D %{SOURCE6} %{buildroot}%{_sysusersdir}/%{sname}.conf
%{__mkdir} -p %{buildroot}/%{_tmpfilesdir}
%{__install} -m 0644 %{SOURCE2} %{buildroot}/%{_tmpfilesdir}/%{sname}.conf
%if %sshd_selinux
%{__install} -d -m 755 %{buildroot}%{_datadir}/selinux/packages
%{__install} -m 644 %{sname}_sshd_fix.pp %{buildroot}%{_datadir}/selinux/packages/
%endif
%check
%if %runselftest
# Upstream's smoke test for packagers: initdb, stanza-create, check, full and
# incremental backups, then a restore of the latter, against every supported
# PostgreSQL found on the system. When run as root, it drops to the postgres
# user.
%meson_test --suite smoke -v
%endif

%pre
%sysusers_create_package %{sname} %SOURCE6

%post
if [ $1 -eq 1 ] ; then
   /usr/bin/systemctl daemon-reload >/dev/null 2>&1 || :
   %if 0%{?suse_version} >= 1500
   %service_add_pre pgbackrest}.service
   %else
   %systemd_post pgbackrest.service
   %endif
fi

%if %sshd_selinux
%{_sbindir}/selinuxenabled 2>/dev/null && \
        %{_sbindir}/semodule -i %{_datadir}/selinux/packages/%{sname}_sshd_fix.pp >/dev/null 2>&1 || :
%endif

%preun
if [ $1 -eq 0 ] ; then
	# Package removal, not upgrade
	/usr/bin/systemctl --no-reload disable %{name}.service >/dev/null 2>&1 || :
	/usr/bin/systemctl stop %{name}.service >/dev/null 2>&1 || :
fi

%postun
/usr/bin/systemctl daemon-reload >/dev/null 2>&1 || :

if [ $1 -ge 1 ] ; then
	# Package upgrade, not uninstall
	/usr/bin/systemctl try-restart %{name}.service >/dev/null 2>&1 || :
fi

%if %sshd_selinux
if [ $1 -eq 0 ] ; then
        # Package removal, not upgrade
        %{_sbindir}/selinuxenabled 2>/dev/null && \
                %{_sbindir}/semodule -r %{sname}_sshd_fix >/dev/null 2>&1 || :
fi
%endif

%files
%defattr(-,root,root)
%license LICENSE
%{_bindir}/pgbackrest
%config(noreplace) %attr (644,root,root) %{_sysconfdir}/pgbackrest.conf
%config(noreplace) %{_sysconfdir}/logrotate.d/pgbackrest
%{_tmpfilesdir}/pgbackrest.conf
%{_sysusersdir}/pgbackrest.conf
%{_unitdir}/pgbackrest.service
%if %sshd_selinux
%{_datadir}/selinux/packages/%{sname}_sshd_fix.pp
%endif
%attr(-,postgres,postgres) /var/log/pgbackrest
%attr(-,postgres,postgres) %{_sharedstatedir}/pgbackrest
%attr(-,postgres,postgres) /var/spool/pgbackrest

%changelog
* Thu Jul 30 2026  Manika Singhal <manika.singhal@percona.com> - 2.59.0
- Update pgBackrest to 2.59.0

* Thu Jan 29 2026  Manika Singhal <manika.singhal@percona.com> - 2.58.0
- Update pgBackrest to 2.58.0

* Tue Jul 16 2019  Evgeniy Patlan <evgeniy.patlan@percona.com> - 2.16.1
- First build of pgbackrest for Percona.
