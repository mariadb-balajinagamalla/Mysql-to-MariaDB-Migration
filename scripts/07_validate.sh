#!/usr/bin/env bash
set -euo pipefail

MARIADB_BIN="${MARIADB_BIN:-mariadb}"
HOST="${HOST:-127.0.0.1}"
PORT="${PORT:-3306}"
USER="${USER:-root}"

PASS="${PASS:-}"
if [[ -n "$PASS" && -z "${MYSQL_PWD:-}" ]]; then
  export MYSQL_PWD="$PASS"
fi

AUTH=(-h"$HOST" -P"$PORT" -u"$USER")
OPTS=(--batch --skip-column-names)

echo "MariaDB version:"
"$MARIADB_BIN" "${AUTH[@]}" -e "SELECT VERSION();"

echo
echo "User authentication plugins after upgrade:"
"$MARIADB_BIN" "${AUTH[@]}" "${OPTS[@]}" \
  -e "SELECT user, host, plugin FROM mysql.user ORDER BY user, host;"

echo
echo "Validation complete."
