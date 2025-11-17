#!/bin/bash

# Firebase Emulator Startup Script with Data Persistence
# This script starts Firebase emulators and preserves data between sessions

EXPORT_DIR="./firebase-emulator-data"

echo "🔥 Starting Firebase Local Emulator Suite..."
echo ""
echo "📊 Emulator UI will be available at: http://localhost:4000"
echo "🔐 Auth Emulator: localhost:9099"
echo "📄 Firestore Emulator: localhost:8081"
echo ""

# Check if export directory exists
if [ -d "$EXPORT_DIR" ]; then
    echo "📦 Found existing emulator data - importing..."
    echo ""
    echo "💾 Data will be automatically exported on exit (Ctrl+C)"
    echo ""
    firebase emulators:start --import="$EXPORT_DIR" --export-on-exit="$EXPORT_DIR"
else
    echo "🆕 No existing data found - starting fresh"
    echo "💡 Tip: Run ./test-firebase-emulators.sh to seed test data"
    echo ""
    echo "💾 Data will be automatically exported on exit (Ctrl+C)"
    echo ""
    firebase emulators:start --export-on-exit="$EXPORT_DIR"
fi
