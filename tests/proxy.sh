#!/usr/bin/env bash
# Exercise both overlays in a disposable Compose project. Ports are assigned by Docker.
set -Eeuo pipefail
trap 'echo "Proxy test failed at line $LINENO" >&2' ERR
cd "$(dirname "$0")/.."
tmp=$(mktemp -d)
export COMPOSE_PROJECT_NAME=proxycheck-$(basename "$tmp" | tr -cd 'a-z0-9')
export PROXY_NETWORK=$COMPOSE_PROJECT_NAME
export TRAEFIK_HOSTNAME=dashboard.proxycheck.test ACME_EMAIL=operator@proxycheck.test
export TRAEFIK_USER=$(printf 'test-password\n' | docker run --rm -i --entrypoint htpasswd httpd:2.4-alpine -niB tester)
export COMPOSE_PROFILES=mail,local-test
pebble=ghcr.io/letsencrypt/pebble@sha256:ddf230642b1a584f519f32e347de1b05a6e4c1f6c35c1863b33effeab5f78199
export PEBBLE_IMAGE=$pebble
extra=()
compose() {
  docker compose -f docker-compose.yaml -f "docker-compose.$mode.yaml" \
    -f "$tmp/fixture.yml" "${extra[@]}" "$@"
}
mode=dev
cleanup() {
  compose down --volumes --remove-orphans >/dev/null 2>&1 || true
  docker network rm "$PROXY_NETWORK" >/dev/null 2>&1 || true
  rm -rf -- "$tmp"
}
trap cleanup EXIT
docker network create "$PROXY_NETWORK" >/dev/null
cat > "$tmp/base.yml" <<'YAML'
services:
  traefik:
    environment:
      TRAEFIK_PROVIDERS_DOCKER_CONSTRAINTS: 'Label(`com.docker.compose.project`, `${COMPOSE_PROJECT_NAME}`)'
    ports: !override
      - "127.0.0.1::80"
  web:
    image: nginx:alpine
    networks: [reverse-proxy]
    labels:
      traefik.enable: "true"
      traefik.http.routers.proxycheck-web.rule: 'Host(`${APP_HOST}`) || Host(`admin.${APP_HOST}`)'
      traefik.http.services.proxycheck-web.loadbalancer.server.port: "80"
  auto:
    profiles: [local-test]
    image: nginx:alpine
    networks: [reverse-proxy]
    labels:
      traefik.enable: "true"
  private:
    image: nginx:alpine
    networks: [reverse-proxy]
    labels:
      traefik.http.routers.proxycheck-private.rule: Host(`hidden.localhost`)
YAML
export APP_HOST=proxycheck.localhost
cp "$tmp/base.yml" "$tmp/fixture.yml"
port() { compose port "$1" "$2" | sed 's/.*://'; }
http() { curl --noproxy '*' -fsS --retry 15 --retry-delay 1 --retry-all-errors --max-time 3 --resolve "$1:$httpport:127.0.0.1" "http://$1:$httpport${2:-/}"; }
compose up -d
compose up -d
httpport=$(port traefik 80)
for host in "$APP_HOST" "admin.$APP_HOST"; do http "$host" | grep -q 'Welcome to nginx'; done
http "auto-$COMPOSE_PROJECT_NAME.localhost" | grep -q 'Welcome to nginx'
http traefik.localhost /dashboard/ >/dev/null
http mail.localhost /livez >/dev/null
for host in hidden.localhost unknown.localhost; do
  [[ $(curl --noproxy '*' -s -o /dev/null -w '%{http_code}' -H "Host: $host" "http://127.0.0.1:$httpport/") == 404 ]]
done
compose restart web
http "$APP_HOST" | grep -q 'Welcome to nginx'
echo "PASS local HTTP, nested route, dashboard, Mailpit, private/unknown 404, restart"
if command -v curl.exe >/dev/null; then
  curl.exe --noproxy '*' -fsS "http://admin.$APP_HOST:$httpport/" | grep -q 'Welcome to nginx'
  echo "PASS Windows localhost resolution and HTTP"
