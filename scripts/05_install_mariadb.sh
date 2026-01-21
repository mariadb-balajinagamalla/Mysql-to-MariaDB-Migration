#!/usr/bin/env bash
set -euo pipefail

# MariaDB Enterprise installation via RPM tarball
# Designed for Amazon Linux 2023 (RHEL 9 compatible)
#
# Required:
#   export MARIADB_ES_TOKEN="xxxxx"
#
# Optional:
#   export MARIADB_ES_VERSION="11.8.5-2"
#   export MARIADB_NOGPGCHECK=1

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "ERROR: Must run on Linux host"
  exit 2
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

PM=""
if command -v dnf >/dev/null 2>&1; then
  PM="dnf"
elif command -v yum >/dev/null 2>&1; then
  PM="yum"
else
  echo "ERROR: No package manager found"
  exit 1
fi

if [[ -z "${MARIADB_ES_TOKEN:-}" ]]; then
  echo "ERROR: MARIADB_ES_TOKEN not set"
  exit 3
fi

VERSION="${MARIADB_ES_VERSION:-11.8.5-2}"
ARCH="x86_64"
OS="rhel-9"

TARBALL="mariadb-enterprise-${VERSION}-${OS}-${ARCH}-rpms.tar"
URL="https://dlm.mariadb.com/${MARIADB_ES_TOKEN}/mariadb-enterprise-server/${VERSION}/pkgtar/${TARBALL}"

WORKDIR="/tmp/mariadb-enterprise-install"
mkdir -p "$WORKDIR"
cd "$WORKDIR"

echo "Downloading MariaDB Enterprise RPM tarball:"
echo "  $URL"

curl -fL -o "$TARBALL" "$URL"

echo "Extracting RPMs..."
tar -xf "$TARBALL"

set +o pipefail
RPM_DIR="$(tar -tf "$TARBALL" | head -1 | cut -d/ -f1)"
set -o pipefail

if [[ ! -d "$RPM_DIR" ]]; then
  echo "ERROR: RPM directory not found after extraction"
  exit 4
fi

cd "$RPM_DIR"

RPM_FLAGS=()
if [[ "${MARIADB_NOGPGCHECK:-0}" == "1" ]]; then
  RPM_FLAGS+=(--nogpgcheck)
fi

echo "Installing RPM dependencies..."
sudo dnf -y install \
  perl perl-DBI perl-Data-Dumper perl-File-Copy perl-Sys-Hostname \
  libaio libsepol unixODBC boost-program-options lzo snappy \
  mysql-selinux || true

echo "Installing MariaDB Enterprise RPMs..."
sudo rpm -Uvh --nodeps --nosignature --nodigest *.rpm

echo "Installing RPMs..."
sudo rpm -Uvh "${RPM_FLAGS[@]}" *.rpm

echo
echo "Installed MariaDB Enterprise packages:"
rpm -qa | grep -E '^MariaDB-' || true

echo
echo "NOTE:"
echo " - MariaDB is installed but NOT started"
echo " - Next step will run mariadb-upgrade"
