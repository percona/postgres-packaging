%global        _enable_debug_package 0
%global        __os_install_post /usr/lib/rpm/brp-compress %{nil}
%global        debug_package %{nil}
%define        _build_id_links none
%define        VERSION        2.0.1
%define        ENVNAME  patroni
%define        INSTALLPATH /opt/
%define        debug_package %{nil}
Name:          percona-patroni
Version:       2.0.1
Release:       3%{dist}
Epoch:         1
License:       MIT
Summary:       PostgreSQL high-availability manager
Source:        percona-patroni-2.0.1.tar.gz
Source1:       patroni-customizations.tar.gz
Patch0:        add-sample-config.patch
Patch1:        better-startup-script.patch
BuildRoot:     %{_tmppath}/%{buildprefix}-buildroot
%if 0%{?rhel} > 7
Requires:      python3-pyyaml, python3-urllib3, python3-prettytable, python3-six python3-dateutil
%else
Requires:      python36-six python2-pyyaml python36-urllib3 python36-prettytable python36-dateutil
%endif
Requires:      python3, python3-psycopg2 >= 2.5.4, libffi, postgresql-server, libyaml
Requires:      /usr/bin/python3.6, libffi, postgresql-server, libyaml, postgresql12-server
BuildRequires: prelink libyaml-devel gcc
Requires(post): %{_sbindir}/update-alternatives
Requires(postun):       %{_sbindir}/update-alternatives
Provides:      patroni
AutoReqProv: no

%global __requires_exclude_from ^%{INSTALLPATH}/lib/python3.6/site-packages/(psycopg2/|_cffi_backend.so|_cffi_backend.cpython-36m-x86_64-linux-gnu.so|.libs_cffi_backend/libffi-.*.so.6.0.4)
%global __provides_exclude_from ^%{INSTALLPATH}/lib/python3.6/

%global __python %{__python3.6}

%description
Packaged version of Patroni HA manager.

%prep
%setup
%setup -D -T -a 1
%patch0 -p1
%patch1 -p1

%build
# remove some things
#rm -f $RPM_BUILD_ROOT/%{prefix}/*.spec

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT%{INSTALLPATH}
virtualenv-3.6 --distribute --system-site-packages $RPM_BUILD_ROOT%{INSTALLPATH}
grep -v psycopg2 requirements.txt | sed 's/kubernetes=.*/kubernetes/' > requirements-venv.txt
$RPM_BUILD_ROOT%{INSTALLPATH}/bin/pip3.6 install -U setuptools psycopg2-binary
$RPM_BUILD_ROOT%{INSTALLPATH}/bin/pip3.6 install -r requirements-venv.txt
$RPM_BUILD_ROOT%{INSTALLPATH}/bin/pip3.6 install --no-deps .
rm $RPM_BUILD_ROOT%{INSTALLPATH}/lib/python3.6/site-packages/consul/aio.py

rm -rf $RPM_BUILD_ROOT/usr/

virtualenv-3.6 --relocatable $RPM_BUILD_ROOT%{INSTALLPATH}
sed -i "s#$RPM_BUILD_ROOT##" $RPM_BUILD_ROOT%{INSTALLPATH}/bin/activate*

#find $(VENV_PATH) -name \*py[co] -exec rm {} \;
#find $(VENV_PATH) -name no-global-site-packages.txt -exec rm {} \;
cp -r extras/ $RPM_BUILD_ROOT%{INSTALLPATH}

mkdir -p $RPM_BUILD_ROOT/lib/systemd/system/
cp patroni.2.service $RPM_BUILD_ROOT/lib/systemd/system/patroni.service
cp patroni-watchdog.service $RPM_BUILD_ROOT/lib/systemd/system/patroni-watchdog.service

mkdir -p $RPM_BUILD_ROOT%{INSTALLPATH}/etc/
cp postgres-telia.yml $RPM_BUILD_ROOT%{INSTALLPATH}/etc/postgresql.yml.sample
chmod 0600 $RPM_BUILD_ROOT%{INSTALLPATH}/etc/postgresql.yml.sample

# undo prelinking
find $RPM_BUILD_ROOT%{INSTALLPATH}/bin/ -type f -perm /u+x,g+x -exec /usr/sbin/prelink -u {} \;
ls $RPM_BUILD_ROOT%{INSTALLPATH} > patroni.txt
mkdir $RPM_BUILD_ROOT%{INSTALLPATH}/patroni
find $RPM_BUILD_ROOT/ -type d -name ".build-id" -exec rm -rf {} \;
for file in $(cat patroni.txt); do
  mv $RPM_BUILD_ROOT%{INSTALLPATH}/$file $RPM_BUILD_ROOT%{INSTALLPATH}/patroni
done

%post
%{_sbindir}/update-alternatives --install %{_bindir}/patroni \
  patroni %{INSTALLPATH}patroni/bin/patroni 100 \
  --slave %{_bindir}/patronictl patroni-patronictl %{INSTALLPATH}patroni/bin/patronictl

%postun
if [ $1 -eq 0 ] ; then
  %{_sbindir}/update-alternatives --remove patroni %{INSTALLPATH}patroni/bin/patroni
fi

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)
/opt/patroni
%attr(-, postgres, postgres) /opt/patroni/etc
%attr(664, root, root) /lib/systemd/system/patroni.service
%attr(664, root, root) /lib/systemd/system/patroni-watchdog.service

%changelog
* Fri Dec 27 2019 Evgeniy Patlan <evgeniy.patlan@percona.com>  1.6.3-1
- Initial build
