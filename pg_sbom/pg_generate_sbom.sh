#!/bin/bash
set -euo pipefail

shell_quote_string() {
    echo "$1" | sed -e 's,\([^a-zA-Z0-9/_.=-]\),\\\1,g'
}

usage () {
    cat <<EOF
Usage: $0 [OPTIONS]
    The following options may be given :
        --pg_version        PostgreSQL major_version.minor_version
        --repo_type         Repository type
        --help) usage ;;
Example $0 --pg_version=17.5 --repo_type=testing
EOF
        exit 1
}

append_arg_to_args () {
    args="$args "$(shell_quote_string "$1")
}

parse_arguments() {
    pick_args=
    if test "$1" = PICK-ARGS-FROM-ARGV
    then
        pick_args=1
        shift
    fi

    for arg do
        val=$(echo "$arg" | sed -e 's;^--[^=]*=;;')
        case "$arg" in
            --pg_version=*) PG_VERSION="$val" ;;
            --repo_type=*) REPO_TYPE="$val" ;;
            --help) usage ;;
            *)
                if test -n "$pick_args"
                then
                    append_arg_to_args "$arg"
                fi
            ;;
        esac
    done
}

CWD=$(pwd)
PG_VERSION=17.5
REPO_TYPE=testing
ARCH=$(uname -m)

parse_arguments PICK-ARGS-FROM-ARGV "$@"

PG_MAJOR_VERSION=$(echo $PG_VERSION | cut -f1 -d'.')

# Set non-interactive tzdata environment variables to avoid prompts
export DEBIAN_FRONTEND=noninteractive
export TZ="UTC"  # Set time zone (you can modify this to your preferred time zone, e.g., "Asia/Kolkata")

# Platform detection
if [ -f /etc/os-release ]; then
  . /etc/os-release
  PLATFORM_ID=$(echo "$ID" | tr '[:upper:]' '[:lower:]')
  VERSION_ID=$(echo "$VERSION_ID" | tr -d '"')
else
  echo "Unable to detect OS."
  exit 1
fi

# Function to install dependencies
install_dependencies() {
  case "$PLATFORM_ID" in
    ol|centos|rhel|rocky|almalinux)
      # RHEL/CentOS/OracleLinux (RHEL 8/9)
      RHEL=$(rpm --eval %rhel)
      PLATFORM=${PLATFORM_ID}${RHEL}
      dnf install -y epel-release || true
      dnf config-manager --set-enabled ol${RHEL}_codeready_builder || true
      dnf install -y 'dnf-command(config-manager)'
      dnf install -y jq
      yum install oracle-epel-release-el${RHEL} || true
      if [[ ${RHEL} -eq 8 ]]; then
        dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
      fi
      ;;
    ubuntu|debian)
      # Install dependencies for Ubuntu/Debian
      PLATFORM=$(echo "$VERSION_CODENAME" | tr '[:upper:]' '[:lower:]')
      apt update
      apt install -y curl gnupg jq lsb-release tzdata
      apt --fix-broken install -y  # Fix broken dependencies
      ;;
    *)
      echo "Unsupported platform: $PLATFORM_ID"
      exit 1
      ;;
  esac
}

# Install required dependencies
install_dependencies

# Configure Time Zone without interactive prompts (for Docker)

if [[ "$PLATFORM_ID" == "ubuntu" || "$PLATFORM_ID" == "debian" ]]; then
  echo "$TZ" > /etc/timezone
  ln -sf /usr/share/zoneinfo/$TZ /etc/localtime
  DEBIAN_FRONTEND=noninteractive apt-get install -y --reinstall tzdata
else
  ln -sf /usr/share/zoneinfo/$TZ /etc/localtime
  echo "$TZ" > /etc/timezone
fi

