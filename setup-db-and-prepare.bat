@echo off
REM This script sets up the database and prepares SQLx data

echo === Setting up database and preparing SQLx data ===

REM Make sure PostgreSQL is running (via Docker)
echo Starting PostgreSQL in Docker if not already running...
docker-compose up -d db

REM Wait for PostgreSQL to be ready
echo Waiting for PostgreSQL to be ready...
timeout /t 5 /nobreak > nul

REM Run migrations to create schema
echo Running database migrations...
set DATABASE_URL=postgres://postgres:password@localhost:5432/dodo_payments
sqlx migrate run

REM Generate SQLx data
echo Generating SQLx data...
cargo sqlx prepare --merged

echo Done! SQLx data has been prepared.
