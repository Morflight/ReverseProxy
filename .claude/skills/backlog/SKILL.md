---
name: backlog
description: View, add, update, or prioritize items in this project's development backlog. Use /backlog to see what's next, /backlog add "item" to queue work, /backlog done ID to mark complete, /backlog priority ID high/medium/low to reprioritize.
---

## Context

The backlog file lives at `.claude/backlog.md` inside this project.

If the backlog file does not exist and the user runs `add`, create it with the standard template (see Bootstrapping below). For all other actions on a missing backlog, tell the user: "No backlog found at `.claude/backlog.md`. Run `/backlog add "first item"` to create one."

## Usage

Parse the user's arguments to determine the action:

- **No args / `show` / `next`** — Display the backlog grouped by priority, showing status tags
- **`add "description"` [priority] [category]** — Add a new item to the backlog
- **`done ID`** — Mark an item as `done` with today's date and move it to the Done section
- **`feedback ID`** — Mark an item as `feedback` (awaiting user review)
- **`start ID`** — Mark an item as `in-progress`
- **`block ID` [reason]** — Mark an item as `blocked`, optionally noting what it's blocked by
- **`priority ID high/medium/low`** — Change an item's priority (move it to the correct section)
- **`detail ID`** — Show full details for an item including notes and references
- **`sprint`** — Show only `ready` and `in-progress` items (current work focus)
- **`remove ID`** — Remove an item entirely from the backlog
- **`init-product <ProductName>`** — Create the shared Trello board for a Product (multi-project) declared in `Dev/.claude/projects.md`, save the board ID inline in `projects.md`, and sync existing backlog items from every member project with their per-project prefixes

## Step 1 — Read the backlog

Read `.claude/backlog.md` from the project root.

## Step 2 — Execute the action

### For `show` / no args:
Display the backlog in a clean table format grouped by priority (high -> medium -> low). Show:
- ID, title, status, category, and any blocking dependencies
- Count of items per priority and total
- Skip the Done section unless explicitly requested (`show all` or `show done`)

### For `add`:
- Scan all existing IDs (B-NNN format) across all sections including Done
- Generate the next sequential ID
- Append to the appropriate priority section in backlog.md
- Default status: `ready`
- Default priority: `medium`
- Default category: `core`

### For `done`:
- Find the item by ID in backlog.md
- Change its status to `done`
- Remove it from its current priority section
- Add it to the Done table at the bottom with today's date

### For `start` / `block` / `priority`:
- Find the item by ID in backlog.md
- Update its status or priority field
- For `priority`: move the row to the correct priority section

### For `detail`:
- Show the full item row plus any Ref file contents if a design doc is referenced

### For `sprint`:
- Filter to only `in-progress` and `ready` items
- Sort by priority (high first), then by status (`in-progress` before `ready`)

### For `remove`:
- Find the item by ID and remove the entire row
- Confirm with the user before deleting: "Remove B-NNN '<title>' from backlog?"

## Step 3 — Write changes

If any modifications were made, write the updated backlog.md back to disk. Preserve the file's existing structure, header, and formatting.

## Customization

Projects can customize this skill freely:
- **Categories** — change the default and add project-specific values (e.g. `combat`, `meta`, `polish` for a game; `api`, `ui`, `auth` for a web app)
- **Priority definitions** — adjust what each priority level means for this project
- **ID prefix** — default is `B-NNN`, can be changed per project
- **Extra columns** — add project-specific columns to the backlog table (e.g. `Ref` for design doc links)

## Bootstrapping

When creating a new backlog (first `add` on a project with no backlog), use this template:

```markdown
# <Project Name> — Development Backlog

> Status: `ready` | `in-progress` | `blocked` | `done`
> Priority: high (critical blocker), medium (important), low (future/polish)

---

## High Priority

| ID | Title | Status | Category | Ref | Notes |
|----|-------|--------|----------|-----|-------|

## Medium Priority

| ID | Title | Status | Category | Ref | Notes |
|----|-------|--------|----------|-----|-------|

## Low Priority

| ID | Title | Status | Category | Ref | Notes |
|----|-------|--------|----------|-----|-------|

## Done

| ID | Title | Completed | Notes |
|----|-------|-----------|-------|
```

## Formatting

When displaying the backlog, use this format:
```
## High Priority
ID     | Title                        | Status      | Category
B-001  | Fix login redirect           | ready       | core
B-002  | API rate limiting            | in-progress | api

## Medium Priority
...

---
3 high, 5 medium, 2 low — 10 items total (2 in-progress)
```

