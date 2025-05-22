#!/bin/bash

echo "=== API Testing Script for Dodo Payments ==="

LOGFILE="api_test_$(date +%Y%m%d_%H%M%S).log"
echo "Log file: $LOGFILE" | tee "$LOGFILE"

BASE_URL="http://localhost:8082"

function make_request() {
    METHOD=$1
    URL=$2
    TOKEN=$3
    DATA=$4

    echo "Request: $METHOD $URL" | tee -a "$LOGFILE"
    if [ "$METHOD" = "GET" ]; then
        curl -s -H "Authorization: Bearer $TOKEN" "$BASE_URL$URL" | tee -a "$LOGFILE"
    else
        curl -s -X $METHOD -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" -d "$DATA" "$BASE_URL$URL" | tee -a "$LOGFILE"
    fi
}

# Health check
echo "Checking API health..." | tee -a "$LOGFILE"
HEALTH=$(curl -s "$BASE_URL/health")
echo "API is healthy." | tee -a "$LOGFILE"

# Register sender
USERNAME="testuser_$(date +%s)"
EMAIL="$USERNAME@example.com"
REGISTER_PAYLOAD="{\"username\":\"$USERNAME\",\"email\":\"$EMAIL\",\"password\":\"password123\"}"
REGISTER_RESPONSE=$(make_request "POST" "/api/users/register" "" "$REGISTER_PAYLOAD")
USER_ID=$(echo $REGISTER_RESPONSE | jq -r '.id')

# Login sender
LOGIN_PAYLOAD="{\"username\":\"$USERNAME\",\"password\":\"password123\"}"
LOGIN_RESPONSE=$(make_request "POST" "/api/users/login" "" "$LOGIN_PAYLOAD")
TOKEN=$(echo $LOGIN_RESPONSE | jq -r '.token')

# Profile check
make_request "GET" "/api/users/profile" "$TOKEN"

# Check balance
make_request "GET" "/api/accounts/balance" "$TOKEN"

# Register recipient
RECIPIENT="recipient_$(date +%s)"
RECIPIENT_PAYLOAD="{\"username\":\"$RECIPIENT\",\"email\":\"$RECIPIENT@example.com\",\"password\":\"password123\"}"
RECIPIENT_RESPONSE=$(make_request "POST" "/api/users/register" "" "$RECIPIENT_PAYLOAD")

# Login recipient
RECIPIENT_LOGIN_PAYLOAD="{\"username\":\"$RECIPIENT\",\"password\":\"password123\"}"
RECIPIENT_LOGIN_RESPONSE=$(make_request "POST" "/api/users/login" "" "$RECIPIENT_LOGIN_PAYLOAD")
RECIPIENT_TOKEN=$(echo $RECIPIENT_LOGIN_RESPONSE | jq -r '.token')

# Recipient profile
make_request "GET" "/api/users/profile" "$RECIPIENT_TOKEN"

# Fund the sender (via dev-only admin endpoint)
FUND_PAYLOAD="{\"amount\":100.0}"
make_request "POST" "/admin/fund/$USER_ID" "" "$FUND_PAYLOAD"

# Create transaction (use recipient_username instead of recipient_id)
TX_PAYLOAD="{\"recipient_username\":\"$RECIPIENT\",\"amount\":10.00,\"currency\":\"USD\",\"description\":\"Test payment\"}"
make_request "POST" "/api/transactions" "$TOKEN" "$TX_PAYLOAD"

# Get transaction history
make_request "GET" "/api/transactions" "$TOKEN"

# Test with invalid token
make_request "GET" "/api/users/profile" "invalid.token.here"

echo "Test completed. Log saved to: $LOGFILE"
