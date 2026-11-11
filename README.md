# ReverseProxy

Run one proxy per Docker host. In WSL, `make start` creates the shared network and starts Traefik. Open http://traefik.localhost/dashboard/ from Windows. Local routes use HTTP on loopback. Run `make smoke` to check the dashboard, or `./check.sh http://app.localhost/health` to check an app. Set HTTP_PORT to test on a different port.

## Route an app

Attach the web service to its private network and the external proxy network. Give each router and service a unique name. Set APP_HOST to `app.localhost` locally and the public DNS name on the server.

```yaml
services:
  web:
    image: nginx:alpine
    networks: [default, reverse-proxy]
    labels:
      traefik.enable: "true"
      traefik.http.routers.myapp.rule: Host(`${APP_HOST:?Set APP_HOST}`)
      traefik.http.services.myapp.loadbalancer.server.port: "80"

networks:
  reverse-proxy:
    external: true
```

Local opt-in containers without a Host rule receive a hostname based on Traefik's normalized Docker service name plus `.localhost`. Set an explicit rule for stable or nested names. For existing apps, move hard-coded entrypoint, TLS and certresolver labels out of the shared app definition when migrating. The proxy supplies these settings per environment.

## Local mail

`COMPOSE_PROFILES=mail make start` adds Mailpit. Use http://mail.localhost and SMTP at `mail:1025` on the shared network. The legacy SMTP alias is `mailcatcher`.

## Production

Set ENV=prod, TRAEFIK_HOSTNAME, ACME_EMAIL, TRAEFIK_USER_USERNAME and TRAEFIK_USER_PASSWORD in the deployment environment. Existing SOPS-based deployments can supply these values. Alternatively supply TRAEFIK_USER as a precomputed htpasswd entry. Point public DNS at the server and allow inbound TCP 80 and 443. Run `make deploy`. Traefik redirects HTTP, issues per-host certificates via HTTP-01, and stores them in `acme/acme.json`. Preserve this directory when rolling back or changing releases. The HTTPS dashboard requires authentication. Supply a public app health URL to `make smoke SMOKE_URL=https://app.example.org/health`.

`make stop` stops this Compose stack. Other projects can continue using the external Docker network.

## Test both environments

Run `tests/proxy.sh` with Docker Compose 2.24.4 or later, curl and Python 3. It uses a temporary Docker network, loopback ports and a local Pebble ACME authority to exercise HTTP-01. On WSL it also probes a nested localhost name with Windows curl when available.
