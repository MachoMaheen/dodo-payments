#!/bin/bash
# Enhanced test script for Dodo Payments API with reliable token handling

# Define server URL
API_URL="http://localhost:8082"

# Colors for better output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m'

echo -e "${BLUE}=== Dodo Payments API Testing Suite ===${NC}"

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo -e "${RED}Error: jq is not installed. Please install jq to run this script.${NC}"
    exit 1
fi

# Function to generate a unique test username
generate_username() {
    echo "testuser_$(date +%s%N | md5sum | head -c 8)"
}

# Function to make request and handle response
make_request() {
    local method=$1
    local endpoint=$2
    local data=$3
    local auth_header=$4

    # Build the curl command
    if [ -n "$data" ]; then
        if [ -n "$auth_header" ]; then
            curl -s -X "$method" "${API_URL}${endpoint}" \
                -H "Content-Type: application/json" \
                -H "Authorization: $auth_header" \
                -d "$data"
        else
            curl -s -X "$method" "${API_URL}${endpoint}" \
                -H "Content-Type: application/json" \
                -d "$data"
        fi
    else
        if [ -n "$auth_header" ]; then
            curl -s -X "$method" "${API_URL}${endpoint}" \
                -H "Content-Type: application/json" \
                -H "Authorization: $auth_header"
        else
            curl -s -X "$method" "${API_URL}${endpoint}" \
                -H "Content-Type: application/json"
        fi
    fi
}

# Test health endpoint
echo -e "${BLUE}Step 1: Testing health endpoint${NC}"
health_response=$(make_request "GET" "/health" "" "")
echo -e "${YELLOW}Response:${NC}"
echo "$health_response" | jq .
echo ""

# Register a new user with unique username
USERNAME=$(generate_username)
EMAIL="${USERNAME}@example.com"
PASSWORD="password123"

echo -e "${BLUE}Step 2: Registering a new user (${USERNAME})${NC}"
register_data="{\"username\":\"${USERNAME}\",\"email\":\"${EMAIL}\",\"password\":\"${PASSWORD}\"}"
register_response=$(make_request "POST" "/api/users/register" "$register_data" "")
echo -e "${YELLOW}Response:${NC}"
echo "$register_response" | jq .
echo ""

# Login user to get JWT token
echo -e "${BLUE}Step 3: Logging in to get JWT token${NC}"
login_data="{\"username\":\"${USERNAME}\",\"password\":\"${PASSWORD}\"}"
login_response=$(make_request "POST" "/api/users/login" "$login_data" "")
echo -e "${YELLOW}Raw login response:${NC}"
echo "$login_response"
echo ""

# Save response to file for better token extraction
echo "$login_response" > login_response.tmp

# Extract token using grep to avoid line break issues
token=$(grep -o '"token":"[^"]*' login_response.tmp | sed 's/"token":"//' | tr -d '\n' | tr -d ' ')
if [ -z "$token" ]; then
    echo -e "${RED}Failed to extract token from response${NC}"
    exit 1
else
    echo -e "${GREEN}Successfully extracted JWT token: ${token:0:20}...${NC}"
    echo ""
fi

# Test user profile endpoint
echo -e "${BLUE}Step 4: Getting user profile${NC}"
profile_response=$(make_request "GET" "/api/users/profile" "" "Bearer $token")
echo -e "${YELLOW}Response:${NC}"
echo "$profile_response" | jq .
echo ""

# Test account balance endpoint
echo -e "${BLUE}Step 5: Getting account balance${NC}"
balance_response=$(make_request "GET" "/api/accounts/balance" "" "Bearer $token")
echo -e "${YELLOW}Response:${NC}"
echo "$balance_response" | jq .
echo ""

# Register a recipient user
RECIPIENT_USERNAME=$(generate_username)
RECIPIENT_EMAIL="${RECIPIENT_USERNAME}@example.com"

echo -e "${BLUE}Step 6: Registering a recipient user (${RECIPIENT_USERNAME})${NC}"
recipient_data="{\"username\":\"${RECIPIENT_USERNAME}\",\"email\":\"${RECIPIENT_EMAIL}\",\"password\":\"${PASSWORD}\"}"
recipient_response=$(make_request "POST" "/api/users/register" "$recipient_data" "")
echo -e "${YELLOW}Response:${NC}"
echo "$recipient_response" | jq .
echo ""

# Create a transaction
echo -e "${BLUE}Step 7: Creating a transaction${NC}"
transaction_data="{\"recipient_username\":\"${RECIPIENT_USERNAME}\",\"amount\":\"10.00\",\"description\":\"Test payment\"}"
transaction_response=$(make_request "POST" "/api/transactions" "$transaction_data" "Bearer $token")
echo -e "${YELLOW}Response:${NC}"
echo "$transaction_response" | jq .
echo ""

# Extract transaction ID
transaction_id=$(echo "$transaction_response" | jq -r '.id // empty')
if [ -n "$transaction_id" ]; then
    echo -e "${GREEN}Transaction created with ID: $transaction_id${NC}"
    
    # Get transaction details
    echo -e "${BLUE}Step 8: Getting transaction details${NC}"
    tx_details=$(make_request "GET" "/api/transactions/$transaction_id" "" "Bearer $token")
    echo -e "${YELLOW}Response:${NC}"
    echo "$tx_details" | jq .
    echo ""
    
    # List all transactions
    echo -e "${BLUE}Step 9: Listing all transactions${NC}"
    all_tx=$(make_request "GET" "/api/transactions" "" "Bearer $token")
    echo -e "${YELLOW}Response:${NC}"
    echo "$all_tx" | jq .
    echo ""
else
    echo -e "${RED}Could not extract transaction ID from response${NC}"
fi

# Clean up temporary files
rm -f login_response.tmp

echo -e "${GREEN}API testing completed!${NC}"
