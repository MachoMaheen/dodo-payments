#!/bin/bash
# Complete API testing script focused on working endpoints

# Define server URL
API_URL="http://localhost:8082"

# Colors for better output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Dodo Payments API Testing (No Auth Required) ===${NC}"

# Test 1: Health endpoint
echo -e "${BLUE}1. Testing health endpoint...${NC}"
health_response=$(curl -s "$API_URL/health")
echo "Response: $health_response"
echo

# Test 2: Register a new user
echo -e "${BLUE}2. Registering a test user with unique name...${NC}"
username="testuser_$(date +%s)"
register_response=$(curl -s -X POST "$API_URL/api/users/register" \
    -H "Content-Type: application/json" \
    -d "{\"username\":\"$username\",\"email\":\"$username@example.com\",\"password\":\"password123\"}")

echo "Response: $register_response"
echo

# Test 3: Login with the new user 
echo -e "${BLUE}3. Logging in with the new user...${NC}"
login_response=$(curl -s -X POST "$API_URL/api/users/login" \
    -H "Content-Type: application/json" \
    -d "{\"username\":\"$username\",\"password\":\"password123\"}")

echo "Raw login response:"
echo "$login_response"
echo

echo -e "${GREEN}API testing complete for endpoints that don't require authentication${NC}"
echo -e "${RED}Note: Authentication is not working correctly due to malformed token response${NC}"
