# StratasLocal Implementation Plan

## Overview

Build all phases (0–7) of the **StratasLocal** portfolio project, following the guide
`StratosLocal Portfolio Project Guide (Docker, minikube, Linux, Git).md` strictly.

**Phase 8 (AWS)** is intentionally deferred — seams are designed in earlier phases
but no AWS access is needed until later.

**Implementation approach:**
- One phase at a time on its own feature branch.
- Tag at the end of each phase (`v0.1.0-phase0`, `v0.2.0-phase1`, …).
- Phase 0 and Phase 1 are the primary hands-on targets and carry full step-by-step detail.
- Phases 2–7 carry high-level roadmap entries that will be expanded before implementation.

**Starting state:** Clean workspace — no git repo, no folders, no files beyond the guide documents.

---

## Target Repository Structure (end state after all phases)

```
strataslocal/
├── .git/
├── .gitignore
├── .pre-commit-config.yaml
├── .github/
│   ├── pull_request_template.md
│   └── workflows/
│       ├── ci.yml
│       └── release.yml
├── CHANGELOG.md
├── CONTRIBUTING.md
├── LICENSE
├── Makefile
├── README.md
├── app/                          # Django app + Dockerfile (Phase 2)
├── charts/strataslocal/          # Helm chart (Phase 5)
├── ci/                           # Workflow helpers, hooks
├── compose/                      # docker-compose.yml (Phase 2)
├── docs/
│   ├── architecture.md
│   ├── adr/
│   │   ├── 001-container-vs-vm-for-selinux.md
│   │   ├── 002-mariadb-datadir.md
│   │   ├── 003-compose-vs-k8s.md
│   │   ├── 004-kustomize-vs-helm.md
│   │   └── 005-bash-vs-ansible.md
│   ├── runbooks/
│   │   ├── sshd-wont-restart.md
│   │   ├── mariadb-datadir-locked.md
│   │   ├── cron-not-running.md
│   │   └── sudo-context-dropped.md
│   ├── lab-mapping.md
│   └── evidence/
├── iac/
│   ├── modules/
│   └── envs/
│       ├── local/
│       └── aws/                  # stub (Phase 8)
├── k8s/
│   ├── base/
│   └── overlays/
│       ├── local/
│       └── aws/                  # stub (Phase 8)
└── linux/
    ├── harden.sh
    ├── vm-only/
    │   ├── selinux.sh
    │   └── firewall.sh
    ├── vm/
    │   └── Vagrantfile
    ├── dockerfiles/
    │   ├── web-node/
    │   │   └── Dockerfile
    │   └── data-node/
    │       └── Dockerfile
    ├── compose/
    │   └── docker-compose.yml
    └── tests/
        ├── container/
        │   └── hardening.bats
        └── vm/
            └── selinux-firewall.bats
```

---

## Sub-Task 1 — Phase 0: Git Foundation

**Status:** `[ ] pending`

### Intent
Establish professional version-control habits before any code is written.
Every subsequent phase depends on this being solid: branching model,
commit message format, pre-commit hooks, PR workflow, and a first tag.

### Expected Outcomes
- A git repository initialised with an initial commit on `main`.
- `.gitignore`, `LICENSE`, `README.md` skeleton, `CONTRIBUTING.md` all committed.
- `pre-commit` framework installed with `shellcheck`, `hadolint`, `yamllint`, `gitleaks` hooks active.
- `commit-msg` hook enforcing Conventional Commits format.
- A feature-branch workflow demonstrated: at least one branch squash-merged.
- Deliberate git practice recorded in `docs/git-practice.md`.
- Annotated tag `v0.1.0-phase0` created with release notes in `CHANGELOG.md`.
- Linear, readable commit history.

### Todo List

1. `git init` in the workspace root; set `main` as the default branch.
2. Create `.gitignore` covering: Python, Node, Terraform, secrets files (`*.env`, `*.pem`, `.env*`), OS artefacts (`.DS_Store`, `Thumbs.db`), editor files, minikube and Vagrant state.
3. Add `LICENSE` (MIT or Apache 2.0 — choose one and record the reason in `CONTRIBUTING.md`).
4. Write `README.md` skeleton: one-line pitch, "Architecture" placeholder, "Quickstart" placeholder, "Phases" table of contents, "Limitations" section noting SELinux/firewalld are VM-only.
5. Write `CONTRIBUTING.md` describing: trunk-based flow, Conventional Commits format (`feat:`, `fix:`, `docs:`, `chore:`), squash-merge policy, and PR checklist.
6. Create `.github/pull_request_template.md` with checkboxes: description, test evidence, DoD items verified.
7. Install `pre-commit`; write `.pre-commit-config.yaml` with hooks:
   - `shellcheck` — shell scripts
   - `hadolint` — Dockerfiles
   - `yamllint` — YAML files
   - `gitleaks` — secrets scanner
