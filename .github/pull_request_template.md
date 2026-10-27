## Description

<!-- What does this PR do? Why is it needed? Link to the relevant issue if one exists. -->

Closes #

---

## Type of change

- [ ] `feat` — new feature or capability
- [ ] `fix` — bug fix
- [ ] `docs` — documentation only
- [ ] `chore` — maintenance / dependencies
- [ ] `refactor` — code restructure, no behaviour change
- [ ] `test` — test additions or corrections
- [ ] `ci` — CI/CD configuration
- [ ] `perf` — performance improvement

---

## Test evidence

<!-- Paste relevant command output, screenshots, or CI run links that prove the change works. -->

```
# e.g. pre-commit run --all-files output, make test output, etc.
```

---

## Definition of Done checklist

- [ ] PR title follows Conventional Commits format (`type(scope): description`).
- [ ] `pre-commit run --all-files` passes locally with zero errors.
- [ ] All new shell scripts pass `shellcheck`.
- [ ] All new Dockerfiles pass `hadolint`.
- [ ] All new YAML files pass `yamllint`.
- [ ] `gitleaks` found no secrets.
- [ ] Relevant documentation (`README.md`, `docs/`, phase-specific notes) has been added or updated.
- [ ] `CHANGELOG.md` updated if this change warrants a version bump.
- [ ] No `.env`, `*.pem`, `*.key`, or other credential files are staged.
- [ ] DoD items for the affected phase (see `strataslocal-plan.md`) are met.

---

## Reviewer notes

<!-- Anything the reviewer should pay special attention to, known gaps, or follow-up work. -->
