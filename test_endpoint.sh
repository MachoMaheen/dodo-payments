#!/bin/bash
# Script for endpoint-by-endpoint testing of the Dodo Payments API

set -e

echo "=== Endpoint Tester for Dodo Payments API ==="

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Define server URL
API_URL="http://localhost:8082"

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo -e "${RED}Error: jq is not installed. Please install jq to run this script.${NC}"
    exit 1
fi

# Functions to test each endpoint separately
test_health() {
    echo -e "${BLUE}Testing: Health Check Endpoint${NC}"
    curl -s "${API_URL}/health" | jq .
}

test_register() {
    echo -e "${BLUE}Testing: User Registration${NC}"
    username="testuser$(date +%s)"
    echo -e "${YELLOW}Using username: $username${NC}"
    
    register_data="{\"username\":\"$username\",\"email\":\"$username@example.com\",\"password\":\"password123\"}"
    curl -s -X POST "${API_URL}/api/users/register" \
        -H "Content-Type: application/json" \
        -d "$register_data" | jq .
        
    echo -e "${YELLOW}Username $username can be used for further tests${NC}"
    echo "$username" > last_username.txt
}

test_login() {
    echo -e "${BLUE}Testing: User Login${NC}"
    
    # Use the last registered username or a default
    username=$(cat last_username.txt 2>/dev/null || echo "testuser1")
    echo -e "${YELLOW}Using username: $username${NC}"
    
    login_data="{\"username\":\"$username\",\"password\":\"password123\"}"
    login_response=$(curl -s -X POST "${API_URL}/api/users/login" \
        -H "Content-Type: application/json" \
        -d "$login_data")
    
    echo "$login_response" | jq .
    
    # Extract token
    if echo "$login_response" | jq -e '.token' > /dev/null 2>&1; then
        token=$(echo "$login_response" | jq -r '.token')
        echo "$token" > token.txt
        echo -e "${GREEN}Token saved to token.txt${NC}"
    else
        echo -e "${RED}Failed to get token${NC}"
    fi
}

test_profile() {
    echo -e "${BLUE}Testing: Get User Profile${NC}"
    
    if [ ! -f token.txt ]; then
        echo -e "${RED}No token found. Run login test first.${NC}"
        return 1
    fi
    
    token=$(cat token.txt)
    curl -s -X GET "${API_URL}/api/users/profile" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $token" | jq .
}

test_balance() {
    echo -e "${BLUE}Testing: Get Account Balance${NC}"
    
    if [ ! -f token.txt ]; then
        echo -e "${RED}No token found. Run login test first.${NC}"
        return 1
    fi
    
    token=$(cat token.txt)
    curl -s -X GET "${API_URL}/api/accounts/balance" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $token" | jq .
}

test_transaction() {
    echo -e "${BLUE}Testing: Create Transaction${NC}"
    
    if [ ! -f token.txt ]; then
        echo -e "${RED}No token found. Run login test first.${NC}"
        return 1
    fi
    
    # Check if we have a recipient username
    if [ ! -f recipient.txt ]; then
        echo -e "${YELLOW}No recipient found. Creating one...${NC}"
        recipient="recipient$(date +%s)"
        register_data="{\"username\":\"$recipient\",\"email\":\"$recipient@example.com\",\"password\":\"password123\"}"
        curl -s -X POST "${API_URL}/api/users/register" \
            -H "Content-Type: application/json" \
            -d "$register_data" > /dev/null
        echo "$recipient" > recipient.txt
    fi
    
    recipient=$(cat recipient.txt)
    token=$(cat token.txt)
    
    transaction_data="{\"recipient_username\":\"$recipient\",\"amount\":\"5.00\",\"currency\":\"USD\",\"description\":\"Test payment\"}"
    tx_response=$(curl -s -X POST "${API_URL}/api/transactions" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $token" \
        -d "$transaction_data")
    
    echo "$tx_response" | jq .
    
    # Extract transaction ID if available
    if echo "$tx_response" | jq -e '.id' > /dev/null 2>&1; then
        tx_id=$(echo "$tx_response" | jq -r '.id')
        echo "$tx_id" > transaction_id.txt
        echo -e "${GREEN}Transaction ID saved to transaction_id.txt${NC}"
    fi
}

test_get_transaction() {
    echo -e "${BLUE}Testing: Get Transaction Details${NC}"
    
    if [ ! -f token.txt ] || [ ! -f transaction_id.txt ]; then
        echo -e "${RED}Missing token or transaction ID. Run login and transaction test first.${NC}"
        return 1
    fi
    
    token=$(cat token.txt)
    tx_id=$(cat transaction_id.txt)
    
    curl -s -X GET "${API_URL}/api/transactions/$tx_id" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $token" | jq .
}

test_list_transactions() {
    echo -e "${BLUE}Testing: List Transactions${NC}"
    
    if [ ! -f token.txt ]; then
        echo -e "${RED}No token found. Run login test first.${NC}"
        return 1
    fi
    
    token=$(cat token.txt)
    
    curl -s -X GET "${API_URL}/api/transactions" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $token" | jq .
}

# Main menu
echo "Please select an endpoint to test:"
echo "1) Health Check"
echo "2) Register User"
echo "3) Login User"
echo "4) Get User Profile"
echo "5) Get Account Balance"
echo "6) Create Transaction"
echo "7) Get Transaction Details"
echo "8) List Transactions"
echo "9) Run All Tests Sequentially"
echo "0) Exit"

read -p "Enter your choice: " choice

case $choice in
    1) test_health ;;
    2) test_register ;;
    3) test_login ;;
    4) test_profile ;;
    5) test_balance ;;
    6) test_transaction ;;
    7) test_get_transaction ;;
    8) test_list_transactions ;;
    9)
        test_health
        test_register
        test_login
        test_profile
        test_balance
        test_transaction
        test_get_transaction
        test_list_transactions
        ;;
    0) echo "Exiting." ;;
    *) echo -e "${RED}Invalid choice${NC}" ;;
esac
