# Dodo Payments Setup Instructions

This document explains how to set up and run the Dodo Payments application.

## Prerequisites

- Docker
- Docker Compose

## Quick Start

1. Clone this repository
2. Run the start script:

```bash
# For Linux/macOS
chmod +x start.sh
./start.sh

# For Windows (Git Bash or similar)
chmod +x start.sh
./start.sh

# For Windows (PowerShell)
docker-compose down
docker-compose build
docker-compose up -d
```

This will:

- Build the Docker images
- Start the PostgreSQL database
- Start the Dodo Payments application

The API will be available at: http://localhost:8080
PostgreSQL is available at: localhost:5433 (User: postgres, Password: password, Database: dodo_payments)

## Manual Setup

If you prefer to set up manually:

1. Build and start the containers:

```bash
docker-compose up -d
```

2. Check the application logs:

```bash
docker-compose logs -f app
```

3. To stop the application:

```bash
docker-compose down
```

## Using Production-Ready Dockerfile

For production use, we provide an optimized Dockerfile:

```bash
# Build with the production Dockerfile
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

## Testing the API

You can use the included test script to test the API endpoints:

```bash
# For Linux/macOS
chmod +x test_api.sh
./test_api.sh

# For Windows (Git Bash or similar)
chmod +x test_api.sh
./test_api.sh
```

## Environment Variables

The following environment variables can be configured in docker-compose.yml:

- `DATABASE_URL`: PostgreSQL connection string (default: postgres://postgres:password@db:5432/dodo_payments)
- `SERVER_ADDR`: Server address and port (default: 0.0.0.0:8080)
- `RUST_LOG`: Logging level (default: info)
- `SQLX_OFFLINE`: Use SQLx offline mode (default: true)

## Project Structure

- `src/`: Source code
- `migrations/`: Database migrations
- `tests/`: Integration tests
- `docker-compose.yml`: Docker Compose configuration
- `Dockerfile`: Docker build configuration
- `Dockerfile.new`: Production-optimized Docker build configuration
- `start.sh`: Script to start the application
- `test_api.sh`: Script to test the API endpoints
- `wait-for-db.sh`: Script to ensure the app waits for the database to be ready
