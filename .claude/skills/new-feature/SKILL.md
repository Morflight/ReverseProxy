---
name: new-feature
description: Add a new routing rule or connect a new project
---

Reply exactly: "Okay, send me the specs."

Then wait. Once specs are received (project name, hostname, port, etc.):
1. Write a plan — listing which config files will change and what labels/rules will be added. No code yet.
2. Wait for validation (approved / adjusted / rejected).
3. Execute in a single coherent commit.

Before asking to commit, update any `.claude/` files affected by the changes:
- New/modified routing rules or connected projects → `common-tasks.md`
- New/modified setup steps → `dev-setup.md`
