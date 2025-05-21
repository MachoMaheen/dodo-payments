#!/bin/bash
# This script sets up the database and prepares SQLx data for offline mode

set -e

echo "Setting up database and preparing SQLx data..."

# Check if PostgreSQL is running
if ! pg_isready -h localhost -p 5432 > /dev/null 2>&1; then
    echo "Error: PostgreSQL is not running on localhost:5432"
    echo "Please start PostgreSQL and try again"
    exit 1
fi

# Source the .env file to get the DATABASE_URL
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

# Create the database if it doesn't exist
echo "Creating database if it doesn't exist..."
PGPASSWORD=${DATABASE_URL##*:} psql -h localhost -U postgres -c "CREATE DATABASE dodo_payments WITH ENCODING 'UTF8' LC_COLLATE='en_US.UTF-8' LC_CTYPE='en_US.UTF-8' TEMPLATE=template0;" || echo "Database already exists"

# Run the migrations
echo "Running migrations..."
for file in migrations/*.sql
do
    echo "Executing migration: $file"
    PGPASSWORD=${DATABASE_URL##*:} psql -h localhost -U postgres -d dodo_payments -f "$file"
done

# Now prepare the SQLx data
echo "Preparing SQLx data..."
cargo sqlx prepare -- --lib

echo "Done! SQLx data has been prepared."
