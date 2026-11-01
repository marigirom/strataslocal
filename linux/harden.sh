#!/bin/bash
# linux/harden.sh
# Idempotent Linux baseline hardening script.
# Safe to run multiple times — each section checks before changing.
# Covers all KodeKloud Linux sysadmin lab areas.
#
# Usage: sudo bash harden.sh
# Expected environment: Rocky Linux 9 (container or VM)

set -euo pipefail

CHANGED=0

log()    { echo "[harden] $*"; }
changed(){ log "CHANGED: $*"; CHANGED=$((CHANGED + 1)); }
skip()   { log "OK (no change): $*"; }

# ---------------------------------------------------------------------------
# 1. USERS AND GROUPS
# ---------------------------------------------------------------------------
log "--- Section 1: Users and Groups ---"

# Detect correct nologin path (Rocky 9 uses /usr/sbin/nologin)
NOLOGIN=/usr/sbin/nologin
if [ ! -x "$NOLOGIN" ]; then
    NOLOGIN=/sbin/nologin
fi
log "nologin path: $NOLOGIN"

# Helper: create group if absent
ensure_group() {
    local grp=$1
    local gid=$2
    if ! getent group "$grp" &>/dev/null; then
        groupadd --gid "$gid" "$grp"
        changed "group $grp (gid $gid) created"
    else
        skip "group $grp exists"
    fi
}

# Helper: create system/service user if absent
ensure_user() {
    local user=$1 uid=$2 grp=$3 shell=$4 comment=$5
    if ! id "$user" &>/dev/null; then
        useradd --uid "$uid" --gid "$grp" --shell "$shell" \
                --comment "$comment" --no-create-home "$user"
        changed "user $user (uid $uid) created"
    else
        skip "user $user exists"
        # Ensure shell is correct even if user pre-existed
        local current_shell
        current_shell=$(getent passwd "$user" | cut -d: -f7)
        if [ "$current_shell" != "$shell" ]; then
            usermod --shell "$shell" "$user"
            changed "user $user shell updated to $shell"
        fi
    fi
}

ensure_group sysadmin 3000
ensure_group devops    3001

ensure_user svc-backup  4001 sysadmin "$NOLOGIN" "Backup Service Account"
ensure_user svc-monitor 4002 sysadmin "$NOLOGIN" "Monitor Service Account"

# Set account expiry for svc-backup (2030-12-31)
EXPIRY=$(chage -l svc-backup 2>/dev/null | grep "Account expires" | cut -d: -f2 | xargs)
if [ "$EXPIRY" != "Dec 31, 2030" ]; then
    chage --expiredate 2030-12-31 svc-backup
    changed "svc-backup account expiry set to 2030-12-31"
else
    skip "svc-backup expiry already set"
fi

# ---------------------------------------------------------------------------
# 2. PERMISSIONS AND ACLs
# ---------------------------------------------------------------------------
log "--- Section 2: Permissions and ACLs ---"

# Target directory for permission lab
LAB_DIR=/opt/lab

if [ ! -d "$LAB_DIR" ]; then
    mkdir -p "$LAB_DIR"
    changed "$LAB_DIR created"
fi

# Create a demo script to mimic the chmod a+x lab task
LAB_SCRIPT="$LAB_DIR/deploy.sh"
if [ ! -f "$LAB_SCRIPT" ]; then
    echo '#!/bin/bash' > "$LAB_SCRIPT"
    echo 'echo "deploy script"' >> "$LAB_SCRIPT"
    changed "$LAB_SCRIPT created"
fi

# chmod a+x (idempotent: only change if not already executable by all)
PERMS=$(stat -c "%a" "$LAB_SCRIPT")
if [[ "$PERMS" != *"5" && "$PERMS" != *"7" ]]; then
    chmod a+x "$LAB_SCRIPT"
    changed "$LAB_SCRIPT set executable for all (chmod a+x)"
    echo "[harden] Result: $(stat -c '%A %n' "$LAB_SCRIPT")"
else
    skip "$LAB_SCRIPT already executable by all (perms: $PERMS)"
fi

# chown to devops group
LAB_OWNER=$(stat -c "%U:%G" "$LAB_DIR")
if [ "$LAB_OWNER" != "root:devops" ]; then
    chown -R root:devops "$LAB_DIR"
    changed "$LAB_DIR ownership set to root:devops"
else
    skip "$LAB_DIR ownership already root:devops"
fi

