#!/bin/sh
set -euo pipefail

# drupal-entrypoint.sh
# Idempotent Drupal site install using drush. Exits with non-zero on fatal errors.

# Default env vars
: "${DO_INSTALL:=false}"
: "${FORCE_REINSTALL:=false}"
: "${SITES_SUBDIR:=default}"
: "${SITE_NAME:=Drupal}"
: "${SITE_PROFILE:=standard}"
: "${ADMIN_USER:=admin}"
: "${ADMIN_PASS:=}"
: "${SITE_MAIL:=admin@example.org}"

# DB envs expected: DRUPAL_DB_HOST, DRUPAL_DB_PORT (optional), DRUPAL_DB_NAME, DRUPAL_DB_USER, DRUPAL_DB_PASSWORD

echo "[entrypoint] starting drupal entrypoint"

# Locate drush: prefer project vendor bin, fall back to PATH
: "${DRUSH_CMD:=}"
if [ -x "/var/www/html/vendor/bin/drush" ]; then
  DRUSH_CMD="/var/www/html/vendor/bin/drush"
elif [ -x "/opt/drupal/vendor/bin/drush" ]; then
  DRUSH_CMD="/opt/drupal/vendor/bin/drush"
else
  # last resort: use whatever 'drush' in PATH resolves to
  if command -v drush >/dev/null 2>&1; then
    DRUSH_CMD="$(command -v drush)"
  else
    DRUSH_CMD="drush"
  fi
fi
echo "[entrypoint] using drush command: $DRUSH_CMD"
DRUPAL_ROOT="/var/www/html"

wait_for_db() {
  # Wait until the DB accepts connections
  DB_HOST="${DRUPAL_DB_HOST:-}"
  DB_NAME="${DRUPAL_DB_NAME:-}"
  DB_USER="${DRUPAL_DB_USER:-}"
  DB_PASS="${DRUPAL_DB_PASSWORD:-}"
  DB_PORT="${DRUPAL_DB_PORT:-3306}"

  if [ -z "$DB_HOST" ] || [ -z "$DB_NAME" ] || [ -z "$DB_USER" ]; then
    echo "[entrypoint] DB env vars missing (DRUPAL_DB_HOST/DRUPAL_DB_NAME/DRUPAL_DB_USER)"
    return 1
  fi

  echo "[entrypoint] waiting for DB at $DB_HOST:$DB_PORT..."
  tries=0
  # Use a small PHP mysqli connection check instead of drush. Drush requires
  # a configured Drupal site; using PHP directly lets us probe the DB socket
  # before settings.php exists.
  until true; do
    tries=$((tries + 1))
    out=$(php -r "mysqli_report(MYSQLI_REPORT_OFF); \$m=new mysqli('${DB_HOST}', '${DB_USER}', '${DB_PASS}', '${DB_NAME}', ${DB_PORT:-3306}); if(\$m->connect_errno) { echo 'CONNECT_ERR:'.\$m->connect_errno.':'.\$m->connect_error; exit(1);} echo 'CONNECT_OK';" 2>&1) || rc=$?
    rc=${rc:-0}
    if [ $rc -eq 0 ] && echo "$out" | grep -q CONNECT_OK; then
      break
    fi
    echo "[entrypoint] php DB check failed (try=$tries rc=$rc) output: $out"
    if [ $tries -gt 30 ]; then
      echo "[entrypoint] timed out waiting for DB"
      return 1
    fi
    sleep 2
  done
  echo "[entrypoint] DB ready"
}

is_drupal_installed() {
  # Use drush to check for the key_value table
  # POSIX-safe: build optional --uri arg as a string
  EXTRA_DRUSH_URI=""
  if [ -n "${SITE_URI:-}" ]; then
    EXTRA_DRUSH_URI="--uri=${SITE_URI}"
  fi

  if $DRUSH_CMD --root="$DRUPAL_ROOT" $EXTRA_DRUSH_URI sql:query "SHOW TABLES LIKE 'key_value';" | grep -q key_value; then
    return 0
  fi
  return 1
}

run_site_install() {
  if [ -z "$ADMIN_PASS" ]; then
    echo "[entrypoint] ADMIN_PASS is required when DO_INSTALL=true"
    return 1
  fi
  echo "[entrypoint] running drush site-install"
  $DRUSH_CMD --root="$DRUPAL_ROOT" $EXTRA_DRUSH_URI site-install "$SITE_PROFILE" \
    --site-name="$SITE_NAME" \
    --account-name="$ADMIN_USER" \
    --account-pass="$ADMIN_PASS" \
    --account-mail="$SITE_MAIL" \
    --db-url="mysql://$DRUPAL_DB_USER:$DRUPAL_DB_PASSWORD@$DRUPAL_DB_HOST/$DRUPAL_DB_NAME" \
    --sites-subdir="$SITES_SUBDIR" \
    --yes
}

main() {
  if [ "${DO_INSTALL}" != "true" ]; then
    echo "[entrypoint] DO_INSTALL != true; skipping site install"
    exec "$@"
  fi

  wait_for_db || exit 1

  if is_drupal_installed; then
    if [ "${FORCE_REINSTALL}" = "true" ]; then
      echo "[entrypoint] FORCE_REINSTALL=true, dropping Drupal tables (dangerous)"
      # drop all tables - this is destructive and requires explicit opt-in
  $DRUSH_CMD --root="$DRUPAL_ROOT" $EXTRA_DRUSH_URI sql:query "SET FOREIGN_KEY_CHECKS=0;" || true
  $DRUSH_CMD --root="$DRUPAL_ROOT" $EXTRA_DRUSH_URI sql:query "SELECT concat('DROP TABLE ', table_name, ';') FROM information_schema.tables WHERE table_schema = '$DRUPAL_DB_NAME';" | $DRUSH_CMD --root="$DRUPAL_ROOT" $EXTRA_DRUSH_URI sql:cli || true
    else
      echo "[entrypoint] Drupal appears to be installed; skipping site install"
      exec "$@"
    fi
  fi

  run_site_install || exit 1

  echo "[entrypoint] post-install: cache rebuild and DB updates"
  $DRUSH_CMD --root="$DRUPAL_ROOT" $EXTRA_DRUSH_URI cr || true
  $DRUSH_CMD --root="$DRUPAL_ROOT" $EXTRA_DRUSH_URI updb -y || true

  echo "[entrypoint] site install complete"

  exec "$@"
}

# If no command provided, run php-fpm (container base image default)
if [ "$#" -eq 0 ]; then
  set -- php-fpm
fi

main "$@"
