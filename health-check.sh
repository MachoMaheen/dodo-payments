#!/bin/bash
# health-check.sh: Health check script for Dodo Payments

set -e

HOST=${1:-"localhost"}
PORT=${2:-"8080"}
TIMEOUT=${3:-"5"}

echo "Checking health of Dodo Payments at $HOST:$PORT..."

# Try to access the health endpoint with timeout
if curl --max-time $TIMEOUT -s "http://$HOST:$PORT/health" | grep -q "healthy"; then
  echo "✅ Service is healthy"
  exit 0
else
  echo "❌ Service is unhealthy"
  exit 1
fi
