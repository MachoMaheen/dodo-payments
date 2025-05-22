#!/bin/bash
# Script to build and run Dodo Payments

# Functions for colored output
function print_success() {
  echo -e "\033[0;32m✅ $1\033[0m"
}

function print_info() {
  echo -e "\033[0;34m🔷 $1\033[0m"
}

function print_error() {
  echo -e "\033[0;31m❌ $1\033[0m"
}

print_info "=== Building and starting Dodo Payments ==="

# Check for Docker and Docker Compose
if ! command -v docker &> /dev/null; then
  print_error "Docker is not installed. Please install Docker first."
  exit 1
fi

if ! docker info &> /dev/null; then
  print_error "Docker is not running. Please start Docker first."
  exit 1
fi

# Stop any existing containers
print_info "Stopping any existing containers..."
docker compose down

# Build and start the services
print_info "Building and starting services..."
docker compose build
docker compose up -d

print_info "Waiting for services to start..."
sleep 5

# Check if services are running
if docker compose ps | grep -q "Up"; then
  print_success "Dodo Payments is running successfully!"
  echo "API will be available at http://localhost:8081"
  echo "PostgreSQL is available at: localhost:5433"
  echo "PostgreSQL credentials: User: postgres, Password: password, Database: dodo_payments"
  echo ""
  echo "To check logs: docker compose logs -f app"
  echo "To stop: docker compose down"
else
  print_error "There was an issue starting the services. Check logs with: docker compose logs"
fi
