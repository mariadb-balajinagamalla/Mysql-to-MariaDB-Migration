#!/usr/bin/env bash
set -euo pipefail

# Always run from repo root so relative paths are stable
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

DUMP_BIN="${DUMP_BIN:-mysqldump}"
HOST="${HOST:-127.0.0.1}"
PORT="${PORT:-3306}"
USER="${USER:-root}"

# Prefer MYSQL_PWD from orchestrator env; fall back to PASS if provided
PASS="${PASS:-}"
if [[ -n "$PASS" && -z "${MYSQL_PWD:-}" ]]; then
  export MYSQL_PWD="$PASS"
fi

OUTDIR="${OUTDIR:-$ROOT/artifacts/backup}"
mkdir -p "$OUTDIR"

AUTH=(--host="$HOST" --port="$PORT" --user="$USER")

echo "Dumping mysql system database from $HOST:$PORT ..."
# Note: mysql system DB contains users/privileges. Keep this dump secure.
"$DUMP_BIN" "${AUTH[@]}" --routines --events --triggers mysql > "$OUTDIR/mysql-system-db.sql"

echo "Wrote: $OUTDIR/mysql-system-db.sql"
