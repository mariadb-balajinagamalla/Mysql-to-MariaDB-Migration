#!/usr/bin/env bash
set -euo pipefail

# MariaDB Enterprise installation via RPM tarball
# Designed for RHEL-family Linux (Rocky / Alma / RHEL)
#
# Required:
#   export MARIADB_ES_TOKEN="xxxxx"
#
# Optional:
#   export MARIADB_ES_VERSION="11.8.5-2"
#   export MARIADB_NOGPGCHECK=1
#   export MARIADB_ES_OS="rhel-9"
#   export MARIADB_ES_ARCH="x86_64"
#
# Remote install (from a third instance):
#   export MARIADB_INSTALL_HOST="192.168.64.2"
#   export MARIADB_INSTALL_SSH_USER="root"
#   export MARIADB_INSTALL_SSH_OPTS="-o StrictHostKeyChecking=no"

if [[ "${SKIP_INSTALL_MARIADB:-0}" == "1" ]]; then
  echo "Skipping MariaDB install (SKIP_INSTALL_MARIADB=1)."
  exit 0
fi

if [[ -n "${MARIADB_INSTALL_HOST:-}" && "${MARIADB_INSTALL_REMOTE:-0}" != "1" ]]; then
  SSH_USER="${MARIADB_INSTALL_SSH_USER:-root}"
  SSH_OPTS="${MARIADB_INSTALL_SSH_OPTS:-}"
  echo "Running MariaDB install on remote host: ${MARIADB_INSTALL_HOST}"
  ssh ${SSH_OPTS} "${SSH_USER}@${MARIADB_INSTALL_HOST}" \
    MARIADB_INSTALL_REMOTE=1 \
    MARIADB_ES_TOKEN="${MARIADB_ES_TOKEN:-}" \
    MARIADB_ES_VERSION="${MARIADB_ES_VERSION:-}" \
    MARIADB_NOGPGCHECK="${MARIADB_NOGPGCHECK:-}" \
    MARIADB_ES_OS="${MARIADB_ES_OS:-}" \
    MARIADB_ES_ARCH="${MARIADB_ES_ARCH:-}" \
    SKIP_INSTALL_MARIADB="${SKIP_INSTALL_MARIADB:-0}" \
    bash -s < "$0"
  exit 0
fi

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "ERROR: Must run on Linux host"
  exit 2
fi

SCRIPT_SOURCE="${BASH_SOURCE[0]:-}"
if [[ -z "$SCRIPT_SOURCE" || "$SCRIPT_SOURCE" == "bash" || "$SCRIPT_SOURCE" == "-bash" ]]; then
  ROOT="$(pwd)"
else
  ROOT="$(cd "$(dirname "$SCRIPT_SOURCE")/.." && pwd)"
fi
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
ARCH="${MARIADB_ES_ARCH:-}"
OS="${MARIADB_ES_OS:-}"

if [[ -z "$OS" && -f /etc/os-release ]]; then
  . /etc/os-release
  case "${ID:-}" in
    rocky|rhel|almalinux|centos)
      if [[ "${VERSION_ID:-}" == 10* ]]; then
        OS="rhel-10"
      else
        OS="rhel-9"
      fi
      ;;
  esac
fi

if [[ -z "$ARCH" ]]; then
  case "$(uname -m)" in
    x86_64|amd64) ARCH="x86_64" ;;
    aarch64|arm64) ARCH="aarch64" ;;
  esac
fi

if [[ -z "$OS" ]]; then
  echo "ERROR: Unable to detect OS. Set MARIADB_ES_OS explicitly (e.g., rhel-9, rhel-10)."
  exit 4
fi
if [[ -z "$ARCH" ]]; then
  echo "ERROR: Unable to detect ARCH. Set MARIADB_ES_ARCH explicitly (e.g., x86_64, aarch64)."
  exit 5
fi

if rpm -qa | grep -qiE '^mysql-community-|^Percona-Server-|^percona-server-'; then
  if [[ "${REMOVE_MYSQL_PACKAGES:-0}" == "1" ]]; then
    echo "Removing existing MySQL/Percona packages (REMOVE_MYSQL_PACKAGES=1)..."
    sudo "$PM" -y remove 'mysql-community-*' 'Percona-Server-*' 'percona-server-*' || true
  else
    echo "ERROR: Existing MySQL/Percona packages detected. Set REMOVE_MYSQL_PACKAGES=1 to remove automatically."
    exit 6
  fi
fi

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
sudo "$PM" -y install \
  perl perl-DBI perl-Data-Dumper perl-File-Copy perl-Sys-Hostname \
  libaio libsepol unixODBC boost-program-options lzo snappy \
  mysql-selinux || true

if rpm -q MariaDB-server MariaDB-server-compat >/dev/null 2>&1; then
  echo "MariaDB already installed; skipping RPM install."
  exit 0
fi

echo "Installing MariaDB Enterprise RPMs..."
set +e
sudo rpm -Uvh --nodeps --nosignature --nodigest *.rpm
RPM_RC=$?
set -e
if [[ "$RPM_RC" -ne 0 ]]; then
  if rpm -q MariaDB-server MariaDB-server-compat >/dev/null 2>&1; then
    echo "MariaDB already installed; ignoring RPM install errors."
    exit 0
  fi
  exit "$RPM_RC"
fi

echo "Installing RPMs..."
set +e
sudo rpm -Uvh "${RPM_FLAGS[@]}" *.rpm
RPM_RC=$?
set -e
if [[ "$RPM_RC" -ne 0 ]]; then
  if rpm -q MariaDB-server MariaDB-server-compat >/dev/null 2>&1; then
    echo "MariaDB already installed; ignoring RPM install errors."
    exit 0
  fi
  exit "$RPM_RC"
fi

echo
echo "Installed MariaDB Enterprise packages:"
rpm -qa | grep -E '^MariaDB-' || true

echo
echo "NOTE:"
echo " - MariaDB is installed but NOT started"
echo " - Next step will run mariadb-upgrade"
