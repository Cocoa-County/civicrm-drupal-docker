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
else
	echo "Warning: Drush is not installed!"
fi

# Start php-fpm as normal
echo "Starting php-fpm..."
exec php-fpm
