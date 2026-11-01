#!/usr/bin/env bats
# linux/tests/container/hardening.bats
# Verification tests for harden.sh — mimics KodeKloud grader assertions.
# Runs inside containers via: docker exec <container> bats /tests/container/hardening.bats

# ---------------------------------------------------------------------------
# 1. USERS AND GROUPS
# ---------------------------------------------------------------------------

@test "group sysadmin exists with GID 3000" {
    run getent group sysadmin
    [ "$status" -eq 0 ]
    echo "$output" | grep -q ":3000:"
}

@test "group devops exists with GID 3001" {
    run getent group devops
    [ "$status" -eq 0 ]
    echo "$output" | grep -q ":3001:"
}

@test "user svc-backup exists with UID 4001" {
    run id -u svc-backup
    [ "$status" -eq 0 ]
    [ "$output" = "4001" ]
}

@test "user svc-monitor exists with UID 4002" {
    run id -u svc-monitor
    [ "$status" -eq 0 ]
    [ "$output" = "4002" ]
}

@test "svc-backup shell is /usr/sbin/nologin" {
    run bash -c "getent passwd svc-backup | cut -d: -f7"
    [ "$status" -eq 0 ]
    # Rocky 9 uses /usr/sbin/nologin; /sbin/nologin is a symlink — accept both
    [[ "$output" == "/usr/sbin/nologin" || "$output" == "/sbin/nologin" ]]
}

@test "svc-monitor shell is /usr/sbin/nologin" {
    run bash -c "getent passwd svc-monitor | cut -d: -f7"
    [ "$status" -eq 0 ]
    [[ "$output" == "/usr/sbin/nologin" || "$output" == "/sbin/nologin" ]]
}

@test "svc-backup account expiry is set" {
    run bash -c "chage -l svc-backup | grep 'Account expires'"
    [ "$status" -eq 0 ]
    # Must not be 'never'
    ! echo "$output" | grep -qi "never"
}

# ---------------------------------------------------------------------------
# 2. PERMISSIONS AND ACLs
# ---------------------------------------------------------------------------

@test "/opt/lab directory exists" {
    [ -d /opt/lab ]
}

@test "/opt/lab/deploy.sh is executable by all" {
    run stat -c "%a" /opt/lab/deploy.sh
    [ "$status" -eq 0 ]
    # Acceptable: 755, 775, 777, 2775, etc. — last octet must include x (1 or 5 or 7)
    local perms="$output"
    local others="${perms: -1}"
    [[ "$others" == "5" || "$others" == "7" || "$others" == "1" || "$others" == "3" ]]
}

@test "/opt/lab group ownership is devops" {
    run stat -c "%G" /opt/lab
    [ "$status" -eq 0 ]
    [ "$output" = "devops" ]
}

@test "/opt/lab permissions are 2775" {
    run stat -c "%a" /opt/lab
    [ "$status" -eq 0 ]
    [ "$output" = "2775" ]
}

@test "/opt/lab has ACL entry for group devops rwx" {
    run bash -c "getfacl /opt/lab 2>/dev/null | grep 'group:devops:rwx'"
    [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# 3. SSHD HARDENING
# ---------------------------------------------------------------------------

@test "sshd_config: PermitRootLogin no" {
    run bash -c "grep -E '^PermitRootLogin\s+no' /etc/ssh/sshd_config"
    [ "$status" -eq 0 ]
}

@test "sshd_config: PasswordAuthentication no" {
    run bash -c "grep -E '^PasswordAuthentication\s+no' /etc/ssh/sshd_config"
    [ "$status" -eq 0 ]
}

@test "sshd_config: PubkeyAuthentication yes" {
    run bash -c "grep -E '^PubkeyAuthentication\s+yes' /etc/ssh/sshd_config"
    [ "$status" -eq 0 ]
}

@test "sshd_config: X11Forwarding no" {
    run bash -c "grep -E '^X11Forwarding\s+no' /etc/ssh/sshd_config"
    [ "$status" -eq 0 ]
}

@test "sshd -t config validation passes" {
    run sshd -t
    [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# 4. CRON
# ---------------------------------------------------------------------------

@test "cron.allow contains root" {
    run bash -c "grep -x root /etc/cron.allow"
    [ "$status" -eq 0 ]
}

@test "cron.allow contains devops" {
    run bash -c "grep -x devops /etc/cron.allow"
    [ "$status" -eq 0 ]
}

@test "cron.deny contains svc-backup" {
    run bash -c "grep -x svc-backup /etc/cron.deny"
    [ "$status" -eq 0 ]
}

@test "cron.deny contains svc-monitor" {
    run bash -c "grep -x svc-monitor /etc/cron.deny"
    [ "$status" -eq 0 ]
}

@test "root crontab contains backup job" {
    run bash -c "crontab -l 2>/dev/null | grep '/opt/lab/deploy.sh'"
    [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# 5. PAM LIMITS
# ---------------------------------------------------------------------------

@test "limits.conf: devops soft nofile 65536" {
    run bash -c "grep -F 'devops           soft    nofile          65536' /etc/security/limits.conf"
    [ "$status" -eq 0 ]
}

@test "limits.conf: devops hard nofile 65536" {
    run bash -c "grep -F 'devops           hard    nofile          65536' /etc/security/limits.conf"
    [ "$status" -eq 0 ]
}

@test "limits.conf: @sysadmin soft nproc 100" {
    run bash -c "grep -F '@sysadmin        soft    nproc           100' /etc/security/limits.conf"
    [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# 6. PACKAGES
# ---------------------------------------------------------------------------

@test "package bind is installed" {
    run rpm -q bind
    [ "$status" -eq 0 ]
}

@test "package cronie is installed" {
    run rpm -q cronie
    [ "$status" -eq 0 ]
}

@test "package traceroute is installed" {
    run rpm -q traceroute
    [ "$status" -eq 0 ]
}

@test "named binary is available (provided by bind package)" {
    run which named
    [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# 7. TIMEZONE
# ---------------------------------------------------------------------------

@test "timezone is set to America/New_York" {
    # timedatectl requires systemd (not available in containers); read symlink directly
    run bash -c "readlink /etc/localtime | sed 's|.*/zoneinfo/||'"
    [ "$status" -eq 0 ]
    [ "$output" = "America/New_York" ]
}

# ---------------------------------------------------------------------------
# 8. SED CONFIG EDITS
# ---------------------------------------------------------------------------

@test "/etc/lab-demo.conf exists" {
    [ -f /etc/lab-demo.conf ]
}

@test "/etc/lab-demo.conf: MAX_CONNECTIONS is 50" {
    run bash -c "grep '^MAX_CONNECTIONS=50$' /etc/lab-demo.conf"
    [ "$status" -eq 0 ]
}

@test "/etc/lab-demo.conf: LOG_LEVEL is info" {
    run bash -c "grep '^LOG_LEVEL=info$' /etc/lab-demo.conf"
    [ "$status" -eq 0 ]
}