8. Add a `commit-msg` hook (`.git/hooks/commit-msg`) rejecting messages that do not match
   `^(feat|fix|docs|chore|refactor|test|ci|perf)(\(.+\))?!?: .+`
9. Make an initial commit on `main`: `chore: initialise repository with git foundation`.
10. Create branch `feat/git-foundation`; add `CONTRIBUTING.md`, `.pre-commit-config.yaml`, PR template; self-review and squash-merge into `main`.
11. Practise deliberate git operations, each recorded briefly in `docs/git-practice.md`:
    - `git rebase -i` to tidy branch history.
    - `git cherry-pick` a dummy hotfix commit.
    - `git bisect` to find a planted-bug commit.
    - `git stash` / `git stash pop`.
    - `git reflog` to recover a "deleted" commit.
    - Resolve a synthetic merge conflict (two branches editing the same README line).
12. Create `CHANGELOG.md` with a `[v0.1.0-phase0]` entry.
13. Tag: `git tag -a v0.1.0-phase0 -m "Phase 0 complete: git foundation in place"`.

### Relevant Context
- Guide section: **Phase 0** (lines 89–105 of the guide).
- Conventional Commits spec: https://www.conventionalcommits.org
- pre-commit framework: https://pre-commit.com

### Tools and Resources

| Tool | Purpose | Install |
|---|---|---|
| `git` | Version control | system |
| `pre-commit` | Hook manager | `pip install pre-commit` |
| `shellcheck` | Shell script linter | `apt/yum install shellcheck` |
| `hadolint` | Dockerfile linter | binary from https://github.com/hadolint/hadolint/releases |
| `yamllint` | YAML linter | `pip install yamllint` |
| `gitleaks` | Secrets scanner | binary from https://github.com/gitleaks/gitleaks/releases |
| `commitlint` (optional) | Commit message lint | `npm install -g @commitlint/cli @commitlint/config-conventional` |

---

## Sub-Task 2 — Phase 1: Linux Baseline as Code

**Status:** `[ ] pending`

### Intent
Turn every KodeKloud Linux sysadmin lab skill into a repeatable, idempotent,
testable script that runs inside Docker containers. The hardening script must be
safe to run twice with no net change on the second run.
The Phase 1 extra step covers SELinux and firewalld in a VM, which cannot be
tested in containers (they share the host kernel).

### Expected Outcomes
- Dockerfiles for `web-node` and `data-node` (Rocky Linux 9 + sshd).
- A `bastion` jump-host container that can SSH to each node.
- `linux/harden.sh` idempotently covering all KodeKloud Linux lab areas.
- `bats-core` tests in `linux/tests/container/` mimicking KodeKloud grader assertions.
- `make up && make test-linux` passes from a clean clone.
- Running `harden.sh` a second time produces zero changes.
- `Vagrantfile` + VM-only scripts + VM bats tests for SELinux and firewalld.
- `docs/adr/001-container-vs-vm-for-selinux.md` and `docs/runbooks/sshd-wont-restart.md`.

### Todo List

1. Create branch `feat/linux-baseline`.
2. Create folder tree:
   `linux/dockerfiles/web-node/`, `linux/dockerfiles/data-node/`,
   `linux/compose/`, `linux/tests/container/`, `linux/tests/vm/`,
   `linux/vm-only/`, `linux/vm/`.
3. Write `linux/dockerfiles/web-node/Dockerfile`:
   - Base: `rockylinux:9`.
   - Install: `openssh-server`, `openssh-clients`, `sudo`, `shadow-utils`, `cronie`,
     `acl`, `procps`, `bind-utils`, `traceroute`, and any packages from the guide.
   - Copy in a hardened `sshd_config` (`PermitRootLogin no`, `PasswordAuthentication no`).
   - Create non-root `devops` user; add SSH public key to `authorized_keys`.
   - `CMD ["/usr/sbin/sshd", "-D"]`.
