#!/usr/bin/env bash
# Phase 1: Clone this project's repo (runs as deploy user)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"
validate_server

header "Phase 1 — Clone repo (${SERVER})"

HOST="$(get_host)"
USER="$(get_user)"
REPO="$(get_field repo)"
DEPLOY_PATH="$(get_field deploy_path)"

echo "==> Target: ${USER}@${HOST}"
echo "==> Repo: ${REPO}"
echo "==> Path: ${DEPLOY_PATH}"
echo ""

# Ensure deploy key exists on server
echo "--- Checking SSH deploy key on server ---"
KEY_EXISTS=$(ssh_as_deploy "test -f ~/.ssh/id_ed25519 && echo yes || echo no")

if [[ "$KEY_EXISTS" == "no" ]]; then
  echo "Generating SSH deploy key on server..."
  ssh_as_deploy 'ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N "" -q'
fi

PUBKEY=$(ssh_as_deploy "cat ~/.ssh/id_ed25519.pub")
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  Deploy key (add as deploy key on this GitHub repo):       ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "  $PUBKEY"
echo ""

# Configure SSH to accept GitHub host key
ssh_as_deploy 'grep -q "github.com" ~/.ssh/known_hosts 2>/dev/null || ssh-keyscan -t ed25519 github.com >> ~/.ssh/known_hosts 2>/dev/null'

# Clone or pull
echo "--- Cloning/pulling ---"
CLONE_RESULT=$(ssh_as_deploy "
  if [ -d '${DEPLOY_PATH}/.git' ]; then
    cd '${DEPLOY_PATH}' && git pull && echo 'PULLED'
  else
    git clone '${REPO}' '${DEPLOY_PATH}' && echo 'CLONED'
  fi
")
echo "  result: ${CLONE_RESULT}"
echo ""
echo "==> Clone phase complete."
