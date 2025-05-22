#!/bin/bash
# Enhanced test script for Dodo Payments API with funding + verification

API_URL="http://localhost:8082"

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m'

echo -e "${BLUE}=== Dodo Payments API Testing Suite ===${NC}"

# Check jq dependency
if ! command -v jq &> /dev/null; then
    echo -e "${RED}Error: jq is not installed. Please install jq to run this script.${NC}"
    exit 1
fi

generate_username() {
    echo "testuser_$(date +%s%N | md5sum | head -c 8)"
}

make_request() {
    local method=$1
    local endpoint=$2
    local data=$3
    local auth_header=$4

    if [ -n "$data" ]; then
        if [ -n "$auth_header" ]; then
            curl -s -X "$method" "${API_URL}${endpoint}" \
                -H "Content-Type: application/json" \
                -H "Authorization: $auth_header" \
                --data-raw "$data"
        else
            curl -s -X "$method" "${API_URL}${endpoint}" \
                -H "Content-Type: application/json" \
                --data-raw "$data"
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

# Function for testing rate limits - shows headers
make_request_with_headers() {
    local method=$1
    local endpoint=$2
    local data=$3
    local auth_header=$4

    if [ -n "$data" ]; then
        if [ -n "$auth_header" ]; then
            curl -v -X "$method" "${API_URL}${endpoint}" \
                -H "Content-Type: application/json" \
                -H "Authorization: $auth_header" \
                --data-raw "$data" 2>&1
        else
            curl -v -X "$method" "${API_URL}${endpoint}" \
                -H "Content-Type: application/json" \
                --data-raw "$data" 2>&1
        fi
    else
        if [ -n "$auth_header" ]; then
            curl -v -X "$method" "${API_URL}${endpoint}" \
                -H "Content-Type: application/json" \
                -H "Authorization: $auth_header" 2>&1
        else
            curl -v -X "$method" "${API_URL}${endpoint}" \
                -H "Content-Type: application/json" 2>&1
        fi
    fi
}

# Step 1: Health check
echo -e "${BLUE}Step 1: Testing health endpoint${NC}"
health_response=$(make_request "GET" "/health" "" "")
echo -e "${YELLOW}Response:${NC}"
echo "$health_response" | jq .
echo ""

# Step 2: Register sender
SENDER_USERNAME=$(generate_username)
SENDER_EMAIL="${SENDER_USERNAME}@example.com"
PASSWORD="password123"
echo -e "${BLUE}Step 2: Registering sender (${SENDER_USERNAME})${NC}"
register_data="{\"username\":\"${SENDER_USERNAME}\",\"email\":\"${SENDER_EMAIL}\",\"password\":\"${PASSWORD}\"}"
register_response=$(make_request "POST" "/api/users/register" "$register_data" "")
echo "$register_response" | jq .
SENDER_ID=$(echo "$register_response" | jq -r '.id')
echo ""

# Step 3: Login sender
echo -e "${BLUE}Step 3: Logging in sender${NC}"
login_data="{\"username\":\"${SENDER_USERNAME}\",\"password\":\"${PASSWORD}\"}"
login_response=$(make_request "POST" "/api/users/login" "$login_data" "")
SENDER_TOKEN=$(echo "$login_response" | jq -r '.token')
echo -e "${GREEN}Token: ${SENDER_TOKEN:0:20}...${NC}"
echo ""

# Step 4: Get sender profile
echo -e "${BLUE}Step 4: Fetching sender profile${NC}"
profile_response=$(make_request "GET" "/api/users/profile" "" "Bearer $SENDER_TOKEN")
echo "$profile_response" | jq .
echo ""

# Step 5: Get sender balance
echo -e "${BLUE}Step 5: Checking sender balance before funding${NC}"
sender_balance_before=$(make_request "GET" "/api/accounts/balance" "" "Bearer $SENDER_TOKEN")
echo "$sender_balance_before" | jq .
echo ""

# Step 5.1: Auto-fund sender
echo -e "${BLUE}Step 5.1: Funding sender via /admin/fund/${SENDER_ID}${NC}"
fund_data="{\"amount\":100.0}"
fund_response=$(make_request "POST" "/admin/fund/${SENDER_ID}" "$fund_data" "")
echo "$fund_response" | jq .
echo ""

# Step 5.2: Check updated sender balance
echo -e "${BLUE}Step 5.2: Verifying sender balance after funding${NC}"
sender_balance_after=$(make_request "GET" "/api/accounts/balance" "" "Bearer $SENDER_TOKEN")
echo "$sender_balance_after" | jq .
echo ""

# Step 6: Register recipient
RECIPIENT_USERNAME=$(generate_username)
RECIPIENT_EMAIL="${RECIPIENT_USERNAME}@example.com"
echo -e "${BLUE}Step 6: Registering recipient (${RECIPIENT_USERNAME})${NC}"
recipient_data="{\"username\":\"${RECIPIENT_USERNAME}\",\"email\":\"${RECIPIENT_EMAIL}\",\"password\":\"${PASSWORD}\"}"
recipient_response=$(make_request "POST" "/api/users/register" "$recipient_data" "")
echo "$recipient_response" | jq .
RECIPIENT_ID=$(echo "$recipient_response" | jq -r '.id')
echo ""

# Step 7: Login recipient
echo -e "${BLUE}Step 7: Logging in recipient${NC}"
recipient_login_data="{\"username\":\"${RECIPIENT_USERNAME}\",\"password\":\"${PASSWORD}\"}"
recipient_login_response=$(make_request "POST" "/api/users/login" "$recipient_login_data" "")
RECIPIENT_TOKEN=$(echo "$recipient_login_response" | jq -r '.token')
echo -e "${GREEN}Token: ${RECIPIENT_TOKEN:0:20}...${NC}"
echo ""

# Step 7.1: Check recipient balance before transfer
echo -e "${BLUE}Step 7.1: Checking recipient balance before transfer${NC}"
recipient_balance_before=$(make_request "GET" "/api/accounts/balance" "" "Bearer $RECIPIENT_TOKEN")
balance_before=$(echo "$recipient_balance_before" | jq -r '.balance')
echo "$recipient_balance_before" | jq .
echo ""

# Step 8: Create transaction
echo -e "${BLUE}Step 8: Creating transaction to recipient${NC}"
transaction_data="{\"recipient_id\":\"$RECIPIENT_ID\",\"amount\":10.0,\"currency\":\"USD\",\"description\":\"Test payment\"}"
echo -e "${YELLOW}Transaction Payload:${NC}"
echo "$transaction_data"

transaction_response=$(make_request "POST" "/api/transactions" "$transaction_data" "Bearer $SENDER_TOKEN")
echo "$transaction_response" | jq .
echo ""

# Step 9: Confirm recipient balance increased
echo -e "${BLUE}Step 9: Checking recipient balance after transaction${NC}"
recipient_balance_after=$(make_request "GET" "/api/accounts/balance" "" "Bearer $RECIPIENT_TOKEN")
balance_after=$(echo "$recipient_balance_after" | jq -r '.balance')
echo "$recipient_balance_after" | jq .

expected_balance=$(awk "BEGIN {print $balance_before + 10.00}")
if (( $(awk "BEGIN {print ($balance_after == $expected_balance)}") )); then
    echo -e "${GREEN}✅ Recipient balance correctly increased by 10.00 USD${NC}"
else
    echo -e "${RED}❌ Balance mismatch. Expected: $expected_balance, Got: $balance_after${NC}"
fi

echo ""
echo -e "${GREEN}🎉 API testing completed!${NC}"

# Add sections for testing rate limiting and invalid tokens
echo ""
echo -e "${BLUE}=== Additional Security Tests ===${NC}"

# Test invalid token
echo -e "${BLUE}Testing Invalid Token Handling${NC}"
echo -e "${YELLOW}Attempt to access profile with invalid token:${NC}"
invalid_token="Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkludmFsaWQgVG9rZW4iLCJpYXQiOjE1MTYyMzkwMjJ9.invalid_signature"
invalid_token_response=$(make_request "GET" "/api/users/profile" "" "$invalid_token")
echo "$invalid_token_response" | jq .

echo -e "${YELLOW}Attempt to access balance with invalid token:${NC}"
invalid_balance_response=$(make_request "GET" "/api/accounts/balance" "" "$invalid_token")
echo "$invalid_balance_response" | jq .

echo -e "${YELLOW}Attempt to access transactions with invalid token:${NC}"
invalid_transactions_response=$(make_request "GET" "/api/transactions" "" "$invalid_token")
echo "$invalid_transactions_response" | jq .

# Test expired token (simulation - we're using an old or malformed token)
echo -e "${BLUE}Testing Expired Token Handling${NC}"
expired_token="Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiZTJiY2U3ZjctNTgwMS00YmVlLWE4MTktYjRjNTQzYzYzMjUwIiwiZXhwIjoxNjIwMDAwMDAwfQ.G8qrPVZlDT0HVi8IHg33bKVd2De1HLSf9MCyg-wopLI"
echo -e "${YELLOW}Attempt to access profile with expired token:${NC}"
expired_token_response=$(make_request "GET" "/api/users/profile" "" "$expired_token")
echo "$expired_token_response" | jq .

# Test rate limiting
echo -e "${BLUE}Testing Rate Limiting${NC}"
echo -e "${YELLOW}Making multiple requests to test rate limiting on login endpoint:${NC}"

# Show rate limit headers for first request
echo -e "${YELLOW}First request with rate limit headers:${NC}"
rate_limit_headers=$(make_request_with_headers "POST" "/api/users/login" "$login_data" "")
echo "$rate_limit_headers" | grep -i "ratelimit"

# Make multiple requests to trigger rate limiting
echo -e "${YELLOW}Making 5 rapid requests to test rate limiting:${NC}"
for i in {1..5}; do
    echo -e "${YELLOW}Request $i:${NC}"
    quick_response=$(make_request "POST" "/api/users/login" "$login_data" "")
    echo "$quick_response" | jq .
    sleep 0.2
done

# Try to hit the rate limit (this might take a while, so we'll limit to 10 more requests)
echo -e "${YELLOW}Attempting to reach rate limit (10 more rapid requests):${NC}"
for i in {1..10}; do
    echo -e "${YELLOW}Rapid request $i:${NC}"
    limit_response=$(make_request "POST" "/api/users/login" "$login_data" "")
    if echo "$limit_response" | grep -q "Too Many Requests"; then
        echo -e "${GREEN}✅ Rate limiting successfully triggered!${NC}"
        break
    fi
    echo "$limit_response" | jq .
    sleep 0.1
done

# Final check with headers to see rate limit status
echo -e "${YELLOW}Checking rate limit headers after multiple requests:${NC}"
final_headers=$(make_request_with_headers "POST" "/api/users/login" "$login_data" "")
echo "$final_headers" | grep -i "ratelimit"

echo ""
echo -e "${GREEN}🎉 All tests completed!${NC}"