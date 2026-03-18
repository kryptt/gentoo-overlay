#!/bin/bash

# Sync Gentoo repo (quiet, non-blocking)
emerge --sync --quiet 2>/dev/null || true

# Set up SSH authorized keys for coworker access
mkdir -p ~/.ssh
cp /var/db/repos/rhansen-overlay/.devcontainer/AUTHORIZED_COWORKERS ~/.ssh/authorized_keys
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys

# Generate host keys if missing and start sshd on port 2222
ssh-keygen -A 2>/dev/null
/usr/sbin/sshd -p 2222 -o PermitRootLogin=yes -o PasswordAuthentication=no

# Display SSH connect string for Tailscale coworkers
HOST_IP=$(cat /var/db/repos/rhansen-overlay/.devcontainer/.host-ip 2>/dev/null | tr -d '[:space:]')
CONTAINER_ID=$(hostname)

echo ""
echo "Coworkers on Tailscale can connect with:"
echo "  ssh -p \$(docker port ${CONTAINER_ID} 2222 | grep -oP '\\d+\$') root@${HOST_IP:-\$(hostname -f)}"
echo ""
