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
SRC_DBS="${SRC_DBS:-}"
SRC_SSL_MODE="${SRC_SSL_MODE:-}"
STRIP_DEFINERS="${STRIP_DEFINERS:-1}"

TGT_HOST="${TGT_HOST:-}"
TGT_PORT="${TGT_PORT:-3306}"
TGT_USER="${TGT_USER:-}"
TGT_PASS="${TGT_PASS:-}"
TGT_SSH_HOST="${TGT_SSH_HOST:-}"
TGT_SSH_USER="${TGT_SSH_USER:-root}"
TGT_SSH_OPTS="${TGT_SSH_OPTS:-}"
ALLOW_TARGET_DB_OVERWRITE="${ALLOW_TARGET_DB_OVERWRITE:-0}"

if [[ -z "$SRC_HOST" || -z "$SRC_USER" || -z "$SRC_PASS" || ( -z "$SRC_DB" && -z "$SRC_DBS" ) ]]; then
  echo "ERROR: Missing source envs. Set SRC_HOST, SRC_USER, SRC_PASS, and SRC_DB or SRC_DBS."
  exit 1
fi

if [[ -z "$TGT_HOST" || -z "$TGT_USER" || -z "$TGT_PASS" ]]; then
  echo "ERROR: Missing target envs. Set TGT_HOST, TGT_USER, TGT_PASS (TGT_PORT optional)."
  exit 1
fi

sql_escape() {
  local s="$1"
  s="${s//\'/\'\'}"
  printf "%s" "$s"
}

target_db_exists() {
  local db="$1"
  local db_esc
  db_esc="$(sql_escape "$db")"
  local q="SELECT COUNT(*) FROM information_schema.schemata WHERE schema_name='${db_esc}';"
  local out=""
  if [[ -n "$TGT_SSH_HOST" ]]; then
    local tgt_pass_q
    tgt_pass_q="$(printf '%q' "$TGT_PASS")"
    out="$(ssh ${TGT_SSH_OPTS} "${TGT_SSH_USER}@${TGT_SSH_HOST}" \
      "MYSQL_PWD=$tgt_pass_q ${MARIADB_BIN} -h'${TGT_HOST}' -P'${TGT_PORT}' -u'${TGT_USER}' --batch --skip-column-names -e \"$q\"")"
  else
    out="$(MYSQL_PWD="$TGT_PASS" "$MARIADB_BIN" -h"$TGT_HOST" -P"$TGT_PORT" -u"$TGT_USER" \
      --batch --skip-column-names -e "$q")"
  fi
  [[ "${out:-0}" -gt 0 ]]
}

if ! command -v "$MARIADB_DUMP_BIN" >/dev/null 2>&1; then
  if command -v mysqldump >/dev/null 2>&1; then
    echo "mariadb-dump not found; using mysqldump."
    MARIADB_DUMP_BIN="mysqldump"
  fi
fi

SRC_AUTH=( -h"$SRC_HOST" -P"$SRC_PORT" -u"$SRC_USER" )
TGT_AUTH=( -h"$TGT_HOST" -P"$TGT_PORT" -u"$TGT_USER" )

if [[ -n "$SRC_DBS" ]]; then
  echo "Source: $SRC_HOST:$SRC_PORT  DBs: $SRC_DBS"
else
  echo "Source: $SRC_HOST:$SRC_PORT  DB: $SRC_DB"
fi
echo "Target: $TGT_HOST:$TGT_PORT"

set -o pipefail
SRC_SSL_ARGS=()
if [[ -n "$SRC_SSL_MODE" ]]; then
  SRC_SSL_ARGS=( --ssl-mode="$SRC_SSL_MODE" )
fi

COMMON_ARGS=(
  --no-data
  --routines --triggers --events
  --no-tablespaces
)
FILTER_CMD=()
if [[ "$STRIP_DEFINERS" == "1" ]]; then
  if [[ "$MARIADB_DUMP_BIN" == "mysqldump" ]]; then
    FILTER_CMD=( sed -E 's/\/\*!50017 DEFINER=`[^`]+`@`[^`]+`\*\/ ?//g; s/DEFINER=`[^`]+`@`[^`]+`//g' )
  else
    DUMP_ARGS+=(--skip-definer)
  fi
fi
if [[ "$MARIADB_DUMP_BIN" == "mysqldump" ]]; then
  COMMON_ARGS+=(--set-gtid-purged=OFF)
else
  COMMON_ARGS+=(--gtid=0)
fi

if [[ -n "$SRC_DBS" ]]; then
  IFS=',' read -r -a DB_LIST <<< "$SRC_DBS"
else
  DB_LIST=("$SRC_DB")
fi

if [[ "$ALLOW_TARGET_DB_OVERWRITE" != "1" ]]; then
  existing=()
  for db in "${DB_LIST[@]}"; do
    db="${db// /}"
    [[ -z "$db" ]] && continue
    if target_db_exists "$db"; then
      existing+=("$db")
    fi
  done
  if [[ "${#existing[@]}" -gt 0 ]]; then
    echo "ERROR: Target DB already exists: ${existing[*]}"
    echo "Set ALLOW_TARGET_DB_OVERWRITE=1 only if you explicitly want to overwrite existing DBs."
    exit 8
  fi
fi

for db in "${DB_LIST[@]}"; do
  db="${db// /}"
  [[ -z "$db" ]] && continue
  DUMP_ARGS=("${COMMON_ARGS[@]}" --databases "$db")
  MYSQL_PWD="$SRC_PASS" "$MARIADB_DUMP_BIN" "${SRC_AUTH[@]}" "${SRC_SSL_ARGS[@]}" "${DUMP_ARGS[@]}" \
    | if [[ "${#FILTER_CMD[@]}" -gt 0 ]]; then "${FILTER_CMD[@]}"; else cat; fi \
    | if [[ -n "$TGT_SSH_HOST" ]]; then
        TGT_PASS_Q="$(printf '%q' "$TGT_PASS")"
        ssh ${TGT_SSH_OPTS} "${TGT_SSH_USER}@${TGT_SSH_HOST}" \
          "MYSQL_PWD=$TGT_PASS_Q ${MARIADB_BIN} ${TGT_AUTH[*]}"
      else
        MYSQL_PWD="$TGT_PASS" "$MARIADB_BIN" "${TGT_AUTH[@]}"
      fi
done
set +o pipefail

echo "Schema-only migration completed."
