%global __requires_exclude_from /*
%global __provides_exclude_from /*

%global sname mod_wsgi
%global debug_package %{nil}
%global srvname   pgadmin4

%undefine __brp_mangle_shebangs
%undefine __brp_ldconfig

%if 0%{?rhel} && 0%{?rhel} == 7
    %define __python /bin/true
%endif


%{!?_httpd_apxs: %{expand: %%global _httpd_apxs %%{_sbindir}/apxs}}

%{!?_httpd_mmn: %{expand: %%global _httpd_mmn %%(cat %{_includedir}/httpd/.mmn 2>/dev/null || echo 0-0)}}
%{!?_httpd_confdir:    %{expand: %%global _httpd_confdir    %%{_sysconfdir}/httpd/conf.d}}
# /etc/httpd/conf.d with httpd < 2.4 and defined as /etc/httpd/conf.modules.d with httpd >= 2.4
%{!?_httpd_modconfdir: %{expand: %%global _httpd_modconfdir %%{_sysconfdir}/httpd/conf.d}}
%{!?_httpd_moddir: %{expand: %%global _httpd_moddir    %%{_libdir}/httpd/modules}}


Name:           percona-pgadmin4
Version:        5.0
Release:        1%{?dist}
Summary:        Installs all required components to run pgAdmin in desktop and web modes.
License:        PostgreSQL
URL:            https://www.pgadmin.org/
Requires:       percona-pgadmin4-server, percona-pgadmin4-desktop, percona-pgadmin4-web
Provides:       %{srvname}
Epoch:          1
AutoReqProv:    no
AutoReq:        no
Packager:       Percona Development Team <https://jira.percona.com>
Vendor:         Percona, LLC

Source0:        %{name}-%{version}.tar.gz
Source1:        mod_wsgi-4.7.1.tar.gz
Source2:        pgadmin4-python3-mod_wsgi.conf
Patch1:         pgadmin4-python3-mod_wsgi-exports.patch
Patch2:         pgadmin4-sphinx-theme.patch

%description
Installs all required components to run pgAdmin in desktop and web modes. pgAdmin is the most popular and feature rich Open Source administration and development platform for PostgreSQL, the most advanced Open Source database in the world.

%package         -n %{name}-web
Summary:        The web interface for pgAdmin, hosted under Apache HTTPD.
License:        PostgreSQL
URL:            https://www.pgadmin.org/
%if 0%{?rhel} && 0%{?rhel} == 7
Requires:       pgadmin4-server, httpd, pgadmin4-python3-mod_wsgi
%else
Requires:       pgadmin4-server, httpd, python3-mod_wsgi
%endif
Provides:       %{srvname}-web
Epoch:          1
AutoReqProv:    no
AutoReq:        no

%description -n %{name}-web
The web interface for pgAdmin, hosted under Apache HTTPD. pgAdmin is the most popular and feature rich Open Source administration and development platform for PostgreSQL, the most advanced Open Source database in the world.


%package         -n %{name}-desktop
Summary:        The desktop user interface for pgAdmin.
License:        PostgreSQL
URL:            https://www.pgadmin.org/
Requires:       pgadmin4-server, libatomic
Provides:       %{srvname}-desktop
AutoReqProv:    no
AutoReq:        no
Epoch:          1

%description -n %{name}-desktop
The desktop user interface for pgAdmin. pgAdmin is the most popular and feature rich Open Source administration and development platform for PostgreSQL, the most advanced Open Source database in the world.

%package        -n %{name}-server
Summary:        The core server package for pgAdmin.
License:        PostgreSQL
URL:            https://www.pgadmin.org/
Provides:       %{srvname}-server
Epoch:          1
AutoReqProv:    no
AutoReq:        no

Requires:       python3, postgresql13-libs, krb5-libs xdg-utils

%description -n %{name}-server
The core server package for pgAdmin. pgAdmin is the most popular and feature rich Open Source administration and development platform for PostgreSQL, the most advanced Open Source database in the world.


%if 0%{?rhel} && 0%{?rhel} == 7
%package -n     percona-pgadmin4-python3-%{sname}
Summary:        A WSGI interface for Python web applications in Apache (customized for pgAdmin4)
License:        ASL 2.0
URL:            https://modwsgi.readthedocs.io/

Requires:       httpd-mmn = %{_httpd_mmn}
BuildRequires:  python3-devel
BuildRequires:  httpd-devel
BuildRequires:  gcc
Provides:       pgadmin4-python3-%{sname}
Epoch:          1
AutoReqProv:    no
AutoReq:        no

# Suppress auto-provides for module DSO
%{?filter_provides_in: %filter_provides_in %{_httpd_moddir}/.*\.so$}
%{?filter_setup}

%description -n percona-pgadmin4-python3-%{sname}
The mod_wsgi adapter is an Apache module that provides a WSGI compliant
interface for hosting Python based web applications within Apache. The
adapter is written completely in C code against the Apache C runtime and
for hosting WSGI applications within Apache has a lower overhead than using
existing WSGI adapters for mod_python or CGI.

%endif


%prep
%setup -n %{name}-%{version}
tar vxzf  %{SOURCE1}


%build
sed -i 's:/usr/local/bin/sphinx-build:/usr/bin/sphinx-build-3:' pkg/linux/build-functions.sh 
%if 0%{?rhel} && 0%{?rhel} == 7
patch -p0 < %{PATCH2}
%endif
pkg/redhat/build.sh
%if 0%{?rhel} && 0%{?rhel} == 7
pushd mod_wsgi-4.7.1

export LDFLAGS="$RPM_LD_FLAGS -L%{_libdir}"
export CFLAGS="$RPM_OPT_FLAGS -fno-strict-aliasing"

%configure --enable-shared --with-apxs=%{_httpd_apxs} --with-python=python3
%{__make} %{?_smp_mflags}
%{_bindir}/python3 setup.py build
popd
%endif


%install
%if 0%{?rhel} && 0%{?rhel} == 7
pushd mod_wsgi-4.7.1
%{__make} install DESTDIR=%{buildroot} LIBEXECDIR=%{_httpd_moddir}
%{__install} -d -m 755 %{buildroot}%{_httpd_modconfdir}
%{__install} -p -m 644 %{SOURCE2} %{buildroot}%{_httpd_modconfdir}/10-pgadmin4-python3-mod_wsgi.conf
%{_bindir}/python3 setup.py install -O1 --skip-build --root %{buildroot}
%{__mv} %{buildroot}%{_httpd_moddir}/mod_wsgi.so %{buildroot}%{_httpd_moddir}/pgadmin4-python3-mod_wsgi.so
%{__mv} %{buildroot}%{_bindir}/mod_wsgi-express %{buildroot}%{_bindir}/pgadmin4-mod_wsgi-express-3
popd
%endif
cp -rfa redhat-build/desktop/* %{buildroot}
cp -rfa redhat-build/server/* %{buildroot}
cp -rfa redhat-build/web/* %{buildroot}
install -d %{buildroot}/etc/httpd/conf.d/
ls pkg/redhat/
cp pkg/redhat/pgadmin4.conf %{buildroot}/etc/httpd/conf.d/ 

%post -n %{name}-desktop
/bin/xdg-icon-resource forceupdate

%files

%files -n %{name}-desktop
/usr/pgadmin4/bin/*
/usr/share/icons/hicolor/128x128/apps/*
/usr/share/icons/hicolor/64x64/apps/*
/usr/share/icons/hicolor/48x48/apps/*
/usr/share/icons/hicolor/32x32/apps/*
/usr/share/icons/hicolor/16x16/apps/*
/usr/share/applications/*

%files -n %{name}-web
/etc/httpd/conf.d/pgadmin4.conf
/usr/pgadmin4/bin/setup-web.sh

%files -n %{name}-server
/usr/pgadmin4/*

%if 0%{?rhel} && 0%{?rhel} == 7
%files -n percona-pgadmin4-python3-%{sname}
%license LICENSE
%config(noreplace) %{_httpd_modconfdir}/*pgadmin4-python3-mod_wsgi.conf
%{_httpd_moddir}/pgadmin4-python3-mod_wsgi.so
%{python3_sitearch}/mod_wsgi-*.egg-info
%{python3_sitearch}/mod_wsgi
%{_bindir}/pgadmin4-mod_wsgi-express-3
%endif

%changelog
* Tue Mar 16 2021 - Evgeniy Patlan <evgeniy.patlan@percona.com> 5.0-1
- Initial build
