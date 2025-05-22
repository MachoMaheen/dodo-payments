#!/bin/bash
# File for initializing the database correctly in Docker

set -e

# Wait for PostgreSQL to be ready
until PGPASSWORD=$POSTGRES_PASSWORD psql -h "db" -U "$POSTGRES_USER" -p "5432" -d "$POSTGRES_DB" -c '\q'; do
  >&2 echo "PostgreSQL is unavailable - sleeping"
  sleep 1
done

>&2 echo "PostgreSQL is up - applying migrations"

# Apply the schema file
PGPASSWORD=$POSTGRES_PASSWORD psql -h "db" -U "$POSTGRES_USER" -p "5432" -d "$POSTGRES_DB" -f "/app/migrations/schema.sql"

# If there was a sample data file, apply it too
if [ -f "/app/migrations/20250521000002_sample_data.sql" ]; then
  >&2 echo "Applying sample data"
  PGPASSWORD=$POSTGRES_PASSWORD psql -h "db" -U "$POSTGRES_USER" -p "5432" -d "$POSTGRES_DB" -f "/app/migrations/20250521000002_sample_data.sql"
fi

>&2 echo "Database initialization completed"
