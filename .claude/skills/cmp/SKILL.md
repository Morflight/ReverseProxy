---
name: cmp
description: Commit current work, merge into master/main, and push
---

## Step 1 — Detect context (silently, before asking anything)

```bash
git branch --show-current          # current branch
git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|.*/||'  # main branch name (main or master)
git status --short                 # uncommitted changes
git log origin/master..HEAD --oneline 2>/dev/null || git log origin/main..HEAD --oneline 2>/dev/null  # unpushed commits on this branch
```

**Guard rails — stop and warn if:**
- Already on `master` or `main`: "You're already on the main branch. This skill is meant to be run from a feature branch. Proceed anyway?" and wait for confirmation.
- Working tree has merge conflict markers (`git status` shows `UU` / `AA` / `DD`): stop entirely — "There are unresolved merge conflicts. Resolve them first."

## Step 2 — Commit phase (if there are uncommitted changes)

If the working tree is clean and there are no staged changes, skip to Step 3.

Otherwise:
1. Show a compact diff summary: `git diff --stat HEAD`
2. Propose a commit message based on the changed files and diff content. Keep it concise (imperative mood, ≤72 chars subject line).
3. Ask: "Commit with this message? (edit or confirm)"
4. Wait for the user to confirm or provide an alternative message.
5. Stage and commit:

```bash
git add -A
git commit -m "<confirmed message>"
```

## Step 3 — Merge into master/main

```bash
git checkout <main-branch>
git pull
git merge <feature-branch> --no-ff -m "Merge <feature-branch> into <main-branch>"
```

`--no-ff` preserves the branch history with a merge commit.

**If merge conflicts occur:** stop immediately. Report which files conflict. Do not attempt auto-resolution. Tell the user to resolve conflicts manually, then re-run `/cmp`.

## Step 4 — Push

```bash
git push
```

If push is rejected (remote has diverged), stop and report the error. Do not force-push without explicit user instruction.

## Step 5 — Cleanup prompt

Ask: "Delete the feature branch `<feature-branch>`?"

If yes:
```bash
git branch -d <feature-branch>
git push origin --delete <feature-branch>
```

## Step 6 — Summary

Print a one-line summary:
- Branch merged: `<feature-branch>` → `<main-branch>`
- Commit(s) included: list the short hashes + subjects
- Push: confirmed or skipped
