#!/bin/bash
# linux/vm-only/firewall.sh
# Idempotent firewalld configuration script — VM only.
# Cannot be tested in containers (modifying nftables/iptables in an
# unprivileged container would affect the host firewall).
#
# Usage: sudo bash firewall.sh
# Requires: firewalld running (systemctl start firewalld)

set -euo pipefail

CHANGED=0
log()    { echo "[firewall] $*"; }
changed(){ log "CHANGED: $*"; CHANGED=$((CHANGED + 1)); }
skip()   { log "OK (no change): $*"; }

# ---------------------------------------------------------------------------
# Ensure firewalld is running
# ---------------------------------------------------------------------------
log "--- firewalld service ---"

if ! systemctl is-active --quiet firewalld; then
    systemctl enable --now firewalld
    changed "firewalld started and enabled"
else
    skip "firewalld already running"
fi

# ---------------------------------------------------------------------------
# Services
# ---------------------------------------------------------------------------
log "--- firewalld services ---"

add_service() {
    local svc=$1
    if firewall-cmd --query-service="$svc" --quiet 2>/dev/null; then
        skip "service $svc already allowed"
    else
        firewall-cmd --permanent --add-service="$svc"
        changed "service $svc added (permanent)"
    fi
}

add_service http
add_service https
add_service ssh

# ---------------------------------------------------------------------------
# Ports
# ---------------------------------------------------------------------------
log "--- firewalld ports ---"

add_port() {
    local port_proto=$1
    if firewall-cmd --query-port="$port_proto" --quiet 2>/dev/null; then
        skip "port $port_proto already open"
    else
        firewall-cmd --permanent --add-port="$port_proto"
        changed "port $port_proto opened (permanent)"
    fi
}

add_port 8080/tcp
add_port 2222/tcp

# ---------------------------------------------------------------------------
# Reload to apply permanent rules
# ---------------------------------------------------------------------------
if [ "$CHANGED" -gt 0 ]; then
    firewall-cmd --reload
    log "firewalld reloaded"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
log "--- Summary ---"
log "Active rules:"
firewall-cmd --list-all 2>/dev/null | sed 's/^/  /'

if [ "$CHANGED" -eq 0 ]; then
    log "IDEMPOTENT: zero firewall changes."
else
    log "DONE: $CHANGED firewall change(s) applied."
fi
