#!/bin/bash
# Debug script to test token format and JSON parsing issues

# Define server URL
API_URL="http://localhost:8082"

# Colors for better output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Dodo Payments API Token Debugging ===${NC}"

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo -e "${RED}Error: jq is not installed. Please install jq to run this script.${NC}"
    exit 1
fi

# Login to get token
echo -e "${BLUE}Logging in to get JWT token...${NC}"
login_response=$(curl -s -X POST "$API_URL/api/users/login" \
    -H "Content-Type: application/json" \
    -d '{"username":"testuser1","password":"password123"}')

echo -e "${BLUE}Raw login response:${NC}"
echo "$login_response"
echo ""

# Attempt to parse response
if echo "$login_response" | jq -e . > /dev/null 2>&1; then
    echo -e "${GREEN}JSON parsing successful${NC}"
    token=$(echo "$login_response" | jq -r .token)
    if [ -n "$token" ]; then
        echo -e "${GREEN}Token extracted: ${NC}"
        echo "$token"
        echo ""
        echo -e "${BLUE}Saving token to file...${NC}"
        echo "$token" > token.txt
        
        # Test profile endpoint with token
        echo -e "${BLUE}Testing profile endpoint...${NC}"
        profile_response=$(curl -v -X GET "$API_URL/api/users/profile" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $token")
        
        echo -e "${BLUE}Raw profile response:${NC}"
        echo "$profile_response"
    else
        echo -e "${RED}Failed to extract token from response${NC}"
    fi
else
    echo -e "${RED}Failed to parse login response as JSON${NC}"
    echo "Error details:"
    echo "$login_response" | jq . 2>&1
fi

echo -e "${GREEN}Debugging completed!${NC}"
