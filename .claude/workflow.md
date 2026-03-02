# Development Workflow

Use slash commands to start a workflow:

- `/fix-bug` — start a bug fix (routing issue, config problem, cert error)
- `/new-feature` — add support for a new project or routing rule

## New Feature / Routing Rule

1. **Create a branch** — `git checkout master && git pull && git checkout -b feat/<kebab-case-name>`
2. Receive specs (which project, which hostname, what routing needed)
3. Write a plan — listing what config files will change — no code yet
4. Wait for validation (approved / adjusted / rejected)
5. Execute in a single coherent commit (infra changes are usually atomic)

## Bug Fix

1. **Create a branch** — `git checkout master && git pull && git checkout -b fix/<kebab-case-name>`
2. Receive bug description
3. If 95%+ confident in a quick fix: "It's an easy fix, here's how: {plan}" and wait for go-ahead
4. Otherwise: follow the feature workflow (plan → validate → execute)

## Execution Rules

- Always start from an up-to-date `master` — pull before branching
- Never write code before a plan is validated
- Before asking to commit, update any `.claude/` files affected by the changes:
  - New/modified routing rules or connected projects → `common-tasks.md`
  - New/modified setup steps → `dev-setup.md`
