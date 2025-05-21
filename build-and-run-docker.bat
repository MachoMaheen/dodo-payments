@echo off
:: Build and run Dodo Payments with fixed Docker setup

echo === Building and running Dodo Payments with Docker ===

:: Make sure we're using runtime queries
set SQLX_OFFLINE=false

:: Stop any running containers
echo Stopping existing containers...
docker-compose down

:: Clean up volumes if needed
echo Do you want to clean up the database volume? (y/n)
set /p clean_db=

if "%clean_db%"=="y" (
  echo Removing database volume...
  docker volume rm dodo-payments_postgres_data 2>nul || echo Volume not found or already removed.
)

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
