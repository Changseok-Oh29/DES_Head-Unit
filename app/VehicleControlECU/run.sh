#!/bin/bash

# Run script for VehicleControlECU
# Must be run with sudo for GPIO access

set -e

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ This application requires root privileges for GPIO access!"
    echo "   Please run with sudo: sudo ./run.sh"
    exit 1
fi

# Check if executable exists
if [ ! -f "build/VehicleControlECU" ]; then
    echo "❌ VehicleControlECU not found!"
    echo "   Build first with: ./build.sh"
    exit 1
fi

echo "═══════════════════════════════════════════════════════"
echo "Starting VehicleControlECU"
echo "═══════════════════════════════════════════════════════"
echo ""

# Set environment variables
export VSOMEIP_CONFIGURATION=$(pwd)/config/vsomeip_ecu1.json
export COMMONAPI_CONFIG=$(pwd)/config/commonapi4someip_ecu1.ini

echo "📋 Configuration:"
echo "   VSOMEIP_CONFIGURATION=$VSOMEIP_CONFIGURATION"
echo "   COMMONAPI_CONFIG=$COMMONAPI_CONFIG"
echo ""

# Check I2C devices
echo "🔍 Checking I2C devices..."
if command -v i2cdetect &> /dev/null; then
    echo "I2C Bus 1:"
    i2cdetect -y 1
    echo ""
else
    echo "⚠️  i2cdetect not found (install i2c-tools)"
    echo ""
fi

# Check gamepad
if [ -e "/dev/input/js0" ]; then
    echo "✅ Gamepad found at /dev/input/js0"
else
    echo "⚠️  Gamepad not found at /dev/input/js0"
    echo "   Application will still work via vsomeip RPC"
fi
echo ""

# Run the application
cd build
exec ./VehicleControlECU
