#!/bin/bash
# Prepare SQLx data and enable compile-time macros

echo "=== Preparing SQLx data for compile-time macros ==="

# Start PostgreSQL in Docker if not already running
echo "Starting PostgreSQL in Docker if not already running..."
docker-compose up -d db

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL to be ready..."
MAX_RETRIES=30
RETRY_COUNT=0

while ! docker exec -i $(docker-compose ps -q db) pg_isready -U postgres 2>/dev/null; do
    RETRY_COUNT=$((RETRY_COUNT+1))
    if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
        echo "Error: PostgreSQL failed to start after multiple attempts"
        exit 1
    fi
    echo "Waiting for PostgreSQL to start... ($RETRY_COUNT/$MAX_RETRIES)"
    sleep 2
done

echo "PostgreSQL is up and running!"

# Ensure database exists
echo "Creating database if it doesn't exist..."
docker exec -i $(docker-compose ps -q db) psql -U postgres -c "CREATE DATABASE dodo_payments;" 2>/dev/null || echo "Database already exists"

# Run migrations to create schema
echo "Running database migrations..."
DATABASE_URL="postgres://postgres:password@localhost:5432/dodo_payments" sqlx migrate run

# Generate SQLx data
echo "Generating SQLx data for compile-time checking..."
export DATABASE_URL="postgres://postgres:password@localhost:5432/dodo_payments"

# Generate SQLx data file
echo "Running sqlx prepare to generate query metadata..."
cargo sqlx prepare --database-url ${DATABASE_URL} -- --all-features || {
  echo "Error: SQLx prepare failed. Trying alternative approach..."
  
  # Try installing sqlx-cli directly and using that
  echo "Installing sqlx-cli..."
  cargo install sqlx-cli --no-default-features --features postgres

  echo "Running sqlx prepare with installed CLI..."
  sqlx prepare --database-url ${DATABASE_URL} --all-features || {
    echo "Error: SQLx prepare failed again. Please check your database connection and SQL syntax."
    exit 1
  }
}

echo "Success! SQLx data has been prepared for compile-time checking."
echo "You can now build the Docker image with 'docker-compose build --no-cache'"
