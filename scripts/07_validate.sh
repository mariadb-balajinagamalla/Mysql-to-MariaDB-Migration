#!/usr/bin/env bash
set -euo pipefail

MARIADB_BIN="${MARIADB_BIN:-mariadb}"
SOCKET="${SOCKET:-/var/lib/mysql/mysql.sock}"
TGT_HOST="${TGT_HOST:-}"
TGT_PORT="${TGT_PORT:-3306}"
TGT_USER="${TGT_USER:-root}"
TGT_PASS="${TGT_PASS:-}"

if [[ -n "$TGT_HOST" && -n "$TGT_USER" && -n "$TGT_PASS" ]]; then
  echo "MariaDB version (TCP validation):"
  MYSQL_PWD="$TGT_PASS" "$MARIADB_BIN" \
    -h"$TGT_HOST" -P"$TGT_PORT" -u"$TGT_USER" \
    --batch --skip-column-names \
    -e "SELECT VERSION();"
else
  echo "MariaDB version (socket-based validation):"
  sudo "$MARIADB_BIN" \
    --socket="$SOCKET" \
    -u root \
    --batch --skip-column-names \
    -e "SELECT VERSION();"
fi

echo
echo "User authentication plugins:"
if [[ -n "$TGT_HOST" && -n "$TGT_USER" && -n "$TGT_PASS" ]]; then
  MYSQL_PWD="$TGT_PASS" "$MARIADB_BIN" \
    -h"$TGT_HOST" -P"$TGT_PORT" -u"$TGT_USER" \
    --batch --skip-column-names \
    -e "SELECT user, host, plugin FROM mysql.user ORDER BY user, host;"
else
  sudo "$MARIADB_BIN" \
    --socket="$SOCKET" \
    -u root \
    --batch --skip-column-names \
    -e "SELECT user, host, plugin FROM mysql.user ORDER BY user, host;"
fi

echo
echo "Storage engines:"
if [[ -n "$TGT_HOST" && -n "$TGT_USER" && -n "$TGT_PASS" ]]; then
  MYSQL_PWD="$TGT_PASS" "$MARIADB_BIN" \
    -h"$TGT_HOST" -P"$TGT_PORT" -u"$TGT_USER" \
    --batch --skip-column-names \
    -e "SHOW ENGINES;"
else
  sudo "$MARIADB_BIN" \
    --socket="$SOCKET" \
    -u root \
    --batch --skip-column-names \
    -e "SHOW ENGINES;"
fi

echo
echo "Validation complete (socket-first)."
