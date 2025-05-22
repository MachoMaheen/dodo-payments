# Dodo Payments Testing Guide

This document provides instructions on how to test the Dodo Payments API, including setting up the environment, running the application, and testing API routes and JWT authentication.

## Setting Up the Environment

### Prerequisites

- Rust and Cargo installed (latest stable version)
- PostgreSQL (version 12 or newer)
- [Optional] Docker and Docker Compose for containerized setup

### Database Setup

1. Install PostgreSQL (if not already installed):

```bash
sudo apt update
sudo apt install postgresql postgresql-contrib
```

2. Start PostgreSQL service:

```bash
sudo service postgresql start
```

3. Create database user and database:

```bash
sudo -u postgres psql -c "CREATE USER dodo WITH PASSWORD 'dodo_payments';"
sudo -u postgres psql -c "CREATE DATABASE dodo_payments OWNER dodo;"
sudo -u postgres psql -c "ALTER USER dodo WITH SUPERUSER;"
```

4. Configure connection string:

Create or edit the `.env` file in the project root directory:

```
DATABASE_URL=postgres://dodo:dodo_payments@localhost/dodo_payments
SQLX_OFFLINE=true
JWT_SECRET=your_secure_jwt_secret_key
SERVER_ADDR=127.0.0.1:8080
```

### Running Database Migrations

Apply the database schema:

```bash
cd /home/maheen/Desktop/dodo-payments
sqlx database create
sqlx migrate run
```

## Running the Application

### Method 1: Using Cargo

Run the application directly with Cargo:

```bash
cd /home/maheen/Desktop/dodo-payments
cargo run
```

### Method 2: Using the Run Script

Use the provided run script:

```bash
cd /home/maheen/Desktop/dodo-payments
chmod +x run.sh
./run.sh
```

### Method 3: Using Docker Compose

Run the application using Docker Compose:

```bash
cd /home/maheen/Desktop/dodo-payments
docker-compose up
```

## Running Tests

### Running All Tests

Run all tests using Cargo:

```bash
cd /home/maheen/Desktop/dodo-payments
cargo test
```

To see detailed output:

```bash
cargo test -- --nocapture
```

### Running Specific Tests

Run specific test files:

```bash
# Run user API tests
cargo test user_api_test

# Run authentication tests
cargo test auth_test
```

### Testing Specific Functions

Run specific test functions:

```bash
# Test user registration functionality
cargo test user_api_test::test_register_user

# Test authentication functionality
cargo test auth_test::test_jwt_generation
```

## Manual API Testing

You can test the API endpoints manually using tools like curl or Postman.

### 1. User Registration

```bash
curl -X POST http://localhost:8080/api/users/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "email": "test@example.com",
    "password": "password123"
  }'
```

### 2. User Login (to get JWT token)

```bash
curl -X POST http://localhost:8080/api/users/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "password": "password123"
  }'
```

Save the token received in the response:

```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

### 3. Get User Profile (with JWT Token)

```bash
curl -X GET http://localhost:8080/api/users/profile \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

### 4. Get Account Balance

```bash
curl -X GET http://localhost:8080/api/accounts/balance \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

### 5. Create Transaction

First, register a second user:

```bash
curl -X POST http://localhost:8080/api/users/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "recipient",
    "email": "recipient@example.com",
    "password": "password123"
  }'
```

Then, create a transaction:

```bash
curl -X POST http://localhost:8080/api/transactions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." \
  -d '{
    "recipient_username": "recipient",
    "amount": "10.00",
    "description": "Test payment"
  }'
```

### 6. List Transactions

```bash
curl -X GET http://localhost:8080/api/transactions \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

## Testing JWT Authentication

### Valid Token Test

1. Get a valid token by logging in
2. Use the token to access a protected endpoint
3. Verify you get a successful response

### Invalid Token Tests

1. **Missing Token Test:**

   ```bash
   curl -X GET http://localhost:8080/api/users/profile
   ```

   Expected result: 401 Unauthorized

2. **Invalid Token Format Test:**

   ```bash
   curl -X GET http://localhost:8080/api/users/profile \
     -H "Authorization: Bearer invalid.token.format"
   ```

   Expected result: 401 Unauthorized

3. **Expired Token Test:**
   Use an expired token (you'll need to modify the JWT secret or wait for token expiration)

   ```bash
   curl -X GET http://localhost:8080/api/users/profile \
     -H "Authorization: Bearer expired.token.here"
   ```

   Expected result: 401 Unauthorized

4. **Token with Invalid Signature:**
   Modify a valid token by changing its signature
   ```bash
   curl -X GET http://localhost:8080/api/users/profile \
     -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.INVALID_SIGNATURE"
   ```
   Expected result: 401 Unauthorized

## Automated Test Cases

The Dodo Payments system includes automated tests for critical components:

### User API Tests

- User registration
- User login and JWT generation
- User profile retrieval
- User profile update

### Authentication Tests

- JWT token generation
- JWT token validation
- Authentication middleware

### Transaction Tests

- Transaction creation
- Transaction retrieval
- Transaction listing
- Transaction validation (e.g., insufficient funds)

### Account Tests

- Account balance retrieval
- Account balance updates after transactions

All these tests ensure that the Dodo Payments backend meets the specified requirements and functions correctly.