4. Write `linux/dockerfiles/data-node/Dockerfile`:
   - Same base and sshd setup as `web-node`.
   - Install `mariadb-server`; explicit datadir setting (Phase 2 will expand this).
   - Entrypoint script starts both `sshd` and `mariadbd`.
5. Write `linux/compose/docker-compose.yml`:
   - Services: `bastion`, `web-node01`, `web-node02`, `web-node03`, `data-node01`.
   - Networks: `front` (bastion ↔ web nodes), `back` (web nodes ↔ data node).
   - Named volume for data-node MariaDB data path.
6. Write `linux/harden.sh` (idempotent — check before change in each section):
   - **Users and groups:** create groups (`sysadmin`, `devops`), users with explicit UIDs,
     set shells (check `/usr/sbin/nologin` vs `/sbin/nologin`), account expiry, home dirs.
   - **Permissions and ACLs:** `chmod`/`chown` targets, `setfacl` rules; replicate the
     `chmod a+x` lab task and echo a result line.
   - **sshd hardening:** patch `/etc/ssh/sshd_config` with `sed -i`; run `sshd -t` before
     reload; skip reload if no change detected.
   - **Cron:** write `cron.allow`/`cron.deny`; add a crontab entry for a scheduled backup.
   - **PAM limits:** idempotently append to `/etc/security/limits.conf`; verify the PAM
     limits module is active.
   - **Packages:** install `bind`/`named`, `cronie`, `traceroute`; comment documenting the
     `bind` vs `named` package naming gotcha.
   - **Timezone and archive:** set timezone via `timedatectl`; create and extract a tar archive.
   - **sed config edits:** demonstrate `sed -i` on a config file.
7. Add `bats-core` as a git submodule at `linux/tests/bats-core` (or install via package manager in Dockerfiles).
8. Write `linux/tests/container/hardening.bats` test cases covering:
   - User exists with correct UID (`id -u username`).
   - Group exists (`getent group groupname`).
   - Shell is exactly `/usr/sbin/nologin` for service accounts.
   - File permissions are exact (`stat -c "%a" /path`).
   - ACL entry present (`getfacl /path | grep "user:name:rwx"`).
   - `sshd_config` contains exact hardening strings.
   - `cron.allow`/`cron.deny` contain expected entries.
   - PAM limits entry present.
   - Package installed (`rpm -q packagename`).
   - Timezone set correctly (`timedatectl show --property=Timezone`).
9. Add `Makefile` targets:
   - `make up` → `docker compose -f linux/compose/docker-compose.yml up -d`
   - `make down` → `docker compose -f linux/compose/docker-compose.yml down`
   - `make test-linux` → run `bats` tests inside each container via `docker exec`
   - `make lint` → `hadolint` on Dockerfiles, `shellcheck` on `.sh`, `yamllint` on `.yml`
10. Run `make up && make test-linux`; fix failures until all tests pass.
11. Run `harden.sh` a second time inside a container; confirm no changes are reported.
12. Save passing test output to `docs/evidence/phase1-test-output.txt`.

#### Phase 1 Extra Step — SELinux and firewalld in a VM

> **VM provider note:** The guide recommends Vagrant with VirtualBox (easiest path) or
> libvirt (lighter, Linux-native, required if KVM is already running because VirtualBox
> conflicts with KVM). Install whichever fits your system — record the choice in
> `docs/adr/001-container-vs-vm-for-selinux.md`.

13. Create `linux/vm/Vagrantfile` using `rockylinux/9` box, memory 2048 MB, 2 CPUs, provisioned with `harden.sh`, `vm-only/selinux.sh`, and `vm-only/firewall.sh`.
14. Write `linux/vm-only/selinux.sh` (idempotent):
    - `setsebool -P httpd_can_network_connect on`
    - `semanage port -a -t ssh_port_t -p tcp 2222` (check with `semanage port -l` first)
    - `restorecon -Rv /relevant/paths`
15. Write `linux/vm-only/firewall.sh` (idempotent):
    - Check `firewall-cmd --query-service=http` before adding.
    - `firewall-cmd --permanent --add-service=http`
    - `firewall-cmd --permanent --add-port=8080/tcp`
    - `firewall-cmd --reload`
