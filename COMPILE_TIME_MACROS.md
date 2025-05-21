# Using SQLx Compile-Time Macros in Dodo Payments

This guide explains how to use SQLx compile-time macros in the Dodo Payments application.

## Benefits of Compile-Time Macros

1. **SQL Verification at Build Time**: Catches errors before runtime
2. **Improved Safety**: Ensures SQL queries are type-checked against the database schema
3. **Better Performance**: No need for runtime SQL parsing

## Requirements

1. A running PostgreSQL database for the compile-time checks
2. The `sqlx-cli` tool installed
3. A valid `sqlx-data.json` file for offline builds

## Setup Process

### 1. Generate SQLx Query Metadata

Run the `prepare-sqlx-data.sh` script to:

- Start a PostgreSQL container
- Run migrations
- Generate the SQLx metadata file

```bash
./prepare-sqlx-data.sh
```

This creates a `sqlx-data.json` file that contains metadata about your SQL queries.

### 2. Build with Compile-Time Checking

Use the provided scripts to build and run the application:

```bash
# If you encounter issues with the regular build script:
./rebuild-docker-fresh.sh
```

Or on Windows:

```cmd
rebuild-docker-fresh.bat
```

This script:

- Ensures `SQLX_OFFLINE=true` is set
- Cleans up Docker build cache
- Builds the Docker image directly
- Starts the services

### 3. Capturing Build Logs

If you encounter any issues during the build process, you can use the log capture scripts:

```bash
# On Unix/Linux/Mac:
./capture-docker-logs.sh

# On Windows:
capture-docker-logs.bat
```

This will generate a timestamped log file with all the build output, which can help diagnose any issues.

## Troubleshooting Common Issues

### "Dockerfile cannot be empty" Error

This is often caused by line ending issues or Docker cache problems. Try:

1. Convert the Dockerfile to Unix line endings:

   ```bash
   dos2unix Dockerfile
   ```

2. Clean Docker build cache:

   ```bash
   docker builder prune -f
   ```

3. Use the `rebuild-docker-fresh.sh` script, which handles these issues.

### SQLx Compile-Time Errors

1. Make sure `sqlx-data.json` is up-to-date with your database schema
2. Ensure every SQL query in your code is captured in the `sqlx-data.json` file
3. Regenerate the SQLx data:
   ```bash
   ./prepare-sqlx-data.sh
   ```

## Adding New Queries

When you add new SQL queries:

1. Make sure your database is running and up-to-date
2. Set `DATABASE_URL` to point to your development database
3. Run `cargo sqlx prepare --database-url ${DATABASE_URL}` to update the metadata
4. Commit the updated `sqlx-data.json` file

## Working with Docker

The Docker setup uses:

- `SQLX_OFFLINE=true` during build to use the metadata
- `sqlx-data.json` file copied into the container
- Compile-time checking via SQLx macros

## Troubleshooting

If you encounter errors like:

```
error: Failed to prepare query: error returned from database: relation "users" does not exist
```

Run the prepare script again to regenerate the SQLx data file:

```bash
./prepare-sqlx-data.sh
```

If you want to debug a specific query, you can temporarily switch to runtime checking by setting `SQLX_OFFLINE=false` in your development environment.
