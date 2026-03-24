#!/bin/bash

# Set up SSH authorized keys for coworker access
mkdir -p ~/.ssh
cp /var/db/repos/rhansen-overlay/.devcontainer/AUTHORIZED_COWORKERS ~/.ssh/authorized_keys
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys

# Generate host keys if missing and start sshd on port 2222
ssh-keygen -A 2>/dev/null
/usr/sbin/sshd -p 2222 -o PermitRootLogin=yes -o PasswordAuthentication=no