Status values: `ready`, `in-progress`, `blocked`, `done`

## Step 4 — Trello Sync (optional)

After writing changes to `backlog.md`, sync the change to Trello if configured.

### Prerequisites check

1. Load Trello credentials from the encrypted file at the Dev workspace root:
```bash
eval $(sops --decrypt /home/osboxes/Documents/Dev/envs/trello.enc.yaml 2>/dev/null | sed 's/: /=/' | sed 's/^/export /')
```
If the file doesn't exist or decryption fails, **skip this step silently**.

2. Resolve the board ID and card prefix for the current project. Resolution order:

   **(a) Product membership (preferred)** — read `Dev/.claude/projects.md`, parse the `## Products` section. If the current project's directory name appears in any product's `Members:` line as `ProjectName (PREFIX)`:
   - `TRELLO_BOARD_ID` = the product's `Trello board:` value (skip if unset, log a hint to run `/backlog init-product <ProductName>`)
   - `CARD_PREFIX` = the per-project `PREFIX` token

   **(b) Legacy per-project board** — if the project is not in any Product, fall back to `.claude/trello-board-id` in the project root:
   - `TRELLO_BOARD_ID` = file contents
   - `CARD_PREFIX` = empty (cards stay `[B-NNN]` for backwards compatibility)

   **(c) None** — no Trello sync, **skip silently**.

### `init-product <ProductName>` command

Creates the shared Trello board for a multi-project Product and syncs every member project's existing backlog items.

**Step 1 — Look up the product:**
Read `Dev/.claude/projects.md`, parse the `## Products` section, find the entry matching `<ProductName>`. If absent, fail with a message asking the user to declare it first.

**Step 2 — Check if already initialized:**
If the product's `Trello board:` line already contains a board ID, refuse unless `--force`.

**Step 3 — Create the board:**
```bash
curl -s -X POST "https://api.trello.com/1/boards/?key=${TRELLO_API_KEY}&token=${TRELLO_TOKEN}" \
  --data-urlencode "name=<ProductName>" \
  -d "defaultLists=false" \
  -d "defaultLabels=false"
```
(Board name is the bare product name, no " — Backlog" suffix.)

**Step 4 — Create lists** (reverse order for left-to-right display):
Done, Feedback, Blocked, In Progress, Ready — each with `pos=top`.

**Step 5 — Create priority labels:**
`high` = red, `medium` = yellow, `low` = green.

**Step 6 — Write the board ID back into `Dev/.claude/projects.md`** in-place under the product's `Trello board:` line, replacing the `_(unset — ...)_` placeholder with the new ID.

**Step 7 — Initial sync:** for each member listed under the product, read `Projects/<member>/.claude/backlog.md` and create one card per item with the per-member prefix in the card name (`[<PREFIX>-B-NNN] Title`), placed on the matching list with the matching priority label.

**Step 8 — Report** with board URL and per-member sync counts.

### Card identity

Cards are identified by the prefixed backlog ID in the card name:
- **In a Product:** `[BDMAPI-B-001] Title` — the prefix tells future agents which member project owns the card
- **Legacy single-project board:** `[B-001] Title` — preserved for backwards compatibility on boards predating the Product model

### Sync actions

| Backlog action | Trello action |
|----------------|---------------|
| `add` | Create card on Ready list with priority label, name `[<PREFIX>-]B-NNN Title` |
| `start` | Move card to In Progress list |
| `done` | Move card to Done list |
| `feedback` | Move card to Feedback list (awaiting user review) |
| `block` | Move card to Blocked list, append reason to description |
| `priority` | Update card label |
| `remove` | Archive card |

Card lookup uses the full prefixed ID (e.g. `[BDMAPI-B-001]`) so two members of the same Product can both have a `B-001` without collision.

### Error handling

Trello sync is **best-effort**. If any API call fails, log a one-line warning. Never retry or block the local update. `backlog.md` is always the source of truth.

### Future: inbound sync

> **Not yet implemented.** A future `triage` command will pull new Trello cards (e.g. customer tickets, external requests) that were created directly on the board, and present them for qualification: accept into a member project's backlog (assign priority/category and project), defer, or reject. This enables non-technical stakeholders to submit work via Trello while the backlog files remain the source of truth. Card identity via `[<PREFIX>-B-NNN]` already distinguishes managed cards from external ones — external cards won't have the prefix at all, and the agent task router uses `<PREFIX>` to know which project a card belongs to.
