# ReverseProxy

Codex entry point for this project.

Read `.ai/README.md` first, then `CLAUDE.md` for the current project overview, commands, stack details, and architecture. This stack provides the shared `reverse-proxy` Docker network, Traefik routing, TLS, and Mailcatcher for hostname-based local projects.

Start this project before dependent local web stacks and stop it last.

Treat `.claude/settings*.json` as legacy Claude configuration only.

## Shared AI Docs

Read `.ai/README.md` first for harness-neutral project knowledge. Prefer `.ai/*.md` over duplicated legacy `.claude/*.md` docs when both exist. Keep `.claude/**` for Claude-native commands, settings, hooks, skills, and legacy material.
