@echo off
REM Improved script to build Docker images and track errors in Windows

echo === Building Docker images and tracking errors ===
set TIMESTAMP=%DATE:~-4,4%%DATE:~-7,2%%DATE:~-10,2%_%TIME:~0,2%%TIME:~3,2%%TIME:~6,2%
set TIMESTAMP=%TIMESTAMP: =0%
set LOG_FILE=build_errors_%TIMESTAMP%.log
set FULL_LOG=docker_full_%TIMESTAMP%.log

echo Full build logs will be saved to %FULL_LOG%
echo Error and warning logs will be saved to %LOG_FILE%

REM Run docker compose build and capture logs
docker compose up --build > %FULL_LOG% 2>&1

REM Extract errors and warnings
findstr /i "error warning fail" %FULL_LOG% > %LOG_FILE%

echo =============================
echo Errors and warnings detected:
echo =============================
type %LOG_FILE%
echo.
echo Build complete. Logs saved to %LOG_FILE%
