#!/usr/bin/env bash
set -euo pipefail

echo "==> Two-step migration: finalize objects (constraints/indexes/routines)"

SQLINESDATA_BIN="${SQLINESDATA_BIN:-}"
SQLINESDATA_CMD_FINALIZE="${SQLINESDATA_CMD_FINALIZE:-}"

if [[ -z "$SQLINESDATA_BIN" && -z "$SQLINESDATA_CMD_FINALIZE" ]]; then
  echo "ERROR: Provide SQLINESDATA_BIN + SQLINESDATA_ARGS_FINALIZE or SQLINESDATA_CMD_FINALIZE."
  exit 1
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
