#!/bin/bash

# Standalone 실행 스크립트
# sudo 필수!

set -e

# Root 확인
if [ "$EUID" -ne 0 ]; then 
    echo "❌ This application requires root privileges for GPIO access!"
    echo "   Please run with sudo: sudo ./run_standalone.sh"
    exit 1
fi

# 실행 파일 확인
if [ ! -f "build_standalone/VehicleControlECU_Standalone" ]; then
    echo "❌ VehicleControlECU_Standalone not found!"
    echo "   Build first with: ./build_standalone.sh"
    exit 1
fi

echo "═══════════════════════════════════════════════════════"
echo "Starting VehicleControlECU (Standalone Mode)"
echo "═══════════════════════════════════════════════════════"
echo ""

# I2C 장치 확인
echo "🔍 Checking I2C devices..."
if command -v i2cdetect &> /dev/null; then
    echo "I2C Bus 1:"
    i2cdetect -y 1
    echo ""
else
    echo "⚠️  i2cdetect not found (install i2c-tools)"
    echo ""
fi

# Gamepad 확인
if [ -e "/dev/input/js0" ]; then
    echo "✅ Gamepad found at /dev/input/js0"
else
    echo "⚠️  Gamepad not found at /dev/input/js0"
fi
echo ""

# 실행
cd build_standalone
exec ./VehicleControlECU_Standalone
