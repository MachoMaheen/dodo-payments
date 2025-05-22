#!/bin/bash
# Script to test the Dodo Payments API with a fixed token mechanism

# Define server URL
API_URL="http://localhost:8082"

# Colors for better output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Dodo Payments API Testing (Fixed Token) ===${NC}"

# Check if the API is running
echo -e "1. ${BLUE}Checking if API is running...${NC}"
health_response=$(curl -s "$API_URL/health")
echo "$health_response"
echo ""

# Register a test user with a unique name to avoid conflicts
echo -e "2. ${BLUE}Registering a test user...${NC}"
current_time=$(date +%s)
test_username="testuser_${current_time}"
register_response=$(curl -s -X POST "$API_URL/api/users/register" \
    -H "Content-Type: application/json" \
    -d "{\"username\":\"$test_username\",\"email\":\"$test_username@example.com\",\"password\":\"password123\"}")

echo "Registration response:"
echo "$register_response"
echo ""

# Login to get token - using a different approach
echo -e "3. ${BLUE}Logging in to get JWT token...${NC}"
login_response=$(curl -s -X POST "$API_URL/api/users/login" \
    -H "Content-Type: application/json" \
    -d "{\"username\":\"$test_username\",\"password\":\"password123\"}")

echo "Raw login response:"
echo "$login_response"
echo ""

# Special token extraction that handles potential line breaks
echo -e "4. ${BLUE}Extracting token using custom method...${NC}"
# Save response to a temporary file
echo "$login_response" > login_response.txt

# Extract token using grep and removing line breaks
token=$(grep -o '"token":"[^"]*' login_response.txt | sed 's/"token":"//' | tr -d '\n' | tr -d ' ')

if [ -z "$token" ]; then
    echo -e "${RED}Failed to extract token${NC}"
    exit 1
else
    echo -e "${GREEN}Successfully extracted token${NC}"
    # Save token to a file for inspection
    echo "$token" > clean_token.txt
    echo -e "${GREEN}Clean token saved to clean_token.txt${NC}"
fi
echo ""

# Use the clean token to test an authenticated endpoint
echo -e "5. ${BLUE}Testing profile endpoint with clean token...${NC}"
profile_response=$(curl -s -X GET "$API_URL/api/users/profile" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $token")

echo "Profile response:"
echo "$profile_response"
echo ""

echo -e "${GREEN}API testing complete${NC}"
