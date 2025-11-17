Name:           percona-postgresql-common
Version:        %{version}
Release:        %{ppg_cmn_release}%{?dist}
BuildArch:      noarch
Summary:        PostgreSQL database-cluster manager
Provides:       postgresql-common
Packager:       Percona Development Team <https://jira.percona.com>
Vendor:         Percona, LLC

License:        GPLv2+
URL:            https://packages.debian.org/sid/%{name}
Source0:        %{name}/%{name}-%{version}.tar.gz
Requires:       percona-postgresql-client-common
Requires:       perl-JSON
Epoch:		1

%description
The postgresql-common package provides a structure under which
multiple versions of PostgreSQL may be installed and/or multiple
clusters maintained at one time.

%package -n percona-postgresql-client-common
Summary: manager for multiple PostgreSQL client versions
Provides: postgresql-client-common
%description -n percona-postgresql-client-common
The postgresql-client-common package provides a structure under which
multiple versions of PostgreSQL client programs may be installed at
the same time. It provides a wrapper which selects the right version
for the particular cluster you want to access (with a command line
option, an environment variable, /etc/postgresql-common/user_clusters,
or ~/.postgresqlrc).

%package -n percona-postgresql-common-dev
Provides: postgresql-common-dev
Provides: postgresql-server-dev-all
Conflicts: percona-postgresql-server-dev-all
Obsoletes: percona-postgresql-server-dev-all < 1:277
Summary: extension build tool for multiple PostgreSQL versions
%description -n percona-postgresql-common-dev
The percona-postgresql-common-dev package provides the pg_buildext script for
simplifying packaging of a PostgreSQL extension supporting multiple major
versions of the product.

%prep
# unpack tarball, ignoring the name of the top level directory inside
%setup -c
mv */* .

%build
make

%install
rm -rf %{buildroot}
pushd debian
        for file in $(ls | grep postgresql| grep -v percona); do
            mv $file "percona-$file"
        done
        echo "dh_make_pgxs/dh_make_pgxs /usr/bin" >> percona-postgresql-common-dev.install
        echo "debhelper/dh_pgxs_test /usr/bin" >> percona-postgresql-common-dev.install
        echo "debhelper/Debian /usr/share/perl" >> percona-postgresql-common-dev.install
        echo "dh_make_pgxs/dh_make_pgxs.1" >> percona-postgresql-common-dev.manpages
        echo "debhelper/dh_pgxs_test.1" >> percona-postgresql-common-dev.manpages
        echo "dh_make_pgxs/debian /usr/share/postgresql-common/dh_make_pgxs" >>  percona-postgresql-common-dev.install
        echo "pgxs_debian_control.mk /usr/share/postgresql-common" >> percona-postgresql-common-dev.install
popd
# install in subpackages using the Debian files
for inst in debian/*.install; do
    pkg=$(basename $inst .install)
    [ "$pkg" = "postgresql-server-dev-all" ] && continue
    echo "### Reading $pkg files list from $inst ###"
    while read file dir; do
        [ "$file" = "supported_versions" ] && continue # only relevant on Debian
        mkdir -p %{buildroot}/$dir
        cp -r $file %{buildroot}/$dir || true
        echo "/$dir/${file##*/}" >> files-$pkg
    done < $inst
done
# install manpages

