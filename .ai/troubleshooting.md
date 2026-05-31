# Troubleshooting

## Traefik dashboard shows no services / routes

- Check that the target containers are on the `reverse-proxy` network
- Verify `traefik.enable=true` label is set on the container
- Check that the `reverse-proxy` network exists: `docker network ls | grep reverse-proxy`
- Restart Traefik: `make deploy`

## Certificate errors in browser

- Make sure `mkcert -install` was run to trust the local CA
- Regenerate certs: `make generate-certificates-dev`
- Ensure `ENV=dev` or `ENV=local` is set in `.env`

## `*.dev.` TLD resolution issues

Never use `.dev` as a TLD. It is a protected gTLD and browsers enforce HTTPS for it. Use `.local.com` instead.

> Populate as further issues and solutions are discovered.
