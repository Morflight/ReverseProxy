---
name: cmp
description: Commit current work, merge into master/main, and push. Use whenever the user says /cmp, "commit and push", "merge and push", "ship it", or wants to finalize work on the current branch. Supports --interactive (step-by-step confirmation) and --complete (stage everything as a backup commit).
---

## Flags

- **`--interactive`** — Ask for confirmation before each step. User can approve, skip, or abort at every phase.
- **`--complete`** — Stage and commit *everything* in the working tree (`git add -A`), bypassing scope filtering. Useful as a quick backup or when the user explicitly wants all changes in one commit.
- Default (no flags) is **trust mode**: auto-detect, auto-commit, auto-push with no prompts.

## Step 1 — Detect context

```bash
git branch --show-current
git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|.*/||'
git status --short
git log origin/master..HEAD --oneline 2>/dev/null || git log origin/main..HEAD --oneline 2>/dev/null
```

Determine:
- `current_branch` — the branch you're on
- `main_branch` — `master` or `main` (whichever exists on the remote)
- `on_main` — whether `current_branch == main_branch`

**Guard rails — stop and warn if:**
- Merge conflict markers in working tree (`UU` / `AA` / `DD` in `git status`): stop — "Unresolved merge conflicts. Resolve them first."

## Step 2 — Sync with remote

Before committing, make sure the current branch isn't behind its remote tracking branch. This prevents push rejections later.

```bash
git fetch origin
```

Then check if the local branch is behind:

```bash
git rev-list --count HEAD..origin/<current_branch>
```

If the count is > 0, fast-forward:

```bash
git pull --ff-only
```

If fast-forward fails (diverged history), stop and tell the user: "Local and remote have diverged on `<current_branch>`. Rebase or merge manually before running /cmp again."

In `--interactive` mode, show: "Branch is N commits behind remote. Fast-forward?" and wait for confirmation.

## Step 3 — Commit phase

If the working tree is clean and nothing is staged, skip to Step 4.

### Scope filtering (default and --interactive)

The goal is to only commit files that are relevant to the work done in this conversation. Other Claude sessions or manual edits may have touched files that don't belong in this commit.

1. Review the conversation history to build a list of files you created, edited, or explicitly discussed with the user.
2. Run `git status --short` and split the changed files into two buckets:
   - **In scope** — files you touched or that the user asked you to work on
   - **Out of scope** — everything else (modified files you never interacted with)
3. If there are out-of-scope files, warn the user:
   "These files have changes but weren't part of our work — skipping them: `<list>`"
4. Stage only in-scope files by name (`git add <file1> <file2> ...`).

In `--interactive` mode, show both buckets and let the user move files between them before staging.

### --complete flag

Skip scope filtering entirely. Stage everything:

```bash
git add -A
```

### Commit message

Generate a concise commit message (imperative mood, ≤72 char subject line) based on the diff content. In trust mode, commit directly without asking. In `--interactive` mode, show the proposed message and wait for confirmation or edits.

```bash
git commit -m "<message>"
```

## Step 4 — Merge into main (feature branch only)

**If `on_main` is true, skip this step entirely** — go straight to Step 5.

On a feature branch:

```bash
git checkout <main_branch>
git pull --ff-only
git merge <feature_branch> --no-ff -m "Merge <feature_branch> into <main_branch>"
```

If the pull fast-forward fails, stop: "Remote `<main_branch>` has diverged. Pull and resolve manually."

If the merge has conflicts, stop immediately. Report which files conflict. Do not attempt auto-resolution: "Merge conflicts in: `<files>`. Resolve them, then re-run `/cmp`."

In `--interactive` mode, confirm before the merge: "Merge `<feature_branch>` into `<main_branch>`?"

## Step 5 — Push

```bash
git push
```

If push is rejected, stop and report the error. Never force-push.

In `--interactive` mode, confirm: "Push to origin?"

## Step 6 — Cleanup (feature branch only)

**If `on_main` is true, skip this step.**

In trust mode, delete the feature branch automatically (local + remote):

```bash
git branch -d <feature_branch>
git push origin --delete <feature_branch>
```

In `--interactive` mode, ask: "Delete feature branch `<feature_branch>` (local + remote)?"

## Step 7 — Backlog sync (if configured)

After pushing, check if the project has a backlog:

```bash
test -f .claude/backlog.md && echo "HAS_BACKLOG" || echo "NO_BACKLOG"
```

**If no backlog exists, skip this step silently.**

If a backlog exists:
1. Read `.claude/backlog.md` and identify any items whose status changed during this session (e.g. marked `done`, `in-progress`, `blocked`).
2. For each changed item, invoke the `/backlog` skill action to sync the change — this triggers Trello sync automatically if the project has a Trello board configured (`.claude/trello-board-id`).
   - Items marked done: `/backlog done <ID>`
   - Items started: `/backlog start <ID>`
   - Items blocked: `/backlog block <ID>`
3. If the backlog was already updated in-file (common when agents update docs), just run the Trello sync portion directly:
   - Load Trello credentials and board ID
   - Find cards matching the changed backlog IDs (by `[B-NNN]` prefix)
   - Move them to the appropriate list (Done, In Progress, Blocked)

This step is best-effort — if Trello sync fails, log a warning and continue.

## Step 8 — Summary

Print a compact summary:

**On main:**
```
✓ Committed: <short hash> <subject>
✓ Pushed to origin/<main_branch>
✓ Backlog synced (N items updated)   ← only if backlog exists
```

**From feature branch:**
```
✓ Committed: <short hash> <subject>
✓ Merged: <feature_branch> → <main_branch>
✓ Pushed to origin/<main_branch>
✓ Deleted: <feature_branch>
✓ Backlog synced (N items updated)   ← only if backlog exists
```

If any files were skipped due to scope filtering, remind the user at the end:
"Note: <N> files with changes were not included (out of scope). Run `/cmp --complete` to include everything."
