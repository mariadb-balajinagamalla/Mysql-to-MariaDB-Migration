#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "ERROR: MariaDB installation must be run on target Linux host."
  exit 2
fi

echo "Installing MariaDB Server and Client..."

sudo yum install -y MariaDB-server MariaDB-client

echo
echo "MariaDB packages installed."
echo "Do NOT start MariaDB until datadir ownership is verified."

echo
echo "Example:"
echo "  sudo chown -R mariadb:mariadb /var/lib/mysql"
