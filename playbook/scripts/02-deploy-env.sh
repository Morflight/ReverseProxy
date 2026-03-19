#!/usr/bin/env bash
# Phase 2: Decrypt SOPS locally → SCP .env file to server
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"
validate_server

header "Phase 2 — Deploy env (${SERVER})"

if ! command -v sops &>/dev/null; then
  echo "ERROR: sops is not installed locally." >&2
  echo "Install it: https://github.com/getsops/sops" >&2
  exit 1
fi

DEPLOY_PATH="$(get_field deploy_path)"
ENV_DEST="$(get_field env_dest)"
ENC_FILE="$(get_field enc_file)"

# Resolve enc_file relative to project root
LOCAL_ENC="${PROJECT_DIR}/${ENC_FILE}"
if [[ ! -f "$LOCAL_ENC" ]]; then
  echo "ERROR: Encrypted file not found: ${LOCAL_ENC}" >&2
  exit 1
fi

echo "==> enc_file: ${LOCAL_ENC}"
echo "==> dest: ${DEPLOY_PATH}/${ENV_DEST}"

# Decrypt and convert app section to KEY=VALUE .env format
TMP_ENV=$(mktemp)
trap "rm -f '$TMP_ENV'" EXIT

sops -d --output-type json "$LOCAL_ENC" \
  | jq -r '.app | to_entries | .[] | .key + "=" + .value' \
  > "$TMP_ENV"

LINE_COUNT=$(wc -l < "$TMP_ENV")
echo "==> Extracted: ${LINE_COUNT} env vars"

# SCP to server
scp_to_deploy "$TMP_ENV" "${DEPLOY_PATH}/${ENV_DEST}"
rm -f "$TMP_ENV"
trap - EXIT

echo "==> Deploy env complete."
