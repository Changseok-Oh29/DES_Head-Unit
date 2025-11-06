#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "═══════════════════════════════════════════════════════"
echo "Starting AmbientApp - Wayland Client Mode"
echo "═══════════════════════════════════════════════════════"
echo ""

# 환경 변수 설정
export VSOMEIP_CONFIGURATION="${SCRIPT_DIR}/config/vsomeip_ecu2.json"
export COMMONAPI_CONFIG="${SCRIPT_DIR}/config/commonapi_ecu2.ini"
export LD_LIBRARY_PATH=/usr/local/lib:${LD_LIBRARY_PATH}

# Wayland 클라이언트 설정
export QT_QPA_PLATFORM=wayland
export WAYLAND_DISPLAY=wayland-hu  # HU Compositor의 커스텀 소켓
export APP_ID=AmbientApp  # 명확한 앱 식별자

# XDG 런타임 디렉토리 명시적 설정
export XDG_RUNTIME_DIR=/run/user/$(id -u)

# WAYLAND_DISPLAY 전체 경로도 설정 (보험)
export QT_WAYLAND_SOCKET_PATH=$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY

# Software rendering (avoid EGL issues)
export QT_QUICK_BACKEND=software
export LIBGL_ALWAYS_SOFTWARE=1

echo "📋 Configuration:"
echo "   Mode: Wayland Client"
echo "   Display: $WAYLAND_DISPLAY"
echo "   Platform: $QT_QPA_PLATFORM"
echo "   XDG_RUNTIME_DIR: $XDG_RUNTIME_DIR"
echo "   Socket: $XDG_RUNTIME_DIR/$WAYLAND_DISPLAY"
echo ""

# 빌드 확인
if [ ! -f "build/AmbientApp" ]; then
    echo "⚠️  AmbientApp not built. Building now..."
    ./build.sh
fi

echo "🚀 Connecting to Wayland compositor..."
echo "   (Make sure HU_MainApp compositor is running)"
echo ""

# AmbientApp 실행
cd build
./AmbientApp
