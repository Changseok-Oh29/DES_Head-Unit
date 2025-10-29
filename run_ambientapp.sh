#!/bin/bash

# Launch script for AmbientApp (vSOMEIP Client)
# This is the CLIENT that subscribes to volumeChanged events

set -e

PROJECT_ROOT="/home/seam/DES_Head-Unit"
cd "$PROJECT_ROOT"

echo "════════════════════════════════════════════════════════════"
echo "💡 Starting AmbientApp (vSOMEIP Client/Subscriber)"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "📋 Configuration:"
echo "  - Service ID: 0x1235 (4661) - connects to MediaApp"
echo "  - Instance ID: 0x5679 (22137)"
echo "  - Role: CLIENT (subscribes to volumeChanged events)"
echo ""
echo "🔧 Setting environment variables..."

# Set library path
export LD_LIBRARY_PATH="$PROJECT_ROOT/install_folder/lib:$LD_LIBRARY_PATH"

# Set vsomeip configuration
export VSOMEIP_CONFIGURATION="$PROJECT_ROOT/app/AmbientApp/vsomeip.json"

# Set CommonAPI configuration
export COMMONAPI_CONFIG="$PROJECT_ROOT/app/AmbientApp/commonapi.ini"

# Optional: Enable vsomeip debug logging
# export VSOMEIP_LOG_LEVEL=debug

echo "✅ Environment configured"
echo "   LD_LIBRARY_PATH: $LD_LIBRARY_PATH"
echo "   VSOMEIP_CONFIGURATION: $VSOMEIP_CONFIGURATION"
echo "   COMMONAPI_CONFIG: $COMMONAPI_CONFIG"
echo ""
echo "════════════════════════════════════════════════════════════"
echo "🚀 Launching AmbientApp..."
echo "════════════════════════════════════════════════════════════"
echo ""
echo "📌 What to look for:"
echo "   1. 'Waiting for MediaApp service...'"
echo "   2. ✅ '[AmbientApp] MediaControlClient: Service is now AVAILABLE!'"
echo "   3. '[AmbientApp] MediaControlClient: Successfully subscribed to events'"
echo "   4. When MediaApp changes volume:"
echo "      → '[AmbientApp] MediaControlClient: Received volumeChanged event: X'"
echo "      → '[AmbientApp] MediaControlClient: Setting brightness to: Y'"
echo "      → 'AmbientManager: Brightness changed'"
echo ""
echo "⚠️  IMPORTANT:"
echo "   - MediaApp must be running FIRST!"
echo "   - If you see 'Service became UNAVAILABLE', MediaApp is not running"
echo ""
echo "🎮 Controls:"
echo "   - Watch the terminal for events"
echo "   - Press Ctrl+C to stop"
echo ""
echo "════════════════════════════════════════════════════════════"
echo ""

# Run AmbientApp
exec "$PROJECT_ROOT/build/app/AmbientApp/AmbientApp"
