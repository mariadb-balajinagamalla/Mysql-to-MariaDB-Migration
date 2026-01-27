#!/usr/bin/env bash
set -euo pipefail

echo "==> Near-zero migration: cutover"

NEAR_ZERO_CUTOVER_CMD="${NEAR_ZERO_CUTOVER_CMD:-}"

if [[ -z "$NEAR_ZERO_CUTOVER_CMD" ]]; then
  echo "ERROR: NEAR_ZERO_CUTOVER_CMD not set."
  echo "Provide a full command to perform cutover and final validation."
  exit 2
fi

bash -c "$NEAR_ZERO_CUTOVER_CMD"
echo "Cutover completed."
