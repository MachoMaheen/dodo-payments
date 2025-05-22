#!/bin/bash
# Script to test the Dodo Payments API with improved JSON handling and error reporting

set -e

echo "=== Improved API Testing Script for Dodo Payments ==="

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Define server URL - use port 8082 as in docker-compose
API_URL="http://localhost:8082"

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo -e "${RED}Error: jq is not installed. Please install jq to run this script.${NC}"
    exit 1
fi

# Check if the API is running
echo -e "${BLUE}Checking if API is running...${NC}"
if ! curl -s "${API_URL}/health" > /dev/null; then
    echo -e "${RED}The API is not running. Make sure the Docker containers are up.${NC}"
    exit 1
fi
echo -e "${GREEN}API is up and running${NC}"
echo ""

# Function to make API requests and display results
make_request() {
    local method=$1
    local endpoint=$2
    local data=$3
    local auth_token=$4

    echo -e "${BLUE}Making ${method} request to ${endpoint}${NC}"

    local curl_args=(-s -X "$method" "${API_URL}${endpoint}" -H "Content-Type: application/json")
    
    # Handle authorization properly
    if [ -n "$auth_token" ]; then
        echo -e "${YELLOW}Using auth token: ${auth_token:0:15}...${NC}"
        curl_args+=(-H "Authorization: Bearer ${auth_token}")
    fi

    if [ -n "$data" ]; then
        echo -e "${YELLOW}Request data: ${data}${NC}"
        curl_args+=(-d "$data")
    fi

    # Make the request and capture both stdout and stderr
    local response
    local err_output
    response=$(curl "${curl_args[@]}" 2> >(err_output=$(cat); return 0))
    local status=$?

    if [ $status -ne 0 ]; then
        echo -e "${RED}Curl command failed with status $status${NC}"
        echo -e "${RED}Error: $err_output${NC}"
        return 1
    fi

    # Print raw response for debugging
    echo -e "${YELLOW}Raw response: $response${NC}"

    # Try to parse as JSON
    if echo "$response" | jq -e . > /dev/null 2>&1; then
        # It's valid JSON
        echo -e "${GREEN}Response (JSON):${NC}"
        echo "$response" | jq .
        echo "$response" # Return the response for capturing
    else
        # Not JSON
        echo -e "${RED}Response (not valid JSON):${NC}"
        echo "$response"
        # Try to identify common JSON parsing issues
        if [[ "$response" == *"Invalid numeric literal"* ]]; then
            echo -e "${RED}Error suggests a numeric parsing issue. Check decimal values in responses.${NC}"
        elif [[ "$response" == *"Unexpected token"* ]]; then
            echo -e "${RED}Error suggests malformed JSON. Check response format.${NC}"
        fi
        echo "$response" # Return the response for capturing
    fi
    
    echo ""
}

# Step 1: Test the health endpoint
echo -e "${BLUE}Step 1: Testing health endpoint${NC}"
make_request "GET" "/health" ""

# Step 2: Register a test user
echo -e "${BLUE}Step 2: Registering a test user${NC}"
register_data='{"username":"testuser1","email":"testuser1@example.com","password":"password123"}'
register_response=$(make_request "POST" "/api/users/register" "$register_data")

# Step 3: Try to login with the registered user
echo -e "${BLUE}Step 3: Logging in to get JWT token${NC}"
login_data='{"username":"testuser1","password":"password123"}'
login_response=$(make_request "POST" "/api/users/login" "$login_data")

# Extract token from login response with improved error handling
if echo "$login_response" | jq -e . > /dev/null 2>&1; then
    # JSON is valid, extract token
    if echo "$login_response" | jq -e '.token' > /dev/null 2>&1; then
        token=$(echo "$login_response" | jq -r '.token')
        if [ "$token" == "null" ] || [ -z "$token" ]; then
            echo -e "${RED}Failed to get token. Token is null or empty. Aborting further tests.${NC}"
            exit 1
        fi
        echo -e "${GREEN}Successfully obtained JWT token: ${token:0:15}...${NC}"
        # For debugging, show token structure
        echo -e "${YELLOW}Token has $(echo "$token" | tr -dc '.' | wc -c) dots, which should be 2 for a valid JWT.${NC}"
    else
        echo -e "${RED}Response is valid JSON but doesn't contain a 'token' field.${NC}"
        echo -e "${RED}Response fields: $(echo "$login_response" | jq 'keys')${NC}"
        exit 1
    fi
else
    echo -e "${RED}Failed to parse login response as JSON.${NC}"
    echo -e "${RED}Raw response: $login_response${NC}"
    exit 1
fi
echo ""

# Step 4: Get user profile
echo -e "${BLUE}Step 4: Getting user profile${NC}"
profile_response=$(make_request "GET" "/api/users/profile" "" "$token")

# Step 5: Get account balance
echo -e "${BLUE}Step 5: Getting account balance${NC}"
balance_response=$(make_request "GET" "/api/accounts/balance" "" "$token")

# Step 6: Register a second user (recipient)
echo -e "${BLUE}Step 6: Registering a recipient user${NC}"
recipient_data='{"username":"recipient1","email":"recipient1@example.com","password":"password123"}'
make_request "POST" "/api/users/register" "$recipient_data"

# Step 7: Create a transaction
echo -e "${BLUE}Step 7: Creating a transaction${NC}"
transaction_data='{"recipient_username":"recipient1","amount":"10.00","description":"Test payment"}'
transaction_response=$(make_request "POST" "/api/transactions" "$transaction_data" "$token")

# Step 8: Extract transaction ID if present
if echo "$transaction_response" | jq -e . > /dev/null 2>&1 && echo "$transaction_response" | jq -e '.id' > /dev/null 2>&1; then
    transaction_id=$(echo "$transaction_response" | jq -r '.id')
    
    # Step 9: Get specific transaction details if available
    echo -e "${BLUE}Step 8: Getting transaction details${NC}"
    make_request "GET" "/api/transactions/$transaction_id" "" "$token"
    
    # Step 10: List all transactions
    echo -e "${BLUE}Step 9: Listing all transactions${NC}"
    make_request "GET" "/api/transactions" "" "$token"
else
    echo -e "${RED}Could not extract transaction ID from response.${NC}"
    echo -e "${RED}Raw response: $transaction_response${NC}"
fi

# Step 10: Test with invalid token
echo -e "${BLUE}Step 10: Testing authentication with invalid token${NC}"
make_request "GET" "/api/users/profile" "" "invalid.token.here"

echo -e "${GREEN}API testing completed!${NC}"
