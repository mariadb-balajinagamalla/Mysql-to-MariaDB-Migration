#!/usr/bin/env bash
set -euo pipefail

echo "==> Binlog migration: configure and start replication"

MYSQL_BIN="${MYSQL_BIN:-mysql}"
MARIADB_BIN="${MARIADB_BIN:-mariadb}"

SRC_HOST="${SRC_HOST:-}"
SRC_PORT="${SRC_PORT:-3306}"
SRC_ADMIN_USER="${SRC_ADMIN_USER:-}"
SRC_ADMIN_PASS="${SRC_ADMIN_PASS:-}"

TGT_HOST="${TGT_HOST:-}"
TGT_PORT="${TGT_PORT:-3306}"
TGT_ADMIN_USER="${TGT_ADMIN_USER:-}"
TGT_ADMIN_PASS="${TGT_ADMIN_PASS:-}"

REPL_USER="${REPL_USER:-}"
REPL_PASS="${REPL_PASS:-}"
BINLOG_COORD_FILE="${BINLOG_COORD_FILE:-artifacts/binlog_coords.env}"
SRC_BINLOG_FILE="${SRC_BINLOG_FILE:-}"
SRC_BINLOG_POS="${SRC_BINLOG_POS:-}"
BINLOG_CREATE_REPL_USER="${BINLOG_CREATE_REPL_USER:-1}"

missing=()
for v in SRC_HOST SRC_ADMIN_USER SRC_ADMIN_PASS TGT_HOST TGT_ADMIN_USER TGT_ADMIN_PASS REPL_USER REPL_PASS; do
  if [[ -z "${!v:-}" ]]; then
    missing+=("$v")
  fi
done
if [[ "${#missing[@]}" -gt 0 ]]; then
  echo "ERROR: Missing env vars: ${missing[*]}"
  exit 1
fi

if [[ -z "$SRC_BINLOG_FILE" || -z "$SRC_BINLOG_POS" ]]; then
  if [[ -f "$BINLOG_COORD_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$BINLOG_COORD_FILE"
  fi
fi
if [[ -z "$SRC_BINLOG_FILE" || -z "$SRC_BINLOG_POS" ]]; then
  echo "ERROR: Missing binlog coordinates. Set SRC_BINLOG_FILE/SRC_BINLOG_POS or generate $BINLOG_COORD_FILE in seed step."
  exit 2
fi

echo "Ensuring replication user exists on source..."
if [[ "$BINLOG_CREATE_REPL_USER" == "1" ]]; then
  repl_user_esc="${REPL_USER//\'/\'\'}"
  repl_pass_esc="${REPL_PASS//\'/\'\'}"
  MYSQL_PWD="$SRC_ADMIN_PASS" "$MYSQL_BIN" --protocol=TCP -h"$SRC_HOST" -P"$SRC_PORT" -u"$SRC_ADMIN_USER" \
    --batch --skip-column-names -e "CREATE USER IF NOT EXISTS '${repl_user_esc}'@'%' IDENTIFIED WITH mysql_native_password BY '${repl_pass_esc}';" || true
  MYSQL_PWD="$SRC_ADMIN_PASS" "$MYSQL_BIN" --protocol=TCP -h"$SRC_HOST" -P"$SRC_PORT" -u"$SRC_ADMIN_USER" \
    --batch --skip-column-names -e "ALTER USER '${repl_user_esc}'@'%' IDENTIFIED WITH mysql_native_password BY '${repl_pass_esc}';" || true
  MYSQL_PWD="$SRC_ADMIN_PASS" "$MYSQL_BIN" --protocol=TCP -h"$SRC_HOST" -P"$SRC_PORT" -u"$SRC_ADMIN_USER" \
    --batch --skip-column-names -e "GRANT REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO '${repl_user_esc}'@'%';" || true
  MYSQL_PWD="$SRC_ADMIN_PASS" "$MYSQL_BIN" --protocol=TCP -h"$SRC_HOST" -P"$SRC_PORT" -u"$SRC_ADMIN_USER" \
    --batch --skip-column-names -e "FLUSH PRIVILEGES;"
fi

repl_sql="CHANGE MASTER TO
  MASTER_HOST='${SRC_HOST}',
  MASTER_PORT=${SRC_PORT},
  MASTER_USER='${REPL_USER}',
  MASTER_PASSWORD='${REPL_PASS}',
  MASTER_LOG_FILE='${SRC_BINLOG_FILE}',
  MASTER_LOG_POS=${SRC_BINLOG_POS};"

echo "Applying replication coordinates: ${SRC_BINLOG_FILE}:${SRC_BINLOG_POS}"
MYSQL_PWD="$TGT_ADMIN_PASS" "$MARIADB_BIN" --protocol=TCP -h"$TGT_HOST" -P"$TGT_PORT" -u"$TGT_ADMIN_USER" \
  --batch --skip-column-names -e "STOP REPLICA;" >/dev/null 2>&1 || \
MYSQL_PWD="$TGT_ADMIN_PASS" "$MARIADB_BIN" --protocol=TCP -h"$TGT_HOST" -P"$TGT_PORT" -u"$TGT_ADMIN_USER" \
  --batch --skip-column-names -e "STOP SLAVE;" >/dev/null 2>&1 || true

MYSQL_PWD="$TGT_ADMIN_PASS" "$MARIADB_BIN" --protocol=TCP -h"$TGT_HOST" -P"$TGT_PORT" -u"$TGT_ADMIN_USER" \
  --batch --skip-column-names -e "$repl_sql"

MYSQL_PWD="$TGT_ADMIN_PASS" "$MARIADB_BIN" --protocol=TCP -h"$TGT_HOST" -P"$TGT_PORT" -u"$TGT_ADMIN_USER" \
  --batch --skip-column-names -e "START REPLICA;" >/dev/null 2>&1 || \
MYSQL_PWD="$TGT_ADMIN_PASS" "$MARIADB_BIN" --protocol=TCP -h"$TGT_HOST" -P"$TGT_PORT" -u"$TGT_ADMIN_USER" \
  --batch --skip-column-names -e "START SLAVE;"

echo "Replication started."
