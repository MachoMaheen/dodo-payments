@echo off
:: Build and run Dodo Payments with compile-time macros
:: This file redoes the Docker setup from scratch

:: Stop any running containers
echo Stopping existing containers...
docker-compose down

:: Remove any cached or problematic Docker build files
echo Cleaning up Docker build cache...
docker builder prune -f

:: Make sure sqlx-data.json exists and is up-to-date
if not exist sqlx-data.json (
  echo Error: sqlx-data.json is missing. We need this file for compile-time validation.
  echo Running prepare-sqlx-data.sh to generate it...
  bash prepare-sqlx-data.sh
) else (
  for %%F in (sqlx-data.json) do if %%~zF==0 (
    echo Error: sqlx-data.json is empty. We need valid content for compile-time validation.
    echo Running prepare-sqlx-data.sh to generate it...
    bash prepare-sqlx-data.sh
  )
)

echo Building Docker image with compile-time macros...
:: Create Docker image directly without using docker-compose
docker build . -t dodo-payments:latest

echo Starting services with docker-compose...
docker-compose up -d

echo Checking if application is running...
timeout /t 5 /nobreak > NUL
curl -v http://localhost:8080/health || echo Application not responding yet, check logs with 'docker-compose logs'

echo Done! You can view the logs with: docker-compose logs -f
