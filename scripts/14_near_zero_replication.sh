#!/usr/bin/env bash
set -euo pipefail

echo "==> Near-zero migration: replication setup"

NEAR_ZERO_REPLICATION_CMD="${NEAR_ZERO_REPLICATION_CMD:-}"

if [[ -z "$NEAR_ZERO_REPLICATION_CMD" ]]; then
  echo "ERROR: NEAR_ZERO_REPLICATION_CMD not set."
  echo "Provide a full command to configure MariaDB as a replica of MySQL."
  exit 2
fi

bash -c "$NEAR_ZERO_REPLICATION_CMD"
echo "Replication setup completed."
