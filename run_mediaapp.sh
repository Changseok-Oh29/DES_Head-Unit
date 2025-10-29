#!/bin/bash

# Launch script for MediaApp (vSOMEIP Service)
# This is the SERVICE PROVIDER that offers volumeChanged events

set -e

PROJECT_ROOT="/home/seam/DES_Head-Unit"
cd "$PROJECT_ROOT"

echo "════════════════════════════════════════════════════════════"
echo "🎵 Starting MediaApp (vSOMEIP Service Provider)"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "📋 Configuration:"
echo "  - Service ID: 0x1235 (4661)"
echo "  - Instance ID: 0x5679 (22137)"
echo "  - Port: 30509 (UDP)"
echo "  - Role: SERVICE (provides volumeChanged events)"
echo ""
echo "🔧 Setting environment variables..."

# Set library path
export LD_LIBRARY_PATH="$PROJECT_ROOT/install_folder/lib:$LD_LIBRARY_PATH"

# Set vsomeip configuration
export VSOMEIP_CONFIGURATION="$PROJECT_ROOT/app/MediaApp/vsomeip.json"

# Set CommonAPI configuration
export COMMONAPI_CONFIG="$PROJECT_ROOT/app/MediaApp/commonapi.ini"

# Optional: Enable vsomeip debug logging
# export VSOMEIP_LOG_LEVEL=debug

echo "✅ Environment configured"
echo "   LD_LIBRARY_PATH: $LD_LIBRARY_PATH"
echo "   VSOMEIP_CONFIGURATION: $VSOMEIP_CONFIGURATION"
echo "   COMMONAPI_CONFIG: $COMMONAPI_CONFIG"
echo ""
echo "════════════════════════════════════════════════════════════"
echo "🚀 Launching MediaApp..."
echo "════════════════════════════════════════════════════════════"
echo ""
echo "📌 What to look for:"
echo "   1. ✅ 'MediaControl vsomeip service registered successfully'"
echo "   2. 'OFFER(1234): [1235.5679:1.0]' - Service is offered"
echo "   3. When you move volume slider:"
echo "      → '[MediaApp] MediaControlStubImpl: Volume changed to: X'"
echo "      → '[MediaApp] MediaControlStubImpl: volumeChanged event broadcasted'"
echo ""
echo "🎮 Controls:"
echo "   - Use the QML UI to change volume"
echo "   - Press Ctrl+C to stop"
echo ""
echo "════════════════════════════════════════════════════════════"
echo ""

# Run MediaApp
exec "$PROJECT_ROOT/build/app/MediaApp/MediaApp"
