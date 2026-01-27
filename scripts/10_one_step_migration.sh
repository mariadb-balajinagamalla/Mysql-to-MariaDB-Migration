#!/usr/bin/env bash
set -euo pipefail

echo "==> One-step migration (mariadb-dump | mariadb)"

MARIADB_DUMP_BIN="${MARIADB_DUMP_BIN:-mariadb-dump}"
MARIADB_BIN="${MARIADB_BIN:-mariadb}"
PV_BIN="${PV_BIN:-pv}"

SRC_HOST="${SRC_HOST:-}"
SRC_PORT="${SRC_PORT:-3306}"
SRC_USER="${SRC_USER:-}"
SRC_PASS="${SRC_PASS:-}"
SRC_DB="${SRC_DB:-}"
SRC_SSL_MODE="${SRC_SSL_MODE:-}"

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

SRC_AUTH=( -h"$SRC_HOST" -P"$SRC_PORT" -u"$SRC_USER" )
TGT_AUTH=( -h"$TGT_HOST" -P"$TGT_PORT" -u"$TGT_USER" )

echo "Source: $SRC_HOST:$SRC_PORT  DB: $SRC_DB"
echo "Target: $TGT_HOST:$TGT_PORT"

PIPE_CMD=()
if command -v "$PV_BIN" >/dev/null 2>&1; then
  PIPE_CMD=( "$PV_BIN" -pet )
fi

SRC_SSL_ARGS=()
if [[ -n "$SRC_SSL_MODE" ]]; then
  SRC_SSL_ARGS=( --ssl-mode="$SRC_SSL_MODE" )
fi

if [[ "${#PIPE_CMD[@]}" -eq 0 ]]; then
  echo "pv not found; running without progress meter."
fi

set -o pipefail
"$MARIADB_DUMP_BIN" "${SRC_AUTH[@]}" "${SRC_SSL_ARGS[@]}" \
  --databases "$SRC_DB" \
  --routines --triggers --events \
  --gtid=0 --no-tablespaces --hex-blob --single-transaction \
  | if [[ "${#PIPE_CMD[@]}" -gt 0 ]]; then "${PIPE_CMD[@]}"; else cat; fi \
  | MYSQL_PWD="$TGT_PASS" "$MARIADB_BIN" "${TGT_AUTH[@]}"
set +o pipefail

echo "One-step migration completed."
