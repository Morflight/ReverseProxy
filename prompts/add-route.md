# Add Route / Connect a Project

Let's connect a new project to the reverse proxy. Use with `/new-feature`.

## Project name
<!-- e.g. MyNewProject -->

## Hostname
<!-- e.g. mynewproject.localhost locally and the public DNS name in production -->

## Container to route to
<!-- The nginx or server container that should receive traffic, e.g. mynewproject_nginx -->

## Internal port
<!-- The port the container listens on internally, e.g. 80 -->

## Docker network
<!-- Usually `reverse-proxy` — confirm the project joins this external network -->

## Environment
<!-- dev (HTTP) / prod (Let's Encrypt) / both -->

## Already done
<!-- Has the project already been added to the reverse-proxy network in its docker-compose? -->

## Notes
<!-- Any special routing rules: path prefix, middleware, basic auth, etc. -->
