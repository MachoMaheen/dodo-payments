@echo off
REM This script sets up the database and prepares SQLx data for offline mode

echo Setting up database and preparing SQLx data...

REM Check if PostgreSQL is running
pg_isready -h localhost -p 5432 >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Error: PostgreSQL is not running on localhost:5432
    echo Please start PostgreSQL and try again
    exit /b 1
)

REM Load the DATABASE_URL from .env file
for /f "tokens=*" %%a in ('findstr /v "^#" .env ^| findstr "DATABASE_URL"') do set %%a

REM Extract password from DATABASE_URL
for /f "tokens=3 delims=:@" %%a in ("%DATABASE_URL%") do set PGPASSWORD=%%a

REM Create the database if it doesn't exist
echo Creating database if it doesn't exist...
psql -h localhost -U postgres -c "CREATE DATABASE dodo_payments WITH ENCODING 'UTF8' LC_COLLATE='en_US.UTF-8' LC_CTYPE='en_US.UTF-8' TEMPLATE=template0;" 2>nul || echo Database already exists

REM Run the migrations
echo Running migrations...
for %%f in (migrations\*.sql) do (
    echo Executing migration: %%f
    psql -h localhost -U postgres -d dodo_payments -f "%%f"
)

REM Now prepare the SQLx data
echo Preparing SQLx data...
cargo sqlx prepare -- --lib

echo Done! SQLx data has been prepared.
