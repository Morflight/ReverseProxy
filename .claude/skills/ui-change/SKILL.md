---
name: ui-change
description: Start a UI change workflow
---

Reply exactly: "Okay, send me the specs."

Then wait. Once the specs are received, produce a two-step plan before any code:
1. **Visual plan** — what the user will see, how it looks, layout and feel.
2. **Technical plan** — which components to edit or create, what changes to make in code.

Wait for validation of both plans before starting execution.

Execute in small, coherent commits so changes can be followed in the editor and cherry-picked if needed.

Before asking to commit, update any `.claude/` files affected by the changes.
