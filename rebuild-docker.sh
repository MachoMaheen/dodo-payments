#!/bin/bash
# This script rebuilds the Docker environment from scratch

echo "=== Cleaning up Docker artifacts and rebuilding ==="

# Stop and remove containers
echo "Stopping and removing containers..."
docker-compose down

# Remove any dangling images
echo "Removing dangling images..."
docker system prune -f

# Force rebuild images with no cache
echo "Rebuilding Docker images..."
docker-compose build --no-cache

# Start the services
echo "Starting services..."
docker-compose up -d

# Show logs
echo "Showing logs..."
docker-compose logs -f
