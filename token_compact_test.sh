#!/bin/bash
# Simple tool to test token with proper formatting

# Define server URL
API_URL="http://localhost:8082"

# Login with a hardcoded user
echo "Logging in to get token..."
token_response=$(curl -s -X POST "$API_URL/api/users/login" \
    -H "Content-Type: application/json" \
    -d '{"username":"testuser1","password":"password123"}')

echo "Raw token response:"
echo "$token_response"
echo 

# Extract token manually avoiding jq
token=$(echo "$token_response" | grep -o '"token":"[^"]*"' | cut -d':' -f2 | tr -d '"' | tr -d '\n' | tr -d ' ')
echo "Extracted token (manual method):"
echo "$token"
echo

# Test the token
echo "Testing profile endpoint with clean token..."
curl -s -X GET "$API_URL/api/users/profile" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $token"
echo
