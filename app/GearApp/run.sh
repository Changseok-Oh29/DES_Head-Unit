#!/bin/bash

set -e

# Check if executable exists
if [ ! -f "build/GearApp" ]; then
    echo "❌ GearApp not found!"
    echo "   Build first with: ./build.sh"
    exit 1
fi

echo "═══════════════════════════════════════════════════════"
echo "Starting GearApp - vsomeip Client"
echo "ECU2 @ 192.168.1.101"
echo "═══════════════════════════════════════════════════════"
echo ""

# Set environment variables for vsomeip
export VSOMEIP_CONFIGURATION=$(pwd)/config/vsomeip_ecu2.json
export VSOMEIP_APPLICATION_NAME=GearApp
export COMMONAPI_CONFIG=$(pwd)/config/commonapi_ecu2.ini

# 라이브러리 경로 설정 (환경변수 우선, 없으면 기본값)
if [ -z "$DEPLOY_PREFIX" ]; then
    export DEPLOY_PREFIX="${HOME}/DES_Head-Unit/install_folder"
fi
export LD_LIBRARY_PATH="${DEPLOY_PREFIX}/lib:/usr/local/lib:$LD_LIBRARY_PATH"

echo "📋 Configuration:"
echo "   Mode: vsomeip Client (ECU2)"
echo "   Local IP: 192.168.1.101"
echo "   Role: Service Consumer (connects to ECU1)"
echo "   VSOMEIP_CONFIGURATION=$VSOMEIP_CONFIGURATION"
echo "   COMMONAPI_CONFIG=$COMMONAPI_CONFIG"
echo ""

echo "🎯 Connecting to:"
echo "   - VehicleControlECU @ ECU1 (192.168.1.100)"
echo ""

echo "Starting application..."
echo "═══════════════════════════════════════════════════════"
echo ""

# Run the application
cd build
exec ./GearApp
