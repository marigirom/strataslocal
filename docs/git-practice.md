# Git Practice Log — Phase 0

This document records every deliberate git operation practised as part of
Sub-Task 1 (Phase 0: Git Foundation). Each section states the goal, the exact
commands used, the observed output, and the key lesson learned.

---

## 1. Interactive Rebase — Tidy Branch History

**Goal:** Squash multiple WIP commits on a feature branch into a single,
well-described commit before merging.

**Branch:** `practice/rebase-demo`

**Setup:** Three messy WIP commits were made on `practice/rebase-demo`:

```
22be237  wip: note 3
9ce1616  wip: note 2
6298c21  wip: note 1
d253f20  feat: add contributing guide, pre-commit hooks, and PR template
```

**Operation:**

```bash
# Reset branch pointer back to the merge base (keeps changes in staging)
git reset --soft d253f20

# Recommit as a single, well-named commit
git commit -m "docs: consolidate README notes (rebased from 3 WIP commits)"
```

This is the scriptable equivalent of `git rebase -i HEAD~3` → marking all
three commits as `squash` / `fixup` in the interactive editor.

**Result:**

```
3f5ed19  docs: consolidate README notes (rebased from 3 WIP commits)
d253f20  feat: add contributing guide, pre-commit hooks, and PR template
```

**Key lesson:** `git reset --soft <base>` is the fastest way to collapse
commits when you are already sure of the target base. For editing individual
commit messages in the middle of a range, use `git rebase -i <base>` and mark
those commits as `reword`.

---

## 2. Cherry-Pick — Apply a Hotfix from Another Branch

**Goal:** Copy a specific commit from `hotfix/typo-fix` onto
`practice/rebase-demo` without merging the entire hotfix branch.

**Hotfix SHA:** `113e5ab`  
**Message:** `fix: correct quickstart placeholder wording`

**Operation:**

```bash
# Identify the commit to pick
git log --oneline hotfix/typo-fix

# Switch to the target branch
git checkout practice/rebase-demo

# Cherry-pick without auto-commit to allow inspection first
git cherry-pick --no-commit 113e5ab

# Commit with an explicit message indicating the source
git commit -m "fix: cherry-pick quickstart typo correction from hotfix/typo-fix"
```

**Note:** A merge conflict occurred in `README.md` because `practice/rebase-demo`
had diverged. The conflict was resolved manually (keeping the hotfix change,
dropping the WIP content from the other branch), then completed with
`git cherry-pick --continue`.

**Key lesson:** Always cherry-pick with `--no-commit` first so you can inspect
the result before it is recorded. Document the source SHA in the commit message
so future `git log` readers understand where the change came from. Conflict
resolution during cherry-pick is identical to resolving merge conflicts.

---

## 3. Bisect — Find the Commit That Introduced a Bug

**Goal:** Use binary search to pinpoint the exact commit that introduced a
regression, without reading every diff manually.

**Branch:** `practice/bisect-demo`

**Setup:** Four commits were planted, with the bug introduced at commit 3:

```
215ef02  chore: bisect demo commit 4 (bad)
d8135c6  chore: bisect demo commit 3 (introduces bug)   ← CULPRIT
9ca89c7  chore: bisect demo commit 2 (good)
d6a8fab  chore: bisect demo commit 1 (good)
```

**Operation:**

```bash
# Start bisect session
git bisect start

# Tell git which commit is known-bad and known-good
git bisect bad  215ef02   # current HEAD is bad
git bisect good 9ca89c7   # last known-good commit

# git lands on d8135c6 — the only candidate between good and bad
# Test confirms this is the first bad commit; mark it
git bisect bad

# git reports: "d8135c6 is the first bad commit"

# End session and return to original HEAD
git bisect reset
```

**Output:**

```
d8135c654ba1e6c147b64e2fe8dfdb254c53a16e is the first bad commit
commit d8135c6 chore: bisect demo commit 3 (introduces bug)
```

**Key lesson:** `git bisect` uses binary search — O(log n) instead of O(n)
inspections. For automated testing, use `git bisect run <test-script>` to let
git mark commits good/bad automatically without human intervention.

---

## 4. Stash — Shelve Uncommitted Work to Switch Context

**Goal:** Stash a half-finished change, switch context, then restore it.

**Operation:**

```bash
# Simulate in-progress work
echo "# stash test line" >> README.md

# Confirm there are staged/unstaged changes
git diff --stat
# README.md | 1 +

# Stash with a descriptive message
git stash push -m "wip: stash demo — README stash test line"

# Working tree is now clean — safe to switch branches or run a quick fix
git diff --stat README.md   # no output

# List stashes
git stash list
# stash@{0}: On main: wip: stash demo — README stash test line

# Restore work
git stash pop

# Confirm change is back
tail -1 README.md
# # stash test line
```

