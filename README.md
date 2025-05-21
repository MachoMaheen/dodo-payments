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

## Quick Setup (Docker)

The easiest way to run the application is using Docker:

```bash
# On Unix/Linux/macOS:
./run.sh

# On Windows:
run.bat
```

Then select option 1 to start the application with Docker, or option 2 to setup the database and generate SQLx data.

## SQLx Offline Mode Issues

If you're experiencing issues with SQLx offline mode (like build failures due to missing query data), run the setup script to properly initialize the database and generate SQLx metadata:

```bash
# On Unix/Linux/macOS:
./setup-db-and-prepare.sh

# On Windows:
setup-db-and-prepare.bat
```

## Manual Setup

### Production-Ready Setup (Recommended)

The most reliable way to run the application is using our production Docker setup:

```bash
# On Windows
.\run-prod.bat

# On Unix/Linux/macOS
chmod +x run-prod.sh
./run-prod.sh
```

This method:

- Automatically sets up the PostgreSQL database
- Runs all migrations before starting the app
- Doesn't require SQLx offline mode or local database
- Works reliably on any system with Docker installed

### Option 1: Production-Ready Deployment (RECOMMENDED)

For a production-ready deployment without any SQLx issues:

```bash
# On Windows
.\production-deploy.bat

# On macOS/Linux
./production-deploy.sh
```

This uses a specially designed Dockerfile.production that properly handles SQL queries at runtime rather than compile-time, making it the most reliable option for deployment in all environments. **Use this for the most stable and reliable experience.**

### Option 2: Super Quick Solution

For quick development testing:

```bash
# On Windows
.\super-quick.bat

# On macOS/Linux
./super-quick.sh
```

This completely bypasses SQLx validation issues and gets the application running with minimal setup. Use this for immediate testing and development.

### Option 3: Simplified Solution

Alternative setup that uses a more standard Docker configuration:

```bash
# On Windows
.\quick-run.bat

# On macOS/Linux
./quick-run.sh
```

This uses a simplified Docker setup that doesn't require SQLx offline mode, allowing the application to connect directly to the database at runtime.

### Option 4: Using the Original Helper Script

```bash
# On macOS/Linux
./run.sh

# On Windows
.\run.cmd
```

This interactive script will guide you through:

- Building and running with Docker
- Building locally and running with Docker
- Generating SQLx data for offline mode
- Setting up your development environment

### Option 2: Manual Setup

#### Local Development

1. Clone the repository

   ```bash
   git clone https://github.com/your-username/dodo-payments.git
   cd dodo-payments
   ```

2. Set up the database

   ```bash
   # Create PostgreSQL database
   createdb dodo_payments
   ```

3. Configure environment variables

   ```bash
   cp .env.example .env
   # Edit .env with your database credentials and other settings
   ```

4. Run database migrations

   ```bash
   cargo install sqlx-cli
   sqlx migrate run
   ```

5. Build and run the application

   ```bash
   cargo run
   ```

6. The API will be available at `http://localhost:8080`

### Using Docker

1. Clone the repository

   ```bash
   git clone https://github.com/your-username/dodo-payments.git
   cd dodo-payments
   ```

2. Create a JWT secret file

   ```bash
   # Generate a random JWT secret
   openssl rand -base64 32 > jwt_secret.txt

   # Or create one manually if openssl isn't available
   echo "your_secure_secret_key_change_this" > jwt_secret.txt
   ```

3. Start the application with Docker Compose

   ```bash
   docker-compose up -d
   ```

4. The API will be available at `http://localhost:8080`

> **Security Note**: The `jwt_secret.txt` file is mounted as a Docker secret. Never commit this file to version control. Add it to your `.gitignore`.

## API Documentation

### User Management

#### Register a new user

```
POST /users/register
Content-Type: application/json

{
  "username": "johndoe",
  "email": "john@example.com",
  "password": "securePassword123"
}
```

Response:

```json
{
  "id": "uuid",
  "username": "johndoe",
  "email": "john@example.com"
}
```

#### Login

```
POST /users/login
Content-Type: application/json

{
  "username": "johndoe",
  "password": "securePassword123"
}
```

Response:

```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "Bearer"
}
```

#### Get user profile

```
GET /users/profile
Authorization: Bearer {token}
```

Response:

```json
{
  "id": "uuid",
  "username": "johndoe",
  "email": "john@example.com"
}
```

### Transaction Management

#### Create a transaction

```
POST /transactions
Authorization: Bearer {token}
Content-Type: application/json

{
  "recipient_id": "uuid",
  "amount": 100.50,
  "currency": "USD"
}
```

Response:

