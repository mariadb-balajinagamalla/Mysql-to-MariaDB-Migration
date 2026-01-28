#!/usr/bin/env bash
set -euo pipefail

echo "==> Create migration user on source and target"

MYSQL_BIN="${MYSQL_BIN:-mysql}"
MARIADB_BIN="${MARIADB_BIN:-mariadb}"

SRC_HOST="${SRC_HOST:-}"
SRC_PORT="${SRC_PORT:-3306}"
SRC_USER="${SRC_USER:-}"
SRC_PASS="${SRC_PASS:-}"
SRC_DB="${SRC_DB:-}"
SRC_ADMIN_USER="${SRC_ADMIN_USER:-}"
SRC_ADMIN_PASS="${SRC_ADMIN_PASS:-}"
SRC_ADMIN_LOCAL="${SRC_ADMIN_LOCAL:-0}"
SRC_ADMIN_SOCKET="${SRC_ADMIN_SOCKET:-}"

TGT_HOST="${TGT_HOST:-}"
TGT_PORT="${TGT_PORT:-3306}"
TGT_USER="${TGT_USER:-}"
TGT_PASS="${TGT_PASS:-}"
TGT_ADMIN_USER="${TGT_ADMIN_USER:-}"
TGT_ADMIN_PASS="${TGT_ADMIN_PASS:-}"
TGT_ADMIN_LOCAL="${TGT_ADMIN_LOCAL:-0}"
TGT_ADMIN_SOCKET="${TGT_ADMIN_SOCKET:-}"
TGT_ADMIN_SSH_USER="${TGT_ADMIN_SSH_USER:-${MARIADB_INSTALL_SSH_USER:-root}}"
TGT_ADMIN_SSH_OPTS="${TGT_ADMIN_SSH_OPTS:-${MARIADB_INSTALL_SSH_OPTS:-}}"
ALLOW_ROOT_USERS="${ALLOW_ROOT_USERS:-0}"

if [[ -z "$SRC_HOST" || -z "$SRC_USER" || -z "$SRC_PASS" || -z "$SRC_DB" ]]; then
  echo "ERROR: Missing source envs. Set SRC_HOST, SRC_USER, SRC_PASS, SRC_DB."
  exit 1
fi

if [[ -z "$TGT_HOST" || -z "$TGT_USER" || -z "$TGT_PASS" ]]; then
  echo "ERROR: Missing target envs. Set TGT_HOST, TGT_USER, TGT_PASS."
  exit 1
fi

if [[ "${ALLOW_ROOT_USERS}" != "1" ]]; then
  if [[ "$SRC_USER" == "root" || "$TGT_USER" == "root" ]]; then
    echo "ERROR: SRC_USER/TGT_USER must not be root. Set ALLOW_ROOT_USERS=1 to override."
    exit 1
  fi
fi

if [[ -z "$SRC_ADMIN_USER" || -z "$SRC_ADMIN_PASS" ]]; then
  echo "WARN: SRC_ADMIN_USER/PASS not set; using SRC_USER/PASS as admin."
  SRC_ADMIN_USER="$SRC_USER"
  SRC_ADMIN_PASS="$SRC_PASS"
fi

if [[ -z "$TGT_ADMIN_USER" || -z "$TGT_ADMIN_PASS" ]]; then
  echo "WARN: TGT_ADMIN_USER/PASS not set; using TGT_USER/PASS as admin."
  TGT_ADMIN_USER="$TGT_USER"
  TGT_ADMIN_PASS="$TGT_PASS"
fi

sql_escape() {
  local s="$1"
  s="${s//\'/\'\'}"
  printf "%s" "$s"
}

SRC_USER_ESC="$(sql_escape "$SRC_USER")"
SRC_PASS_ESC="$(sql_escape "$SRC_PASS")"
SRC_DB_ESC="$(sql_escape "$SRC_DB")"
TGT_USER_ESC="$(sql_escape "$TGT_USER")"
TGT_PASS_ESC="$(sql_escape "$TGT_PASS")"
SRC_ADMIN_USER_ESC="$(sql_escape "$SRC_ADMIN_USER")"
TGT_ADMIN_USER_ESC="$(sql_escape "$TGT_ADMIN_USER")"

