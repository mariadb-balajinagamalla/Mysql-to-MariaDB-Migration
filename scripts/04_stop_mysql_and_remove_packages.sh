#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "ERROR: This step must be executed on the MySQL host (Linux)."
  echo "Aborting to prevent accidental local damage."
  exit 2
fi

echo "Stopping MySQL service..."
sudo systemctl stop mysqld || sudo service mysqld stop || true

echo
echo "Installed MySQL / Percona packages:"
rpm -qa | grep -iE 'mysql|percona' || true

echo
echo "IMPORTANT:"
echo "This step is DESTRUCTIVE."
echo "Review the list above carefully."

echo
echo "To actually remove packages, edit this script and UNCOMMENT:"
echo "  sudo rpm -e --nodeps <package-name>"

exit 0
