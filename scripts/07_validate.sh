#!/usr/bin/env bash
set -euo pipefail

MARIADB_BIN="${MARIADB_BIN:-mariadb}"
SOCKET="${SOCKET:-/var/lib/mysql/mysql.sock}"

echo "MariaDB version (socket-based validation):"
sudo "$MARIADB_BIN" \
  --socket="$SOCKET" \
  -u root \
  --batch --skip-column-names \
  -e "SELECT VERSION();"

echo
echo "User authentication plugins:"
sudo "$MARIADB_BIN" \
  --socket="$SOCKET" \
  -u root \
  --batch --skip-column-names \
  -e "SELECT user, host, plugin FROM mysql.user ORDER BY user, host;"

echo
echo "Storage engines:"
sudo "$MARIADB_BIN" \
  --socket="$SOCKET" \
  -u root \
  --batch --skip-column-names \
  -e "SHOW ENGINES;"

echo
echo "Validation complete (socket-first)."