# chmod 2775 on dir (setgid so new files inherit group)
LAB_DPERMS=$(stat -c "%a" "$LAB_DIR")
if [ "$LAB_DPERMS" != "2775" ]; then
    chmod 2775 "$LAB_DIR"
    changed "$LAB_DIR permissions set to 2775 (setgid)"
else
    skip "$LAB_DIR permissions already 2775"
fi

# ACL: give devops group rwx on the lab dir
if ! getfacl "$LAB_DIR" 2>/dev/null | grep -q "^group:devops:rwx"; then
    setfacl -m g:devops:rwx "$LAB_DIR"
    changed "ACL g:devops:rwx set on $LAB_DIR"
else
    skip "ACL g:devops:rwx already on $LAB_DIR"
fi

# ---------------------------------------------------------------------------
# 3. SSHD HARDENING
# ---------------------------------------------------------------------------
log "--- Section 3: sshd Hardening ---"

SSHD_CONF=/etc/ssh/sshd_config
SSHD_CHANGED=0

patch_sshd() {
    local key=$1 value=$2
    # If the exact "key value" line already exists (uncommented), skip
    if grep -qE "^${key}\s+${value}$" "$SSHD_CONF"; then
        skip "sshd: $key $value already set"
        return
    fi
    # If the key exists (commented or different value), replace it
    if grep -qE "^#?\s*${key}\s+" "$SSHD_CONF"; then
        sed -i "s|^#\?\s*${key}\s.*|${key} ${value}|" "$SSHD_CONF"
    else
        echo "${key} ${value}" >> "$SSHD_CONF"
    fi
    changed "sshd: $key set to $value"
    SSHD_CHANGED=$((SSHD_CHANGED + 1))
}

patch_sshd PermitRootLogin     no
patch_sshd PasswordAuthentication no
patch_sshd PubkeyAuthentication yes
patch_sshd X11Forwarding       no

# Validate config before reloading
if ! sshd -t 2>/dev/null; then
    echo "[harden] ERROR: sshd_config validation failed — not reloading." >&2
    exit 1
fi

if [ "$SSHD_CHANGED" -gt 0 ]; then
    # In containers sshd runs as PID 1 substitute; send HUP if running
    if pgrep -x sshd &>/dev/null; then
        kill -HUP "$(pgrep -x sshd | head -1)"
        changed "sshd reloaded (HUP sent)"
    fi
fi

# ---------------------------------------------------------------------------
# 4. CRON
# ---------------------------------------------------------------------------
log "--- Section 4: Cron ---"

# cron.allow — only listed users may use cron
CRON_ALLOW=/etc/cron.allow
for cron_user in root devops; do
    if ! grep -qx "$cron_user" "$CRON_ALLOW" 2>/dev/null; then
        echo "$cron_user" >> "$CRON_ALLOW"
        changed "cron.allow: added $cron_user"
    else
        skip "cron.allow: $cron_user already present"
    fi
done

# cron.deny — block svc accounts
CRON_DENY=/etc/cron.deny
for cron_user in svc-backup svc-monitor; do
    if ! grep -qx "$cron_user" "$CRON_DENY" 2>/dev/null; then
        echo "$cron_user" >> "$CRON_DENY"
        changed "cron.deny: added $cron_user"
    else
        skip "cron.deny: $cron_user already present"
    fi
done

# Add a scheduled backup crontab entry for root
BACKUP_JOB="0 2 * * * /opt/lab/deploy.sh >> /var/log/deploy.log 2>&1"
if ! crontab -l 2>/dev/null | grep -qF "$BACKUP_JOB"; then
    (crontab -l 2>/dev/null; echo "$BACKUP_JOB") | crontab -
    changed "cron: backup job added for root"
else
    skip "cron: backup job already present"
fi

# ---------------------------------------------------------------------------
# 5. PAM LIMITS
# ---------------------------------------------------------------------------
log "--- Section 5: PAM Limits ---"

LIMITS_CONF=/etc/security/limits.conf

add_limit() {
    local line=$1
    if ! grep -qxF "$line" "$LIMITS_CONF"; then
        echo "$line" >> "$LIMITS_CONF"
        changed "limits.conf: added '$line'"
    else
        skip "limits.conf: '$line' already present"
    fi
}

add_limit "devops           soft    nofile          65536"
add_limit "devops           hard    nofile          65536"
add_limit "@sysadmin        soft    nproc           100"
add_limit "@sysadmin        hard    nproc           200"

