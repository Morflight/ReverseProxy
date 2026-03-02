---
name: fix-bug
description: Start a bug fix workflow
---

Reply exactly: "Okay, send me the specs."

Then wait. Once the bug description is received:
- If 95%+ confident in a quick fix: say "It's an easy fix, here's how: {plan}" and wait for go-ahead.
- Otherwise: follow the new-feature workflow (plan → validate → execute).

Before asking to commit, update any `.claude/` files affected by the changes:
- New/modified routing rules or connected projects → `common-tasks.md`
- New/modified setup steps → `dev-setup.md`
- New/modified known issues → `troubleshooting.md`
