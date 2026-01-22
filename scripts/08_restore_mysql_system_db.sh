#!/usr/bin/env bash
set -euo pipefail

echo "==> Restore mysql system database (socket-first)"

BACKUP_FILE="${BACKUP_FILE:-artifacts/backup/mysql-system-db.sql}"
MARIADB_BIN="${MARIADB_BIN:-mariadb}"
USER="${USER:-root}"
PASS="${PASS:-}"

# Start MariaDB if not running
if ! systemctl is-active --quiet mariadb; then
  echo "MariaDB is not running. Starting mariadb..."
  sudo systemctl start mariadb
fi

# Prefer SOCKET if explicitly provided, else infer from logs/defaults
SOCKET="${SOCKET:-}"

if [[ -z "$SOCKET" ]]; then
  SOCKET="$($MARIADB_BIN --print-defaults 2>/dev/null | tr ' ' '\n' | sed -n 's/^--socket=//p' | head -n 1 || true)"
fi

if [[ -z "$SOCKET" ]]; then
  # Fallbacks
  for candidate in /var/lib/mysql/mysql.sock /run/mysqld/mysqld.sock /tmp/mysql.sock; do
    if sudo test -S "$candidate"; then
      SOCKET="$candidate"
      break
    fi
  done
fi

# Wait for socket to appear (use sudo because ec2-user can't access /var/lib/mysql)
if [[ -n "$SOCKET" ]]; then
  echo "Waiting for socket: $SOCKET"
  for i in {1..30}; do
    if sudo test -S "$SOCKET"; then
      break
    fi
    sleep 1
  done
fi

if [[ -z "$SOCKET" || ! $(sudo test -S "$SOCKET" && echo ok) ]]; then
  echo "ERROR: socket not accessible/found by orchestrator."
  echo "Diagnostics:"
  sudo systemctl status mariadb -l --no-pager || true
  echo "Try listing sockets (sudo):"
  sudo ls -l /var/lib/mysql/*.sock /run/mysqld/*.sock /tmp/*.sock 2>/dev/null || true
  exit 2
fi

echo "Using socket: $SOCKET"

if [[ ! -f "$BACKUP_FILE" ]]; then
  echo "ERROR: backup file not found: $BACKUP_FILE"
  exit 3
fi

# Pass password if provided (works for mysql_native_password)
PWOPTS=()
if [[ -n "$PASS" ]]; then
  PWOPTS=(--password="$PASS")
fi

# Restore using sudo so socket path is reachable
sudo "$MARIADB_BIN" --protocol=SOCKET --socket="$SOCKET" -u"$USER" "${PWOPTS[@]}" mysql < "$BACKUP_FILE"

echo "Restore completed."
