#!/bin/bash
# Simple script to build and run Dodo Payments

echo "=== Building and starting Dodo Payments ==="
docker-compose down
docker-compose build
docker-compose up -d

echo "Dodo Payments is starting up..."
echo "API will be available at http://localhost:8080"
echo ""
echo "To check logs: docker-compose logs -f app"
echo "To stop: docker-compose down"
