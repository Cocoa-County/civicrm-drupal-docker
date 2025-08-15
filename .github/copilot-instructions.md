# Repository instructions for AI assistants

Purpose: Help code assistants follow project conventions and avoid common pitfalls.

## Tech stack
- Drupal 11 (PHP 8.3) via FPM
- Nginx as web server
- MariaDB, Adminer (dev only), MailHog (dev only)
- Docker Compose with `.env`-driven config and dev/prod profiles

## Conventions
- Do not mount the project root. Mount only:
  - `./web -> /var/www/html/web`
  - `./vendor -> /var/www/html/vendor`
- Writable path uses a named volume:
  - `files-data -> /var/www/html/web/sites/default/files`
- CiviCRM runs inside the Drupal container (no separate CiviCRM web service).
- Use `.env` for config. Dev services (Adminer, MailHog) are behind the `dev` profile.
- Prefer Windows PowerShell commands in docs and examples.

## Compose expectations
- Web: Nginx serves from `/var/www/html/web`; PHP-FPM upstream is `drupal:9000`.
- DB host is `db`; default creds come from `.env`.
- Dev profile exposes:
  - Site: `http://localhost:${WEB_PORT}`
  - Adminer: `http://localhost:${ADMINER_PORT}`
  - MailHog: `http://localhost:${MAILHOG_HTTP_PORT}`

## Do
- Keep changes minimal and scoped.
- Validate with `docker compose config` after editing compose files.
- Use `.env` variables in compose instead of hardcoding.
- Use bind mounts read-only for code, named volume for writable files.

## Don’t
- Don’t mount the repository root into containers.
- Don’t introduce a separate web container for CiviCRM.
- Don’t commit real `.env` files; use example files instead.

## Useful commands (PowerShell)
```powershell
# Dev up
docker compose --profile dev up -d --build

# Prod up
docker compose up -d --build

# Shell into PHP container
docker compose exec drupal bash

# Validate compose
docker compose config
```

## Notes
- If you add features (e.g., Xdebug), guard them behind an env flag and/or the `dev` profile.
- Prefer Composer-managed workflows for Drupal/CiviCRM installation.
