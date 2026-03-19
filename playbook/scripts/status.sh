#!/usr/bin/env bash
# Health check: show running containers on the server
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"
validate_server

header "Status — ${SERVER}"

HOST="$(get_host)"
USER="$(get_user)"

echo "==> ${USER}@${HOST}"
echo ""

ssh_as_deploy "docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"
