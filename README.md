# Dodo Payments

A Rust-based backend service for managing transactions and user accounts. This application provides RESTful API endpoints for user management, transaction processing, and account balance management.

## Features

- **User Management**: Registration, authentication, and profile management
- **Transaction Management**: Create, retrieve, and list transactions between users
- **Account Management**: Manage and query user account balances
- **Security**: JWT-based authentication, input validation, and error handling
- **Persistence**: PostgreSQL database for storing user and transaction data
- **Modern Architecture**: Asynchronous processing using Rust's async/await

## Tech Stack

- **Language**: Rust
- **Web Framework**: Actix Web
- **Database**: PostgreSQL
- **ORM**: SQLx (SQL toolkit with compile-time checked queries)
- **Authentication**: JWT (JSON Web Tokens)
- **Validation**: Validator
- **Containerization**: Docker and Docker Compose
- **Rate Limiting**: Actix Extensible Rate Limit
- **Logging**: Env Logger

## Getting Started

### Prerequisites

- Rust and Cargo installed (latest stable version)
- PostgreSQL database (version 12 or higher)
- [Optional] Docker and Docker Compose for containerized setup

### Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/your-username/dodo-payments.git
   cd dodo-payments
   ```

2. Set up the database:

   ```bash
   # Using local PostgreSQL
   sudo -u postgres psql -c "CREATE USER dodo WITH PASSWORD 'dodo_payments';"
   sudo -u postgres psql -c "CREATE DATABASE dodo_payments OWNER dodo;"
   sudo -u postgres psql -c "ALTER USER dodo WITH SUPERUSER;"

   # Or using Docker
   docker-compose up -d postgres
   ```

3. Configure the environment:
   Create a `.env` file in the project root with the following content:

   ```
   DATABASE_URL=postgres://dodo:dodo_payments@localhost/dodo_payments
   SERVER_ADDR=127.0.0.1:8080
   SQLX_OFFLINE=true
   ```

4. Run database migrations:

   ```bash
   sqlx database create
   sqlx migrate run
   ```

5. Build and run the application:

   ```bash
   cargo build
   cargo run

   # Or use the run script
   ./run.sh
   ```

### Docker Setup

Alternatively, you can use Docker Compose to run the entire application:

```bash
docker-compose up
```

## SQLx Development

This project uses SQLx for type-safe database queries. There are two modes of operation:

### 1. Development Mode (with SQLx Offline)

For development, you can generate SQLx metadata to work without a live database during compilation:

```bash
# Generate SQLx metadata for offline development
./setup_sqlx_offline.sh

# Set offline mode for local development
export SQLX_OFFLINE=true

# Now you can build and run without a database connection during compilation
cargo build
```

### 2. Docker Mode (with Runtime Validation)

When using Docker, query validation is performed at runtime:

```bash
# Build and run with Docker
docker-compose up
```

## API Documentation

For detailed information about the API endpoints, request/response formats, and example requests, see the [API Documentation](API.md).

## Testing

For instructions on how to test the API routes and JWT authentication, see the [Testing Guide](TESTING.md).

## Project Structure

```
dodo-payments/
├── migrations/             # Database migrations
├── src/
│   ├── config/             # Application configuration
│   ├── handlers/           # API endpoint handlers
│   ├── middleware/         # Custom middleware (e.g., authentication)
│   ├── models/             # Data models and database schema
│   ├── utils/              # Utility functions (e.g., JWT helpers)
│   ├── lib.rs              # Library exports
│   └── main.rs             # Application entry point
├── tests/                  # Integration tests
├── Cargo.toml              # Rust dependencies and project metadata
├── docker-compose.yml      # Docker configuration
├── Dockerfile              # Docker build instructions
└── README.md              # Project documentation
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
The Docker setup uses runtime validation (SQLX_OFFLINE=false), which means:

No need for a database during the build process
SQL queries are validated at runtime
Easier Docker builds without database dependencies

# Start the application with Docker

docker-compose up -d

# Dodo Payments

A Rust-based backend service for managing transactions and user accounts in a simplified payment system.

## Features

- **User Management**: Registration, authentication, and profile management
- **Transaction Management**: Create, retrieve, and list transactions
- **Account Balances**: Query and manage account balances
- **Security**: JWT authentication, password hashing, and rate limiting
- **API Documentation**: Comprehensive API documentation
- **Docker Support**: Easy setup and deployment with Docker

## Technology Stack

- **Language**: Rust
- **Web Framework**: Actix Web
- **Database**: PostgreSQL with SQLx
- **Authentication**: JSON Web Tokens (JWT)
- **Password Hashing**: Argon2
- **Validation**: Validator crate
- **Documentation**: API documentation with examples
- **Containerization**: Docker & Docker Compose

## Getting Started

### Prerequisites

- Docker and Docker Compose

### Running the Application

1. Clone this repository
2. Make the scripts executable:
   ```bash
   chmod +x setup.sh run.sh
   ```