16. Write `linux/tests/vm/selinux-firewall.bats`:
    - `getenforce` returns `Enforcing`.
    - `ls -Z` shows expected SELinux context.
    - `ausearch -m avc -ts recent` finds no denials.
    - `firewall-cmd --list-all` contains expected services and ports.
    - `curl localhost:8080` succeeds; blocked port times out.
17. Add Makefile target: `make test-linux-vm` → `vagrant up` then
    `vagrant ssh -c "sudo bats /vagrant/tests/vm"`.
18. Write `docs/adr/001-container-vs-vm-for-selinux.md` documenting the container limitation
    and the Vagrant/VirtualBox vs libvirt trade-off.
19. Write `docs/runbooks/sshd-wont-restart.md` as an incident-style page derived from the lab gotcha.
20. Update `docs/lab-mapping.md` with Phase 1 entries (see Sub-Task 3 below).
21. Update `README.md`: add Phase 1 quickstart section, container-vs-VM coverage table,
    and "Limitations" section.
22. Update `CHANGELOG.md` with a `[v0.2.0-phase1]` entry.
23. Squash-merge `feat/linux-baseline` into `main`; tag `v0.2.0-phase1`.

### Relevant Context
- Guide section: **Phase 1** and **Phase 1 Extra Step** (lines 106–205 of the guide).
- `/usr/sbin/nologin` vs `/sbin/nologin` gotcha is explicitly called out in the guide.
- MariaDB datadir deep-dive is a Phase 2 concern; Phase 1 data-node only needs MariaDB installed.
- VM tests are local-only; CI cannot run nested VMs. Evidence = screenshot or saved output.
- Do not use privileged containers with systemd as a SELinux workaround (guide explicitly warns against this).

### Tools and Resources

| Tool | Purpose | Install |
|---|---|---|
| `docker` / `docker compose` | Build and run containers | system |
| `rockylinux:9` Docker image | RHEL-compatible container base | `docker pull rockylinux:9` |
| `bats-core` | Shell testing framework | `git submodule add https://github.com/bats-core/bats-core` |
| `hadolint` | Dockerfile linter | binary from GitHub releases |
| `shellcheck` | Shell script linter | `apt/yum install shellcheck` |
| `yamllint` | YAML linter | `pip install yamllint` |
| `Vagrant` | VM provisioning | https://developer.hashicorp.com/vagrant/downloads |
| VirtualBox | VM provider (option A — no KVM conflict) | https://www.virtualbox.org/wiki/Downloads |
| libvirt + `vagrant-libvirt` | VM provider (option B — if KVM is running) | `apt install libvirt-daemon-system` + `vagrant plugin install vagrant-libvirt` |
| `setfacl` / `getfacl` | ACL management | `acl` package inside container/VM |
| `semanage` | SELinux port management | `policycoreutils-python-utils` inside VM |

---

## Sub-Task 3 — Makefile and docs/lab-mapping.md

**Status:** `[ ] pending`

### Intent
Ensure the `Makefile` is the single entry point for all developer operations,
and that `lab-mapping.md` explicitly bridges every KodeKloud lab area to project files.
Both are required deliverables called out by name in the guide.

### Expected Outcomes
- `Makefile` at repo root with `.PHONY`, `help` target, and all targets for Phases 0–1
  (plus stubs for later phases).
- `docs/lab-mapping.md` fully populated for Phase 0 and Phase 1.
- `make up && make test-linux` confirmed to pass end-to-end from a clean clone.

### Todo List

1. Consolidate all `Makefile` targets added in Sub-Tasks 1 and 2; add `.PHONY` declarations.
2. Add a `help` target that prints each target and its purpose.
3. Add stub targets for later phases: `k8s-up`, `k8s-down`, `scan`, `helm-lint`.
4. Populate `docs/lab-mapping.md`:

