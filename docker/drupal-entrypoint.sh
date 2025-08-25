#!/bin/bash
set -e

# ┌─────────────────────────────────────────────┐
# │               PRINTING INFO                 │
# └─────────────────────────────────────────────┘
echo "Container started: $(date)"
echo "Hostname: $(hostname)"
echo "User: $(whoami)"
echo "Working directory: $(pwd)"
echo "PHP version: $(php -v | head -n 1)"

# Path to vendor bin dir to path
export PATH="/opt/drupal/vendor/bin:${PATH}"

# Path to Drupal root **ADVANCED**
DRUPAL_ROOT=${DRUPAL_ROOT:-/opt/drupal/web}

# ┌─────────────────────────────────────────────┐
# │                CHECKING INSTALL STATUS      │
# └─────────────────────────────────────────────┘
if [ -f "${DRUPAL_ROOT}/sites/default/.docker_install_complete" ]; then
	echo "Install marker present at ${DRUPAL_ROOT}/sites/default/.docker_install_complete — starting php-fpm."
	exec php-fpm
	exit 0
fi

# ┌─────────────────────────────────────────────┐
# │               CHECKING DB CONNECTION        │
# └─────────────────────────────────────────────┘
echo "Checking database connection once using drush..."
set +e

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
	echo "Continuing startup despite DB check failure."
fi

# ┌─────────────────────────────────────────────┐
# │               DRUPAL INSTALLATION           │
# └─────────────────────────────────────────────┘
echo "Attempting Drupal installation."
# Defaults
DRUPAL_SITE_NAME=${DRUPAL_SITE_NAME:-"Drupal Site"}
DRUPAL_ADMIN_USER=${DRUPAL_ADMIN_USER:-admin}
DRUPAL_ADMIN_PASS=${DRUPAL_ADMIN_PASS:-admin}

# Build DB URL from environment variables commonly provided by compose
DB_HOST=${DB_HOST:-db}
DB_PORT=${DB_PORT:-3306}
DB_NAME=${DB_NAME:-drupal}
DB_USER=${DB_USER:-drupal}
DB_PASS=${DB_PASS:-drupal}

DB_URL="mysql://${DB_USER}:${DB_PASS}@${DB_HOST}:${DB_PORT}/${DB_NAME}"
DB_URL_MASK="mysql://${DB_USER}:****@${DB_HOST}:${DB_PORT}/${DB_NAME}"

echo "Running drush site:install with DB URL: ${DB_URL_MASK} (root: ${DRUSH_ROOT})"

# Write full drush install output to a log so it can be inspected later
DRUPAL_INSTALL_LOG=${DRUPAL_INSTALL_LOG:-/var/log/drupal-install.log}
mkdir -p "$(dirname "$DRUPAL_INSTALL_LOG")"
: > "${DRUPAL_INSTALL_LOG}"
set +e

drush site:install standard --db-url="${DB_URL}" --site-name="${DRUPAL_SITE_NAME}" --account-name="${DRUPAL_ADMIN_USER}" --account-pass="${DRUPAL_ADMIN_PASSWORD}" --yes --root="${DRUPAL_ROOT}" >"${DRUPAL_INSTALL_LOG}" 2>&1

rc=$?
set -e
DRUPAL_INSTALL_RC=$rc

if [ $rc -eq 0 ]; then
	echo "Drupal site installed successfully. Install log (${DRUPAL_INSTALL_LOG}):"
	cat "${DRUPAL_INSTALL_LOG}"
else
	echo "ERROR: Drupal autoinstall failed (exit code: $rc). Install log (${DRUPAL_INSTALL_LOG}):"
	cat "${DRUPAL_INSTALL_LOG}"
	echo "Continuing startup despite autoinstall failure."
fi

# ┌─────────────────────────────────────────────┐
# │           settings.docker.php INJECT        │
# └─────────────────────────────────────────────┘
echo "Injecting settings.docker.php include into settings.php..."
cat <<EOF >> "${DRUPAL_ROOT}/sites/default/settings.php"

if (file_exists(__DIR__ . '/settings.docker.php')) {
  include __DIR__ . '/settings.docker.php';
}

EOF

# ┌─────────────────────────────────────────────┐
# │               CiviCRM INSTALLATION          │
# └─────────────────────────────────────────────┘
echo "Attempting CiviCRM installation."

# Default CMS URL to localhost and use NGINX_PORT from compose (fallback 8080)
CIVICRM_URI=${CIVICRM_URI:-"http://localhost:${NGINX_PORT:-8080}"}

echo "Running cv core:install with CMS URL: ${CIVICRM_URI} and DB: ${DB_URL_MASKED} (root: ${DRUPAL_ROOT})"
# Write full cv install output to a log so it can be inspected later
CIVICRM_INSTALL_LOG=${CIVICRM_INSTALL_LOG:-/var/log/civicrm-install.log}
mkdir -p "$(dirname "$CIVICRM_INSTALL_LOG")"
: > "${CIVICRM_INSTALL_LOG}"
set +e

(cd "${DRUPAL_ROOT}" && cv core:install --url="${CIVICRM_URI}" --db="${DB_URL}") >"${CIVICRM_INSTALL_LOG}" 2>&1

rc=$?
set -e
CIVICRM_INSTALL_RC=$rc

if [ $rc -eq 0 ]; then
	echo "CiviCRM installed successfully. Install log (${CIVICRM_INSTALL_LOG}):"
	cat "${CIVICRM_INSTALL_LOG}"

	echo "Fixing ownership of CiviCRM files directory..."
	chown www-data:www-data -R /opt/drupal/web/sites/default/files/civicrm
else
	echo "ERROR: CiviCRM install failed (exit code: $rc). Install log (${CIVICRM_INSTALL_LOG}):"
	cat "${CIVICRM_INSTALL_LOG}"
	echo "Continuing startup despite CiviCRM install failure." 
fi

# ┌─────────────────────────────────────────────┐
# │               INSTALL MARKER                │
# └─────────────────────────────────────────────┘
echo "Writing install marker to ${DRUPAL_ROOT}/sites/default/.docker_install_complete"
mkdir -p "${DRUPAL_ROOT}/sites/default"
cat > "${DRUPAL_ROOT}/sites/default/.docker_install_complete" <<MARKER
timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
drupal_install_log: ${DRUPAL_INSTALL_LOG:-/var/log/drupal-install.log}
drupal_install_rc: ${DRUPAL_INSTALL_RC:-unknown}
civicrm_install_log: ${CIVICRM_INSTALL_LOG:-/var/log/civicrm-install.log}
civicrm_install_rc: ${CIVICRM_INSTALL_RC:-unknown}
marker_note: "Created by drupal-entrypoint.sh"
MARKER

# ┌─────────────────────────────────────────────┐
# │               PHP-FPM STARTUP               │
# └─────────────────────────────────────────────┘
echo "Starting php-fpm..."
exec php-fpm
