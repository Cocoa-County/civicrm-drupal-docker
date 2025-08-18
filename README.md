# civiccrm-drupal-docker

Minimal Docker Compose setup to run Drupal + CiviCRM-related code locally.

## Quick start

1. Create a `.env` file at the repo root with these values (example):

```
DB_NAME=drupal
DB_USER=drupal
DB_PASSWORD=drupal_password
DB_ROOT_PASSWORD=root_password
PORT_HTTP=8080
```

2. Build and start:

```
# PowerShell
docker compose up -d --build
```

3. Open http://localhost:8080 (or the port in `PORT_HTTP`).

Stop the stack:

```
# PowerShell
docker compose down
```

## What the compose file provides

- `drupal` — built from `docker/Dockerfile`, with site code mounted at `/var/www/html` (see `web/`).
- `db` — MariaDB (persistent via `db_data`).
- `nginx` — Nginx proxy serving the site on the host port.

## Important files

- `docker/Dockerfile` — builds the runtime image.
- `docker-compose.yml` — service wiring and volumes.
- `nginx/default.conf` — nginx config.

## Notes

- The compose file currently mounts `web/composer.json` and `web/composer.lock` into the container; keep those files present.
- On Windows, bind mounts can cause file-permission issues; using the named `drupal_data` volume avoids those issues.
- CI builds the image on push (see `.github/workflows/docker-image.yml`).

## Want more?

I can add a `.env.example`, a short `DEVELOPMENT.md` (composer/drush tips), or a CI smoke-test step — tell me which and I'll add it.
