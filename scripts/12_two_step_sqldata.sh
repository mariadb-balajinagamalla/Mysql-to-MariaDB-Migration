#!/usr/bin/env bash
set -euo pipefail

echo "==> Two-step migration: parallel data transfer (SQLines Data)"

SQLINESDATA_BIN="${SQLINESDATA_BIN:-}"
SQLINESDATA_CMD="${SQLINESDATA_CMD:-}"
SQLINESDATA_CMD_TEMPLATE="${SQLINESDATA_CMD_TEMPLATE:-}"
SRC_DBS="${SRC_DBS:-}"

if [[ -z "$SQLINESDATA_BIN" && -z "$SQLINESDATA_CMD" ]]; then
  echo "ERROR: Provide SQLINESDATA_BIN + SQLINESDATA_ARGS or SQLINESDATA_CMD."
  echo "Example:"
  echo "  export SQLINESDATA_BIN=./sqlinesdata"
  echo "  export SQLINESDATA_ARGS='-sd=mysql,user/pass@src:3306/db -td=mysql,user/pass@tgt:3306/db -smap=db:db -ss=6 -t=db.* -constraints=no -indexes=no -triggers=no -views=no -procedures=no'"
  exit 1
fi

if [[ -n "$SRC_DBS" ]]; then
  if [[ -z "$SQLINESDATA_CMD_TEMPLATE" ]]; then
    echo "ERROR: SRC_DBS set but SQLINESDATA_CMD_TEMPLATE is empty."
    exit 1
  fi
  IFS=',' read -r -a DB_LIST <<< "$SRC_DBS"
  for db in "${DB_LIST[@]}"; do
    db="${db// /}"
    if [[ -z "$db" ]]; then
      continue
    fi
    cmd="${SQLINESDATA_CMD_TEMPLATE//\{DB\}/$db}"
    bash -c "$cmd"
  done
  echo "SQLines Data transfer completed."
  exit 0
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
