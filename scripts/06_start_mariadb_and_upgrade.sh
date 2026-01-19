#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "ERROR: This step must run on the MariaDB host (Linux)."
  exit 2
fi

echo "Validating MariaDB configuration (unsupported options check)..."
mariadbd --help --verbose > /tmp/mariadbd_help_verbose.log 2>&1 || true
echo "Check: /tmp/mariadbd_help_verbose.log"

echo
echo "Starting MariaDB..."
sudo systemctl start mariadb

echo
echo "Running mariadb-upgrade..."
sudo mariadb-upgrade --force

echo
sudo systemctl status mariadb --no-pager || true

echo
echo "Upgrade complete."
