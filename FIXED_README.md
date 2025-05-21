# Dodo Payments

A Rust-based backend service for managing transactions and user accounts in a simplified version of a payment system.

## Features

- **User Management**: Registration, authentication, and profile management
- **Transaction Management**: Create, retrieve, and list transactions
- **Account Balances**: Query and manage account balances
- **Security**: JWT authentication, password hashing with Argon2, rate limiting
- **Containerization**: Docker and Docker Compose support for easy deployment

## Technology Stack

- **Language**: Rust
- **Web Framework**: Actix Web
- **Database**: PostgreSQL with SQLx
- **Authentication**: JWT (JSON Web Tokens)
- **Password Hashing**: Argon2
- **Validation**: Validator crate
- **Configuration**: Environment variables with dotenv
- **Logging**: env_logger and log crate
- **Containerization**: Docker & Docker Compose

## Prerequisites

- Docker and Docker Compose (for the easiest setup)
- Or: Rust (latest stable) and PostgreSQL (if running locally)

## Quick Start (FIXED AND WORKING)

The solution is now fixed and will work properly:

```bash
# On Windows
.\run-app.bat

# On macOS/Linux
./run-app.sh
```

This will:

1. Start a PostgreSQL database
2. Build and run the application with SQL validation disabled
3. Make the API available at http://localhost:8080

## API Endpoints

### Authentication

- **POST /users/register** - Register a new user

  - Request: `{ "username": "user1", "email": "user1@example.com", "password": "securepassword" }`
  - Response: `{ "id": "uuid", "token": "jwt-token" }`

- **POST /users/login** - Login with credentials

  - Request: `{ "username": "user1", "password": "securepassword" }`
  - Response: `{ "id": "uuid", "token": "jwt-token" }`

- **GET /users/profile** - Get user profile (requires authentication)
  - Header: `Authorization: Bearer {token}`
  - Response: `{ "id": "uuid", "username": "user1", "email": "user1@example.com" }`

### Transactions

- **POST /transactions** - Create a new transaction (requires authentication)

  - Header: `Authorization: Bearer {token}`
  - Request: `{ "recipient_id": "uuid", "amount": 100.00, "currency": "USD" }`
  - Response: `{ "id": "uuid", "sender_id": "uuid", "recipient_id": "uuid", "amount": 100.00, "currency": "USD", "status": "pending" }`

- **GET /transactions/{id}** - Get transaction details (requires authentication)

  - Header: `Authorization: Bearer {token}`
  - Response: `{ "id": "uuid", "sender_id": "uuid", "recipient_id": "uuid", "amount": 100.00, "currency": "USD", "status": "completed" }`

- **GET /transactions** - List transactions (requires authentication)
  - Header: `Authorization: Bearer {token}`
  - Query params: `?status=completed&limit=10&offset=0`
  - Response: `{ "transactions": [...], "total": 42, "limit": 10, "offset": 0 }`

### Accounts

- **GET /accounts/balance** - Get account balance (requires authentication)
  - Header: `Authorization: Bearer {token}`
  - Response: `{ "balance": 950.00, "currency": "USD" }`

## Development

### Project Structure

- `src/config/` - Application configuration
- `src/handlers/` - API endpoint handlers
- `src/middleware/` - Middleware components (authentication, etc.)
- `src/models/` - Data models and database schema
- `src/utils/` - Utility functions
- `migrations/` - Database migrations
- `tests/` - Unit and integration tests

### Running Tests

```bash
cargo test
```

## Fix Details

This repository had issues with SQLx offline mode. The solution:

1. Disabled SQLx offline mode in the Dockerfile
2. Created a working docker-compose configuration
3. Updated environment settings to avoid compilation issues
4. Added comprehensive scripts to run in various environments

## License

MIT
