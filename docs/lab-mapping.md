# Lab Mapping

Maps KodeKloud Linux sysadmin lab exercises to the StratasLocal implementation.
Each row shows the lab skill, where it lives in this repo, and how it is verified.

---

## Phase 1 — Linux Baseline as Code

| KodeKloud Lab Skill | Implementation | Test / Verification |
|---|---|---|
| **Users and groups** — create groups, users with explicit UIDs | [`linux/harden.sh`](../linux/harden.sh) §1 | `hardening.bats` tests 1–7 |
| **Custom shells** — `/usr/sbin/nologin` vs `/sbin/nologin` gotcha | [`linux/harden.sh`](../linux/harden.sh) §1 | `hardening.bats` tests 5–6 |
| **Account expiry** — `chage --expiredate` | [`linux/harden.sh`](../linux/harden.sh) §1 | `hardening.bats` test 7 |
| **Permissions** — `chmod`, `chown`, setgid directory | [`linux/harden.sh`](../linux/harden.sh) §2 | `hardening.bats` tests 8–11 |
| **ACLs** — `setfacl`/`getfacl`, `chmod a+x` lab task | [`linux/harden.sh`](../linux/harden.sh) §2 | `hardening.bats` test 12 |
| **sshd hardening** — `PermitRootLogin no`, key-only auth, `sshd -t` | [`linux/harden.sh`](../linux/harden.sh) §3 | `hardening.bats` tests 13–17 |
| **Cron** — `cron.allow`/`cron.deny`, scheduled backup entry | [`linux/harden.sh`](../linux/harden.sh) §4 | `hardening.bats` tests 18–22 |
| **PAM limits** — `limits.conf`, PAM module verification | [`linux/harden.sh`](../linux/harden.sh) §5 | `hardening.bats` tests 23–25 |
| **Package management** — `bind`/`named` gotcha, `cronie`, `traceroute` | [`linux/harden.sh`](../linux/harden.sh) §6 | `hardening.bats` tests 26–29 |
| **Timezone** — `ln -sf /usr/share/zoneinfo/...` (no systemd needed) | [`linux/harden.sh`](../linux/harden.sh) §7 | `hardening.bats` test 30 |
| **Archive** — `tar -czf` create, `tar -xzf` extract | [`linux/harden.sh`](../linux/harden.sh) §7 | manual / idempotency run |
| **sed config edits** — `sed -i` on a config file | [`linux/harden.sh`](../linux/harden.sh) §8 | `hardening.bats` tests 31–33 |
| **SELinux** — `getenforce`, `setsebool -P`, `semanage port`, `restorecon` | [`linux/vm-only/selinux.sh`](../linux/vm-only/selinux.sh) | `selinux-firewall.bats` tests 1–6 (VM only) |
| **firewalld** — `firewall-cmd`, services, ports, reload | [`linux/vm-only/firewall.sh`](../linux/vm-only/firewall.sh) | `selinux-firewall.bats` tests 7–13 (VM only) |

### Test Commands

| Command | Scope | CI-safe |
|---|---|---|
| `make test-linux` | All container controls (33 tests × 3 nodes) | ✅ Yes |
| `make idempotent` | Second-run zero-change verification | ✅ Yes |
| `make test-linux-vm` | SELinux + firewalld (VM only) | ❌ Local only |

### Environment Coverage

| Control | Container | VM |
|---|---|---|
| Users, groups, UIDs | ✅ | ✅ |
| Permissions and ACLs | ✅ | ✅ |
| sshd hardening | ✅ | ✅ |
| Cron | ✅ | ✅ |
| PAM limits | ✅ | ✅ |
| Packages | ✅ | ✅ |
| Timezone, archive, sed | ✅ | ✅ |
| SELinux enforcement | ❌ host kernel | ✅ |
| firewalld rules | ❌ host firewall | ✅ |

### Evidence

- Container tests: [`docs/evidence/phase1-test-output.txt`](evidence/phase1-test-output.txt)
- VM tests: [`docs/evidence/phase1-vm-test-output.txt`](evidence/phase1-vm-test-output.txt) _(added after VM run)_

---

## Phase 0 — Git Foundation

| Practice | Implementation | Evidence |
|---|---|---|
| git init, branching, squash-merge | Repo history | `git log --oneline` |
| Conventional Commits | `commit-msg` hook | `.git/hooks/commit-msg` |
| pre-commit hooks | `.pre-commit-config.yaml` | Hook output on each commit |
| Deliberate git operations | `docs/git-practice.md` | Recorded step by step |