for manpages in debian/*.manpages; do
    pkg=$(basename $manpages .manpages)
    [ "$pkg" = "postgresql-server-dev-all" ] && continue
    echo "### Reading $pkg manpages list from $manpages ###"
    while read file; do
        section="${file##*.}"
        mandir="%{buildroot}%{_mandir}/man$section"
        mkdir -p $mandir
        for f in $file; do # expand wildcards
            cp $f $mandir
            echo "%doc %{_mandir}/man$section/$(basename $f).gz" >> files-$pkg
        done
    done < $manpages
done
# install pg_wrapper symlinks by augmenting the existing pgdg.rpm alternatives
while read dest link; do
    name="pgsql-$(basename $link)"
    echo "update-alternatives --install /$link $name /$dest 9999" >> percona-postgresql-client-common.post
    echo "update-alternatives --remove $name /$dest" >> percona-postgresql-client-common.preun
done < debian/percona-postgresql-client-common.links
# activate rpm-specific tweaks
sed -i -e 's/#redhat# //' \
    %{buildroot}/lib/systemd/system-generators/postgresql-generator \
    %{buildroot}/usr/bin/pg_config \
    %{buildroot}/usr/bin/pg_virtualenv \
    %{buildroot}/usr/share/perl5/PgCommon.pm \
    %{buildroot}/usr/share/postgresql-common/init.d-functions \
    %{buildroot}/usr/share/postgresql-common/pg_getwal
# install init script
mkdir -p %{buildroot}/etc/init.d %{buildroot}/etc/logrotate.d
cp debian/percona-postgresql-common.postgresql.init %{buildroot}/etc/init.d/postgresql
cp rpm/init-functions-compat %{buildroot}/usr/share/postgresql-common
# ssl defaults to 'off' here because we don't have pregenerated snakeoil certs
sed -e 's/__SSL__/off/' createcluster.conf > %{buildroot}/etc/postgresql-common/createcluster.conf
cp debian/percona-postgresql-common.logrotate %{buildroot}/etc/logrotate.d/postgresql-common
sed -i '2d' files-percona-postgresql-common-dev

%files -n percona-postgresql-common -f files-percona-postgresql-common
%attr(0755, root, root) %config /etc/init.d/postgresql
#%attr(0755, root, root) /usr/share/postgresql-common/percona-postgresql-common.postinst
/usr/share/postgresql-common/init-functions-compat
%config /etc/postgresql-common/createcluster.conf
%config /etc/logrotate.d/postgresql-common

%if 0%{?rhel} >= 7
%config /lib/systemd/system/*.service
%config /lib/systemd/system/*.timer
%config /lib/systemd/system-generators/postgresql-generator
%endif

%files -n percona-postgresql-client-common -f files-percona-postgresql-client-common

%files -n percona-postgresql-common-dev -f files-percona-postgresql-common-dev

%post
# create postgres user
groupadd -g 26 -o -r postgres >/dev/null 2>&1 || :
useradd -M -n -g postgres -o -r -d /var/lib/pgsql -s /bin/bash \
    -c "PostgreSQL Server" -u 26 postgres >/dev/null 2>&1 || :
# create directories so postgres can create clusters without root
install -d -o postgres -g postgres /etc/postgresql /var/lib/postgresql /var/lib/pgsql /var/log/postgresql /var/run/postgresql
# install logrotate config
version_lt () {
    newest=$( ( echo "$1"; echo "$2" ) | sort -V | tail -n1)
    [ "$1" != "$newest" ]
}
lrversion=$(rpm --queryformat '%{VERSION}' -q logrotate)
if version_lt $lrversion 3.8; then
    echo "Adjusting /etc/logrotate.d/postgresql-common for logrotate version $lrversion"
    sed -i -e '/ su /d' /etc/logrotate.d/postgresql-common || :
fi

%post -n percona-postgresql-client-common -f percona-postgresql-client-common.post
update-alternatives --install /usr/bin/ecpg pgsql-ecpg /usr/share/postgresql-common/pg_wrapper 9999

%preun -n percona-postgresql-client-common -f percona-postgresql-client-common.preun
update-alternatives --remove pgsql-ecpg /usr/share/postgresql-common/pg_wrapper

%changelog
* Tue Sep 29 2020 Christoph Berg <myon@debian.org> 217-1
- Drop postgresql-server-dev-all package, it's debian-specific only.
* Fri Dec 09 2016 Bernd Helmle <bernd.helmle@credativ.de> 177-1
- New upstream release 177
* Fri Jun 03 2016 Bernd Helmle <bernd.helmle@credativ.de> 174-2
- Fix package dependencies and systemd integration
* Thu Aug  7 2014 Christoph Berg <christoph.berg@credativ.de> 160-1
- Omit the LD_PRELOAD logic in pg_wrapper
* Thu Jun  5 2014 Christoph Berg <christoph.berg@credativ.de> 158-1
- Initial specfile version