| KodeKloud Lab Area | Skills Demonstrated | Project File(s) |
|---|---|---|
| Linux admin — users/groups | UIDs, shells, expiry, home dirs | `linux/harden.sh`, `linux/tests/container/hardening.bats` |
| Linux admin — permissions/ACLs | chmod, chown, setfacl, getfacl | `linux/harden.sh`, `linux/tests/container/hardening.bats` |
| Linux admin — sshd hardening | sshd_config, PermitRootLogin, key auth | `linux/harden.sh`, `linux/dockerfiles/web-node/Dockerfile` |
| Linux admin — cron | cron.allow, cron.deny, crontab | `linux/harden.sh` |
| Linux admin — PAM limits | limits.conf, PAM module | `linux/harden.sh` |
| Linux admin — packages | bind/named gotcha, cronie, traceroute | `linux/harden.sh` |
| Linux admin — timezone/archive/sed | timedatectl, tar, sed -i | `linux/harden.sh` |
| Linux admin — SELinux | setsebool, semanage, restorecon | `linux/vm-only/selinux.sh`, `linux/tests/vm/selinux-firewall.bats` |
| Linux admin — firewalld | firewall-cmd, permanent rules | `linux/vm-only/firewall.sh`, `linux/tests/vm/selinux-firewall.bats` |
| Git workflow | branching, Conventional Commits, hooks, tags | `.pre-commit-config.yaml`, `CONTRIBUTING.md`, `docs/git-practice.md` |

5. Verify `make up && make test-linux` passes on a clean clone.

### Tools and Resources

| Tool | Purpose |
|---|---|
| `make` | Build automation entry point |
| Markdown | `lab-mapping.md` table format |

---

## Sub-Task 4 — Phase 2: Docker (high-level roadmap)

**Status:** `[ ] pending`

### Intent
Build production-quality Docker images and a multi-service Compose stack.
This phase deepens Phase 1 containers into a real application deployment.

### Expected Outcomes
- Multi-stage Dockerfile for a small Django app (non-root, pinned, HEALTHCHECK, no secrets in layers).
- `compose/docker-compose.yml` with app, MariaDB, reverse proxy; `front`/`back` networks; env files.
- MariaDB datadir lesson applied and captured in `docs/adr/002-mariadb-datadir.md`.
- `hadolint` and `trivy image` integrated into `make lint` and `make scan`.
- Local registry (`registry:2`) running; images pushed/pulled from it.
- Tag `v0.2.0-phase2`.

### Relevant Context
- Guide section: **Phase 2** (lines 207–222 of the guide).
- Before/after image size comparison required as portfolio evidence.
- `docker cp`, `docker exec`, log and network inspection practice.
- MariaDB `mysql_install_db` detail and the `mysql_install_db` ADR.

### Tools and Resources

| Tool | Purpose |
|---|---|
| `docker buildx` | Multi-stage builds |
| `hadolint` | Dockerfile linter (already installed Phase 0) |
| `trivy` | Image vulnerability scanner |
| `registry:2` | Local Docker registry |
| Django | App framework (small, existing stack) |

---

## Sub-Task 5 — Phase 3: Kubernetes on minikube (high-level roadmap)

**Status:** `[ ] pending`

### Intent
Run the same app on Kubernetes, reinforcing lab topics and closing all the missing
Kubernetes fundamentals (Services, Ingress, ConfigMaps, Secrets, PVCs, probes, RBAC, NetworkPolicy).

### Expected Outcomes
- Pod with two containers sharing `emptyDir`.
- Deployment with rolling update + rollback demo.
- Job for Django migrations; CronJob for nightly DB backup to a PVC.
- ConfigMap and Secret for app config and DB credentials.
- StatefulSet + PVC for MariaDB.
- Ingress via `minikube addons enable ingress` with `/etc/hosts` local hostname.
- HPA with load test using `hey` or `ab`.
- RBAC ServiceAccount with least-privilege Role.
- NetworkPolicy restricting DB access to app only (Calico CNI).
- Kustomize `base` and `overlays/local`.
- `make k8s-up` deploys the full stack; tag `v0.3.0-phase3`.

### Relevant Context
- Guide section: **Phase 3** (lines 223–248 of the guide).
- Start minikube: `minikube start --cpus=4 --memory=6144 --driver=docker --cni=calico`.
- NetworkPolicy requires Calico: `--cni=calico` flag at minikube start.
- Namespaces: `strata-dev`, `strata-prod`.
- `k8s/base/` and `k8s/overlays/local/` folder structure.
- `k8s/overlays/aws/` stubbed for Phase 8.

### Tools and Resources

| Tool | Purpose |
|---|---|
| `minikube` | Local Kubernetes cluster |
| `kubectl` | Kubernetes CLI |
| `kustomize` | Manifest layering |
| `hey` or `ab` | Load testing for HPA demo |
| Calico CNI | NetworkPolicy enforcement |

