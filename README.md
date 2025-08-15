# Assessor Website 2026 - Docker stack

This docker-compose spins up:
- Drupal 11 FPM (PHP 8.3)
- Nginx web server (serves Drupal via FPM)
- CiviCRM runs within the Drupal container (no separate service)
- MariaDB 10.11
- Adminer (DB UI)
- MailHog (SMTP sink + web UI)

## Quick start

1) Start the stack

```powershell
# From repo root
docker compose up -d --build
```

2) Visit apps
- Site: http://localhost:8080
- Adminer: http://localhost:8081 (Server: db, User: drupal, Pass: drupal, DB: drupal)
- MailHog: http://localhost:8025

3) Drupal install
- Use database host `db`, database `drupal`, username `drupal`, password `drupal`.

4) CiviCRM
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
