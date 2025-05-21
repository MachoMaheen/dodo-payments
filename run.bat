@echo off
REM Main script to run Dodo Payments backend

REM Display header
echo ========================================
echo       Dodo Payments Backend Runner      
echo ========================================
echo.

REM Function to check if Docker is available
where docker >nul 2>&1 || (
    echo Error: Docker is not installed or not in PATH
    exit /b 1
)

:menu
REM Display menu and get user choice
echo Please select an option:
echo 1) Start application with Docker
echo 2) Setup database and prepare SQLx data
echo 3) Show API documentation
echo 4) Exit
echo.
set /p choice="Enter your choice (1-4): "

if "%choice%"=="1" (
    echo Starting application with Docker...
    docker-compose up -d
    echo.
    echo Application is running!
    echo API is available at: http://localhost:8080
    echo To view logs, use: docker-compose logs -f app
    echo To stop the service, use: docker-compose down
    goto :eof
)

if "%choice%"=="2" (
    echo Setting up database...
    
    REM Start PostgreSQL container if it's not already running
    docker-compose up -d db
    
    REM Wait for PostgreSQL to be ready
    echo Waiting for PostgreSQL to be ready...
    timeout /t 5 /nobreak > nul
    
    REM Run migrations and prepare SQLx data
    if exist ".\setup-db-and-prepare.bat" (
        echo Running setup-db-and-prepare.bat...
        call .\setup-db-and-prepare.bat
    ) else (
        echo Warning: setup-db-and-prepare.bat not found. Database might not be properly initialized.
    )
    
    echo.
    echo Database setup complete!
    goto :eof
)

if "%choice%"=="3" (
    if exist "API_DOCUMENTATION.md" (
        type API_DOCUMENTATION.md
    ) else (
        echo Error: API_DOCUMENTATION.md not found.
    )
    goto :eof
)

if "%choice%"=="4" (
    echo Exiting.
    goto :eof
)

echo Invalid choice. Please run the script again and select a valid option.
exit /b 1
