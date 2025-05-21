@echo off
REM Build script for Dodo Payments on Windows

echo === Dodo Payments Build Helper ===
echo.
echo This script will help you build and run the Dodo Payments application.
echo.

echo [1] Build and Run with Docker (recommended)
echo [2] Build and Run locally
echo [3] Generate SQLx data for offline mode
echo [4] Setup development environment
echo [Q] Quit

choice /C 1234Q /N /M "Choose an option: "

if errorlevel 5 goto :EOF
if errorlevel 4 goto SETUP_DEV
if errorlevel 3 goto GENERATE_SQLX
if errorlevel 2 goto BUILD_LOCAL
if errorlevel 1 goto BUILD_DOCKER

:BUILD_DOCKER
echo.
echo === Building with Docker ===
echo.
docker-compose build
echo.
echo === Starting services ===
docker-compose up -d
echo.
echo Services are running! Access the API at http://localhost:8080
goto :EOF

:BUILD_LOCAL
echo.
echo === Building locally ===
echo.

REM Build the application locally
echo Building binary locally...
cargo build --release

REM Check if build was successful
if %ERRORLEVEL% NEQ 0 (
    echo Build failed!
    exit /b %ERRORLEVEL%
)

echo Build successful!
echo Starting Docker with locally built binary...

REM Run Docker Compose with the local binary configuration
docker-compose -f docker-compose-dev.yml up
goto :EOF

:GENERATE_SQLX
echo.
echo === Generating SQLx data ===
echo.

set /p DB_URL=Enter database URL [postgres://postgres:password@localhost:5432/dodo_payments]: 
if "%DB_URL%"=="" set DB_URL=postgres://postgres:password@localhost:5432/dodo_payments

echo Setting DATABASE_URL=%DB_URL%
set DATABASE_URL=%DB_URL%

call generate_sqlx_data.bat
goto :EOF

:SETUP_DEV
echo.
echo === Setting up development environment ===
echo.

echo Installing required tools...
cargo install sqlx-cli --no-default-features --features postgres

echo Creating JWT secret file...
echo "your_development_jwt_secret" > jwt_secret.txt

echo Development environment setup complete!
echo.
echo Next steps:
echo 1. Set up your database
echo 2. Generate SQLx data with option 3
echo 3. Build the application with Docker (option 1) or locally (option 2)
goto :EOF
