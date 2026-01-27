#!/usr/bin/env bash
set -euo pipefail

echo "==> Near-zero migration: CDC stream (Debezium)"

NEAR_ZERO_CDC_CMD="${NEAR_ZERO_CDC_CMD:-}"

if [[ -z "$NEAR_ZERO_CDC_CMD" ]]; then
  echo "ERROR: NEAR_ZERO_CDC_CMD not set."
  echo "Provide a full command to start Debezium CDC streaming."
  exit 2
fi

bash -c "$NEAR_ZERO_CDC_CMD"
echo "CDC stream started."
