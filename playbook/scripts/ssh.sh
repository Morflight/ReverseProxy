#!/usr/bin/env bash
# Interactive SSH as deploy user
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"
validate_server

HOST="$(get_host)"
USER="$(get_user)"

echo "==> Connecting to ${USER}@${HOST} ..."
exec ssh -t "${USER}@${HOST}"
