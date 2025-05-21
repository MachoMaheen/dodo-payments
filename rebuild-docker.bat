@echo off
REM This script rebuilds the Docker environment from scratch

echo === Cleaning up Docker artifacts and rebuilding ===

REM Stop and remove containers
echo Stopping and removing containers...
docker-compose down

REM Remove any dangling images
echo Removing dangling images...
docker system prune -f

REM Force rebuild images with no cache
echo Rebuilding Docker images...
docker-compose build --no-cache

REM Start the services
echo Starting services...
docker-compose up -d

REM Show logs
echo Showing logs...
docker-compose logs -f
