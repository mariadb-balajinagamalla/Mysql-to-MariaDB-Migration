#!/usr/bin/env bash
set -euo pipefail

# Install MariaDB Enterprise Server packages on Linux using mariadb_es_repo_setup.
# Token must be provided via environment (NOT in repo):
#   export MARIADB_ES_TOKEN="xxxxx"
# Optional:
#   export MARIADB_ES_VERSION="11.8"

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "ERROR: This step must be executed on the MySQL host (Linux)."
  exit 2
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# Pick package manager (AL2023 uses dnf)
PM=""
if command -v dnf >/dev/null 2>&1; then
  PM="dnf"
elif command -v yum >/dev/null 2>&1; then
  PM="yum"
else
  echo "ERROR: Neither dnf nor yum found on this host."
  exit 1
fi

MARIADB_ES_VERSION="${MARIADB_ES_VERSION:-11.8}"

if [[ -z "${MARIADB_ES_TOKEN:-}" ]]; then
  echo "ERROR: MARIADB_ES_TOKEN is not set in environment."
  echo "Set it like: export MARIADB_ES_TOKEN='<your token>'"
  exit 3
fi

echo "Installing MariaDB Server and Client..."
echo "Configuring MariaDB Enterprise repo via mariadb_es_repo_setup (version ${MARIADB_ES_VERSION})..."

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

# Correct official URL (NOT enterprise-release-setup)
curl -fLsS -o "$TMPDIR/mariadb_es_repo_setup" \
  "https://dlm.mariadb.com/enterprise-release-helpers/mariadb_es_repo_setup"
chmod +x "$TMPDIR/mariadb_es_repo_setup"

# Configure repos (requires sudo)
sudo "$TMPDIR/mariadb_es_repo_setup" \
  --token "${MARIADB_ES_TOKEN}" \
  --mariadb-server-version "${MARIADB_ES_VERSION}"

echo
echo "Repo configured. Installing packages..."
sudo "$PM" -y install MariaDB-server MariaDB-client MariaDB-backup

echo
echo "Installed MariaDB packages:"
rpm -qa | grep -E '^MariaDB-(server|client|backup)' || true

echo
echo "NOTE:"
echo " - Do NOT start MariaDB yet unless you are ready for the swap."
echo " - Next step will handle startup + mariadb-upgrade."
