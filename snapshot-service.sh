#!/bin/bash

# Desktop snapshot service - runs independently from API
# Continuously captures desktop screenshots at configurable intervals

# Configuration from environment variables
SNAPSHOT_PATH="${SNAPSHOT_PATH:-/tmp/desktop_snapshot.png}"
SNAPSHOT_INTERVAL_MS="${SNAPSHOT_INTERVAL_MS:-500}"
DISPLAY="${DISPLAY:-:0}"

# Convert milliseconds to seconds for sleep
SLEEP_INTERVAL=$(echo "scale=3; $SNAPSHOT_INTERVAL_MS / 1000" | bc -l)

echo "Starting desktop snapshot service..."
echo "Snapshot path: $SNAPSHOT_PATH"
echo "Capture interval: ${SNAPSHOT_INTERVAL_MS}ms (${SLEEP_INTERVAL}s)"
echo "Display: $DISPLAY"

# Ensure the directory exists
mkdir -p "$(dirname "$SNAPSHOT_PATH")"

# Wait for X server to be ready
while ! xdpyinfo -display "$DISPLAY" >/dev/null 2>&1; do
    echo "Waiting for X server on display $DISPLAY..."
    sleep 1
done

echo "X server ready, starting capture loop..."

# Continuous capture loop
while true; do
    # Create temporary file to ensure atomic writes
    TEMP_PATH="${SNAPSHOT_PATH}.tmp"
    
    # Capture desktop using xwd + ImageMagick convert
    if DISPLAY="$DISPLAY" xwd -root | convert xwd:- png:"$TEMP_PATH" 2>/dev/null; then
        # Atomic move to final location
        mv "$TEMP_PATH" "$SNAPSHOT_PATH"
    else
        echo "Warning: Screenshot capture failed at $(date)"
        # Clean up temp file if it exists
        rm -f "$TEMP_PATH"
    fi
    
    # Sleep for the specified interval
    sleep "$SLEEP_INTERVAL"
done
