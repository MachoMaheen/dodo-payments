# Dodo Payments

A backend service for managing transactions and user accounts built with Rust.

## Features

- User Management (registration, authentication, profile management)
- Transaction Management (create, retrieve, list transactions)
- Account Balances (manage and query user account balances)
- JWT-based authentication
- Rate limiting and security measures

## Technical Stack

- Language: Rust
- Web Framework: Actix Web
- Database: PostgreSQL
- Authentication: JWT tokens
- Containerization: Docker and Docker Compose

## Prerequisites

- Docker and Docker Compose installed on your machine
- No need for PostgreSQL installed locally (handled by Docker)

## Quick Start

The easiest way to run the application is to use Docker Compose:

```bash
# Clone the repository
git clone [your-repo-url]
cd dodo-payments

# Build and start the application
./start.sh
```

This will:

1. Build the Docker container
2. Start the PostgreSQL database
3. Start the application

The API will be available at: http://localhost:8080

## Manual Setup

If you prefer to set up things manually:

```bash
# Start Docker Compose
docker-compose up --build -d

# Check logs
docker-compose logs -f
```

## Environment Variables

The application uses the following environment variables:

- `DATABASE_URL`: PostgreSQL connection string (default: postgres://postgres:password@db:5432/dodo_payments)
- `SERVER_ADDR`: Server address (default: 0.0.0.0:8080)
- `RUST_LOG`: Log level (default: info)
- `JWT_SECRET`: Secret for JWT tokens (read from jwt_secret.txt if not provided)

## API Documentation

See [API.md](API.md) for detailed API documentation.

## Testing

See [TESTING.md](TESTING.md) for information on running tests.

## PostgreSQL Access

The PostgreSQL database is accessible at:

- Host: localhost
- Port: 5433 (to avoid conflicts with any local PostgreSQL installation)
- Username: postgres
- Password: password
- Database: dodo_payments

## Development

To develop locally without Docker:

1. Install PostgreSQL on your machine
2. Set up the database:

```bash
createdb dodo_payments
psql -d dodo_payments -f migrations/schema.sql
```

3. Install Rust and Cargo
4. Run the application:

```bash
cargo run
```

## Troubleshooting

- **The application fails to start**: Check the logs with `docker-compose logs -f app`
- **Database connection issues**: Ensure the PostgreSQL container is running with `docker-compose ps`
- **Changes not taking effect**: Rebuild the containers with `docker-compose up --build -d`

## License

[Your License]
