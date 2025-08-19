#!/bin/bash
set -e

# Print basic container info
echo "Container started: $(date)"
echo "Hostname: $(hostname)"
echo "User: $(whoami)"
echo "Working directory: $(pwd)"
echo "PHP version: $(php -v | head -n 1)"

# Check if Drush is installed
if command -v drush >/dev/null 2>&1; then
	echo "Drush is installed: $(drush --version | head -n 1)"

	# Configuration: allow overriding via environment variables
	# New variable: SKIP_DB_CHECK (preferred). Legacy: SKIP_DB_WAIT
	SKIP_DB_CHECK=${SKIP_DB_CHECK:-${SKIP_DB_WAIT:-0}}
	# If set to 1, exit with non-zero code when DB check fails
	DB_REQUIRED=${DB_REQUIRED:-0}

	if [ "${SKIP_DB_CHECK}" = "1" ]; then
		echo "SKIP_DB_CHECK=1; skipping database connection check."
	else
		echo "Checking database connection once using drush..."
	# Run a single check; capture stderr for debugging and allow the command to fail
	set +e
	# Capture stderr into a variable while silencing stdout. Order matters:
	# `2>&1 >/dev/null` routes stderr into stdout (which is captured by the
	# command substitution) and sends stdout to /dev/null — this captures only
	# the error output in the variable.
	drush_err=$(drush sql:query "SELECT 1" 2>&1 >/dev/null || true)
		rc=$?
		set -e
		if [ $rc -eq 0 ]; then
			echo "Database connection OK. Continuing startup."
		else
			echo "Warning: drush could not connect to the database (exit code: $rc)."
			if [ -n "${drush_err}" ]; then
				echo "drush error output:"
				echo "${drush_err}"
			fi
			if [ "${DB_REQUIRED}" = "1" ]; then
				echo "DB_REQUIRED=1 — exiting with failure."
				exit 1
			else
				echo "Continuing startup despite DB check failure."
			fi
		fi
	fi
else
	echo "Warning: Drush is not installed!"
fi

# If requested, attempt a one-time automated Drupal site install using drush
# Controlled via environment variables:
# AUTO_INSTALL=1           -> run autoinstall
# AUTO_INSTALL_REQUIRED=1  -> exit with failure if autoinstall fails
# DRUPAL_SITE_NAME, ADMIN_USER, ADMIN_PASS
if [ "${AUTO_INSTALL:-0}" = "1" ]; then
	echo "AUTO_INSTALL=1; attempting Drupal autoinstall."
	# Defaults
	DRUPAL_SITE_NAME=${DRUPAL_SITE_NAME:-"Drupal Site"}
	ADMIN_USER=${ADMIN_USER:-admin}
	ADMIN_PASS=${ADMIN_PASS:-admin}
	DRUSH_ROOT=${DRUSH_ROOT:-/var/www/html}

	# If settings.php exists, assume site is already installed
	if [ -f "${DRUSH_ROOT}/sites/default/settings.php" ]; then
		echo "Found existing settings.php at ${DRUSH_ROOT}/sites/default/settings.php — skipping autoinstall."
	else
		# Build DB URL from environment variables commonly provided by compose
		DB_HOST=${DRUPAL_DB_HOST:-db}
		DB_PORT=${DRUPAL_DB_PORT:-3306}
		DB_NAME=${DRUPAL_DB_NAME:-${DB_NAME}}
		DB_USER=${DRUPAL_DB_USER:-${DB_USER}}
		DB_PASS=${DRUPAL_DB_PASSWORD:-${DB_PASSWORD}}
		DB_URL="mysql://${DB_USER}:${DB_PASS}@${DB_HOST}:${DB_PORT}/${DB_NAME}"

	# Avoid printing the DB password to logs; show a masked URL instead.
	DB_URL_MASK="mysql://${DB_USER}:****@${DB_HOST}:${DB_PORT}/${DB_NAME}"
	echo "Running drush site:install with DB URL: ${DB_URL_MASK} (root: ${DRUSH_ROOT})"
		set +e
		install_err=$(drush site:install standard --db-url="${DB_URL}" --site-name="${DRUPAL_SITE_NAME}" --account-name="${ADMIN_USER}" --account-pass="${ADMIN_PASS}" --yes --root="${DRUSH_ROOT}" 2>&1 || true)
		rc=$?
		set -e
		if [ $rc -eq 0 ]; then
			echo "Drupal site installed successfully."
		else
			echo "ERROR: Drupal autoinstall failed (exit code: $rc)."
			if [ -n "${install_err}" ]; then
				echo "drush install output:"
				echo "${install_err}"
			fi
			if [ "${AUTO_INSTALL_REQUIRED:-0}" = "1" ]; then
				echo "AUTO_INSTALL_REQUIRED=1 — exiting with failure."
				exit 1
			else
				echo "Continuing startup despite autoinstall failure."
			fi
		fi
	fi
fi

# Start php-fpm as normal
echo "Starting php-fpm..."
exec php-fpm
