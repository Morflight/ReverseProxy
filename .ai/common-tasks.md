# Common tasks

Use the root README for the start, stop, route, mail and smoke commands. Run `tests/proxy.sh` to validate local HTTP and production TLS in an isolated Compose project.

## Legacy routes to check during migration

| Hostname                  | Project                        |
|---------------------------|--------------------------------|
| `traefik.local.com`       | Traefik dashboard (this proxy) |
| `bdmapi.local.com`        | BlaguesEtDessinsMobileAPI      |
| `bdmobile.local.com`      | BlaguesEtDessinsMobile (Metro/Expo DevTools) |
| `mailcatcher.local.com`   | Mailcatcher (dev email viewer) |
| `cra.local.com`           | RegaproseCRA                   |
