#!/bin/bash

# Start Specmatic stub in the background and capture its output
STUB_OUTPUT=$(mktemp)
java $JAVA_OPTS -jar ~/.specmatic/specmatic.jar stub --port 8080 openapi.yaml >"$STUB_OUTPUT" 2>&1 &
STUB_PID=$!

echo "✅ Specmatic stub started..."

# Wait until the stub prints the URL (timeout 10s)
URL=""
for i in {1..10}; do
    URL_LINE=$(grep -m 1 "Stub server is running on the following URLs" "$STUB_OUTPUT")
    if [ -n "$URL_LINE" ]; then
        # Extract URL (remove leading '- ' and trailing text)
        URL=$(grep -o "http://[^ ]*" "$STUB_OUTPUT" | head -n 1)
        break
    fi
    sleep 1
done

if [ -z "$URL" ]; then
    echo "❌ Failed to capture stub URL"
    kill $STUB_PID
    exit 1
fi

echo "✅ Stub URL captured dynamically: $URL"

# Example: call the /hello endpoint
FULL_URL="$URL/hello"
status_code=$(curl -o /dev/null -s -w "%{http_code}" $FULL_URL)

if [ "$status_code" -ge 200 ] && [ "$status_code" -lt 400 ]; then
    echo "✅ Endpoint is reachable: $FULL_URL (HTTP $status_code)"
else
    echo "❌ Endpoint is NOT reachable: $FULL_URL (HTTP $status_code)"
    kill $STUB_PID
    exit 1
fi

# Fetch response and check message
response=$(curl -s $FULL_URL)
message=$(echo "$response" | jq -r '.message')

if [ -n "$message" ]; then
    echo "✅ Assertion passed: message exists -> '$message'"
else
    echo "❌ Assertion failed: message missing in response"
fi

# Stop the stub
kill $STUB_PID
rm "$STUB_OUTPUT"