# Verify PAM limits module is active
PAM_LIMITS=/etc/pam.d/login
if ! grep -q "pam_limits.so" "$PAM_LIMITS" 2>/dev/null; then
    log "WARNING: pam_limits.so not found in $PAM_LIMITS — limits may not apply at login."
else
    skip "PAM limits module active in $PAM_LIMITS"
fi

# ---------------------------------------------------------------------------
# 6. PACKAGES
# ---------------------------------------------------------------------------
log "--- Section 6: Package Management ---"

# NOTE on bind vs named:
# On RHEL/Rocky Linux, the DNS server daemon is named 'named' but the
# package that provides it is called 'bind'. Installing 'bind' gives you
# the 'named' binary. This is a common gotcha — 'yum install named' fails.

install_if_absent() {
    local pkg=$1
    if ! rpm -q "$pkg" &>/dev/null; then
        dnf install -y "$pkg"
        changed "package $pkg installed"
    else
        skip "package $pkg already installed"
    fi
}

install_if_absent bind
install_if_absent cronie
install_if_absent traceroute

# ---------------------------------------------------------------------------
# 7. TIMEZONE AND ARCHIVE
# ---------------------------------------------------------------------------
log "--- Section 7: Timezone and Archive ---"

TARGET_TZ="America/New_York"

# Read timezone from the localtime symlink — works in containers and VMs
# (timedatectl requires systemd as PID 1, which containers do not have)
CURRENT_TZ=$(readlink /etc/localtime 2>/dev/null | sed 's|.*/zoneinfo/||')

if [ "$CURRENT_TZ" != "$TARGET_TZ" ]; then
    ln -sf "/usr/share/zoneinfo/${TARGET_TZ}" /etc/localtime
    echo "$TARGET_TZ" > /etc/timezone
    changed "timezone set to $TARGET_TZ"
else
    skip "timezone already $TARGET_TZ"
fi

# Create a demo archive (idempotent)
ARCHIVE=/tmp/lab-archive.tar.gz
if [ ! -f "$ARCHIVE" ]; then
    tar -czf "$ARCHIVE" -C /opt lab
    changed "archive created at $ARCHIVE"
else
    skip "archive $ARCHIVE already exists"
fi

# Demonstrate extraction (into /tmp/lab-extracted)
EXTRACT_DIR=/tmp/lab-extracted
if [ ! -d "$EXTRACT_DIR" ]; then
    mkdir -p "$EXTRACT_DIR"
    tar -xzf "$ARCHIVE" -C "$EXTRACT_DIR"
    changed "archive extracted to $EXTRACT_DIR"
else
    skip "extraction dir $EXTRACT_DIR already exists"
fi

# ---------------------------------------------------------------------------
# 8. SED CONFIG EDITS
# ---------------------------------------------------------------------------
log "--- Section 8: sed Config Edits ---"

# Demonstrate sed -i on a demo config file
DEMO_CONF=/etc/lab-demo.conf
if [ ! -f "$DEMO_CONF" ]; then
    cat > "$DEMO_CONF" <<'EOF'
# Lab demo config
MAX_CONNECTIONS=10
LOG_LEVEL=warn
TIMEOUT=30
EOF
    changed "$DEMO_CONF created"
fi

# Change MAX_CONNECTIONS to 50 if not already set
if ! grep -q "^MAX_CONNECTIONS=50$" "$DEMO_CONF"; then
    sed -i 's/^MAX_CONNECTIONS=.*/MAX_CONNECTIONS=50/' "$DEMO_CONF"
    changed "$DEMO_CONF: MAX_CONNECTIONS set to 50 via sed -i"
else
    skip "$DEMO_CONF: MAX_CONNECTIONS already 50"
fi

# Change LOG_LEVEL to info
if ! grep -q "^LOG_LEVEL=info$" "$DEMO_CONF"; then
    sed -i 's/^LOG_LEVEL=.*/LOG_LEVEL=info/' "$DEMO_CONF"
    changed "$DEMO_CONF: LOG_LEVEL set to info via sed -i"
else
    skip "$DEMO_CONF: LOG_LEVEL already info"
fi

# ---------------------------------------------------------------------------
# SUMMARY
# ---------------------------------------------------------------------------
log "--- Summary ---"
if [ "$CHANGED" -eq 0 ]; then
    log "IDEMPOTENT: script ran with ZERO changes (already hardened)."
else
    log "DONE: $CHANGED change(s) applied."
fi
