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

<!-- Next release will be v0.2.0-phase1 (Linux Baseline as Code) -->
