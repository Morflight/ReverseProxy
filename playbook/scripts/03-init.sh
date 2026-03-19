#!/usr/bin/env bash
# Phase 3: Run init commands on the server
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"
validate_server

header "Phase 3 — Init project (${SERVER})"

HOST="$(get_host)"
USER="$(get_user)"
DEPLOY_PATH="$(get_field deploy_path)"
CMD_COUNT="$(get_init_command_count)"

echo "==> Target: ${USER}@${HOST}"
echo "==> Path: ${DEPLOY_PATH}"
echo "==> Commands: ${CMD_COUNT}"
echo ""

for i in $(seq 0 $((CMD_COUNT - 1))); do
  cmd="$(get_init_command "$i")"
  echo "  > ${cmd}"
  ssh_as_deploy "cd '${DEPLOY_PATH}' && ${cmd}"
done

echo ""
echo "==> Init complete."
