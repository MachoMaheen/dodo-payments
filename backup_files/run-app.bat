@echo off
REM Simple run script for Dodo Payments

echo === Dodo Payments - Starting Application ===
echo.
echo This script will start the database and application using Docker.
echo.

REM Check if JWT secret exists
if not exist jwt_secret.txt (
    echo Creating JWT secret file...
    echo ELO9Osfpj2CCbX7iduAqmYmzqgaswnbdYHgcvnjAD7c= > jwt_secret.txt
)

echo Starting services...
docker-compose -f docker-compose.working.yml up -d

echo.
echo Services are starting...
echo Application will be available at http://localhost:8080
echo.
echo To check logs:
echo docker-compose -f docker-compose.working.yml logs -f app
echo.
echo To stop services:
echo docker-compose -f docker-compose.working.yml down
