#!/bin/bash

# ════════════════════════════════════════════════════════════
# HU_MainApp Compositor 실행 스크립트
# ════════════════════════════════════════════════════════════

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "════════════════════════════════════════════════════════════"
echo "Running HU_MainApp - Wayland Compositor"
echo "════════════════════════════════════════════════════════════"

# Wayland Compositor 설정 - 환경에 따라 자동 선택
export XDG_RUNTIME_DIR=/run/user/$(id -u)
export WAYLAND_DISPLAY=wayland-hu  # 커스텀 소켓 이름

# 플랫폼 자동 선택
if [ -n "$DISPLAY" ]; then
    # X11이 있으면 xcb 사용
    export QT_QPA_PLATFORM=xcb
    echo "Platform: xcb (X11 detected: $DISPLAY)"
elif [ -e "/dev/dri/card0" ]; then
    # DRM 장치가 있으면 eglfs 사용
    export QT_QPA_PLATFORM=eglfs
    export QT_QPA_EGLFS_INTEGRATION=eglfs_kms
    echo "Platform: eglfs (DRM/KMS mode)"
else
    # 마지막 대안: linuxfb
    export QT_QPA_PLATFORM=linuxfb
    echo "Platform: linuxfb (Fallback mode)"
fi

echo "XDG_RUNTIME_DIR: $XDG_RUNTIME_DIR"
echo "WAYLAND_DISPLAY: $WAYLAND_DISPLAY (Custom socket name)"
echo ""

# 실행 파일 경로
if [ -f "${SCRIPT_DIR}/build_compositor/HU_MainApp_Compositor" ]; then
    EXEC_PATH="${SCRIPT_DIR}/build_compositor/HU_MainApp_Compositor"
else
    echo "❌ Error: HU_MainApp_Compositor executable not found!"
    echo "   Build first with: ./build_compositor.sh"
    exit 1
fi

echo "Executable: ${EXEC_PATH}"
echo ""
echo "🖼️  Starting Wayland Compositor..."
echo "   Apps can now connect and display their windows"
echo ""
echo "To run independent apps:"
echo "  $ cd ../GearApp && ./run.sh"
echo "  $ cd ../MediaApp && ./run.sh"
echo "  $ cd ../AmbientApp && ./run.sh"
echo "════════════════════════════════════════════════════════════"
echo ""

# 실행
exec "${EXEC_PATH}"
