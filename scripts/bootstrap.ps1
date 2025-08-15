Param(
  [switch]$Recreate
)

Write-Host "Bootstrapping Drupal + CiviCRM dev environment..." -ForegroundColor Cyan

$ErrorActionPreference = 'Stop'

# Ensure .env
if (-not (Test-Path -Path (Join-Path $PSScriptRoot '..' '.env'))) {
  Copy-Item (Join-Path $PSScriptRoot '..' '.env.example') (Join-Path $PSScriptRoot '..' '.env') -Force
  Write-Host "Created .env from .env.example"
}

# Bring up containers
if ($Recreate) {
  docker compose down -v
}

docker compose up -d --build

# Install Drupal if not present
Set-Location (Join-Path $PSScriptRoot '..')

if (-not (Test-Path -Path (Join-Path (Get-Location) 'composer.json'))) {
  Write-Host "Creating Drupal recommended project via Composer..." -ForegroundColor Cyan
  docker compose run --rm web bash -lc "composer create-project drupal/recommended-project ."
}

# Require CiviCRM packages
Write-Host "Adding CiviCRM packages..." -ForegroundColor Cyan
docker compose run --rm web bash -lc "composer config --no-plugins allow-plugins.civicrm/composer-compile-plugin true && composer config --no-plugins allow-plugins.civicrm/civicrm-asset-plugin true && composer require civicrm/civicrm-setup '@stable' civicrm/civicrm-core '^5.70' civicrm/civicrm-drupal-8 '^5.70' civicrm/civicrm-asset-plugin '^1.3'"

Write-Host "All set. Open http://localhost:8080/civicrm/setup to finish installation." -ForegroundColor Green
