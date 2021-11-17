%global srcname psycopg2


Summary:        PostgreSQL database adapter for Python
Name:           python3-%{srcname}
Version:        2.8.6
Release:        4%{?dist}
# The exceptions allow linking to OpenSSL and PostgreSQL's libpq
License:        LGPLv3+ with exceptions
URL:            http://initd.org/psycopg/
Source0:        psycopg2-%{version}.tar.gz
# https://github.com/psycopg/psycopg2/blob/2_7_5/doc/src/install.rst#prerequisites
BuildRequires:  postgresql-devel > 9.1
BuildRequires:  gcc
Packager:       Percona Development Team <https://jira.percona.com>
Vendor:         Percona, Inc

BuildRequires:  python3-devel
BuildRequires:  python3-setuptools
# rename from python36-psycopg2
Provides:       python36-%{srcname} = %{version}-%{release}
Obsoletes:      python36-%{srcname} < 2.9.1-1


%description
Psycopg is the most popular PostgreSQL adapter for the Python programming
language. At its core it fully implements the Python DB API 2.0 specifications.
Several extensions allow access to many of the features offered by PostgreSQL.


%package tests
Summary:        Test suite for python3-%{srcname}
Requires:       python3-%{srcname} = %{version}-%{release}
# rename from python36-psycopg2-tests
Provides:       python36-%{srcname}-tests = %{version}-%{release}
Obsoletes:      python36-%{srcname}-tests < 2.9.1-1


%description tests
This sub-package delivers set of tests for the adapter.


%prep
%setup -q -n %{srcname}-%{version}
# delete shebangs
find -name \*.py | xargs sed -i -e '1 {/^#!/d}'


%build
%py3_build


%install
%py3_install

# Copy tests directory:
%{__mkdir} -p %{buildroot}%{python3_sitearch}/%{srcname}/
%{__cp} -rp tests %{buildroot}%{python3_sitearch}/%{srcname}/tests
%{__rm} -f %{buildroot}%{python3_sitearch}/%{sname}/tests/test_async_keyword.py

%files
%license LICENSE
%doc AUTHORS NEWS README.rst
%{python3_sitearch}/%{srcname}
%{python3_sitearch}/%{srcname}-%{version}-py%{python3_version}.egg-info


%files tests
%{python3_sitearch}/psycopg2/tests


%changelog
* Thu Aug 26 2021 Evgeniy Patlan <evgeniy.patlan@percona.com> - 2.9.1-1
- initial build
