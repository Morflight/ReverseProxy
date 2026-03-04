# Fix Routing Issue

Let's debug a routing or TLS problem. Use with `/fix-bug`.

## What should happen
<!-- e.g. https://myproject.local.com should reach the project's nginx container -->

## What actually happens
<!-- e.g. 404 from Traefik, TLS error, connection refused, redirect loop -->

## Affected hostname
<!-- The hostname that is misbehaving -->

## Steps to reproduce
<!-- Browser URL, curl command, etc. -->
```bash
curl -sk https://affected.local.com
```

## Traefik logs
<!-- Run: docker logs traefik_traefik --tail 50 -->
```

```

## Container status
<!-- Run: docker ps --format "table {{.Names}}\t{{.Status}}" -->
```

```

## Network check
<!-- Run: docker inspect <affected_container> | grep -A10 reverse-proxy -->
```

```

## What I've already tried

## Acceptance criteria
- [ ]
- [ ]
