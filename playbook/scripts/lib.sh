#!/usr/bin/env bash
# Shared helpers for playbook scripts
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLAYBOOK_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_DIR="$(cd "$PLAYBOOK_DIR/.." && pwd)"
YQ="$PLAYBOOK_DIR/.bin/yq"
SERVERS_FILE="$PLAYBOOK_DIR/servers.yaml"

# ── yq bootstrap ──────────────────────────────────────────────────
ensure_yq() {
  if [[ -x "$YQ" ]]; then
    return
  fi
  echo "==> Downloading yq to playbook/.bin/yq ..."
  mkdir -p "$PLAYBOOK_DIR/.bin"
  local arch
  arch="$(uname -m)"
  case "$arch" in
    x86_64)  arch="amd64" ;;
    aarch64) arch="arm64" ;;
  esac
  curl -sSL "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_${arch}" \
    -o "$YQ"
  chmod +x "$YQ"
  echo "==> yq installed."
}

# ── YAML helpers ──────────────────────────────────────────────────
yq_read() {
  ensure_yq
  "$YQ" eval "$1" "$SERVERS_FILE"
}

# ── Server helpers ────────────────────────────────────────────────
get_host() {
  yq_read ".servers.${SERVER}.host"
}

get_user() {
  yq_read ".servers.${SERVER}.user"
}

get_field() {
  local field="$1"
  yq_read ".servers.${SERVER}.${field}"
}

get_init_command_count() {
  yq_read ".servers.${SERVER}.init_commands | length"
}

get_init_command() {
  local index="$1"
  yq_read ".servers.${SERVER}.init_commands[${index}]"
}

# ── SSH helpers ───────────────────────────────────────────────────
ssh_as_root() {
  local host
  host="$(get_host)"
  ssh -o StrictHostKeyChecking=accept-new "root@${host}" "$@"
}

ssh_as_deploy() {
  local host user
  host="$(get_host)"
  user="$(get_user)"
  ssh -o StrictHostKeyChecking=accept-new "${user}@${host}" "$@"
}

scp_to_deploy() {
  local src="$1" dest="$2"
  local host user
  host="$(get_host)"
  user="$(get_user)"
  scp -o StrictHostKeyChecking=accept-new "$src" "${user}@${host}:${dest}"
}

# ── Validation ────────────────────────────────────────────────────
validate_server() {
  if [[ -z "${SERVER:-}" ]]; then
    echo "ERROR: SERVER is not set. Usage: make <target> SERVER=dedibox-1" >&2
    exit 1
  fi
  local host
  host="$(yq_read ".servers.${SERVER}.host")"
  if [[ "$host" == "null" ]]; then
    echo "ERROR: Server '${SERVER}' not found in servers.yaml" >&2
    exit 1
  fi
}

# ── Display ───────────────────────────────────────────────────────
header() {
  echo ""
  echo "══════════════════════════════════════════════════════════"
  echo "  $1"
  echo "══════════════════════════════════════════════════════════"
  echo ""
}
