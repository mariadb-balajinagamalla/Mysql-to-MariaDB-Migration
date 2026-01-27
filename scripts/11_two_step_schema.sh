#!/usr/bin/env bash
set -euo pipefail

echo "==> Two-step migration: schema only (no data)"

MARIADB_DUMP_BIN="${MARIADB_DUMP_BIN:-mariadb-dump}"
MARIADB_BIN="${MARIADB_BIN:-mariadb}"

SRC_HOST="${SRC_HOST:-}"
SRC_PORT="${SRC_PORT:-3306}"
SRC_USER="${SRC_USER:-}"
SRC_PASS="${SRC_PASS:-}"
SRC_DB="${SRC_DB:-}"

TGT_HOST="${TGT_HOST:-}"
TGT_PORT="${TGT_PORT:-3306}"
TGT_USER="${TGT_USER:-}"
TGT_PASS="${TGT_PASS:-}"

if [[ -z "$SRC_HOST" || -z "$SRC_USER" || -z "$SRC_PASS" || -z "$SRC_DB" ]]; then
  echo "ERROR: Missing source envs. Set SRC_HOST, SRC_USER, SRC_PASS, SRC_DB (SRC_PORT optional)."
  exit 1
fi

if [[ -z "$TGT_HOST" || -z "$TGT_USER" || -z "$TGT_PASS" ]]; then
  echo "ERROR: Missing target envs. Set TGT_HOST, TGT_USER, TGT_PASS (TGT_PORT optional)."
  exit 1
fi

export MYSQL_PWD="$SRC_PASS"

SRC_AUTH=( -h"$SRC_HOST" -P"$SRC_PORT" -u"$SRC_USER" )
TGT_AUTH=( -h"$TGT_HOST" -P"$TGT_PORT" -u"$TGT_USER" )

echo "Source: $SRC_HOST:$SRC_PORT  DB: $SRC_DB"
echo "Target: $TGT_HOST:$TGT_PORT"

set -o pipefail
"$MARIADB_DUMP_BIN" "${SRC_AUTH[@]}" \
  --no-data --databases "$SRC_DB" \
  --routines --triggers \
  --gtid=0 --no-tablespaces \
  | MYSQL_PWD="$TGT_PASS" "$MARIADB_BIN" "${TGT_AUTH[@]}"
set +o pipefail

echo "Schema-only migration completed."
