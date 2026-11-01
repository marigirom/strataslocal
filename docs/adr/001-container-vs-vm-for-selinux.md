# ADR 001 — Container vs VM for SELinux and firewalld

**Status:** Accepted  
**Date:** 2026-11-01  
**Phase:** 1 (Linux Baseline as Code)

---

## Context

Phase 1 turns every KodeKloud Linux sysadmin lab skill into a repeatable,
idempotent, testable script. The primary test environment is Docker containers
(Rocky Linux 9), because they are fast to spin up, require no hypervisor, and
work on any machine with Docker installed.

Two controls from the KodeKloud labs **cannot** be tested inside containers:

| Control | Reason containers cannot test it |
|---|---|
| **SELinux enforcement** | Containers share the host kernel. SELinux enforcement mode is a kernel-level setting. A container cannot change or verify the host kernel's SELinux mode; `getenforce` inside a container reflects the host. |
| **firewalld** | `firewalld` relies on `nftables`/`iptables` kernel hooks. Running it in an unprivileged container is unsupported and dangerous (it would modify the host's firewall). |

This is an honest limitation that must be documented rather than papered over
with workarounds (e.g. privileged containers running systemd — the guide
explicitly warns against this).

---

## Decision

1. **All controls except SELinux and firewalld** are covered in Docker containers
   (`web-node01`, `web-node02`, `web-node03`, `data-node01`) using
   `linux/harden.sh` and verified with `make test-linux`.

2. **SELinux and firewalld** are covered in a separate Rocky Linux 9 VM
   provisioned with Vagrant. The same `harden.sh` runs in the VM, plus
   `linux/vm-only/selinux.sh` and `linux/vm-only/firewall.sh`. Verified with
   `make test-linux-vm`.

---

## VM Provider Choice

Two options were evaluated:

| Option | Pros | Cons |
|---|---|---|
| **Vagrant + VirtualBox** | Easiest setup; `vagrant up` is one command; wide community support | Conflicts with KVM — cannot run if KVM modules are loaded |
| **Vagrant + libvirt** | Linux-native; works alongside KVM; lighter on memory | Requires `libvirt-daemon-system` + `vagrant-libvirt` plugin install |

**Chosen:** Vagrant + **libvirt** — confirmed by `lsmod | grep kvm` showing
`kvm_intel` loaded. VirtualBox cannot coexist with KVM on this machine.
The `Vagrantfile` is written for libvirt (`config.vm.provider "libvirt"`).

> **Provider used on this machine:** libvirt (KVM/kvm_intel detected)

---

## Coverage Table

| Control | Container (`make test-linux`) | VM (`make test-linux-vm`) |
|---|---|---|
| Users, groups, UIDs | ✅ | ✅ |
| Permissions and ACLs | ✅ | ✅ |
| sshd hardening | ✅ | ✅ |
| Cron | ✅ | ✅ |
| PAM limits | ✅ | ✅ |
| Packages | ✅ | ✅ |
| Timezone, archive, sed | ✅ | ✅ |
| **SELinux enforcement** | ❌ (host kernel only) | ✅ |
| **firewalld rules** | ❌ (host firewall risk) | ✅ |

---

## Consequences

- `make test-linux` is fast (<30 s), runs in CI, covers 33 assertions.
- `make test-linux-vm` is slow (~3 min), runs locally only, adds SELinux and
  firewalld coverage.
- GitHub Actions cannot run nested VMs; VM test evidence is captured as a
  saved output file (`docs/evidence/phase1-vm-test-output.txt`).
- The VM adds ~2 GB RAM usage; run `vagrant halt` before starting minikube
  (Phase 3) if memory is constrained.
