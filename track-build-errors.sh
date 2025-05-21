#!/bin/bash
# Improved script to build Docker images and track errors

echo "=== Building Docker images and tracking errors ==="
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="build_errors_$TIMESTAMP.log"

echo "Full build logs will be saved to docker_full_$TIMESTAMP.log"
echo "Error and warning logs will be saved to $LOG_FILE"

# Run docker compose build with full logging
docker compose up --build 2>&1 | tee "docker_full_$TIMESTAMP.log" | grep -i "error\|warning\|fail" > "$LOG_FILE"

echo "============================="
echo "Errors and warnings detected:"
echo "============================="
cat "$LOG_FILE"
echo ""
echo "Build complete. Logs saved to $LOG_FILE"
