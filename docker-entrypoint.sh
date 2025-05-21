#!/bin/bash
# Docker entrypoint script that runs migrations before starting the application

set -e

echo "=== Dodo Payments Application Startup ==="

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL to be ready..."
until PGPASSWORD=$POSTGRES_PASSWORD psql -h db -U $POSTGRES_USER -d $POSTGRES_DB -c '\q'; do
  echo "PostgreSQL is not available yet - sleeping"
  sleep 1
done

echo "PostgreSQL is up - running migrations"

# Run migrations using sqlx CLI
echo "Running database migrations..."
cd /app
for file in migrations/*.sql
do
  echo "Executing migration: $file"
  PGPASSWORD=$POSTGRES_PASSWORD psql -h db -U $POSTGRES_USER -d $POSTGRES_DB -f "$file"
done

echo "Migrations complete - starting application"

# Start the application
exec /app/dodo-payments
