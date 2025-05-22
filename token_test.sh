#!/bin/bash
# Script for minimal API testing focusing on the JWT token issue

set -e

echo "=== Minimal Token Test for Dodo Payments API ==="

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

echo -e "${BLUE}Checking if API is running...${NC}"
health_response=$(curl -s "${API_URL}/health")
echo "$health_response" | jq .
echo ""

# Register a test user
echo -e "${BLUE}Registering a test user...${NC}"
register_data='{"username":"testuser2","email":"testuser2@example.com","password":"password123"}'
register_response=$(curl -s -X POST "${API_URL}/api/users/register" \
    -H "Content-Type: application/json" \
    -d "$register_data")
echo "$register_response" | jq .
echo ""

# Login to get token with explicit output redirection
echo -e "${BLUE}Logging in to get JWT token...${NC}"
login_data='{"username":"testuser2","password":"password123"}'
login_response=$(curl -s -X POST "${API_URL}/api/users/login" \
    -H "Content-Type: application/json" \
    -d "$login_data" -o token_response.json)

echo -e "${YELLOW}Token response saved to token_response.json${NC}"
echo -e "${YELLOW}Analyzing token response...${NC}"

# Check the file and try to extract token
if [ -f "token_response.json" ]; then
    file_size=$(wc -c < token_response.json)
    echo -e "${BLUE}Response file size: $file_size bytes${NC}"
    
    # Try to parse as JSON
    if cat token_response.json | jq -e . > /dev/null 2>&1; then
        echo -e "${GREEN}Response is valid JSON${NC}"
        cat token_response.json | jq .
        
        # Extract token
        token=$(cat token_response.json | jq -r '.token')
        if [ "$token" == "null" ] || [ -z "$token" ]; then
            echo -e "${RED}Token is null or empty${NC}"
        else
            echo -e "${GREEN}Token extracted: ${token:0:15}...${NC}"
            
            # Save token to a file for inspection
            echo "$token" > token.txt
            echo -e "${YELLOW}Token saved to token.txt${NC}"
            
            # Use hexdump to check for any binary or non-printable characters
            echo -e "${YELLOW}Hexdump of token:${NC}"
            hexdump -C token.txt | head -10
            
            # Try to make a request with this token
            echo -e "${BLUE}Testing token with a profile request...${NC}"
            profile_response=$(curl -s -X GET "${API_URL}/api/users/profile" \
                -H "Content-Type: application/json" \
                -H "Authorization: Bearer $token" \
                -o profile_response.json)
                
            echo -e "${YELLOW}Profile response saved to profile_response.json${NC}"
            
            if [ -f "profile_response.json" ]; then
                if cat profile_response.json | jq -e . > /dev/null 2>&1; then
                    echo -e "${GREEN}Profile response is valid JSON${NC}"
                    cat profile_response.json | jq .
                else
                    echo -e "${RED}Profile response is not valid JSON${NC}"
                    cat profile_response.json
                fi
            fi
        fi
    else
        echo -e "${RED}Response is not valid JSON${NC}"
        cat token_response.json
        
        # Check for encoding issues
        echo -e "${YELLOW}First 100 bytes of response (hex):${NC}"
        hexdump -C token_response.json | head -5
    fi
else
    echo -e "${RED}Response file was not created${NC}"
fi

echo -e "${GREEN}Test completed${NC}"
