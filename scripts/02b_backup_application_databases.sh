#!/usr/bin/env bash
set -euo pipefail

echo "==> Backup application databases (exclude system schemas) [TCP + no-defaults]"

MARIADB_BIN="${MARIADB_BIN:-mariadb}"
MYSQLDUMP_BIN="${MYSQLDUMP_BIN:-mysqldump}"

HOST="${HOST:-127.0.0.1}"
PORT="${PORT:-3306}"
USER="${USER:-migrate}"
PASS="${PASS:-}"

BACKUP_DIR="${BACKUP_DIR:-artifacts/backup}"
TS="$(date +%Y%m%d_%H%M%S)"

if [[ -z "$PASS" ]]; then
  echo "ERROR: PASS is empty. Set PASS for TCP automation user (recommended: migrate)."
  exit 1
fi

export MYSQL_PWD="$PASS"

mkdir -p "$BACKUP_DIR"

AUTH=(--no-defaults --protocol=TCP -h"$HOST" -P"$PORT" -u"$USER")

echo "Discovering application schemas..."

APP_DBS=$(
  "$MARIADB_BIN" "${AUTH[@]}" --batch --skip-column-names \
    -e "
      SELECT schema_name
      FROM information_schema.schemata
      WHERE schema_name NOT IN ('mysql','information_schema','performance_schema','sys')
      ORDER BY schema_name;
    "
)

if [[ -z "$APP_DBS" ]]; then
  echo "ERROR: No application databases found to back up."
  exit 1
fi

echo "Found application databases:"
echo "$APP_DBS" | sed 's/^/  - /'

for db in $APP_DBS; do
  OUT_FILE="$BACKUP_DIR/${db}_app_backup_${TS}.sql"
  echo
  echo "Backing up database: $db"
  echo " -> $OUT_FILE"

  "$MYSQLDUMP_BIN" \
    "${AUTH[@]}" \
    --databases "$db" \
    --single-transaction \
    --routines \
    --triggers \
    --events \
    --hex-blob \
    --set-gtid-purged=OFF \
    --default-character-set=utf8mb4 \
    > "$OUT_FILE"
done

echo
echo "Application database backup completed successfully."
echo "Backups stored in: $BACKUP_DIR"