fi
compose down
mode=prod
export COMPOSE_PROFILES=
export APP_HOST=proxycheck.test
mkdir -p "$tmp/acme"
id=$(docker create "$pebble")
docker cp "$id:/test/config/pebble-config.json" "$tmp/pebble.json"
docker cp "$id:/test/certs/pebble.minica.pem" "$tmp/ca.pem"
docker rm "$id" >/dev/null
python3 - "$tmp/pebble.json" <<'PY'
import json, sys
from pathlib import Path
p = Path(sys.argv[1])
config = json.loads(p.read_text())
config["pebble"]["httpPort"] = 80
p.write_text(json.dumps(config))
PY
# Replace only the test port mappings and ACME directory. Real HTTP-01 validation
# runs across the isolated Docker network using the router hostnames as aliases.
export TEST_DIR=$tmp
cat > "$tmp/prod-fixture.yml" <<'YAML'
services:
  traefik:
    environment:
      TRAEFIK_CERTIFICATESRESOLVERS_LETSENCRYPT_ACME_CASERVER: https://pebble:14000/dir
      LEGO_CA_CERTIFICATES: /test-ca.pem
    ports: !override
      - "127.0.0.1::80"
      - "127.0.0.1::443"
    volumes:
      - "${TEST_DIR}/acme:/etc/traefik/acme"
      - "${TEST_DIR}/ca.pem:/test-ca.pem:ro"
    networks:
      reverse-proxy:
        aliases: [proxycheck.test, admin.proxycheck.test, dashboard.proxycheck.test]
  pebble:
    image: ${PEBBLE_IMAGE}
    command: ["-config", "/fixture.json"]
    environment:
      PEBBLE_VA_NOSLEEP: "1"
      PEBBLE_WFE_NONCEREJECT: "0"
    volumes:
      - "${TEST_DIR}/pebble.json:/fixture.json:ro"
    networks: [reverse-proxy]
    ports: ["127.0.0.1::15000"]
YAML
extra=(-f "$tmp/prod-fixture.yml")
compose up -d pebble
compose up -d
httpport=$(port traefik 80)
httpsport=$(port traefik 443)
[[ $(curl --noproxy '*' -s -o /dev/null -w '%{redirect_url}' --retry 10 --retry-connrefused -H "Host: $APP_HOST" "http://127.0.0.1:$httpport/hello") == "https://$APP_HOST/hello" ]]
curl --noproxy '*' -kfsS "https://127.0.0.1:$(port pebble 15000)/roots/0" > "$tmp/root.pem"
tls() { curl --noproxy '*' --cacert "$tmp/root.pem" --resolve "$1:$httpsport:127.0.0.1" "https://$1:$httpsport${2:-/}" "${@:3}"; }
for i in {1..60}; do
  if tls "$APP_HOST" / -fs >/dev/null; then break; fi
  sleep 1
done
tls "$APP_HOST" / -fsS | grep -q 'Welcome to nginx'
tls "admin.$APP_HOST" / -fsS | grep -q 'Welcome to nginx'
[[ $(tls "$TRAEFIK_HOSTNAME" /dashboard/ -s -o /dev/null -w '%{http_code}') == 401 ]]
tls "$TRAEFIK_HOSTNAME" /dashboard/ -fsS -u tester:test-password >/dev/null
# A fresh container must serve trusted TLS using only persisted ACME state.
compose stop pebble
compose up -d --no-deps --force-recreate traefik
httpsport=$(port traefik 443)
tls "$APP_HOST" / -fsS --retry 10 --retry-all-errors --retry-delay 1 | grep -q 'Welcome to nginx'
tls "admin.$APP_HOST" / -fsS | grep -q 'Welcome to nginx'
echo "PASS production redirect, ACME HTTP-01, trusted TLS for both names, dashboard auth and proxy restart"
