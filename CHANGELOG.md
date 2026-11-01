# Changelog

All notable changes to StratasLocal are documented in this file.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versions follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [v0.1.0-phase0] — 2025 — Phase 0: Git Foundation

### Summary

Phase 0 establishes the version-control foundation that every subsequent phase
depends on. A professional branching model, commit-message discipline,
automated pre-commit hooks, and deliberate git practice are all in place before
any application code is written.

### Added

- **Repository initialised** on `main` with `git init --initial-branch=main`.
- **`.gitignore`** covering Python, Node.js, Terraform, secrets (`*.env`,
  `*.pem`, `.env*`), OS artefacts (`.DS_Store`, `Thumbs.db`), editor files
  (`.idea/`, `.vscode/`), minikube, and Vagrant.
- **`LICENSE`** — MIT licence chosen for maximum permissiveness.
- **`README.md`** skeleton: one-line pitch, Architecture placeholder, Quickstart
  placeholder, Phases table of contents, Limitations section (SELinux/firewalld
  VM-only caveat documented).
- **`CONTRIBUTING.md`** describing trunk-based development, Conventional Commits
  format, squash-merge policy, and the PR checklist. Includes rationale for the
  MIT licence choice.
- **`.github/pull_request_template.md`** with type-of-change checkboxes, test
  evidence section, and a full Definition of Done checklist.
- **`pre-commit` framework** installed; `.pre-commit-config.yaml` configured
  with four hooks:
  - `shellcheck` (v0.10.0.1) — shell script static analysis.
  - `hadolint` (v2.12.0) — Dockerfile best-practice linter.
  - `yamllint` (v1.38.0) — YAML style and correctness checker.
  - `gitleaks` (v8.27.2) — secrets scanner to prevent credential leaks.
- **`commit-msg` hook** (`.git/hooks/commit-msg`) enforcing the Conventional
  Commits pattern `^(feat|fix|docs|chore|refactor|test|ci|perf)(\(.+\))?!?: .+`
  — invalid messages are rejected with a clear error and examples.
- **`docs/git-practice.md`** recording all six deliberate git operations:
  interactive rebase, cherry-pick, bisect, stash/pop, reflog recovery, and
  merge-conflict resolution.

### Workflow demonstrated

- Feature-branch `feat/git-foundation` created, three commits made, then
  squash-merged into `main` as a single clean commit.
- Practice branches (`practice/rebase-demo`, `practice/bisect-demo`,
  `practice/conflict-branch-a/b`, `hotfix/typo-fix`) used to exercise git
  mechanics; all operations documented in `docs/git-practice.md`.

### Definition of Done — Phase 0 ✅

- [x] Repository initialised with initial commit on `main`.
- [x] `.gitignore`, `LICENSE`, `README.md`, `CONTRIBUTING.md` committed.
- [x] `pre-commit` active with shellcheck, hadolint, yamllint, gitleaks.
- [x] `commit-msg` hook enforcing Conventional Commits.
- [x] Feature-branch workflow demonstrated (squash-merge).
- [x] Deliberate git practice recorded in `docs/git-practice.md`.
- [x] `CHANGELOG.md` created with `[v0.1.0-phase0]` entry.
- [x] Annotated tag `v0.1.0-phase0` created.
- [x] Linear, readable commit history on `main`.

---

## [v0.2.0-phase1] — 2026-11-01 — Phase 1: Linux Baseline as Code

### Summary

Phase 1 turns every KodeKloud Linux sysadmin lab skill into a repeatable,
idempotent, testable script running inside Rocky Linux 9 Docker containers.
All 33 bats assertions pass across three nodes; running `harden.sh` a second
time produces zero changes. SELinux and firewalld are deferred to the VM
extra step (Milestone 4).

### Added

- **`linux/dockerfiles/web-node/Dockerfile`** — Rocky Linux 9 + sshd,
  `devops` user with SSH key, bats-core installed.
- **`linux/dockerfiles/data-node/Dockerfile`** — same base + MariaDB server,
  dual entrypoint starting both `sshd` and `mysqld_safe`.
- **`linux/compose/docker-compose.yml`** — `bastion` + `web-node01/02/03` +
  `data-node01`; `front` and `back` bridge networks; named `mariadb-data` volume.
- **`linux/harden.sh`** — idempotent 8-section hardening script:
  users/groups, permissions/ACLs, sshd, cron, PAM limits, packages,
  timezone, sed config edits. Uses `CHANGED` counter; zero changes on second run.
- **`linux/tests/bats-core`** — bats-core v1.14.0 as a git submodule.
- **`linux/tests/container/hardening.bats`** — 33 test cases covering all
  hardening sections; mimics KodeKloud grader assertion style.
- **`Makefile`** — `up`, `down`, `build`, `test-linux`, `harden`,
  `idempotent`, `lint` targets.
- **`docs/evidence/phase1-test-output.txt`** — captured passing test run
  and idempotency confirmation.
- **`docs/adr/001-container-vs-vm-for-selinux.md`** — documents why SELinux
  and firewalld require a VM, provider choice rationale, coverage table.
- **`docs/runbooks/sshd-wont-restart.md`** — incident-style runbook covering
  config syntax errors, wrong nologin path, systemd-in-container trap, and
  missing host keys.

### Fixed

- Timezone: replaced `timedatectl set-timezone` (requires systemd PID 1)
  with `ln -sf /usr/share/zoneinfo/...` — works in containers and VMs.
- devops GID aligned to 2000 (matches Dockerfile `useradd`).
- `named` binary test uses `test -x /usr/sbin/named` instead of `which`
  (restricted `$PATH` in containers).

### Definition of Done — Phase 1 containers ✅

- [x] Dockerfiles build cleanly; `make up` starts all 5 containers.
- [x] `make harden` runs `harden.sh` on all nodes without error.
- [x] `make test-linux` — 33/33 passing on web-node01, web-node02, data-node01.
- [x] `make idempotent` — zero `CHANGED` lines on second `harden.sh` run.
- [x] Evidence saved to `docs/evidence/phase1-test-output.txt`.
- [x] ADR 001 and sshd runbook written.
- [ ] VM extra step (SELinux + firewalld) — pending Milestone 4.

---

<!-- Next release will be v0.2.0-phase1 (after VM extra step is complete) -->