---

## Sub-Task 6 — Phase 4: CI/CD Pipeline (high-level roadmap)

**Status:** `[ ] pending`

### Intent
Make every push automatically linted, tested, built, scanned, and (locally) deployed.
No PR can merge with a failing check.

### Expected Outcomes
- GitHub Actions workflow with jobs: `lint`, `test`, `build`, `scan`, `deploy-local` (kind or minikube in runner).
- `act` configured for local workflow development.
- Tag-triggered release job builds and pushes versioned images.
- Layer and dependency caching.
- Status badge in README.
- Tag `v0.4.0-phase4`.

### Relevant Context
- Guide section: **Phase 4** (lines 250–264 of the guide).
- Tools: `shellcheck`, `hadolint`, `yamllint`, `kubeconform`, `bats`, Docker Buildx, Trivy.
- `act`: https://github.com/nektos/act
- GHCR is a free, AWS-free option for public image hosting.
- `.github/workflows/ci.yml` and `.github/workflows/release.yml`.

### Tools and Resources

| Tool | Purpose |
|---|---|
| GitHub Actions | CI/CD platform |
| `act` | Run workflows locally |
| `kubeconform` | Kubernetes manifest validation |
| `trivy` | Image scanning in CI |
| Docker Buildx | Multi-platform image builds |

---

## Sub-Task 7 — Phase 5: Packaging and GitOps (high-level roadmap)

**Status:** `[ ] pending`

### Intent
Show deployment maturity beyond `kubectl apply`: package with Helm and automate
sync with Argo CD so Git is the single source of truth.

### Expected Outcomes
- Helm chart at `charts/strataslocal/` with `values-local.yaml`.
- `helm lint` and `helm template` added to CI.
- Argo CD installed on minikube, pointed at `k8s/overlays/local` or the chart.
- Drift correction demonstrated: manual `kubectl edit` is reverted automatically.
- Tag `v0.5.0-phase5`.

### Relevant Context
- Guide section: **Phase 5** (lines 265–275 of the guide).
- Optional: local Gitea server for fully offline GitOps loop.
- Argo CD setup: `kubectl create namespace argocd` + apply install manifest.

### Tools and Resources

| Tool | Purpose |
|---|---|
| `helm` | Kubernetes package manager |
| Argo CD | GitOps controller |
| Gitea (optional) | Local Git server |

---

## Sub-Task 8 — Phase 6: Observability (high-level roadmap)

**Status:** `[ ] pending`

### Intent
Make system behaviour visible through metrics, dashboards, and alerts.

### Expected Outcomes
- `kube-prometheus-stack` installed via Helm with minikube-appropriate resource limits.
- Django metrics exposed via `django-prometheus`.
- Grafana dashboard: request rate, error rate, latency, pod restarts.
- Alert rule: pod crash looping or high 5xx rate.
- Scaling DB to zero fires an alert visibly on the dashboard.
- Tag `v0.5.0-phase6` (combined with Phase 5 per suggested timeline).

### Relevant Context
- Guide section: **Phase 6** (lines 277–292 of the guide).
- minikube resource requirement: ~4 CPUs, 6–8 GB RAM.
- Loki + Promtail optional; structured JSON logging is the simpler alternative.
- `django-prometheus`: https://github.com/korfuri/django-prometheus

### Tools and Resources

| Tool | Purpose |
|---|---|
| `kube-prometheus-stack` Helm chart | Prometheus + Grafana + Alertmanager |
| `django-prometheus` | Django metrics exporter |
| `kube-state-metrics` | Kubernetes object metrics |

---

## Sub-Task 9 — Phase 7: IaC, Docs and Runbooks (high-level roadmap)

**Status:** `[ ] pending`

### Intent
Codify the environment itself with Terraform and Ansible; make the project fully
readable by a stranger through runbooks, ADRs, and `lab-mapping.md`.

