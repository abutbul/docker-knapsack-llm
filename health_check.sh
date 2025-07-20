#!/bin/bash

# Health check script for the desktop snapshot service
# This script monitors the snapshot service and can restart it if needed

SNAPSHOT_PATH="${SNAPSHOT_PATH:-/tmp/desktop_snapshot.png}"
API_URL="http://localhost:5000"
SNAPSHOT_INTERVAL_MS="${SNAPSHOT_INTERVAL_MS:-500}"

# Calculate max age (3x the configured interval)
MAX_AGE_SECONDS=$(echo "scale=2; $SNAPSHOT_INTERVAL_MS * 3 / 1000" | bc -l)

echo "🔍 Desktop Snapshot Service Health Check"
echo "========================================"
echo "📁 Snapshot path: $SNAPSHOT_PATH"
echo "⏱️  Expected interval: ${SNAPSHOT_INTERVAL_MS}ms"
echo "⏰ Max age tolerance: ${MAX_AGE_SECONDS}s"

# Check if snapshot service process is running
if ! pgrep -f "snapshot-service.sh" > /dev/null; then
    echo "❌ Snapshot service process not running"
    exit 1
else
    echo "✅ Snapshot service process is running"
fi

# Check if API server is running
if ! curl -s "$API_URL/snapshot-info" > /dev/null 2>&1; then
    echo "❌ API server not responding"
    exit 1
else
    echo "✅ API server is responding"
fi

# Get snapshot info from API
SNAPSHOT_INFO=$(curl -s "$API_URL/snapshot-info")
echo "📊 Snapshot Service Status:"
echo "$SNAPSHOT_INFO" | python3 -m json.tool 2>/dev/null || echo "$SNAPSHOT_INFO"

# Check if snapshot file exists
if [ ! -f "$SNAPSHOT_PATH" ]; then
    echo "❌ Snapshot file not found at $SNAPSHOT_PATH"
    exit 1
fi

# Check file age
FILE_AGE=$(stat -c %Y "$SNAPSHOT_PATH")
CURRENT_TIME=$(date +%s)
AGE_SECONDS=$((CURRENT_TIME - FILE_AGE))

echo ""
echo "📸 Snapshot File Analysis:"
echo "  Path: $SNAPSHOT_PATH"
echo "  Size: $(stat -c %s "$SNAPSHOT_PATH") bytes"
echo "  Age: ${AGE_SECONDS}s"
echo "  Last modified: $(date -d @${FILE_AGE})"

if [ $AGE_SECONDS -gt $MAX_AGE_SECONDS ]; then
    echo "⚠️  Warning: Snapshot is older than ${MAX_AGE_SECONDS}s"
    echo "    This may indicate the capture service is not running properly"
    exit 1
else
    echo "✅ Snapshot is fresh (< ${MAX_AGE_SECONDS}s old)"
fi

# Check if we can capture a new screenshot manually
echo ""
echo "🧪 Testing manual screenshot capture..."
TEST_SCREENSHOT="/tmp/test_screenshot.png"

if DISPLAY=:0 xwd -root | convert xwd:- png:"$TEST_SCREENSHOT" 2>/dev/null; then
    TEST_SIZE=$(stat -c %s "$TEST_SCREENSHOT" 2>/dev/null || echo "0")
    if [ "$TEST_SIZE" -gt 1000 ]; then
        echo "✅ Manual screenshot test successful ($TEST_SIZE bytes)"
        rm -f "$TEST_SCREENSHOT"
    else
        echo "❌ Manual screenshot test failed (file too small: $TEST_SIZE bytes)"
        exit 1
    fi
else
    echo "❌ Manual screenshot test failed (xwd/convert error)"
    exit 1
fi

echo ""
echo "🎉 All health checks passed!"
echo "   Desktop snapshot service is working correctly"
