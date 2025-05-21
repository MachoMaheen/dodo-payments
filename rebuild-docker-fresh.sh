# Build and run Dodo Payments with compile-time macros
# This file redoes the Docker setup from scratch

# Stop any running containers
echo "Stopping existing containers..."
docker-compose down

# Remove any cached or problematic Docker build files
echo "Cleaning up Docker build cache..."
docker builder prune -f

# Make sure sqlx-data.json exists and is up-to-date
if [ ! -f "sqlx-data.json" ] || [ ! -s "sqlx-data.json" ]; then
  echo "Error: sqlx-data.json is missing or empty. We need this file for compile-time validation."
  echo "Running prepare-sqlx-data.sh to generate it..."
  bash prepare-sqlx-data.sh
fi

echo "Building Docker image with compile-time macros..."
# Create Docker image directly without using docker-compose
docker build . -t dodo-payments:latest

echo "Starting services with docker-compose..."
docker-compose up -d

echo "Checking if application is running..."
sleep 5
curl -v http://localhost:8080/health || echo "Application not responding yet, check logs with 'docker-compose logs'"

echo "Done! You can view the logs with: docker-compose logs -f"
