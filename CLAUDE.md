# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

A local Traefik v3.1.4 reverse proxy that routes Docker-based development projects by hostname. It provides a shared network that other project stacks attach to, eliminating port-mapping conflicts across concurrent projects.

## Commands

```bash
make create-network            # One-time: create the shared Docker bridge network
make start                     # Start Traefik (run after each machine restart)
make stop                      # Stop Traefik
make deploy                    # Stop then start (restart)
make generate-certificates-dev # Generate mkcert TLS certs (requires ENV=dev or local)
```

`.env` is auto-created from `.env.dist` on first `make` invocation.

## Architecture

**Traffic flow:** All HTTP (`:80`) is redirected to HTTPS (`:443`). Traefik reads Docker labels from containers on the `reverse-proxy` network and routes requests based on hostname rules.

**Configuration files:**
- `docker/traefik.yaml` — Main Traefik static config: entrypoints, Docker provider (watches `docker.sock`), file provider, and Let's Encrypt ACME resolver
- `docker/ssl.yaml` — TLS file provider pointing to `certs/cert.pem` and `certs/cert-key.pem` (dev only, git-ignored)

**Connecting other projects:** Other `docker-compose.yaml` stacks join the reverse proxy by declaring the external network and adding Traefik labels:
```yaml
networks:
  reverse-proxy:
    external: true
```

**Dashboard:** Available at `https://traefik.local.com` (add `127.0.0.1 traefik.local.com` to `/etc/hosts`), protected by htpasswd basic auth generated from `TRAEFIK_USER_USERNAME`/`TRAEFIK_USER_PASSWORD` in `.env`.

**Environments:**
- `dev`/`local`: uses mkcert self-signed certs (`certs/`)
- `prod`: uses Let's Encrypt ACME via `ACME_EMAIL`; ACME state stored in `acme/acme.json` (git-ignored)

**DNS note:** Never use `*.dev.` as a TLD — it is a protected gTLD and will cause resolution issues.