### Expected Outcomes
- Terraform modules using `kreuzwerker/docker` and `hashicorp/kubernetes` (or `helm`) providers.
- `iac/modules/` with provider-agnostic interfaces; `iac/envs/local/` and `iac/envs/aws/` stub.
- Ansible `roles/hardening` playbook run against Compose "servers" via SSH from bastion.
- Shell `harden.sh` retained as comparison; trade-offs documented in `docs/adr/005-bash-vs-ansible.md`.
- Runbooks for all four lab gotchas (sshd, MariaDB datadir, cron.allow, sudo context).
- ADRs: Compose vs Kubernetes, Kustomize vs Helm, bash vs Ansible, container vs VM for SELinux.
- `docs/lab-mapping.md` complete for all phases.
- A new reader can clone and run using only the README.
- Tag `v1.0.0-phase7`.

### Relevant Context
- Guide section: **Phase 7** (lines 293–305 of the guide).
- `kreuzwerker/docker` Terraform provider: manages Docker containers/networks/volumes.
- `iac/envs/aws/backend.tf` is a stub — backend block isolated for future S3 backend.
- Ansible playbooks connect to containers via SSH from the bastion container.

### Tools and Resources

| Tool | Purpose |
|---|---|
| `terraform` | Infrastructure as Code |
| `ansible` | Configuration management |
| `kreuzwerker/docker` provider | Terraform Docker management |
| `hashicorp/kubernetes` provider | Terraform Kubernetes management |
| `helm` Terraform provider | Helm release management via Terraform |

---

## Phase 8 Note (Deferred — design seams only)

Phase 8 (AWS integration) is out of scope for this plan. The guide's Phase 8 seam table
(minikube → EKS, registry:2 → ECR, MariaDB StatefulSet → RDS, PVC → EBS, etc.) must be
considered in every earlier phase. Specifically:

- Image repo and tag set through a variable — never hard-coded.
- App reads DB host, port, credentials only from env/Secret.
- StorageClass referenced by name in values files.
- Backup script takes a destination URI (`local/path` today, `s3://` later).
- Terraform `modules/compute` interface with `envs/aws` stub.
- Backend block isolated in `iac/envs/*/backend.tf`.

---

## Full Definition of Done (Phases 0 + 1)

- [ ] `git clone <repo> && make up && make test-linux` passes from a clean environment.
- [ ] Running `harden.sh` twice produces no changes on the second run.
- [ ] All shell scripts pass `shellcheck` with zero warnings.
- [ ] All Dockerfiles pass `hadolint` with zero warnings.
- [ ] All YAML files pass `yamllint`.
- [ ] `gitleaks` finds no secrets in commit history.
- [ ] Linear, readable commit history; all commits use Conventional Commit format.
- [ ] Annotated tags `v0.1.0-phase0` and `v0.2.0-phase1` exist.
- [ ] `CONTRIBUTING.md`, `CHANGELOG.md`, PR template committed.
- [ ] `docs/lab-mapping.md` covers all Phase 0 and Phase 1 lab areas.
- [ ] `docs/adr/001-container-vs-vm-for-selinux.md` written.
- [ ] `docs/runbooks/sshd-wont-restart.md` written.
- [ ] VM test results evidenced by screenshot or saved output.

---

## Suggested Tag History

| Tag | Phase | Milestone |
|---|---|---|
| `v0.1.0-phase0` | 0 | Git foundation: linear history, hooks, PR workflow |
| `v0.2.0-phase1` | 1 | Hardened Linux containers with passing bats tests |
| `v0.3.0-phase2` | 2 | Secure multi-service Compose stack with scans |
| `v0.4.0-phase3` | 3 | Full app on minikube, rollback and NetworkPolicy demos |
| `v0.5.0-phase4` | 4 | CI pipeline green, badge in README |
| `v0.6.0-phase5-6` | 5+6 | Helm, Argo CD, Grafana dashboard |
| `v1.0.0-phase7` | 7 | Terraform, Ansible, runbooks, ADRs complete |
| `v2.0.0-phase8` | 8 | AWS overlay (EKS, ECR, RDS, S3) — future |

---

## Context for Implementation

- **Working directory:** `/home/avat/Desktop/MyProjects/StratasLocal`
- **Guide file:** `StratosLocal Portfolio Project Guide (Docker, minikube, Linux, Git).md`
- **Platform:** Linux x64
- **No existing code** — start from scratch with `git init`.
- Sub-tasks must be implemented strictly in order (1 → 2 → 3 → 4 … → 9).
- After each sub-task, update the Status field in this plan file before proceeding.
- Phases 2–7 sub-tasks (4–9) must have their todo lists expanded from the high-level
  roadmap into step-by-step detail before implementation begins on that phase.
