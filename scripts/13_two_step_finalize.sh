#!/usr/bin/env bash
set -euo pipefail

echo "==> Two-step migration: finalize objects (constraints/indexes/routines)"

SQLINESDATA_BIN="${SQLINESDATA_BIN:-}"
SQLINESDATA_CMD_FINALIZE="${SQLINESDATA_CMD_FINALIZE:-}"
SQLINESDATA_CMD_FINALIZE_TEMPLATE="${SQLINESDATA_CMD_FINALIZE_TEMPLATE:-}"
SRC_DBS="${SRC_DBS:-}"

if [[ -z "$SQLINESDATA_BIN" && -z "$SQLINESDATA_CMD_FINALIZE" ]]; then
  echo "ERROR: Provide SQLINESDATA_BIN + SQLINESDATA_ARGS_FINALIZE or SQLINESDATA_CMD_FINALIZE."
  exit 1
fi

if [[ -n "$SRC_DBS" ]]; then
  if [[ -z "$SQLINESDATA_CMD_FINALIZE_TEMPLATE" ]]; then
    echo "ERROR: SRC_DBS set but SQLINESDATA_CMD_FINALIZE_TEMPLATE is empty."
    exit 1
  fi
  IFS=',' read -r -a DB_LIST <<< "$SRC_DBS"
  for db in "${DB_LIST[@]}"; do
    db="${db// /}"
    if [[ -z "$db" ]]; then
      continue
    fi
    cmd="${SQLINESDATA_CMD_FINALIZE_TEMPLATE//\{DB\}/$db}"
    bash -c "$cmd"
  done
  echo "SQLines Data finalize completed."
  exit 0
fi

if [[ -n "$SQLINESDATA_CMD_FINALIZE" ]]; then
  bash -c "$SQLINESDATA_CMD_FINALIZE"
  echo "SQLines Data finalize completed."
  exit 0
fi

SQLINESDATA_ARGS_FINALIZE="${SQLINESDATA_ARGS_FINALIZE:-}"
if [[ -z "$SQLINESDATA_ARGS_FINALIZE" ]]; then
  echo "ERROR: SQLINESDATA_ARGS_FINALIZE is empty."
  exit 1
fi

"$SQLINESDATA_BIN" $SQLINESDATA_ARGS_FINALIZE
echo "SQLines Data finalize completed."
