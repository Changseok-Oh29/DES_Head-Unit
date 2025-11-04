#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "═══════════════════════════════════════════════════════"
echo "Starting GearApp - vsomeip Client"
echo "ECU2 @ 192.168.1.101"
echo "═══════════════════════════════════════════════════════"
echo ""

# 환경 변수 설정
export VSOMEIP_CONFIGURATION="${SCRIPT_DIR}/config/vsomeip_ecu2.json"
export COMMONAPI_CONFIG="${SCRIPT_DIR}/config/commonapi_ecu2.ini"
export LD_LIBRARY_PATH=/usr/local/lib:${LD_LIBRARY_PATH}

echo "📋 Configuration:"
echo "   Mode: vsomeip Client (ECU2)"
echo "   Local IP: 192.168.1.101"
echo "   Role: Service Consumer (connects to ECU1)"
echo "   VSOMEIP_CONFIGURATION=${VSOMEIP_CONFIGURATION}"
echo "   COMMONAPI_CONFIG=${COMMONAPI_CONFIG}"
echo ""
echo "🎯 Connecting to:"
echo "   - VehicleControlECU @ ECU1 (192.168.1.100)"
echo ""

# 빌드 확인
if [ ! -f "build/GearApp" ]; then
    echo "⚠️  GearApp not built. Building now..."
    ./build.sh
fi

echo "Starting application..."
echo "═══════════════════════════════════════════════════════"
echo ""

# GearApp 실행
cd build
./GearApp
