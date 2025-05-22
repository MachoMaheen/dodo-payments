#!/bin/bash
# Script to debug the token validation issues

# Define server URL
API_URL="http://localhost:8082"

# Colors for better output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Dodo Payments JWT Token Debugging ===${NC}"

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo -e "${RED}Error: jq is not installed. Please install jq to run this script.${NC}"
    exit 1
fi

# Login to get token
echo -e "1. ${BLUE}Logging in to get JWT token...${NC}"
login_response=$(curl -s -X POST "$API_URL/api/users/login" \
    -H "Content-Type: application/json" \
    -d '{"username":"testuser1","password":"password123"}')

echo "Raw login response:"
echo "$login_response"
echo ""

if echo "$login_response" | jq -e . > /dev/null 2>&1; then
    echo "Parsed JSON response:"
    echo "$login_response" | jq .
    
    token=$(echo "$login_response" | jq -r .token)
    if [ -n "$token" ] && [ "$token" != "null" ]; then
        echo -e "${GREEN}Successfully obtained token:${NC}"
        echo "$token"
        
        # Save token to file for examination
        echo "$token" > token.txt
        echo -e "${GREEN}Token saved to token.txt${NC}"
    else
        echo -e "${RED}Failed to get token from response${NC}"
        exit 1
    fi
else
    echo -e "${RED}Failed to parse login response as JSON${NC}"
    exit 1
fi
echo ""

# Test with explicit token header format
echo -e "2. ${BLUE}Testing user profile with verbose token debugging...${NC}"
echo "Using token: $token"
echo "Header: Authorization: Bearer $token"

profile_response=$(curl -v -X GET "$API_URL/api/users/profile" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $token" 2>&1)

echo "Raw profile response with verbose output:"
echo "$profile_response"
echo ""

# Test simple health endpoint
echo -e "3. ${BLUE}Testing health endpoint for comparison...${NC}"
health_response=$(curl -s "$API_URL/health")
echo "Health endpoint response:"
echo "$health_response" | jq .
echo ""

echo -e "${GREEN}Token debugging completed!${NC}"
