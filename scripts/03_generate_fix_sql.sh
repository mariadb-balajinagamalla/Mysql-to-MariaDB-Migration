#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

MYSQL_BIN="${MYSQL_BIN:-mysql}"
HOST="${HOST:-127.0.0.1}"
PORT="${PORT:-3306}"
USER="${USER:-root}"

PASS="${PASS:-}"
if [[ -n "$PASS" && -z "${MYSQL_PWD:-}" ]]; then
  export MYSQL_PWD="$PASS"
fi

OUTDIR="${OUTDIR:-$ROOT/outputs}"
mkdir -p "$OUTDIR"

MYSQL_AUTH=( -h"$HOST" -P"$PORT" -u"$USER" )
MYSQL_OPTS=( --batch --skip-column-names --raw )

echo "== Generating user plugin fix SQL =="
"$MYSQL_BIN" "${MYSQL_AUTH[@]}" "${MYSQL_OPTS[@]}" -e "
SELECT CONCAT(
  'ALTER USER ''', user, '''@''', host,
  ''' IDENTIFIED WITH mysql_native_password BY ''<SET_PASSWORD_HERE>'';'
)
FROM mysql.user
WHERE user NOT IN ('mysql.infoschema','mysql.session','mysql.sys')
  AND (plugin LIKE '%sha%' OR plugin LIKE '%caching_sha2%')
ORDER BY user, host;
" > "$OUTDIR/fix_users_to_native_password.sql"

echo "Wrote: $OUTDIR/fix_users_to_native_password.sql"
echo "NOTE: Replace <SET_PASSWORD_HERE> manually or wire from secrets."

echo
echo "== Generating JSON-to-LONGTEXT conversion SQL (optional) =="
"$MYSQL_BIN" "${MYSQL_AUTH[@]}" "${MYSQL_OPTS[@]}" -e "
SELECT CONCAT(
  'ALTER TABLE ', table_schema, '.', table_name, ' ',
  'MODIFY ', column_name, ' LONGTEXT;'
)
FROM information_schema.COLUMNS
WHERE data_type='json'
  AND table_schema NOT IN ('mysql','information_schema','performance_schema','sys')
ORDER BY table_schema, table_name, column_name;
" > "$OUTDIR/fix_json_to_longtext.sql"

echo "Wrote: $OUTDIR/fix_json_to_longtext.sql"
echo "Only apply if you truly need TEXT storage for compatibility."
