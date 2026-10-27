# Contributing to StratasLocal

Thank you for contributing! This document describes the workflow, commit format,
and review expectations for all contributions.

---

## Licence Choice

This project is released under the **MIT Licence**.

MIT was chosen because:
- It is maximally permissive — anyone can study, fork, and adapt this lab.
- It imposes no viral copy-left requirements on downstream projects that embed
  these scripts or playbooks.
- It is widely recognised and legally unambiguous.

By submitting a pull request you agree that your contribution will be licensed
under the same MIT terms.

---

## Branching Model — Trunk-Based Development

We follow a **trunk-based development** flow:

- `main` is the single trunk and is always in a deployable state.
- Feature work is done on **short-lived branches** (`feat/`, `fix/`, `docs/`,
  `chore/`, etc.) that are squash-merged into `main` within 1–2 days of opening.
- Long-lived feature branches are not permitted; break large work into small
  increments instead.
- Direct commits to `main` are only permitted for trivial typo fixes and are
  strongly discouraged.

```
main  ──────────────────────────────────────────────────▶
          ╲  feat/my-feature  ╱
           ────────────────────  (squash-merge → single commit on main)
```

---

## Conventional Commits Format

Every commit message **must** follow the
[Conventional Commits](https://www.conventionalcommits.org) specification.

### Format

```
<type>[optional scope][optional !]: <description>

[optional body]

[optional footer(s)]
```

### Allowed types

| Type | When to use |
|------|-------------|
| `feat` | A new feature or capability |
| `fix` | A bug fix |
| `docs` | Documentation-only changes |
| `chore` | Maintenance (deps, build scripts, config) |
| `refactor` | Code change that is neither a fix nor a feature |
| `test` | Adding or correcting tests |
| `ci` | CI/CD configuration changes |
| `perf` | Performance improvement |

### Examples

```
feat(ansible): add baseline package list for Fedora
fix(docker): correct healthcheck interval in compose file
docs: update quickstart with minikube prerequisites
chore: bump pre-commit hook versions
refactor(k8s): extract common labels into named template
```

### Breaking changes

Append `!` after the type/scope, and add a `BREAKING CHANGE:` footer:

```
feat(api)!: rename service endpoint

BREAKING CHANGE: /health is now /healthz
```

A `commit-msg` git hook (`.git/hooks/commit-msg`) will **reject** commits whose
first line does not match the required pattern. Fix the message and try again.

---

## Squash-Merge Policy

All pull requests are merged with **squash-merge**. This means:

- The entire PR is collapsed into a single commit on `main`.
- The squash commit message must itself follow the Conventional Commits format.
- Internal WIP commits on a branch can be messy; only the final squash message
  is permanent.

---

## Pull Request Checklist

Before requesting review, ensure every item in
[`.github/pull_request_template.md`](.github/pull_request_template.md) is
checked. Key items:

- [ ] The PR title follows Conventional Commits format.
- [ ] `pre-commit run --all-files` passes locally with no errors.
- [ ] Relevant documentation has been added or updated.
- [ ] The Definition of Done (DoD) items for the affected phase are met.
- [ ] No secrets, credentials, or personally identifiable information have been
      committed (gitleaks hook verifies this automatically).

---

## Local Development Setup

```bash
# 1. Install pre-commit
pip install pre-commit

# 2. Install hooks into your local clone
pre-commit install --hook-type commit-msg
pre-commit install

# 3. Run all hooks against every file
pre-commit run --all-files
```

---

## Questions

Open a GitHub Discussion or drop a comment on the relevant issue.
