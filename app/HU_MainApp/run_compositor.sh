#!/bin/bash

# ════════════════════════════════════════════════════════════
# HU_MainApp Compositor 실행 스크립트
# ════════════════════════════════════════════════════════════

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "════════════════════════════════════════════════════════════"
echo "Running HU_MainApp - Wayland Compositor"
echo "════════════════════════════════════════════════════════════"

# Wayland Compositor 설정 (서버로 실행)
export XDG_RUNTIME_DIR=/run/user/$(id -u)
export QT_QPA_PLATFORM=xcb  # Compositor는 X11에서 실행 (Wayland 서버 역할)
export WAYLAND_DISPLAY=wayland-hu  # 커스텀 소켓 이름
echo "XDG_RUNTIME_DIR: $XDG_RUNTIME_DIR"
echo "QT_QPA_PLATFORM: $QT_QPA_PLATFORM (Compositor runs as X11 server)"
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
