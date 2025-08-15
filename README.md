# Drupal + CiviCRM (Dev) on Docker

This repo scaffolds a local development environment for Drupal 10 with CiviCRM using Docker. It keeps the stack close to what you can deploy on AWS later (ECS/EKS or EC2 with Docker).

## What's inside

- docker-compose with:
  - web: PHP 8.2 + Apache with required extensions
  - db: MariaDB 10.6
  - mailhog: local email testing UI
- Composer-driven Drupal project (docroot at `web/`)
- CiviCRM packages via Composer with web-based setup (`/civicrm/setup`)

## Quick start (Windows/PowerShell)

Prereqs: Docker Desktop, Git.

1. Copy env file
   ```powershell
   Copy-Item .env.example .env
   ```
2. Start and bootstrap
   ```powershell
   ./scripts/bootstrap.ps1
   ```
3. Complete setup in browser
   - Visit http://localhost:8080/civicrm/setup
   - Database host: `db`, name/user/pass from `.env`
   - Base URL: `http://localhost:8080`

## Common commands

- Start/stop: `docker compose up -d` / `docker compose down`
- Shell in web: `docker compose exec web bash`
- Run Composer: `docker compose run --rm web composer <cmd>`

## AWS notes

For AWS, you'll likely:
- Build the `web` image and push to ECR
- Provision RDS for the database
- Use S3 for `web/sites/default/files` via S3FS or an asset pipeline
- Terminate TLS on ALB/CloudFront

We'll add IaC (e.g., Terraform) and deployment workflows as next steps.
