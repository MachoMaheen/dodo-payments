#!/bin/bash
# Advanced token test script that handles malformed tokens

# Define server URL
API_URL="http://localhost:8082"

# Colors for better output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Dodo Payments Token Fix Test ===${NC}"

# Test login endpoint first without trying to parse the response as JSON
echo -e "${BLUE}1. Testing login endpoint (raw response)...${NC}"
login_raw=$(curl -s -X POST "$API_URL/api/users/login" \
    -H "Content-Type: application/json" \
    -d '{"username":"testuser1","password":"password123"}')

echo "Raw login response:"
echo "$login_raw"
echo

# Store the raw login response for analysis
echo "$login_raw" > token_response.json
echo -e "${GREEN}Raw response saved to token_response.json${NC}"
echo

# Check specific endpoints that don't require authentication
echo -e "${BLUE}2. Testing health endpoint...${NC}"
health_response=$(curl -s "$API_URL/health")
echo "$health_response"
echo

# Registering a new test user
echo -e "${BLUE}3. Registering a new test user...${NC}"
register_response=$(curl -s -X POST "$API_URL/api/users/register" \
    -H "Content-Type: application/json" \
    -d '{"username":"testuser_new","email":"testuser_new@example.com","password":"password123"}')

echo "Raw registration response:"
echo "$register_response"
echo

echo -e "${GREEN}Token testing complete. Check token_response.json for token analysis${NC}"
