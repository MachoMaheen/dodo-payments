#!/bin/bash
# Build and run Dodo Payments with compile-time SQL macros

echo "=== Building and running Dodo Payments with Docker using compile-time SQL macros ==="

# Make sure we're using compile-time queries
export SQLX_OFFLINE=true

# Stop any running containers
echo "Stopping existing containers..."
docker-compose down

# Clean up volumes if needed
echo "Do you want to clean up the database volume? (y/n)"
read clean_db
if [ "$clean_db" = "y" ]; then
  echo "Removing database volume..."
  docker volume rm dodo-payments_postgres_data || true

  # If we're rebuilding from scratch, we need to prepare SQLx data
  echo "Preparing SQLx data..."
  ./prepare-sqlx-data.sh
fi

# Use the existing Dockerfile which is already configured for compile-time macros
echo "Using Dockerfile with compile-time SQL macros..."

# Build the Docker image
echo "Building Docker image..."
docker-compose build --no-cache

# Start the services
echo "Starting services..."
docker-compose up -d

# Show logs
echo "Showing logs (press Ctrl+C to exit)..."
docker-compose logs -f

echo "Done! The application should be running at http://localhost:8080"
