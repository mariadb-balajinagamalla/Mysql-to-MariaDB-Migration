#!/usr/bin/env bash
set -euo pipefail

echo "==> Binlog migration: verify replication"

MARIADB_BIN="${MARIADB_BIN:-mariadb}"

TGT_HOST="${TGT_HOST:-}"
TGT_PORT="${TGT_PORT:-3306}"
TGT_ADMIN_USER="${TGT_ADMIN_USER:-}"
TGT_ADMIN_PASS="${TGT_ADMIN_PASS:-}"
BINLOG_MAX_LAG_SECS="${BINLOG_MAX_LAG_SECS:-30}"

if [[ -z "$TGT_HOST" || -z "$TGT_ADMIN_USER" || -z "$TGT_ADMIN_PASS" ]]; then
  echo "ERROR: Missing target admin envs for verify step."
  exit 1
fi

status_line="$(MYSQL_PWD="$TGT_ADMIN_PASS" "$MARIADB_BIN" --protocol=TCP -h"$TGT_HOST" -P"$TGT_PORT" -u"$TGT_ADMIN_USER" \
  --batch --skip-column-names -e "SHOW REPLICA STATUS\\G" 2>/dev/null | awk -F': ' '
    $1 ~ /Replica_IO_Running|Slave_IO_Running/ {io=$2}
    $1 ~ /Replica_SQL_Running|Slave_SQL_Running/ {sql=$2}
    $1 ~ /Seconds_Behind_Master/ {lag=$2}
    END {print io"\t"sql"\t"lag}
  ')"

if [[ -z "$status_line" || "$status_line" == $'\t\t' ]]; then
  status_line="$(MYSQL_PWD="$TGT_ADMIN_PASS" "$MARIADB_BIN" --protocol=TCP -h"$TGT_HOST" -P"$TGT_PORT" -u"$TGT_ADMIN_USER" \
    --batch --skip-column-names -e "SHOW SLAVE STATUS\\G" 2>/dev/null | awk -F': ' '
      $1 ~ /Slave_IO_Running/ {io=$2}
      $1 ~ /Slave_SQL_Running/ {sql=$2}
      $1 ~ /Seconds_Behind_Master/ {lag=$2}
      END {print io"\t"sql"\t"lag}
    ')"
fi

if [[ -z "$status_line" || "$status_line" == $'\t\t' ]]; then
  echo "ERROR: Could not read replication status from target."
  exit 2
fi

io_state="$(printf "%s" "$status_line" | awk -F'\t' '{print $1}')"
sql_state="$(printf "%s" "$status_line" | awk -F'\t' '{print $2}')"
lag_secs="$(printf "%s" "$status_line" | awk -F'\t' '{print $3}')"

echo "IO running: ${io_state:-unknown}"
echo "SQL running: ${sql_state:-unknown}"
echo "Seconds behind master: ${lag_secs:-unknown}"

if [[ "${io_state:-No}" != "Yes" || "${sql_state:-No}" != "Yes" ]]; then
  echo "ERROR: Replication threads are not healthy."
  exit 3
fi

if [[ -n "$lag_secs" && "$lag_secs" != "NULL" ]]; then
  if [[ "$lag_secs" =~ ^[0-9]+$ ]] && (( lag_secs > BINLOG_MAX_LAG_SECS )); then
    echo "ERROR: Replication lag too high (${lag_secs}s > ${BINLOG_MAX_LAG_SECS}s)."
    exit 4
  fi
fi

echo "Replication verify passed."
