#!/bin/bash
# Base URL
BASE_URL="http://localhost:8080"
API_PATH="/hello"
FULL_URL="$BASE_URL$API_PATH"

# Check if the full URL is reachable
status_code=$(curl -o /dev/null -s -w "%{http_code}" $FULL_URL)

if [ "$status_code" -ge 200 ] && [ "$status_code" -lt 400 ]; then
  echo "✅ Full URL is reachable: $FULL_URL (HTTP $status_code)"
else
  echo "❌ Full URL is NOT reachable: $FULL_URL (HTTP $status_code)"
  exit 1
fi

# Call the full URL
response=$(curl -s $FULL_URL)

# Extract 'message' using jq
message=$(echo "$response" | jq -r '.message')

# Assert the 'message' field exists and is non-empty
if [ -n "$message" ]; then
  echo "✅ Assertion passed: message exists in $API_PATH -> '$message'"
else
  echo "❌ Assertion failed: message field is missing or empty in $API_PATH"
fi
