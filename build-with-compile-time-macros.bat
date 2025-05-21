@echo off
:: Build and run Dodo Payments with compile-time SQL macros

echo === Building and running Dodo Payments with Docker using compile-time SQL macros ===

:: Make sure we're using compile-time queries
set SQLX_OFFLINE=true

:: Stop any running containers
echo Stopping existing containers...
docker-compose down

:: Clean up volumes if needed
echo Do you want to clean up the database volume? (y/n)
set /p clean_db=

if "%clean_db%"=="y" (
  echo Removing database volume...
  docker volume rm dodo-payments_postgres_data 2>nul || echo Volume not found or already removed.

  :: If we're rebuilding from scratch, we need to prepare SQLx data
  echo Preparing SQLx data...
  bash prepare-sqlx-data.sh
)

:: Use the existing Dockerfile which is already configured for compile-time macros
echo Using Dockerfile with compile-time SQL macros...

:: Build the Docker image
echo Building Docker image...
docker-compose build --no-cache

:: Start the services
echo Starting services...
docker-compose up -d

:: Show logs
echo Showing logs (press Ctrl+C to exit)...
docker-compose logs -f

echo Done! The application should be running at http://localhost:8080
