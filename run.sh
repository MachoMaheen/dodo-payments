#!/bin/bash
# Script to run the Dodo Payments application

echo "=== Starting Dodo Payments Application ==="
echo "NOTE: This script is for running without Docker."
echo "For Docker setup, use ./start.sh instead"
echo ""

# Ensure JWT secret exists
if [ ! -f jwt_secret.txt ]; then
    echo "Creating JWT secret..."
    echo "secretjwtsecretdodopaymentsjwtsecret123456" > jwt_secret.txt
fi

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo "Creating .env file..."
    cat > .env << EOL
DATABASE_URL=postgres://postgres:password@localhost:5432/dodo_payments
SERVER_ADDR=127.0.0.1:8080
RUST_LOG=info
SQLX_OFFLINE=true
EOL
fi
    sudo -u postgres psql -c "ALTER USER dodo WITH SUPERUSER;"
fi

# Enable SQLX offline mode
export SQLX_OFFLINE=true

# Build and run the application
echo "Building and running Dodo Payments..."
cargo run

# Clean up previous Docker resources
docker-compose down

# Build and capture errors
echo "Building and starting services ($(date))..." > build_errors.log
SQLX_OFFLINE=true docker-compose build --no-cache 2>&1 | tee -a build_errors.log

# Check for build success
if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo "Build succeeded, starting services..." | tee -a build_errors.log
    SQLX_OFFLINE=true docker-compose up -d 2>&1 | tee -a build_errors.log
    echo "Services started successfully. Check build_errors.log for details." | tee -a build_errors.log
    echo "To view application logs: docker-compose logs -f app"
else
    echo "Build failed. Check build_errors.log for details." | tee -a build_errors.log
    grep -i "error\|warning" build_errors.log > build_errors_summary.log
    echo "A summary of errors and warnings has been saved to build_errors_summary.log"
    
    # Try to determine what's still failing
    echo "Attempting to fix remaining issues..."
    ./fix_code_issues.sh
fi