#!/usr/bin/env bash
set -euo pipefail

echo "==> Preflight checks (one_step)"

MYSQL_BIN="${MYSQL_BIN:-mysql}"
MARIADB_DUMP_BIN="${MARIADB_DUMP_BIN:-mariadb-dump}"
PV_BIN="${PV_BIN:-pv}"

SRC_HOST="${SRC_HOST:-}"
SRC_PORT="${SRC_PORT:-3306}"
SRC_USER="${SRC_USER:-}"
SRC_PASS="${SRC_PASS:-}"
SRC_DB="${SRC_DB:-}"

TGT_HOST="${TGT_HOST:-}"
TGT_PORT="${TGT_PORT:-3306}"
TGT_USER="${TGT_USER:-}"
TGT_PASS="${TGT_PASS:-}"
TGT_SSH_HOST="${TGT_SSH_HOST:-}"
TGT_SSH_USER="${TGT_SSH_USER:-root}"
TGT_SSH_OPTS="${TGT_SSH_OPTS:-}"

AUTO_FIX="${PREFLIGHT_AUTO_FIX:-0}"
AUTO_FIX_TARGET="${PREFLIGHT_AUTO_FIX_TARGET:-$AUTO_FIX}"

missing=()
for v in SRC_HOST SRC_USER SRC_PASS SRC_DB TGT_HOST TGT_USER TGT_PASS; do
  if [[ -z "${!v:-}" ]]; then
    missing+=("$v")
  fi
done
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

if [[ -n "$TGT_SSH_HOST" ]]; then
  echo "Checking target SSH connectivity..."
  if ! ssh ${TGT_SSH_OPTS} "${TGT_SSH_USER}@${TGT_SSH_HOST}" "true" >/dev/null 2>&1; then
    echo "ERROR: SSH to target failed."
    exit 4
  fi

  echo "Checking target mariadb client..."
  if ! ssh ${TGT_SSH_OPTS} "${TGT_SSH_USER}@${TGT_SSH_HOST}" "command -v mariadb >/dev/null 2>&1"; then
    if [[ "$AUTO_FIX_TARGET" == "1" ]]; then
      echo "Attempting to install mariadb client deps on target..."
      ssh ${TGT_SSH_OPTS} "${TGT_SSH_USER}@${TGT_SSH_HOST}" "sudo dnf -y install mariadb-client libxcrypt-compat >/dev/null 2>&1 || true"
    else
      echo "WARN: mariadb client not found on target."
    fi
  fi

  echo "Checking target TCP connectivity..."
  if ! ssh ${TGT_SSH_OPTS} "${TGT_SSH_USER}@${TGT_SSH_HOST}" \
    "MYSQL_PWD='${TGT_PASS}' mariadb -h'${TGT_HOST}' -P'${TGT_PORT}' -u'${TGT_USER}' --connect-timeout=5 -e 'SELECT 1;' >/dev/null 2>&1"; then
    echo "WARN: target TCP connect failed. Will attempt socket path during user creation/validate."
  fi
fi

if command -v "$PV_BIN" >/dev/null 2>&1; then
  echo "pv found."
else
  echo "pv not found (optional)."
fi

echo "Preflight complete."
