#!/bin/bash
# Production deployment script for Dodo Payments (Unix/Linux/macOS)

echo "=== Dodo Payments Production Deployment ==="
echo
echo "This script will build and start the production-ready application."
echo

echo "Starting services..."
docker-compose -f docker-compose.prod.yml up --build -d

echo
echo "Services are starting..."
echo "This may take a minute or two for the first build."
echo
echo "When ready, the API will be available at http://localhost:8080"
echo
echo "To check logs:"
echo "docker-compose -f docker-compose.prod.yml logs -f app"
echo
echo "To stop services:"
echo "docker-compose -f docker-compose.prod.yml down"
