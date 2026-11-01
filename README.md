# StratasLocal

> [Branch A edit] A comprehensive, phase-by-phase lab that builds a production-grade local
> stack — from Linux baseline through Docker, Kubernetes, CI/CD, GitOps, and
> Observability — on a single developer workstation.

---

## Architecture

The stack is built in layers, each phase producing independently verifiable
artefacts before the next begins:

```
Phase 0  →  Git Foundation
Phase 1  →  Linux Baseline as Code (scripts + containers + VM)
Phase 2  →  Docker (containerised workloads)
Phase 3  →  Kubernetes on minikube
Phase 4  →  CI/CD Pipeline (GitHub Actions / local runner)
Phase 5  →  Packaging and GitOps (Helm, ArgoCD)
Phase 6  →  Observability (Prometheus, Grafana, Loki)
Phase 7  →  IaC, Docs and Runbooks (Terraform, MkDocs)
```

**Phase 1 container topology:**

```
bastion  ──[front network]──  web-node01
                           ├─ web-node02
                           └─ web-node03
                                  │
                           [back network]
                                  │
                            data-node01 (+ MariaDB)
```

---

## Quickstart

### Prerequisites

- Linux host (Fedora/RHEL-family recommended)
- `git`, `make`, `docker`, `docker compose`
- Python 3 + `pip` (for `pre-commit`)
- `bats-core` is bundled as a git submodule — no separate install needed

### Phase 1 — Linux Baseline

```bash
# Clone (with submodules)
git clone --recurse-submodules <repo-url> strataslocal
cd strataslocal

# Build images and start all containers
make up

# Apply the hardening baseline to all nodes
make harden

# Run the full bats test suite (33 tests × 3 nodes)
make test-linux

# Verify idempotency — second run must produce zero changes
make idempotent

# Stop containers (data volume is preserved)
make down
```

---

## Phases — Table of Contents

| Phase | Sub-Task | Status |
|-------|----------|--------|
| 0 | [Git Foundation](docs/git-practice.md) | ✅ complete |
| 1 | Linux Baseline as Code | ✅ complete (containers) / 🔲 VM pending |
| 2 | Docker | 🔲 pending |
| 3 | Kubernetes on minikube | 🔲 pending |
| 4 | CI/CD Pipeline | 🔲 pending |
| 5 | Packaging and GitOps | 🔲 pending |
| 6 | Observability | 🔲 pending |
| 7 | IaC, Docs and Runbooks | 🔲 pending |

---

## Limitations

- **SELinux and firewalld** configuration is intentionally VM-only. These
  subsystems require a full Linux kernel with the relevant security modules
  loaded. They cannot be exercised inside a rootless container or on macOS/
  Windows hosts without a dedicated VM (Vagrant + VirtualBox/KVM recommended).
- The local Kubernetes cluster (`minikube`) is a single-node development
  cluster only — not a production-grade multi-node setup.
- All cloud-provider integrations are stubbed; this lab runs entirely offline.

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for branch strategy, commit format,
and the PR checklist.

## License

[MIT](LICENSE) — see the file for full terms.
The MIT licence was chosen for maximum permissiveness; contributors retain
copyright on their patches.
