#!/usr/bin/env bash
set -euo pipefail

# Drupal entrypoint: wait for DB and run drush site:install automatically when
# the container starts if the site is not yet installed.

DRUPAL_HTML_DIR=/var/www/html
# Prefer /var/www/html/web if present
if [ -d "$DRUPAL_HTML_DIR/web" ]; then
  DRUPAL_ROOT="$DRUPAL_HTML_DIR/web"
else
  DRUPAL_ROOT="$DRUPAL_HTML_DIR"
fi

# Locate drush binary: try system drush then vendor/bin
if command -v drush >/dev/null 2>&1; then
  DRUSH_BIN="$(command -v drush)"
elif [ -x "$DRUPAL_HTML_DIR/vendor/bin/drush" ]; then
  DRUSH_BIN="$DRUPAL_HTML_DIR/vendor/bin/drush"
elif [ -x "$DRUPAL_ROOT/../vendor/bin/drush" ]; then
  DRUSH_BIN="$DRUPAL_ROOT/../vendor/bin/drush"
else
  DRUSH_BIN=""
fi

SITE_SETTINGS="$DRUPAL_ROOT/sites/default/settings.php"

wait_for_db() {
  local host=${1:-${DB_HOST:-db}}
  local port=${2:-${DB_PORT:-3306}}
  # Try up to 30 times with 2s delay
  for i in $(seq 1 30); do
    if bash -c "</dev/tcp/${host}/${port}" >/dev/null 2>&1; then
      echo "Database available at ${host}:${port}"
      return 0
    fi
    echo "Waiting for database ${host}:${port} (${i}/30)..."
    sleep 2
  done
  echo "Timed out waiting for database ${host}:${port}"
  return 1
}

auto_install() {
  if [ -z "$DRUSH_BIN" ]; then
    echo "drush not found; skipping automatic install."
    return
  fi

  if [ -f "$SITE_SETTINGS" ]; then
    echo "Drupal appears installed (found $SITE_SETTINGS). Running cache rebuild and exiting entrypoint prep."
    # Ensure drush uses the correct root
    "$DRUSH_BIN" -r "$DRUPAL_ROOT" cr || true
    return
  fi

  echo "No settings.php found; proceeding with automated site installation using drush."

  # Ensure settings directory exists and is writable
  mkdir -p "$DRUPAL_ROOT/sites/default/files"
  chmod 775 "$DRUPAL_ROOT/sites/default/files" || true

  # If default.settings.php exists, copy it to settings.php so drush can write to it.
  if [ -f "$DRUPAL_ROOT/sites/default/default.settings.php" ] && [ ! -f "$SITE_SETTINGS" ]; then
    cp "$DRUPAL_ROOT/sites/default/default.settings.php" "$SITE_SETTINGS"
    chmod 664 "$SITE_SETTINGS" || true
  fi

  # Build DB URL
  # Support both DB_* env names and DRUPAL_DB_* as provided by the compose file.
  DB_DRIVER=${DB_DRIVER:-mysql}
  DB_HOST=${DB_HOST:-${DRUPAL_DB_HOST:-db}}
  DB_PORT=${DB_PORT:-${DRUPAL_DB_PORT:-3306}}
  DB_NAME=${DB_NAME:-${DRUPAL_DB_NAME:-drupal}}
  DB_USER=${DB_USER:-${DRUPAL_DB_USER:-drupal}}
  # Compose commonly uses DB_PASSWORD; accept DB_PASS or DB_PASSWORD or DRUPAL_DB_PASSWORD
  DB_PASS=${DB_PASS:-${DB_PASSWORD:-${DRUPAL_DB_PASSWORD:-drupal}}}

  DB_URL="${DB_DRIVER}://${DB_USER}:${DB_PASS}@${DB_HOST}:${DB_PORT}/${DB_NAME}"

  SITE_NAME=${SITE_NAME:-Drupal}
  PROFILE=${PROFILE:-standard}
  ACCOUNT_NAME=${ACCOUNT_NAME:-admin}
  ACCOUNT_PASS=${ACCOUNT_PASS:-admin}
  ACCOUNT_MAIL=${ACCOUNT_MAIL:-admin@example.com}
  SITE_MAIL=${SITE_MAIL:-"${ACCOUNT_MAIL}"}

  echo "Waiting for database before running site install..."
  if ! wait_for_db "$DB_HOST" "$DB_PORT"; then
    echo "Database not available; aborting automated installation."
    return 1
  fi

  echo "Running drush site:install (profile: $PROFILE, site name: '$SITE_NAME')"
  # Try to ensure the database exists using the mysql client first. Some drush
  # install paths invoke the mysql CLI to create/drop DBs; if the server does
  # not support TLS but the client requires it, creation can fail. Try common
  # non-SSL flags (MariaDB client) before letting drush attempt creation.
  if command -v mysql >/dev/null 2>&1; then
    echo "Ensuring database '${DB_NAME}' exists using mysql client..."
    # Try --ssl=0 (MariaDB/MySQL clients), then --skip-ssl; ignore failures.
    if mysql -h "$DB_HOST" -P "$DB_PORT" -u"$DB_USER" -p"$DB_PASS" --ssl=0 -e "CREATE DATABASE IF NOT EXISTS \`$DB_NAME\`;" >/dev/null 2>&1; then
      echo "Database ensured with --ssl=0"
    elif mysql -h "$DB_HOST" -P "$DB_PORT" -u"$DB_USER" -p"$DB_PASS" --skip-ssl -e "CREATE DATABASE IF NOT EXISTS \`$DB_NAME\`;" >/dev/null 2>&1; then
      echo "Database ensured with --skip-ssl"
    else
      echo "Could not ensure database with mysql client; will let drush try."
    fi
  fi

  "$DRUSH_BIN" -r "$DRUPAL_ROOT" site:install "$PROFILE" \
    --db-url="$DB_URL" \
    --site-name="$SITE_NAME" \
    --account-name="$ACCOUNT_NAME" \
    --account-pass="$ACCOUNT_PASS" \
    --account-mail="$ACCOUNT_MAIL" \
    --site-mail="$SITE_MAIL" \
    -y

  echo "Drush site install finished. Clearing cache and ensuring permissions."
  "$DRUSH_BIN" -r "$DRUPAL_ROOT" cr || true

  # secure settings.php
  chmod 440 "$SITE_SETTINGS" || true
}

# If the first argument looks like a flag (starts with -), prepend the default
# command (php-fpm). This allows Docker CMD to be omitted in compose files.
if [ "${1:-}" = "" ]; then
  # no command provided; just try install and then start php-fpm
  auto_install || true
  exec php-fpm
fi

case "$1" in
  php-fpm|apache2|drush|bash|sh)
    # Run auto-install before launching main service
    auto_install || true
    exec "$@"
    ;;
  *)
    # For arbitrary commands, just run them (but attempt automatic install first)
    auto_install || true
    exec "$@"
    ;;
esac
