# Local Context

## Screenshots

Pasted images (from terminal paste) land in `~/.cp-images/`, not in the project directory. When the user pastes a screenshot, look for it there.

## No Local Runtimes

Never assume `node`, `npm`, `npx`, `php`, `composer`, `python`, or any other runtime is installed on the host. Everything runs through Docker containers.

- **Node/npm/npx**: `docker compose exec <node-container> npm ...` or `docker compose run --rm <node-container> npx ...`
- **PHP/Composer**: `docker compose exec <php-container> php ...` or `docker compose exec <php-container> composer ...`
- **Python/pip**: `docker compose exec <python-container> python ...`

Use `Makefile` targets when available — they already wrap the container commands.
