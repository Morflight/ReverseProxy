# Common Tasks

## Core Commands

```bash
make create-network             # One-time: create the shared Docker bridge network
make start                      # Start Traefik
make stop                       # Stop Traefik
make deploy                     # Restart Traefik (stop + start)
make generate-certificates-dev  # Generate mkcert TLS certs (requires ENV=dev or local)
```

## Connecting a Project to the Reverse Proxy

Add to the project's `docker-compose.yaml`:

```yaml
networks:
  reverse-proxy:
    external: true
```

Then attach the app container to the network and add Traefik labels, e.g.:

```yaml
services:
  my_service:
    networks:
      - reverse-proxy
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.myapp.rule=Host(`myapp.local.com`)"
      - "traefik.http.routers.myapp.tls=true"
      - "traefik.http.services.myapp.loadbalancer.server.port=8080"
```

Also add `127.0.0.1 myapp.local.com` to `/etc/hosts`.

## Currently Connected Projects

| Hostname                  | Project                        |
|---------------------------|--------------------------------|
| `traefik.local.com`       | Traefik dashboard (this proxy) |
| `bdmapi.local.com`        | BlaguesEtDessinsMobileAPI      |
| `bdmobile.local.com`      | BlaguesEtDessinsMobile (Metro/Expo DevTools) |
| `mailcatcher.local.com`   | Mailcatcher (dev email viewer) |
| `cra.local.com`           | RegaproseCRA                   |

## TLS Certificates (Dev)

```bash
# Generate wildcard cert for *.local.com
make generate-certificates-dev  # requires ENV=dev or ENV=local in .env
```

Uses `mkcert`. Certs stored in `certs/` (gitignored). The Traefik file provider (`docker/ssl.yaml`) points to these certs.

> Never use `*.dev.` as a TLD — it is a protected gTLD.

## Dashboard

Available at `https://traefik.local.com` — protected by htpasswd basic auth.
Credentials from `TRAEFIK_USER_USERNAME`/`TRAEFIK_USER_PASSWORD` in `.env`.