```json
{
  "id": "uuid",
  "sender_id": "uuid",
  "recipient_id": "uuid",
  "amount": 100.5,
  "currency": "USD",
  "status": "completed",
  "created_at": "2025-05-21T12:34:56Z"
}
```

#### Get a transaction

```
GET /transactions/{transaction_id}
Authorization: Bearer {token}
```

Response:

```json
{
  "id": "uuid",
  "sender_id": "uuid",
  "recipient_id": "uuid",
  "amount": 100.5,
  "currency": "USD",
  "status": "completed",
  "created_at": "2025-05-21T12:34:56Z"
}
```

#### List transactions

```
GET /transactions?limit=10&offset=0&status=completed
Authorization: Bearer {token}
```

Response:

```json
{
  "transactions": [
    {
      "id": "uuid",
      "sender_id": "uuid",
      "recipient_id": "uuid",
      "amount": 100.50,
      "currency": "USD",
      "status": "completed",
      "created_at": "2025-05-21T12:34:56Z"
    },
    ...
  ],
  "total": 42
}
```

### Account Management

#### Get account balance

```
GET /accounts/balance
Authorization: Bearer {token}
```

Response:

```json
{
  "balance": 899.5,
  "currency": "USD"
}
```

## Testing

### Running Tests

```bash
# Run all tests
cargo test

# Run specific tests
cargo test auth
cargo test user_api
```

## Docker Deployment

This project includes a comprehensive Docker setup for both production and development:

### Production Deployment

```bash
# Build and run using Docker Compose
docker-compose up -d
```

### Development Workflow

```bash
# Build locally and run with Docker (for development)
./run.sh
# or on Windows
.\build-and-run-windows.bat
```

### Docker Features

- **SQLx Offline Mode** for reliable builds without database connections
- **Multi-stage builds** for smaller production images
- **Development mode** with local binary mounting for faster iterations
- **Health checks** for reliable container orchestration
- **Helper scripts** for common development tasks

For detailed Docker instructions, see [DOCKER_INSTRUCTIONS.md](./DOCKER_INSTRUCTIONS.md) and [SQLX_OFFLINE_MODE.md](./SQLX_OFFLINE_MODE.md).

## Project Structure

```
dodo-payments/
├── src/                 # Source code
│   ├── config/          # Application configuration
│   ├── handlers/        # API endpoint handlers
│   ├── middleware/      # Middleware components (auth, etc.)
│   ├── models/          # Data models and schemas
│   ├── utils/           # Utility functions
│   ├── main.rs          # Application entry point
│   └── lib.rs           # Library exports for testing
├── migrations/          # Database migrations
├── tests/               # Integration tests
├── Dockerfile           # Container definition
├── docker-compose.yml   # Production deployment setup
├── docker-compose-dev.yml # Development container setup
└── scripts/             # Helper scripts
    ├── run.sh           # Main runner script (Linux/macOS)
    ├── run.cmd          # Main runner script (Windows)
    └── test_api.sh      # API testing helper
```

### Key Components

- **Models**: Data structures representing database entities and API requests/responses
- **Handlers**: API endpoint implementations (controllers)
- **Middleware**: Cross-cutting concerns like authentication
- **Config**: Application configuration from environment variables
- **Utils**: Helper functions and utilities
- **Migrations**: Database schema definitions and changes

## Troubleshooting

If you encounter any issues with the application:

1. **Use the troubleshooting script**:

   ```bash
   # On macOS/Linux
   ./troubleshoot.sh
   ```

   This script automatically checks for common issues with Docker, permissions, network connectivity, and more.

2. **Verify your setup**:

   ```bash
   # On macOS/Linux
   ./verify_setup.sh
   ```

   This script validates that all required files and configurations are in place.

3. **Common issues**:
   - SQLx offline mode errors: Run `./generate_sqlx_data.sh` to create the necessary data file
   - Database connection issues: Make sure PostgreSQL is running and accessible
   - Docker network issues: Run `docker-compose down` followed by `docker-compose up -d`

For more detailed troubleshooting guidance, see [DOCKER_TROUBLESHOOTING.md](./DOCKER_TROUBLESHOOTING.md).

## Security Considerations

- JWT tokens expire after 24 hours
- Passwords are hashed using Argon2 algorithm
- Rate limiting is applied to prevent brute force attacks
- Input validation is performed on all requests
- Database queries are parameterized to prevent SQL injection

## Future Improvements

- Add support for multiple currencies and currency conversion
- Implement webhook notifications for transaction events
- Add admin dashboard for system monitoring
- Implement transaction history with pagination
- Add support for recurring payments

## License

MIT License
