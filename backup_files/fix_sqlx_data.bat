@echo off
REM This script generates SQLx metadata for offline mode using Docker

echo Starting PostgreSQL container for SQLx metadata generation...
REM Start a PostgreSQL container
docker run --name temp-postgres -e POSTGRES_PASSWORD=password -e POSTGRES_USER=postgres -e POSTGRES_DB=dodo_payments -d -p 5432:5432 postgres:13

echo Waiting for PostgreSQL to start...
REM Wait for PostgreSQL to initialize
timeout /t 10 /nobreak > nul

echo Running migrations...
REM Copy migrations to a temporary location in the container
docker cp ./migrations temp-postgres:/tmp/migrations

REM Run the migrations inside the container
docker exec temp-postgres bash -c "apt-get update && apt-get install -y postgresql-client && PGPASSWORD=password psql -h localhost -U postgres -d dodo_payments -f /tmp/migrations/20250521000001_initial_schema.sql && PGPASSWORD=password psql -h localhost -U postgres -d dodo_payments -f /tmp/migrations/20250521000002_test_data.sql"

echo Setting up environment...
REM Set DATABASE_URL for SQLx
set DATABASE_URL=postgres://postgres:password@localhost:5432/dodo_payments

echo Generating SQLx metadata...
REM Generate the SQLx data file
cargo sqlx prepare --merged --database-url postgres://postgres:password@localhost:5432/dodo_payments -- --all-features

echo Cleaning up...
REM Stop and remove the temporary PostgreSQL container
docker stop temp-postgres
docker rm temp-postgres

echo SQLx metadata generation complete! The sqlx-data.json file has been updated.
echo You can now build the Docker image with SQLX_OFFLINE=true
