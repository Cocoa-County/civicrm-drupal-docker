# Assessor Website 2026 - Docker stack

This docker-compose spins up:
- Drupal 11 FPM (PHP 8.3)
- Nginx web server (serves Drupal via FPM)
- CiviCRM runs within the Drupal container (no separate service)
- MariaDB 10.11
- Adminer (DB UI)
- MailHog (SMTP sink + web UI)

## Quick start

1) Configure environment

Copy one of the examples and adjust values:

```powershell
cp .env.example .env       # for dev
# or
cp .env.prod.example .env  # for production
```

2) Start the stack

```powershell
# From repo root
docker compose --profile dev up -d --build
```

3) Visit apps
- Site: http://localhost:${WEB_PORT:-8080}
- Adminer (dev only): http://localhost:${ADMINER_PORT:-8081} (Server: db, User: ${DB_USER}, Pass: ${DB_PASSWORD}, DB: ${DB_NAME})
- MailHog (dev only): http://localhost:${MAILHOG_HTTP_PORT:-8025}

4) Drupal install
- Use database host `db`, database `drupal`, username `drupal`, password `drupal`.

5) CiviCRM
- Use the Drupal container for CiviCRM CLI/admin tasks. Example:

```powershell
docker compose exec drupal bash
# Inside container, you can run drush/cv once installed, e.g.:
# drush status
# cv --help
```

## Notes
- The repo is bind-mounted into `/var/www/html` in both `drupal` and `web`. Edit code locally and refresh.
- Adjust credentials and exposed ports as needed in `docker-compose.yml`.

### Install CiviCRM into Drupal (example outline)
There are multiple ways to install CiviCRM. One common path is via Composer in a codebase managed locally and mounted into the container.

If you are using the bind-mount (default here), install within the container against `/var/www/html`:

```powershell
docker compose exec drupal bash
# Inside container, at /var/www/html
# Install Composer if not present, then require modules as needed
# Example steps (adjust per your project):
# composer require drush/drush
# composer require civicrm/civicrm-asset-plugin:"^1" --no-plugins
# composer config extra.enable-patching true
# composer require civicrm/civicrm-core:"~5" civicrm/civicrm-packages:"~5" civicrm/civicrm-drupal-8:"~5"
# vendor/bin/drush en -y civicrm
```

For production, prefer a proper Composer-managed code repo on the host, bind-mounted into `/var/www/html`, and a custom image that installs dependencies during build.

### Dev vs Prod
- Dev: use `--profile dev` to include Adminer and MailHog.
- Prod: omit the profile; consider setting `APP_ENV=prod` in `.env` and exposing only `WEB_PORT`.

### AI assistant instructions
See `.github/copilot-instructions.md` for repo-specific conventions and guidance that assistants should follow.
