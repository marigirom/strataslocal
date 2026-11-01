# Runbook: sshd Won't Restart

**Severity:** Medium  
**Component:** OpenSSH server (`sshd`)  
**Environments:** Rocky Linux 9 — containers and VMs  
**Phase:** 1 (Linux Baseline as Code)

---

## Symptom

After editing `/etc/ssh/sshd_config`, the service fails to restart or reload:

```
Job for sshd.service failed. See 'journalctl -xe' for details.
```

Or, in a container without systemd:

```
System has not been booted with systemd as init system (PID 1). Can't operate.
Failed to connect to bus: Host is down
```

---

## Root Causes

### Cause 1 — Config syntax error

The most common cause. A typo in `sshd_config` causes `sshd` to refuse to
start entirely, locking you out of the system.

**Diagnosis:**

```bash
sshd -t
```

`sshd -t` does a full config test without starting a daemon. Any error is
printed to stderr with the exact line number.

**Fix:** Correct the error `sshd -t` reports, then restart.

> **Lab gotcha from harden.sh:** `harden.sh` always runs `sshd -t` before
> attempting a reload. If validation fails, the script exits with an error
> rather than restarting a broken daemon. This is the safe pattern.

---

### Cause 2 — Wrong nologin path in `sshd_config`

On Rocky Linux 9, the correct path is `/usr/sbin/nologin`.  
On older RHEL/CentOS systems, it was `/sbin/nologin`.

If a config line references the wrong path, users get locked out but sshd
itself may still start. Check:

```bash
ls -la /sbin/nologin /usr/sbin/nologin
# On Rocky 9: /sbin/nologin -> ../usr/sbin/nologin (symlink)
```

---

### Cause 3 — Trying to use systemctl in a container

Containers do not run systemd as PID 1.

```bash
# This will fail in a container:
systemctl restart sshd   # → "Failed to connect to bus: Host is down"

# Use this instead — send HUP to the running sshd process:
kill -HUP $(pgrep -x sshd | head -1)

# Or, if sshd is PID 1 (entrypoint), restart the container:
docker restart <container-name>
```

---

### Cause 4 — Host key files missing

If `ssh-keygen -A` was never run, host key files in `/etc/ssh/` are absent
and sshd refuses to start.

```bash
# Regenerate all host keys:
ssh-keygen -A
# Then restart sshd
```

The `entrypoint.sh` in this project runs `ssh-keygen -A` automatically on
container start.

---

## Prevention Checklist

Before restarting sshd after any config change:

```bash
# 1. Test config syntax
sshd -t && echo "Config OK"

# 2. Verify host keys exist
ls /etc/ssh/ssh_host_*_key 2>/dev/null || echo "WARNING: host keys missing"

# 3. Keep a second SSH session open while restarting (on a real server)
#    so you can recover if the restart fails
```

---

## Recovery (if locked out of a real VM)

1. Access the console directly (VirtualBox/libvirt VM console, not SSH).
2. Log in as root.
3. Run `sshd -t` to find the config error.
4. Fix the error in `/etc/ssh/sshd_config`.
5. `systemctl restart sshd`.
6. Test SSH access from another terminal before closing the console.

---

## Related

- [`linux/harden.sh`](../../linux/harden.sh) — Section 3: sshd Hardening
- [`linux/tests/container/hardening.bats`](../../linux/tests/container/hardening.bats) — tests 13–17
- [ADR 001](../adr/001-container-vs-vm-for-selinux.md) — container vs VM limitations
