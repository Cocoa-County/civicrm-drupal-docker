## Overview
This repository builds a small Drupal + CiviCRM stack using a multi-stage `Dockerfile` (builder + runtime) and a `docker-compose.yml` orchestration file. The entrypoint performs a one-time site install (Drupal and CiviCRM), injects a `settings.docker.php` include into `settings.php`, and supports environment-driven runtime settings like trusted hosts and hash salt.

## Quick start
1. Copy the example env file and edit values as needed:

```powershell
Copy-Item .env.example .env -Force
# Edit .env with your editor of choice
code .env
```

2. Build and start the stack:

```powershell
docker compose up --build -d
```

3. Watch logs while the first-time install runs:

```powershell
docker compose logs -f drupal
# Or tail the install logs from inside the container
docker compose exec drupal powershell -Command "bash -lc 'tail -f /var/log/drupal-install.log /var/log/civicrm-install.log'"
```

4. Stop the stack:

```powershell
docker compose down
```

## Important environment variables
Create or edit `./.env` (copy from `./.env.example`). Below are the primary variables the compose file and entrypoint use.

| Variable | Default | Purpose |
|---|---:|---|
| `DB_HOST` | `db` | Database host (compose service name) |
| `DB_PORT` | `3306` | Database port |
| `DB_NAME` | `drupal` | Database name used by Drupal/CiviCRM |
| `DB_USER` | `drupal` | DB username |
| `DB_PASSWORD` | `drupal` | DB password (keep secrets out of VCS) |
| `DB_ROOT_PASSWORD` | `drupal` | MariaDB root password |
| `NGINX_PORT` | `8080` | Host port mapped to the nginx service |
| `DRUPAL_INSTALL_LOG` | `/var/log/drupal-install.log` | Path where drupal install output is written inside the container |
| `DRUPAL_SITE_NAME` | `Drupal Site` | Site name for automated install |
| `DRUPAL_ADMIN_USER` | `admin` | Admin username for automated install |
| `DRUPAL_ADMIN_PASSWORD` | `admin` | Admin password for automated install |
| `DRUPAL_TRUSTED_HOSTS` | `localhost` | Comma-separated list of trusted hosts; supports `*` wildcards; used by `settings.docker.php` |
| `DRUPAL_HASH_SALT` | (none) | Drupal `hash_salt` — can also be provided via Docker secrets at `/run/secrets/drupal_hash_salt` or `/run/secrets/hash_salt` |
| `DRUPAL_CONFIG_SYNC_DIR` | (none) | Path to config sync directory inside container |
| `CIVICRM_INSTALL_LOG` | `/var/log/civicrm-install.log` | Path where CiviCRM install output is written inside the container |
| `CIVICRM_URI` | `http://localhost:$NGINX_PORT` | CMS base URL provided to CiviCRM on install |

Notes:
- Keep production secrets out of version control. Use a secrets manager or Docker secrets when possible. `settings.docker.php` will read `DRUPAL_HASH_SALT` from env or from `/run/secrets/drupal_hash_salt` (or `/run/secrets/hash_salt`).
- `DRUPAL_TRUSTED_HOSTS` accepts comma-separated values; `settings.docker.php` converts them into Drupal trusted host regex patterns and supports wildcard entries like `*.example.org`.

## Useful commands

- Rebuild the PHP image and restart (useful after code or Dockerfile changes):

```powershell
docker compose up --build -d --force-recreate
```

- Enter the Drupal container shell:

```powershell
docker compose exec drupal bash
```

- Run Drush inside the container (example: cache rebuild):

```powershell
docker compose exec drupal bash -lc 'drush cr'
```

- Run CiviCRM CLI (`cv`) inside the Drupal root:

```powershell
docker compose exec drupal bash -lc 'cd /var/www/html && cv status'
```

## Troubleshooting notes
- If the first-time install fails, check the logs (`/var/log/drupal-install.log`, `/var/log/civicrm-install.log`) and container logs (`docker compose logs drupal`). The entrypoint writes a marker file at `sites/default/.docker_install_complete` after it runs once; remove it to re-run installs.
- On Windows Git, you may see a warning about line endings when committing shell scripts — this warning does not affect container execution, but you can normalize line endings if desired.

## References
- See `docker/Dockerfile` for build/runtime details and `docker/drupal-entrypoint.sh` for install/startup behavior. `docker/settings.docker.php` contains the runtime setting injection logic used by Drupal.
