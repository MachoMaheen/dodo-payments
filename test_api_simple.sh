#!/bin/bash
# Simple script to test the Dodo Payments API

# Define server URL
API_URL="http://localhost:8082"

# Colors for better output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Dodo Payments API Testing ===${NC}"

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo -e "${RED}Error: jq is not installed. Please install jq to run this script.${NC}"
    exit 1
fi

# Check if the API is running
echo -e "1. ${BLUE}Checking if API is running...${NC}"
health_response=$(curl -s "$API_URL/health")
echo "$health_response" | jq .
echo ""

# Register a test user
echo -e "2. ${BLUE}Registering a test user...${NC}"
register_response=$(curl -s -X POST "$API_URL/api/users/register" \
    -H "Content-Type: application/json" \
    -d '{"username":"testuser1","email":"testuser1@example.com","password":"password123"}')

if echo "$register_response" | jq . > /dev/null 2>&1; then
    echo "$register_response" | jq .
else
    echo "Error: $register_response"
fi
echo ""

# Login to get token
echo -e "3. ${BLUE}Logging in to get JWT token...${NC}"
login_response=$(curl -s -X POST "$API_URL/api/users/login" \
    -H "Content-Type: application/json" \
    -d '{"username":"testuser1","password":"password123"}')

if echo "$login_response" | jq -e . > /dev/null 2>&1; then
    echo "$login_response" | jq .
    token=$(echo "$login_response" | jq -r .token)
    if [ -n "$token" ]; then
        echo -e "${GREEN}Successfully obtained token${NC}"
    else
        echo -e "${RED}Failed to get token from response${NC}"
        exit 1
    fi
else
    echo -e "${RED}Failed to parse login response: $login_response${NC}"
    exit 1
fi
echo ""

# Get user profile
echo -e "4. ${BLUE}Getting user profile...${NC}"
profile_response=$(curl -s -X GET "$API_URL/api/users/profile" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $token")

echo "Raw response: $profile_response"
if echo "$profile_response" | jq -e . > /dev/null 2>&1; then
    echo "$profile_response" | jq .
else
    echo "Error parsing JSON"
fi
echo ""

# Get account balance
echo -e "5. ${BLUE}Getting account balance...${NC}"
balance_response=$(curl -s -X GET "$API_URL/api/accounts/balance" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $token")

echo "Raw response: $balance_response"
if echo "$balance_response" | jq -e . > /dev/null 2>&1; then
    echo "$balance_response" | jq .
else
    echo "Error parsing JSON"
fi
echo ""

# Register a second user (recipient)
echo -e "6. ${BLUE}Registering a recipient user...${NC}"
recipient_response=$(curl -s -X POST "$API_URL/api/users/register" \
    -H "Content-Type: application/json" \
    -d '{"username":"recipient1","email":"recipient1@example.com","password":"password123"}')

echo "$recipient_response" | jq .
echo ""

# Create a transaction
echo -e "7. ${BLUE}Creating a transaction...${NC}"
transaction_response=$(curl -s -X POST "$API_URL/api/transactions" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $token" \
    -d '{"recipient_username":"recipient1","amount":"10.00","currency":"USD","description":"Test payment"}')

echo "$transaction_response" | jq .

# Extract transaction ID
if transaction_id=$(echo "$transaction_response" | jq -r .id 2>/dev/null) && [ "$transaction_id" != "null" ] && [ -n "$transaction_id" ]; then
    echo -e "${GREEN}Transaction created with ID: $transaction_id${NC}"
    echo ""
    
    # Get transaction details
    echo -e "8. ${BLUE}Getting transaction details...${NC}"
    tx_details=$(curl -s -X GET "$API_URL/api/transactions/$transaction_id" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $token")
    
    echo "$tx_details" | jq .
    echo ""
    
    # List all transactions
    echo -e "9. ${BLUE}Listing all transactions...${NC}"
    all_tx=$(curl -s -X GET "$API_URL/api/transactions" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $token")
    
    echo "$all_tx" | jq .
    echo ""
else
    echo -e "${RED}Could not extract transaction ID from response${NC}"
fi

# Test invalid authentication
echo -e "10. ${BLUE}Testing with invalid token...${NC}"
invalid_auth=$(curl -s -X GET "$API_URL/api/users/profile" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer invalid.token.here")

echo "$invalid_auth" | jq .
echo ""

echo -e "${GREEN}API testing completed!${NC}"
