@echo off
:: Capture Docker build logs for Dodo Payments

echo === Capturing Docker build logs for Dodo Payments ===

set LOG_FILE=docker_build_logs_%date:~-4,4%%date:~-7,2%%date:~-10,2%_%time:~0,2%%time:~3,2%%time:~6,2%.log
set LOG_FILE=%LOG_FILE: =0%
echo Logs will be saved to %LOG_FILE%

:: Stop any running containers
echo Stopping existing containers... > %LOG_FILE%
docker-compose down >> %LOG_FILE% 2>&1

:: Clean Docker builder cache
echo Cleaning Docker builder cache... >> %LOG_FILE%
docker builder prune -f >> %LOG_FILE% 2>&1

:: Build the Docker image with full output logging
echo Building Docker image... >> %LOG_FILE%
set DOCKER_BUILDKIT=1
docker build . -t dodo-payments:latest --progress=plain >> %LOG_FILE% 2>&1

echo Starting services... >> %LOG_FILE%
docker-compose up -d >> %LOG_FILE% 2>&1

echo Getting container logs... >> %LOG_FILE%
docker-compose logs >> %LOG_FILE% 2>&1

echo Logs have been saved to %LOG_FILE%
