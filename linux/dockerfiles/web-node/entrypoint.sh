#!/bin/bash
set -euo pipefail

# Generate host keys if they don't exist (first boot)
ssh-keygen -A

exec /usr/sbin/sshd -D
