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
	DRUSH_ROOT=${DRUSH_ROOT:-/opt/drupal/web}

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
		# Write full drush install output to a log so it can be inspected later
		DRUPAL_INSTALL_LOG=${DRUPAL_INSTALL_LOG:-/var/log/drupal-install.log}
		mkdir -p "$(dirname "$DRUPAL_INSTALL_LOG")"
		: > "${DRUPAL_INSTALL_LOG}"
		set +e
		drush site:install standard --db-url="${DB_URL}" --site-name="${DRUPAL_SITE_NAME}" --account-name="${ADMIN_USER}" --account-pass="${ADMIN_PASS}" --yes --root="${DRUSH_ROOT}" >"${DRUPAL_INSTALL_LOG}" 2>&1
		rc=$?
		set -e
		if [ $rc -eq 0 ]; then
			echo "Drupal site installed successfully. Install log (${DRUPAL_INSTALL_LOG}):"
			cat "${DRUPAL_INSTALL_LOG}"
		else
			echo "ERROR: Drupal autoinstall failed (exit code: $rc). Install log (${DRUPAL_INSTALL_LOG}):"
			cat "${DRUPAL_INSTALL_LOG}"
			if [ "${AUTO_INSTALL_REQUIRED:-0}" = "1" ]; then
				echo "AUTO_INSTALL_REQUIRED=1 — exiting with failure."
				exit 1
			else
				echo "Continuing startup despite autoinstall failure."
			fi
		fi
	fi
fi

# If requested, attempt a one-time automated CiviCRM install using cv
# Controlled via environment variables:
# CIVICRM_INSTALL=1                -> run CiviCRM install
# CIVICRM_INSTALL_REQUIRED=1       -> exit with failure if install fails
# CIVICRM_CMS_BASE_URL             -> the CMS base URL (ex: https://d10.example.org)
# CIVICRM_DB_DSN                  -> the DB DSN (ex: mysql://user:pass@host:3306/dbname)
# CV_ROOT                         -> path to Drupal root (defaults to DRUSH_ROOT or /var/www/html)
if [ "${CIVICRM_INSTALL:-0}" = "1" ]; then
	echo "CIVICRM_INSTALL=1; attempting CiviCRM core:install via cv."

	CV_ROOT=${CV_ROOT:-/opt/drupal/web}
	# Default CMS URL to localhost and use PORT_HTTP from compose (fallback 8080)
	CIVICRM_CMS_BASE_URL=${CIVICRM_CMS_BASE_URL:-"http://localhost:${PORT_HTTP:-8080}"}
	CIVICRM_DB_DSN=${CIVICRM_DB_DSN:-""}

	# Check for cv binary
	if ! command -v cv >/dev/null 2>&1; then
		echo "ERROR: cv (CiviCRM CLI) not found in PATH; skipping CiviCRM install."
		if [ "${CIVICRM_INSTALL_REQUIRED:-0}" = "1" ]; then
			echo "CIVICRM_INSTALL_REQUIRED=1 — exiting with failure."
			exit 1
		else
			echo "Continuing startup despite missing cv."
		fi
	else
		# Avoid printing secrets: mask password in DSN for logs
		if [ -n "${CIVICRM_DB_DSN}" ]; then
			CIVICRM_DB_DSN_MASKED=$(echo "${CIVICRM_DB_DSN}" | sed -E 's%(:[^:@]+@)%:****@%')
		else
			CIVICRM_DB_DSN_MASKED="(empty)"
		fi

		echo "Running cv core:install with CMS URL: ${CIVICRM_CMS_BASE_URL} and DB: ${CIVICRM_DB_DSN_MASKED} (root: ${CV_ROOT})"
		# Write full cv install output to a log so it can be inspected later
		CIVICRM_INSTALL_LOG=${CIVICRM_INSTALL_LOG:-/var/log/civicrm-install.log}
		mkdir -p "$(dirname "$CIVICRM_INSTALL_LOG")"
		: > "${CIVICRM_INSTALL_LOG}"
		set +e
		(cd "${CV_ROOT}" && cv core:install --url="${CIVICRM_CMS_BASE_URL}" --db="${CIVICRM_DB_DSN}") >"${CIVICRM_INSTALL_LOG}" 2>&1
		rc=$?
		set -e
		if [ $rc -eq 0 ]; then
			echo "CiviCRM installed successfully. Install log (${CIVICRM_INSTALL_LOG}):"
			cat "${CIVICRM_INSTALL_LOG}"
		else
			echo "ERROR: CiviCRM install failed (exit code: $rc). Install log (${CIVICRM_INSTALL_LOG}):"
			cat "${CIVICRM_INSTALL_LOG}"
			if [ "${CIVICRM_INSTALL_REQUIRED:-0}" = "1" ]; then
				echo "CIVICRM_INSTALL_REQUIRED=1 — exiting with failure."
				exit 1
			else
				echo "Continuing startup despite CiviCRM install failure." 
			fi
		fi
	fi
fi

# Start php-fpm as normal
echo "Starting php-fpm..."
exec php-fpm
