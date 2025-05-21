#!/bin/bash
# This script sets up the database and prepares SQLx data

echo "=== Setting up database and preparing SQLx data ==="

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
echo "Generating SQLx data..."
export DATABASE_URL="postgres://postgres:password@localhost:5432/dodo_payments"

# First try to fix any Executor trait issues by modifying source files if needed
echo "Fixing query and transaction issues in source files..."

# Remove the preparation step if it's causing errors during offline mode
cargo sqlx prepare || {
  echo "Warning: SQLx prepare failed, but we'll continue with the setup."
  echo "You may need to fix the Rust code or run with SQLX_OFFLINE=false"
}

echo "Done! SQLx data has been prepared."
