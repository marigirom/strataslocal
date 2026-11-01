#!/usr/bin/env bats
# linux/tests/vm/selinux-firewall.bats
# VM-only bats tests for SELinux and firewalld.
# Run via: sudo bats /vagrant/tests/vm/selinux-firewall.bats
# Or via:  make test-linux-vm  (vagrant ssh + bats)

# ---------------------------------------------------------------------------
# SELinux
# ---------------------------------------------------------------------------

@test "SELinux is Enforcing" {
    run getenforce
    [ "$status" -eq 0 ]
    [ "$output" = "Enforcing" ]
}

@test "SELinux config file set to enforcing (survives reboot)" {
    run bash -c "grep '^SELINUX=enforcing' /etc/selinux/config"
    [ "$status" -eq 0 ]
}

@test "httpd_can_network_connect boolean is on" {
    run bash -c "getsebool httpd_can_network_connect | awk '{print \$3}'"
    [ "$status" -eq 0 ]
    [ "$output" = "on" ]
}

@test "port 2222 is labelled ssh_port_t" {
    run bash -c "semanage port -l | grep 'ssh_port_t' | grep -w '2222'"
    [ "$status" -eq 0 ]
}

@test "/etc/ssh has correct SELinux context (etc_t or sshd_key_t)" {
    run bash -c "ls -Zd /etc/ssh | awk '{print \$1}'"
    [ "$status" -eq 0 ]
    # Accept system_u:object_r:etc_t or sshd_config_t
    [[ "$output" == *"etc_t"* || "$output" == *"sshd"* ]]
}

@test "no recent AVC denials in audit log" {
    # ausearch returns exit 1 when no matches found — that is the passing case
    run bash -c "ausearch -m avc -ts recent 2>&1"
    # Either no events (exit 1 = pass) or events exist (exit 0 = investigate)
    if [ "$status" -eq 0 ]; then
        # There are AVC events — fail the test and show them
        echo "AVC denials found:"
        echo "$output"
        false
    fi
    # exit 1 from ausearch = "<no matches>" = clean
    true
}

# ---------------------------------------------------------------------------
# firewalld
# ---------------------------------------------------------------------------

@test "firewalld service is active" {
    run systemctl is-active firewalld
    [ "$status" -eq 0 ]
    [ "$output" = "active" ]
}

@test "firewalld: http service is allowed" {
    run firewall-cmd --query-service=http
    [ "$status" -eq 0 ]
    [ "$output" = "yes" ]
}

@test "firewalld: https service is allowed" {
    run firewall-cmd --query-service=https
    [ "$status" -eq 0 ]
    [ "$output" = "yes" ]
}

@test "firewalld: ssh service is allowed" {
    run firewall-cmd --query-service=ssh
    [ "$status" -eq 0 ]
    [ "$output" = "yes" ]
}

@test "firewalld: port 8080/tcp is open" {
    run firewall-cmd --query-port=8080/tcp
    [ "$status" -eq 0 ]
    [ "$output" = "yes" ]
}

@test "firewalld: port 2222/tcp is open" {
    run firewall-cmd --query-port=2222/tcp
    [ "$status" -eq 0 ]
    [ "$output" = "yes" ]
}

@test "firewall-cmd --list-all output contains http" {
    run firewall-cmd --list-all
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "http"
}

@test "firewall-cmd --list-all output contains 8080/tcp" {
    run firewall-cmd --list-all
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "8080/tcp"
}
