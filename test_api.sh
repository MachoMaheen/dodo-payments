#!/bin/bash
# Script to test the Dodo Payments API

set -e

echo "=== API Testing Script for Dodo Payments ==="

# Ensure the application is running
if ! curl -s http://localhost:8080/api/health > /dev/null; then
    echo "The application does not seem to be running. Start it with ./run.sh"
    exit 1
fi

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to make API requests and display results
function make_request() {
    local method=$1
    local endpoint=$2
    local data=$3
    local auth_header=$4
    
    echo -e "${BLUE}Making ${method} request to ${endpoint}${NC}"
    
    local headers="-H \"Content-Type: application/json\""
    if [ ! -z "$auth_header" ]; then
        headers="$headers -H \"Authorization: Bearer $auth_header\""
    fi
    
    local cmd="curl -s -X $method http://localhost:8080$endpoint $headers"
    if [ ! -z "$data" ]; then
        cmd="$cmd -d '$data'"
    fi
    
    # Execute command
    local response=$(eval $cmd)
    
    # Check if response is valid JSON
    if echo "$response" | jq . > /dev/null 2>&1; then
        echo -e "${GREEN}Response:${NC}"
        echo "$response" | jq .
    else
        echo -e "${RED}Response:${NC}"
        echo "$response"
    fi
    
    echo ""
    
    # Return response for potential processing
    echo "$response"
}

# Register a test user
echo -e "${BLUE}1. Registering a test user...${NC}"
register_response=$(make_request "POST" "/api/users/register" '{
    "username": "testuser",
    "email": "test@example.com",
    "password": "password123"
}')

# Login to get JWT token
echo -e "${BLUE}2. Logging in to get JWT token...${NC}"
login_response=$(make_request "POST" "/api/users/login" '{
    "username": "testuser",
    "password": "password123"
}')

# Extract token from response
token=$(echo $login_response | jq -r '.token')

if [ "$token" == "null" ] || [ -z "$token" ]; then
    echo -e "${RED}Failed to get token. Aborting further tests.${NC}"
    exit 1
fi

echo -e "${GREEN}Successfully obtained JWT token: ${token:0:15}...${NC}"

# Get user profile
echo -e "${BLUE}3. Getting user profile...${NC}"
make_request "GET" "/api/users/profile" "" "$token"

# Get account balance
echo -e "${BLUE}4. Getting account balance...${NC}"
make_request "GET" "/api/accounts/balance" "" "$token"

# Register a second user (recipient)
echo -e "${BLUE}5. Registering a recipient user...${NC}"
make_request "POST" "/api/users/register" '{
    "username": "recipient",
    "email": "recipient@example.com",
    "password": "password123"
}'

# Create a transaction
echo -e "${BLUE}6. Creating a transaction...${NC}"
make_request "POST" "/api/transactions" '{
    "recipient_username": "recipient",
    "amount": "10.00",
    "description": "Test payment"
}' "$token"

# Get list of transactions
echo -e "${BLUE}7. Getting list of transactions...${NC}"
make_request "GET" "/api/transactions" "" "$token"

# Test invalid token
echo -e "${BLUE}8. Testing authentication with invalid token...${NC}"
make_request "GET" "/api/users/profile" "" "invalid.token.here"

echo -e "${GREEN}API testing completed!${NC}"
