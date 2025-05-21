# Dodo Payments Troubleshooting Guide

This document provides solutions for common issues when working with the Dodo Payments backend.

## SQLx Offline Mode Errors

### Problem: SQLx offline mode errors during compilation

Error messages like:

```
error: `SQLX_OFFLINE=true` but there is no cached data for this query, run `cargo sqlx prepare` to update the query cache or unset `SQLX_OFFLINE`
```

### Solution:

1. **Option 1: Use provided setup script**

   ```bash
   # On Unix/Linux/macOS:
   ./setup-db-and-prepare.sh

   # On Windows:
   setup-db-and-prepare.bat
   ```

2. **Option 2: Manual steps**
   - Start PostgreSQL: `docker-compose up -d db`
   - Wait for PostgreSQL to be ready
   - Run the migrations: `sqlx migrate run`
   - Generate SQLx data: `cargo sqlx prepare --merged`
3. **Option 3: Disable offline mode**
   - Set `SQLX_OFFLINE=false` in your `.env` file
   - This requires a database connection during compilation

## Database Connection Issues

### Problem: Cannot connect to the database

Error messages like:

```
Health check failed: error connecting to database: connection refused
```

### Solution:

1. **Check if PostgreSQL is running**
   ```bash
   docker-compose ps
   ```
2. **Start PostgreSQL if it's not running**
   ```bash
   docker-compose up -d db
   ```
3. **Verify database connection settings**
   - Check the `DATABASE_URL` in your `.env` file
   - For Docker: `postgres://postgres:password@db:5432/dodo_payments`
   - For local development: `postgres://postgres:password@localhost:5432/dodo_payments`

## Docker Build Failures

### Problem: Docker build fails due to SQLx errors

### Solution:

1. **Use the simplified Dockerfile**
   - Use the `Dockerfile` in the repository which is configured to handle SQLx offline mode
2. **Build with SQLx offline mode disabled**
   ```bash
   SQLX_OFFLINE=false docker-compose build
   ```
3. **Generate SQLx data before building**
   - See solutions for SQLx offline mode errors above

### Problem: "Dockerfile cannot be empty" error

### Solution:

1. **Fix line ending issues**

   ```bash
   dos2unix Dockerfile
   ```

2. **Clean Docker build cache**

   ```bash
   docker builder prune -f
   ```

3. **Use the rebuild script**

   ```bash
   # On Unix/Linux/macOS:
   ./rebuild-docker-fresh.sh

   # On Windows:
   rebuild-docker-fresh.bat
   ```

4. **Check your docker-compose.yml for syntax errors**
   - Make sure all indentation and formatting is correct
5. **Track build errors**

   ```bash
   # On Unix/Linux/macOS:
   ./track-build-errors.sh

   # On Windows:
   track-build-errors.bat
   ```

## JWT Authentication Issues

### Problem: Authentication failures with "Invalid token" error

### Solution:

1. **Check if the token has expired**
   - Default expiration is 24 hours
   - Request a new token by logging in again
2. **Verify the JWT_SECRET is consistent**

   - The same `JWT_SECRET` must be used for token generation and verification
   - Check the value in your `.env` file

3. **Ensure the token is correctly included in requests**
   - Format: `Authorization: Bearer YOUR_TOKEN`
   - No extra spaces or characters

## Need More Help?

If you're still experiencing issues, please create an issue on the project repository with:

1. The command you're trying to run
2. The full error message
3. Your environment details (OS, Rust version, etc.)
