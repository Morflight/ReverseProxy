#!/usr/bin/env bash
# Phase 0: System deps, deploy user, Docker (runs as root)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"
validate_server

header "Phase 0 — Bootstrap (${SERVER})"

HOST="$(get_host)"
USER="$(get_user)"
DEPLOY_PATH="$(get_field deploy_path)"

echo "==> Target: root@${HOST}"
echo "==> Deploy user: ${USER}"
echo ""

REMOTE_SCRIPT=$(cat <<REMOTE
set -euo pipefail

echo "--- Updating system packages ---"
apt-get update -qq
apt-get upgrade -y -qq

echo "--- Installing base dependencies ---"
apt-get install -y -qq git curl ca-certificates gnupg make ufw

echo "--- Installing Docker CE ---"
if ! command -v docker &>/dev/null; then
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg
  echo "deb [arch=\$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \$(. /etc/os-release && echo \$VERSION_CODENAME) stable" \
    > /etc/apt/sources.list.d/docker.list
  apt-get update -qq
  apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  echo "Docker installed."
else
  echo "Docker already installed, skipping."
fi

echo "--- Creating deploy user: ${USER} ---"
if ! id "${USER}" &>/dev/null; then
  useradd -m -s /bin/bash "${USER}"
  echo "User ${USER} created."
else
  echo "User ${USER} already exists."
fi

usermod -aG docker "${USER}"
echo "${USER} added to docker group."

echo "--- Setting up SSH keys for ${USER} ---"
DEPLOY_SSH_DIR="/home/${USER}/.ssh"
mkdir -p "\$DEPLOY_SSH_DIR"
if [[ -f /root/.ssh/authorized_keys ]]; then
  cp /root/.ssh/authorized_keys "\$DEPLOY_SSH_DIR/authorized_keys"
fi
chown -R ${USER}:${USER} "\$DEPLOY_SSH_DIR"
chmod 700 "\$DEPLOY_SSH_DIR"
chmod 600 "\$DEPLOY_SSH_DIR/authorized_keys" 2>/dev/null || true

echo "--- Creating deploy directory ---"
mkdir -p "${DEPLOY_PATH}"
chown ${USER}:${USER} "${DEPLOY_PATH}"
echo "  ${DEPLOY_PATH} -> ok"

echo "--- Configuring firewall ---"
if command -v ufw &>/dev/null; then
  ufw allow 22/tcp   >/dev/null 2>&1 || true
  ufw allow 80/tcp   >/dev/null 2>&1 || true
  ufw allow 443/tcp  >/dev/null 2>&1 || true
  echo "y" | ufw enable >/dev/null 2>&1 || true
  echo "UFW configured (22, 80, 443)."
fi

echo ""
echo "==> Bootstrap complete."
REMOTE
)

ssh -o StrictHostKeyChecking=accept-new "root@${HOST}" "$REMOTE_SCRIPT"
