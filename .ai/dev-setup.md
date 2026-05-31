# Dev Setup

## Prerequisites

- Docker, Docker Compose, Make
- `mkcert` installed (for TLS certs in dev): `sudo apt install mkcert` or via `brew install mkcert`

## First-Time Setup

```bash
# 1. Create the shared Docker network (once per machine)
make create-network

# 2. Copy and fill env file (auto-done by Makefile if missing)
cp .env.dist .env
# Fill in TRAEFIK_USER_USERNAME, TRAEFIK_USER_PASSWORD, ACME_EMAIL

# 3. Generate TLS certificates (dev only)
# Set ENV=dev in .env first
make generate-certificates-dev

# 4. Start the proxy
make start
```

## Environment Variables (`.env`)

| Variable                  | Description                                              |
|---------------------------|----------------------------------------------------------|
| `ENV`                     | `dev` / `local` / `prod`                                 |
| `TRAEFIK_USER_USERNAME`   | Dashboard basic auth username                            |
| `TRAEFIK_USER_PASSWORD`   | Dashboard basic auth password (plaintext, hashed by make)|
| `ACME_EMAIL`              | Email for Let's Encrypt (prod only)                      |

## DNS

Add to `/etc/hosts` for each project and for the dashboard:

```
127.0.0.1 traefik.local.com
127.0.0.1 mailcatcher.local.com
127.0.0.1 bdmapi.local.com
127.0.0.1 cra.local.com
```

## Config Files

| File                    | Description                                                  |
|-------------------------|--------------------------------------------------------------|
| `docker/traefik.yaml`   | Static config: entrypoints, Docker provider, ACME resolver   |
| `docker/ssl.yaml`       | TLS file provider (dev certs, gitignored)                    |
| `docker-compose.yaml`   | Base Traefik service definition                              |
| `docker-compose.dev.yaml` | Dev overlay (mounts dev certs, dev-specific config)        |

## Environments

- **dev / local**: uses mkcert self-signed certs from `certs/`
- **prod**: uses Let's Encrypt ACME; state stored in `acme/acme.json` (gitignored)

## Gotchas

> Populate as setup issues are discovered.