echo "Creating migration user on source: $SRC_HOST:$SRC_PORT"
if [[ "$SRC_ADMIN_LOCAL" == "1" ]]; then
  SRC_SOCKET_ARGS=()
  if [[ -n "$SRC_ADMIN_SOCKET" ]]; then
    SRC_SOCKET_ARGS+=(--socket="$SRC_ADMIN_SOCKET")
  fi
  MYSQL_PWD="$SRC_ADMIN_PASS" "$MYSQL_BIN" --protocol=SOCKET -u"$SRC_ADMIN_USER" ${SRC_SOCKET_ARGS[@]+"${SRC_SOCKET_ARGS[@]}"} \
    --batch --skip-column-names <<SQL
CREATE USER IF NOT EXISTS '${SRC_USER_ESC}'@'%' IDENTIFIED BY '${SRC_PASS_ESC}';
GRANT SELECT ON *.* TO '${SRC_USER_ESC}'@'%';
GRANT SHOW VIEW, TRIGGER, EVENT ON \`${SRC_DB_ESC}\`.* TO '${SRC_USER_ESC}'@'%';
FLUSH PRIVILEGES;
SQL
else
  MYSQL_PWD="$SRC_ADMIN_PASS" "$MYSQL_BIN" --protocol=TCP -h"$SRC_HOST" -P"$SRC_PORT" -u"$SRC_ADMIN_USER" \
    --batch --skip-column-names <<SQL
CREATE USER IF NOT EXISTS '${SRC_USER_ESC}'@'%' IDENTIFIED BY '${SRC_PASS_ESC}';
GRANT SELECT ON *.* TO '${SRC_USER_ESC}'@'%';
GRANT SHOW VIEW, TRIGGER, EVENT ON \`${SRC_DB_ESC}\`.* TO '${SRC_USER_ESC}'@'%';
FLUSH PRIVILEGES;
SQL
fi

echo "Creating migration user on target: $TGT_HOST:$TGT_PORT"
if [[ "$TGT_ADMIN_LOCAL" == "1" && -n "${MARIADB_INSTALL_HOST:-}" ]]; then
  SQL_TGT="CREATE USER IF NOT EXISTS '${TGT_USER_ESC}'@'%' IDENTIFIED BY '${TGT_PASS_ESC}';
GRANT ALL PRIVILEGES ON \`${SRC_DB_ESC}\`.* TO '${TGT_USER_ESC}'@'%';
GRANT SELECT ON mysql.user TO '${TGT_USER_ESC}'@'%';
FLUSH PRIVILEGES;"
  TGT_SOCKET_EXPR='
sock="";
if [ -n "'"$TGT_ADMIN_SOCKET"'" ]; then
  sock="'"$TGT_ADMIN_SOCKET"'";
else
  # Try common socket paths first (no mariadb client dependency)
  for c in /var/lib/mysql/mysql.sock /run/mysqld/mysqld.sock /tmp/mysql.sock; do
    if [ -S "$c" ]; then sock="$c"; break; fi;
  done;
fi;
echo "$sock";
'
  ssh ${TGT_ADMIN_SSH_OPTS} "${TGT_ADMIN_SSH_USER}@${MARIADB_INSTALL_HOST}" "sudo systemctl start mariadb >/dev/null 2>&1 || true"
  TARGET_SOCKET=$(ssh ${TGT_ADMIN_SSH_OPTS} "${TGT_ADMIN_SSH_USER}@${MARIADB_INSTALL_HOST}" "$TGT_SOCKET_EXPR")
  if [[ -z "$TARGET_SOCKET" ]]; then
    echo "ERROR: Could not detect MariaDB socket on target."
    exit 2
  fi
  printf '%s\n' "$SQL_TGT" | ssh ${TGT_ADMIN_SSH_OPTS} "${TGT_ADMIN_SSH_USER}@${MARIADB_INSTALL_HOST}" \
    "sudo ${MARIADB_BIN} --protocol=SOCKET -u'${TGT_ADMIN_USER}' --socket='${TARGET_SOCKET}' --batch --skip-column-names"
else
  MYSQL_PWD="$TGT_ADMIN_PASS" "$MARIADB_BIN" --protocol=TCP -h"$TGT_HOST" -P"$TGT_PORT" -u"$TGT_ADMIN_USER" \
    --batch --skip-column-names <<SQL
CREATE USER IF NOT EXISTS '${TGT_USER_ESC}'@'%' IDENTIFIED BY '${TGT_PASS_ESC}';
GRANT ALL PRIVILEGES ON \`${SRC_DB_ESC}\`.* TO '${TGT_USER_ESC}'@'%';
GRANT SELECT ON mysql.user TO '${TGT_USER_ESC}'@'%';
FLUSH PRIVILEGES;
SQL
fi

echo "Migration user setup completed."
