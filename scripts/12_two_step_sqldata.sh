#!/usr/bin/env bash
set -euo pipefail

echo "==> Two-step migration: parallel data transfer (SQLines Data)"

SQLINESDATA_BIN="${SQLINESDATA_BIN:-}"
SQLINESDATA_CMD="${SQLINESDATA_CMD:-}"

if [[ -z "$SQLINESDATA_BIN" && -z "$SQLINESDATA_CMD" ]]; then
  echo "ERROR: Provide SQLINESDATA_BIN + SQLINESDATA_ARGS or SQLINESDATA_CMD."
  echo "Example:"
  echo "  export SQLINESDATA_BIN=./sqlinesdata"
  echo "  export SQLINESDATA_ARGS='-sd=mysql,user/pass@src:3306/db -td=mysql,user/pass@tgt:3306/db -smap=db:db -ss=6 -t=db.* -constraints=no -indexes=no -triggers=no -views=no -procedures=no'"
  exit 1
fi

if [[ -n "$SQLINESDATA_CMD" ]]; then
  bash -c "$SQLINESDATA_CMD"
  echo "SQLines Data transfer completed."
  exit 0
fi

SQLINESDATA_ARGS="${SQLINESDATA_ARGS:-}"
if [[ -z "$SQLINESDATA_ARGS" ]]; then
  echo "ERROR: SQLINESDATA_ARGS is empty."
  exit 1
fi

"$SQLINESDATA_BIN" $SQLINESDATA_ARGS
echo "SQLines Data transfer completed."