**Key lesson:** Use descriptive stash messages with `-m` — anonymous stashes
(`git stash`) are hard to identify in long `git stash list` output.
`git stash pop` removes the stash after restoring; use `git stash apply` if you
want the stash to remain on the stack.

---

## 5. Reflog — Recover a "Deleted" Commit

**Goal:** Simulate accidentally discarding a commit with `git reset --hard`,
then recover it using `git reflog`.

**Operation:**

```bash
# Make a commit we are about to "lose"
echo "# reflog recovery test" >> README.md
git add README.md
git commit -m "docs: reflog demo — commit to be deleted"
# SHA: cc4ccf7

# Simulate accidental hard reset (drops the commit from branch history)
git reset --hard HEAD~1
# HEAD is now at d253f20

# The commit is gone from git log but still in the object store
git log --oneline | grep cc4ccf7   # not found

# Inspect reflog to find the lost SHA
git reflog | head -5
# d253f20 HEAD@{0}: reset: moving to HEAD~1
# cc4ccf7 HEAD@{1}: commit: docs: reflog demo — commit to be deleted

# Recover by cherry-picking the lost SHA
git cherry-pick --no-commit cc4ccf7
git commit -m "docs: reflog demo — recovered via git reflog + cherry-pick"
```

**Key lesson:** `git reset --hard` does NOT permanently delete commits —
they remain in the object store until garbage-collected (default 90 days).
`git reflog` is always the first place to look when you think a commit is lost.
You can also recover with `git reset --hard <lost-sha>` directly if you want to
restore the branch pointer rather than cherry-pick.

---

## 6. Merge Conflict Resolution — Two Branches Editing the Same Line

**Goal:** Deliberately create a merge conflict and resolve it manually,
practising the identify → edit → mark-resolved → commit workflow.

**Setup:**

- `practice/conflict-branch-a`: changed the README pitch line to
  `[Branch A edit] A comprehensive, phase-by-phase lab`.
- `practice/conflict-branch-b`: changed the same line to
  `[Branch B edit] A standalone, phase-by-phase lab`.

**Operation:**

```bash
# Merge branch-a first — clean merge
git checkout main
git merge --no-ff practice/conflict-branch-a -m "docs: merge branch-a pitch edit"

# Merge branch-b — CONFLICT
git merge practice/conflict-branch-b
# CONFLICT (content): Merge conflict in README.md
# Automatic merge failed; fix conflicts and then commit the result.

# README.md now contains conflict markers:
# <<<<<<< HEAD
# > [Branch A edit] A comprehensive, phase-by-phase lab
# =======
# > [Branch B edit] A standalone, phase-by-phase lab
# >>>>>>> practice/conflict-branch-b

# Edit README.md to keep the desired version (Branch A's wording)
# Remove all <<<, ===, >>> markers

# Mark as resolved
git add README.md

# Commit the merge
git commit -m "docs: resolve merge conflict — keep branch-a pitch line"
```

**Key lesson:** The three-step resolution workflow is always:
1. **Identify** conflicting hunks (`git diff`, or look for `<<<`/`===`/`>>>` markers).
2. **Edit** the file to reflect the intended final state (remove all markers).
3. **Mark resolved** with `git add <file>`, then `git commit`.

Use `git mergetool` or a GUI diff tool (VS Code, IntelliJ, vimdiff) for complex
conflicts. `git checkout --theirs <file>` / `git checkout --ours <file>` provide
shortcuts when you want to accept one side wholesale.

---

## Summary Table

| # | Operation | Branch(es) | Outcome |
|---|-----------|------------|---------|
| 1 | `git reset --soft` + squash commit (rebase -i equivalent) | `practice/rebase-demo` | 3 WIP commits collapsed into 1 |
| 2 | `git cherry-pick` | `hotfix/typo-fix` → `practice/rebase-demo` | Hotfix commit applied; conflict resolved |
| 3 | `git bisect` | `practice/bisect-demo` | Bug commit `d8135c6` identified in 1 step |
| 4 | `git stash` / `git stash pop` | `main` | WIP shelved and restored cleanly |
| 5 | `git reflog` + `git cherry-pick` | `main` | "Deleted" commit `cc4ccf7` recovered |
| 6 | Merge conflict resolution | `conflict-branch-a/b` → `main` | Conflict in README.md resolved manually |
