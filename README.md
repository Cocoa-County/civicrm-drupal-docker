# civiccrm-drupal-docker

One-click local deployment for Drupal + CiviCRM using Docker Compose.

This repository is intended to let you create a working Drupal site with CiviCRM installed with a minimal set of steps.

If you just want the fast path (recommended for local development): copy the example env, edit secrets, and run docker compose. The entrypoint script will optionally run a one-time Drupal autoinstall and then a CiviCRM install.

## Checklist (what I'll do in this README)
- Provide a one-click (copy-and-run) deployment path for Windows / PowerShell.
- Explain required environment variables and which ones control automatic install behavior.
- Note common pitfalls and quick troubleshooting steps for database, networking, and logs.

## Quick one-click deploy (PowerShell)

1. Copy the example env and edit any secrets you care about:

```powershell
Copy-Item .env.example .env
# Edit .env with your preferred editor (Notepad, VS Code, etc.)
code .env  # or notepad .env
```

2. Bring up the stack (builds the images the first time):

```powershell
docker compose up -d --build
```

3. Open the site in your browser (default port configured in `.env`):

http://localhost:8080

To stop and remove containers:

```powershell
docker compose down
```

## How the automated installs work

- The container image installs Drupal, Drush and the CiviCRM PHP packages at build time.
- The runtime entrypoint (`docker/drupal-entrypoint.sh`) will:
	- Optionally check the database connection before proceeding.
	- Optionally run `drush site:install` if `AUTO_INSTALL=1` and `settings.php` is not present.
	- Optionally run `cv core:install` to install CiviCRM if `CIVICRM_INSTALL=1`.

Control variables (set in `.env`):

- `AUTO_INSTALL` (0/1) — run `drush site:install` automatically on first container start.
- `AUTO_INSTALL_REQUIRED` (0/1) — if 1, the container will exit non-zero when autoinstall fails.
- `CIVICRM_INSTALL` (0/1) — run `cv core:install` automatically after Drupal is installed.
- `CIVICRM_INSTALL_REQUIRED` (0/1) — if 1, container exits on CiviCRM install failure.
- `SKIP_DB_CHECK` (0/1) — skip the preflight DB check in the entrypoint.
- `DB_REQUIRED` (0/1) — if 1, the entrypoint exits when DB checks fail.

Key log locations inside the container (useful for troubleshooting):

- Drupal autoinstall log: `/var/log/drupal-install.log`
- CiviCRM install log: `/var/log/civicrm-install.log`

## Important networking note (CiviCRM install)

The CiviCRM installer (`cv core:install`) needs a reachable CMS URL. By default the scripts may set a CMS URL like `http://localhost:8080`, but "localhost" inside a container refers to the container itself and not your host. Choose one of these options depending on your needs:

- Recommended for container-internal access (fastest, works inside the compose network): set `CIVICRM_CMS_BASE_URL=http://nginx` in your `.env`. The `nginx` service listens on port 80 inside the Docker network and is reachable by service name.
- If you need the CMS URL to be the host address (so the site is reachable from your browser at that URL), set `CIVICRM_CMS_BASE_URL` to `http://host.docker.internal:8080` on Docker for Windows, or to `http://<your-host-ip>:8080` where `<your-host-ip>` is the host machine IP that the containers can reach.

In short: ensure `CIVICRM_CMS_BASE_URL` is a URL that the install process inside the `drupal` container can reach.

## Common issues & troubleshooting

- Database connection failures
	- Symptoms: entrypoint prints drush errors about connecting to MySQL/MariaDB.
	- Check: `docker logs drupal_db` and `docker inspect` to confirm envs. Confirm `MARIADB_ROOT_PASSWORD`, `MARIADB_DATABASE`, `MARIADB_USER`, `MARIADB_PASSWORD` are set correctly in `.env` and referenced in `docker-compose.yml`.
	- Tip: increase `start_period` / `retries` in the `db` healthcheck if your host is slow.

- CiviCRM installer can't reach the CMS
	- Symptom: cv errors during `cv core:install` complaining about HTTP/connection errors.
	- Fix: set `CIVICRM_CMS_BASE_URL` to a URL reachable from the `drupal` container (see note above).

- File permissions / uploads not writable
	- Ensure `/opt/drupal/web/sites/default/files` (mounted to `/var/www/html/sites/default/files`) is writable by the PHP process. The Dockerfile tries to chown/correct permissions but host mount semantics on Windows can interfere — prefer using the named volume `drupal_data` provided by compose.

- How to inspect installer logs
	- Drupal install log: `docker exec -it drupal_app cat /var/log/drupal-install.log`
	- CiviCRM install log: `docker exec -it drupal_app cat /var/log/civicrm-install.log`

## Environment file

An example `.env.example` is provided in the repository. Copy it to `.env` and edit secrets before running the stack.

## Files of interest

- `docker/Dockerfile` — builds the combined Drupal + CiviCRM runtime image.
- `docker/drupal-entrypoint.sh` — controls DB checks and optional auto-installs.
- `docker-compose.yml` — service definitions and volumes.
- `nginx/default.conf` — nginx configuration used by the `nginx` service.

## Next steps / optional improvements I can add

- Add a lightweight smoke-test (CI) that brings the compose stack up, checks the home page, and then tears it down.
- Add a small `DEVELOPMENT.md` with common drush/composer commands.
- Make the CiviCRM CMS URL auto-detect better (try service name then fall back to host.docker.internal).

Requirements coverage:

- One-click deployment guide: Done (copy .env.example + `docker compose up -d --build`).
- Explain env variables and install flags: Done.
- Troubleshooting notes (DB, networking, logs): Done.

If you want, I can also create a simple `make` or PowerShell script to wrap the copy + up steps into a single command.
