#!/bin/bash

# Capture Specmatic test output
OUTPUT=$(mktemp)

# Start Specmatic test in background
java -jar ~/.specmatic/specmatic.jar test service.yaml \
  --testBaseURL=https://my-json-server.typicode.com/specmatic/specmatic-documentation-examples \
  > "$OUTPUT" 2>&1 &

SPEC_PID=$!   # Capture Specmatic PID

echo "🔄 Specmatic test started (PID: $SPEC_PID)..."

# Wait for Specmatic to finish
wait $SPEC_PID

echo "✅ Specmatic test finished. Parsing results..."
echo ""

# ----------------------------------------
# Extract URL called by Specmatic
# ----------------------------------------
CALLED_URL=$(grep -o "GET [^ ]*" "$OUTPUT" | awk '{print $2}' | head -n 1)

if [ -n "$CALLED_URL" ]; then
    echo "🌐 URL Called: $CALLED_URL"
else
    echo "❌ Could not extract URL"
fi

# ----------------------------------------
# Extract HTTP Status Code
# ----------------------------------------
STATUS_CODE=$(grep -A3 "Response at" "$OUTPUT" | grep -oE " [0-9]{3} " | tr -d ' ' | head -n 1)

if [ -n "$STATUS_CODE" ]; then
    echo "📡 Status Code: $STATUS_CODE"
else
    echo "❌ Could not extract status code"
fi

# ----------------------------------------
# Extract JSON Message (field: name)
# ----------------------------------------
MESSAGE=$(grep -A10 "{\|{\"" "$OUTPUT" | grep '"name"' | sed 's/.*"name": "\(.*\)",.*/\1/' | head -n 1)

if [ -n "$MESSAGE" ]; then
    echo "💬 Message Field (name): $MESSAGE"
else
    echo "❌ Could not extract JSON message field"
fi

echo ""
echo "🧹 Cleaning up..."

# Kill the Specmatic process if still running
if ps -p $SPEC_PID > /dev/null 2>&1; then
    echo "🔪 Killing Specmatic process (PID: $SPEC_PID)"
    kill $SPEC_PID
else
    echo "ℹ️ Specmatic process already exited."
fi

rm "$OUTPUT"

echo "🎉 All done!"
