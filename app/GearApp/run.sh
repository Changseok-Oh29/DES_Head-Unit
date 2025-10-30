#!/bin/bash

set -e

# Check if executable exists
if [ ! -f "build/GearApp" ]; then
    echo "❌ GearApp not found!"
    echo "   Build first with: ./build.sh"
    exit 1
fi

echo "═══════════════════════════════════════════════════════"
echo "Starting GearApp - DEPLOYMENT MODE"
echo "ECU2 @ 192.168.1.101"
echo "═══════════════════════════════════════════════════════"
echo ""

# Set environment variables for DEPLOYMENT
export VSOMEIP_CONFIGURATION=$(pwd)/config/vsomeip_ecu2.json
export COMMONAPI_CONFIG=$(pwd)/config/commonapi_ecu2.ini
export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH

echo "📋 Configuration:"
echo "   Mode: DEPLOYMENT (Raspberry Pi ECU2)"
echo "   Local IP: 192.168.1.101"
echo "   Remote Service: VehicleControlECU @ 192.168.1.100"
echo "   VSOMEIP_CONFIGURATION=$VSOMEIP_CONFIGURATION"
echo "   COMMONAPI_CONFIG=$COMMONAPI_CONFIG"
echo ""

echo "🔌 Waiting for VehicleControlECU service on ECU1..."
echo "   Make sure ECU1 (192.168.1.100) is running!"
echo ""

echo "Starting GearApp..."
echo "═══════════════════════════════════════════════════════"
echo ""

# Run the application
cd build
exec ./GearApp
