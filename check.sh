#!/usr/bin/env bash
set -euo pipefail

url=${1:-http://traefik.localhost/dashboard/}
options=()
# Some WSL resolvers lack wildcard localhost support. Preserve the HTTP Host header.
if [[ $url =~ ^http://([[:alnum:].-]+\.localhost)(:([0-9]+))?(/|$) ]]; then
  host=${BASH_REMATCH[1]}
  port=${BASH_REMATCH[3]:-80}
  options+=(--noproxy "$host" --resolve "$host:$port:127.0.0.1")
fi
status=$(curl "${options[@]}" --silent --show-error --max-time 8 \
  --output /dev/null --write-out '%{http_code}' "$url")
printf 'HTTP %s from %s\n' "$status" "$url"
[[ $status == 2?? ]]
