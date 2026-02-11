#!/usr/bin/env bash
set -euo pipefail

echo "==> Preflight checks (two_step)"

MYSQL_BIN="${MYSQL_BIN:-mysql}"
MARIADB_DUMP_BIN="${MARIADB_DUMP_BIN:-mariadb-dump}"

SRC_HOST="${SRC_HOST:-}"
SRC_PORT="${SRC_PORT:-3306}"
SRC_USER="${SRC_USER:-}"
SRC_PASS="${SRC_PASS:-}"
SRC_DB="${SRC_DB:-}"
SRC_DBS="${SRC_DBS:-}"

TGT_HOST="${TGT_HOST:-}"
TGT_PORT="${TGT_PORT:-3306}"
TGT_USER="${TGT_USER:-}"
TGT_PASS="${TGT_PASS:-}"

SQLINESDATA_BIN="${SQLINESDATA_BIN:-}"

missing=()
for v in SRC_HOST SRC_USER SRC_PASS TGT_HOST TGT_USER TGT_PASS; do
  if [[ -z "${!v:-}" ]]; then
    missing+=("$v")
  fi
done
if [[ -z "$SRC_DB" && -z "$SRC_DBS" ]]; then
  missing+=("SRC_DB_or_SRC_DBS")
fi
if [[ "${#missing[@]}" -gt 0 ]]; then
  echo "ERROR: Missing env vars: ${missing[*]}"
  exit 1
fi

if ! command -v "$MYSQL_BIN" >/dev/null 2>&1; then
  echo "ERROR: mysql client not found (MYSQL_BIN=$MYSQL_BIN)."
  exit 2
fi

if ! command -v "$MARIADB_DUMP_BIN" >/dev/null 2>&1; then
  if command -v mysqldump >/dev/null 2>&1; then
    echo "mariadb-dump not found; mysqldump is available (OK)."
  else
    echo "ERROR: neither mariadb-dump nor mysqldump found on source host."
    exit 3
  fi
fi

echo "Checking source connectivity..."
MYSQL_PWD="$SRC_PASS" "$MYSQL_BIN" -h"$SRC_HOST" -P"$SRC_PORT" -u"$SRC_USER" \
  --connect-timeout=5 --batch --skip-column-names \
  -e "SELECT 1;" >/dev/null

if [[ -n "$SQLINESDATA_BIN" ]]; then
  if [[ ! -x "$SQLINESDATA_BIN" ]]; then
    echo "ERROR: SQLINESDATA_BIN not executable: $SQLINESDATA_BIN"
    exit 4
  fi
else
  if command -v sqldata >/dev/null 2>&1; then
    echo "sqldata found in PATH (OK)."
  else
    echo "ERROR: SQLINESDATA_BIN not set and sqldata not found in PATH."
    exit 5
  fi
fi

echo "Preflight complete."