# Install Percona repo and PostgreSQL
install_percona_postgres() {
  case "$PLATFORM_ID" in
    ol|rhel|centos|oraclelinux)
      # Install Percona repo on RHEL/CentOS/OracleLinux
      curl -sO https://repo.percona.com/yum/percona-release-latest.noarch.rpm
      dnf install -y percona-release-latest.noarch.rpm
      percona-release enable ppg-${PG_VERSION} ${REPO_TYPE}
      dnf module disable postgresql || true
      dnf install -y \
        percona-postgresql${PG_MAJOR_VERSION} \
        percona-postgresql${PG_MAJOR_VERSION}-server \
        percona-postgresql${PG_MAJOR_VERSION}-contrib \
        percona-postgresql${PG_MAJOR_VERSION}-libs \
        percona-postgresql${PG_MAJOR_VERSION}-devel \
	percona-postgresql${PG_MAJOR_VERSION}-llvmjit \
	percona-postgresql${PG_MAJOR_VERSION}-plperl \
	percona-postgresql${PG_MAJOR_VERSION}-plpython3 \
	percona-postgresql${PG_MAJOR_VERSION}-pltcl \
        percona-postgresql-common \
	percona-postgresql-client-common \
        percona-pg_stat_monitor${PG_MAJOR_VERSION} \
        percona-pg_repack${PG_MAJOR_VERSION} \
        percona-pgaudit${PG_MAJOR_VERSION} \
        percona-pgaudit${PG_MAJOR_VERSION}_set_user \
        percona-pgvector_${PG_MAJOR_VERSION} \
        percona-wal2json${PG_MAJOR_VERSION} \
	percona-haproxy \
	percona-patroni \
	percona-pg_gather \
	percona-pgbackrest \
	percona-pgbadger \
	percona-pgpool-II-pg${PG_MAJOR_VERSION} \
	percona-postgis33_${PG_MAJOR_VERSION} \
	etcd
      ;;
    ubuntu|debian)
      # Install Percona repo on Ubuntu/Debian
      curl -sO https://repo.percona.com/apt/percona-release_latest.generic_all.deb
      dpkg -i percona-release_latest.generic_all.deb
      apt --fix-broken install -y  # Fix broken dependencies
      apt update

      # Explicitly enable the ppg-${PG_MAJOR_VERSION} repository
      percona-release enable telemetry
      percona-release enable ppg-${PG_VERSION} ${REPO_TYPE}
      apt-get update
      apt-get install -y \
	percona-postgresql-${PG_MAJOR_VERSION} \
	percona-postgresql-server-dev-${PG_MAJOR_VERSION} \
	percona-postgresql-client-${PG_MAJOR_VERSION} \
	percona-postgresql-plperl-${PG_MAJOR_VERSION} \
	percona-postgresql-plpython3-${PG_MAJOR_VERSION} \
	percona-postgresql-pltcl-${PG_MAJOR_VERSION} \
	percona-haproxy \
	percona-patroni \
	percona-pg-gather \
	percona-postgresql-${PG_MAJOR_VERSION}-repack \
	percona-pg-stat-monitor${PG_MAJOR_VERSION} \
	percona-postgresql-${PG_MAJOR_VERSION}-pgaudit \
	percona-pgaudit${PG_MAJOR_VERSION}-set-user \
	percona-pgbackrest \
	percona-pgbadger \
	percona-pgbouncer \
	percona-pgpool2 \
	postgresql-${PG_MAJOR_VERSION}-pgpool2 \
	percona-postgresql-${PG_MAJOR_VERSION}-pgvector \
	percona-postgresql-${PG_MAJOR_VERSION}-postgis-3 \
	percona-postgresql-postgis \
	percona-postgis \
	percona-postgresql-common \
	percona-postgresql-client \
	percona-postgresql-contrib \
	percona-postgresql-server-dev-all \
	postgresql-client-common \
	postgresql-common \
	percona-postgresql \
	percona-postgresql-${PG_MAJOR_VERSION}-wal2json \
	etcd \
	etcd-client \
	etcd-server
      ;;
    *)
      echo "Unsupported platform: $PLATFORM_ID"
      exit 1
      ;;
  esac
}

# Install Percona repository and PostgreSQL
install_percona_postgres

# Check if PostgreSQL user exists and create it if not
if ! id -u postgres &>/dev/null; then
  echo "Creating PostgreSQL user..."
  useradd -r -s /bin/bash postgres
fi

# Create PGDATA directory if not initialized
export PGDATA=/var/lib/pgsql/${PG_MAJOR_VERSION}/data
if [ ! -s "$PGDATA/PG_VERSION" ]; then
  echo "Initializing PostgreSQL..."
  mkdir -p "$PGDATA"
  chown postgres:postgres "$PGDATA"
  # Use the correct initdb location
  if [ -f "/usr/pgsql-${PG_MAJOR_VERSION}/bin/initdb" ]; then
    su - postgres -c "/usr/pgsql-${PG_MAJOR_VERSION}/bin/initdb -D $PGDATA"
  elif [ -f "/usr/lib/postgresql/${PG_MAJOR_VERSION}/bin/initdb" ]; then
    su - postgres -c "/usr/lib/postgresql/${PG_MAJOR_VERSION}/bin/initdb -D $PGDATA"
  else
    echo "initdb command not found. Please verify PostgreSQL installation."
    exit 1
  fi
else
  echo "PostgreSQL data directory already exists; skipping initdb."
fi

# Install Syft (if not already installed)
if ! command -v syft &>/dev/null; then
  curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b /usr/local/bin
fi

mkdir -p $CWD/pg_sbom

# Generate full SBOM using db fallback
echo "Generating full SBOM via db..."
syft dir:/ --output cyclonedx-json > sbom-full-db.json

# Filter PostgreSQL ${PG_VERSION} components and preserve SBOM structure
jq '{
  "$schema": ."$schema",
  "bomFormat": .bomFormat,
  "specVersion": .specVersion,
  "serialNumber": .serialNumber,
  "version": .version,
  "metadata": .metadata,
  "components": [.components[] | select(.name | test("postgresql|percona"; "i"))]
}' sbom-full-db.json > $CWD/pg_sbom/sbom-percona-postgresql-${PG_VERSION}-${PLATFORM}-${ARCH}.json

echo "✅ SBOM for Percona PostgreSQL ${PG_VERSION} written to: $CWD/pg_sbom/sbom-percona-postgresql-${PG_VERSION}-${PLATFORM}-${ARCH}.json"

