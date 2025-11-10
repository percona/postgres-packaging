%define		_build_id_links none
%global		debug_package %{nil}
%global		_missing_build_ids_terminate_build 0

%ifarch x86_64
%global		tarballarch amd64
%endif
%ifarch ppc64le
%global		tarballarch ppc64le
%endif
%ifarch aarch64
%global		tarballarch arm64
%endif

Name:		etcd
Version:	%{version}
Release:	%{release}%{?dist}
Summary:	Distributed reliable key-value store
License:	ASL 2.0
URL:		https://github.com/%{name}-io/%{name}
Source0:	%{name}-%{version}.tar.gz
Source1:	%{name}.service
Source2:	%{name}.conf.yaml

BuildRequires:	python3-devel
%if 0%{?rhel} && 0%{?rhel} == 7
BuildRequires:	systemd
%else
BuildRequires:	systemd-rpm-macros
%endif

%if 0%{?fedora} >= 37 || 0%{?rhel} >= 7
Requires(pre):	shadow-utils
%endif
%if 0%{?suse_version} >= 1315
Requires(pre):	shadow
%endif

%description
etcd is a distributed reliable key-value store for the most critical data
of a distributed system, with a focus on being:
- Simple: well-defined, user-facing API (gRPC)
- Secure: automatic TLS with optional client cert authentication
- Fast: benchmarked 10,000 writes/sec
- Reliable: properly distributed using Raft

%prep
%setup -q -n %{name}-%{version}

%build

%install
%{__mkdir} -p %{buildroot}/%{_bindir}
%{__cp} etcd etcdctl etcdutl %{buildroot}/%{_bindir}

%{__mkdir} -p %{buildroot}/%{_sysconfdir}/%{name}
%{__cp} %{SOURCE2} %{buildroot}/%{_sysconfdir}/%{name}/%{name}.conf.yaml

%{__mkdir} -p %{buildroot}/%{_unitdir}
%{__cp} %{SOURCE1} %{buildroot}/%{_unitdir}/

%{__mkdir} -p %{buildroot}/%{_var}/lib/%{name}

%pre
getent group %{name} >/dev/null || groupadd -r %{name}
getent passwd %{name} >/dev/null || useradd -r -g %{name} -d %{_sharedstatedir}/%{name} \
    -s /sbin/nologin -c "etcd user" %{name}

%post
%systemd_post %{name}.service

%preun
%systemd_preun %{name}.service

%postun
%systemd_postun %{name}.service

%files
%defattr(-,root,root,-)
%doc README*
%dir %attr(755, root, root) %{_sysconfdir}/%{name}
%dir %attr(750, etcd, etcd) %{_var}/lib/%{name}
%config(noreplace) %{_sysconfdir}/%{name}/%{name}.conf.yaml
%{_unitdir}/%{name}.service
%attr(755, root, root) %{_bindir}/etcd
%attr(755, root, root) %{_bindir}/etcdctl
%attr(755, root, root) %{_bindir}/etcdutl

%changelog
* Thu Feb 1 2024 Devrim Gündüz <devrim@gunduz.org> - 3.5.12-1PGDG
- Update to 3.5.12, per changes described at:
  https://github.com/etcd-io/etcd/blob/main/CHANGELOG/CHANGELOG-3.5.md#v3512-2024-01-31

* Fri Dec 8 2023 Devrim Gündüz <devrim@gunduz.org> - 3.5.11-1PGDG
- Update to 3.5.11, per changes described at:
  https://github.com/etcd-io/etcd/blob/main/CHANGELOG/CHANGELOG-3.5.md#v3511-tbd

* Tue Oct 31 2023 Devrim Gündüz <devrim@gunduz.org> - 3.5.10-1PGDG
- Update to 3.5.10, per changes described at:
  https://github.com/etcd-io/etcd/blob/main/CHANGELOG/CHANGELOG-3.5.md#v3510-2023-10-27

* Thu Aug 10 2023 Devrim Gündüz <devrim@gunduz.org> - 3.5.9-2PGDG
- Fix dependency on SLES 15, per report from Matt Baker:
  https://redmine.postgresql.org/issues/7847
- Add PGDG branding

* Mon May 15 2023 Devrim Gündüz <devrim@gunduz.org> - 3.5.9-1
- Update to 3.5.9, per changes described at:
  https://github.com/etcd-io/etcd/blob/main/CHANGELOG/CHANGELOG-3.5.md#v359-2023-05-11

* Thu May 4 2023 Devrim Gündüz <devrim@gunduz.org> - 3.5.8-1
- Update to 3.5.8, per changes described at:
  https://github.com/etcd-io/etcd/blob/main/CHANGELOG/CHANGELOG-3.5.md#v358-2023-04-13

* Fri Mar 17 2023 Devrim Gündüz <devrim@gunduz.org> - 3.5.7-2
- Enable builds on RHEL 7

* Mon Jan 30 2023 Devrim Gündüz <devrim@gunduz.org> - 3.5.7-1
- Update to 3.5.7, per changes described at:
  https://github.com/etcd-io/etcd/blob/main/CHANGELOG/CHANGELOG-3.5.md#v357-2023-01-20

* Wed Nov 23 2022 Devrim Gündüz <devrim@gunduz.org> - 3.5.6-1
- Update to 3.5.6

* Wed Nov 16 2022 Devrim Gündüz <devrim@gunduz.org> - 3.5.5-2
- Make sure that we pick up the correct tarball for all supported
  architectures, not a single one.

* Mon Oct 24 2022 Devrim Gündüz <devrim@gunduz.org> - 3.5.5-1
- Update to 3.5.5
- Enable v2 protocol by default,  per Alexandre Pereira:
  https://redmine.postgresql.org/issues/7704

* Wed Sep 14 2022 Devrim Gündüz <devrim@gunduz.org> - 3.5.4-2
- Make sure that we don't override the config file, per report and
  fix from Matt Baker.
- Create working directory, so that the daemon can start out of the box.

* Thu Aug 18 2022 Devrim Gündüz <devrim@gunduz.org> - 3.5.4-1
- Initial packaging for PostgreSQL RPM repository.
