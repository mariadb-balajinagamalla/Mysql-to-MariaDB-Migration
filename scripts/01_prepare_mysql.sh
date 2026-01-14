#!/usr/bin/env bash
set -euo pipefail

MYSQL="${MYSQL:-mysql}"
HOST="${HOST:-127.0.0.1}"
PORT="${PORT:-3306}"
USER="${USER:-root}"

PASS="${PASS:-}"
if [[ -n "$PASS" && -z "${MYSQL_PWD:-}" ]]; then
  export MYSQL_PWD="$PASS"
fi

AUTH=(-h"$HOST" -P"$PORT" -u"$USER")

echo "Setting innodb_fast_shutdown=0 (required before major upgrade)"
$MYSQL "${AUTH[@]}" -e "SET @@GLOBAL.innodb_fast_shutdown=0;"
echo "Done."
