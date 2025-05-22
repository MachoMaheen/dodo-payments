#!/bin/bash

set -e

# === Parse CLI flags ===
HEADLESS=false
for arg in "$@"; do
  if [ "$arg" == "--headless" ]; then
    HEADLESS=true
  fi
done

# === Log Setup ===
timestamp=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="api_test_${timestamp}.log"
exec > >(tee -a "$LOG_FILE") 2>&1
exec 3>&1

# === Colors ===
if [ "$HEADLESS" = false ]; then
  GREEN='\033[0;32m'
  RED='\033[0;31m'
  BLUE='\033[0;34m'
  NC='\033[0m'
else
  GREEN='' RED='' BLUE='' NC=''
fi

echo "=== API Testing Script for Dodo Payments ==="
echo "Log file: $LOG_FILE"
[ "$HEADLESS" = true ] && echo "Running in HEADLESS mode"

# === Config ===
API_URL="http://localhost:8082"
UNAME="testuser_$(date +%s)"
EMAIL="${UNAME}@example.com"
PASS="password123"
RECIPIENT="recipient_$(date +%s)"

# === Utility ===
make_request() {
  local method=$1
  local endpoint=$2
  local data=$3
  local auth_token=$4

  echo -e "${BLUE}Request: ${method} ${endpoint}${NC}"
  local curl_args=(-s -X "$method" "${API_URL}${endpoint}" -H "Content-Type: application/json")
  [ -n "$auth_token" ] && curl_args+=(-H "Authorization: Bearer $auth_token")
  [ -n "$data" ] && curl_args+=(-d "$data")

  local response
  response=$(curl "${curl_args[@]}")
  local status=$?

  if [ $status -ne 0 ]; then
    echo -e "${RED}Curl failed with status $status${NC}"
    exit 1
  fi

  if echo "$response" | jq . > /dev/null 2>&1; then
    echo -e "${GREEN}Response:${NC}"
    echo "$response" | jq .
  else
    echo -e "${RED}Invalid JSON:${NC}"
    echo "$response"
  fi

  echo ""
  echo "$response" >&3
}

# === Start ===

echo -e "${BLUE}Checking API health...${NC}"
if ! curl -s "${API_URL}/health" > /dev/null; then
  echo -e "${RED}API not reachable. Start backend.${NC}"
  exit 1
fi
echo -e "${GREEN}API is healthy.${NC}"

# Register user
register_data="{\"username\":\"$UNAME\",\"email\":\"$EMAIL\",\"password\":\"$PASS\"}"
make_request "POST" "/api/users/register" "$register_data" 3>&1 1>&2

# Login user
login_data="{\"username\":\"$UNAME\",\"password\":\"$PASS\"}"
login_response=$(make_request "POST" "/api/users/login" "$login_data" 3>&1 1>&2)
token=$(echo "$login_response" | jq -r '.token')

if [ -z "$token" ] || [ "$token" = "null" ]; then
  echo -e "${RED}Token extraction failed${NC}"
  exit 1
fi
echo -e "${GREEN}Token: ${token:0:16}...${NC}"

# Profile and balance
make_request "GET" "/api/users/profile" "" "$token" 3>&1 1>&2
make_request "GET" "/api/accounts/balance" "" "$token" 3>&1 1>&2

# Register recipient
recipient_data="{\"username\":\"$RECIPIENT\",\"email\":\"${RECIPIENT}@example.com\",\"password\":\"password123\"}"
make_request "POST" "/api/users/register" "$recipient_data" 3>&1 1>&2

# Login recipient + extract ID
recipient_login_data="{\"username\":\"$RECIPIENT\",\"password\":\"password123\"}"
recipient_login=$(make_request "POST" "/api/users/login" "$recipient_login_data" 3>&1 1>&2)
recipient_token=$(echo "$recipient_login" | jq -r '.token')
recipient_profile=$(make_request "GET" "/api/users/profile" "" "$recipient_token" 3>&1 1>&2)
recipient_id=$(echo "$recipient_profile" | jq -r '.id // empty')

[ -z "$recipient_id" ] && echo -e "${RED}No recipient ID${NC}" && exit 1

# Create transaction
transaction_data="{\"recipient_id\":\"$recipient_id\",\"amount\":10.00,\"currency\":\"USD\",\"description\":\"Test payment\"}"

transaction_response=$(make_request "POST" "/api/transactions" "$transaction_data" "$token" 3>&1 1>&2)
transaction_id=$(echo "$transaction_response" | jq -r '.id // empty')

# Retrieve transaction
[ -n "$transaction_id" ] && make_request "GET" "/api/transactions/$transaction_id" "" "$token" 3>&1 1>&2
make_request "GET" "/api/transactions" "" "$token" 3>&1 1>&2

# Invalid token test
make_request "GET" "/api/users/profile" "" "invalid.token.here" 3>&1 1>&2

exec 3>&-
echo -e "${GREEN}Test completed. Log saved to: ${LOG_FILE}${NC}"
