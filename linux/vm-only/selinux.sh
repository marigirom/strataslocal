#!/bin/bash
# linux/vm-only/selinux.sh
# Idempotent SELinux configuration script — VM only.
# Cannot be tested in containers (they share the host kernel and cannot
# change or verify kernel SELinux enforcement mode).
#
# Usage: sudo bash selinux.sh
# Requires: policycoreutils-python-utils (provides semanage)

set -euo pipefail

CHANGED=0
log()    { echo "[selinux] $*"; }
changed(){ log "CHANGED: $*"; CHANGED=$((CHANGED + 1)); }
skip()   { log "OK (no change): $*"; }

# ---------------------------------------------------------------------------
# 1. Verify SELinux is Enforcing
# ---------------------------------------------------------------------------
log "--- SELinux Enforcement ---"

CURRENT_MODE=$(getenforce 2>/dev/null || echo "Disabled")
if [ "$CURRENT_MODE" = "Enforcing" ]; then
    skip "SELinux already Enforcing"
else
    log "WARNING: SELinux is '$CURRENT_MODE'. Setting to Enforcing..."
    setenforce 1
    # Make permanent across reboots
    sed -i 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config
    changed "SELinux set to Enforcing"
fi

# ---------------------------------------------------------------------------
# 2. Boolean: allow httpd to make network connections
# ---------------------------------------------------------------------------
log "--- SELinux Booleans ---"

HTTPD_NET=$(getsebool httpd_can_network_connect 2>/dev/null | awk '{print $3}')
if [ "$HTTPD_NET" = "on" ]; then
    skip "httpd_can_network_connect already on"
else
    setsebool -P httpd_can_network_connect on
    changed "httpd_can_network_connect set to on (persistent)"
fi

# ---------------------------------------------------------------------------
# 3. Custom port label: ssh_port_t on TCP 2222
# ---------------------------------------------------------------------------
log "--- SELinux Port Labels ---"

if semanage port -l | grep -q "^ssh_port_t.*tcp.*2222"; then
    skip "port 2222 already labelled ssh_port_t"
else
    semanage port -a -t ssh_port_t -p tcp 2222
    changed "port 2222 labelled as ssh_port_t"
fi

# ---------------------------------------------------------------------------
# 4. Restore default file contexts
# ---------------------------------------------------------------------------
log "--- SELinux File Contexts ---"

# Restore contexts on ssh host keys and config (safe to run multiple times)
restorecon -Rv /etc/ssh/ 2>/dev/null | grep -v "^$" | while read -r line; do
    changed "restorecon: $line"
done || true

# Restore /opt/lab if it exists (harden.sh creates it)
if [ -d /opt/lab ]; then
    restorecon -Rv /opt/lab/ 2>/dev/null | grep -v "^$" | while read -r line; do
        changed "restorecon: $line"
    done || true
    skip "restorecon applied to /opt/lab/"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
log "--- Summary ---"
if [ "$CHANGED" -eq 0 ]; then
    log "IDEMPOTENT: zero SELinux changes."
else
    log "DONE: $CHANGED SELinux change(s) applied."
fi
