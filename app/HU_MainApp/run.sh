#!/bin/bash

# ════════════════════════════════════════════════════════════
# HU_MainApp Compositor 실행 스크립트
# ════════════════════════════════════════════════════════════

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "════════════════════════════════════════════════════════════"
echo "Running HU_MainApp - Wayland Compositor"
echo "════════════════════════════════════════════════════════════"

# Wayland 설정
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1

# 실행 파일 경로
if [ -f "${SCRIPT_DIR}/build/HU_MainApp_Compositor" ]; then
    EXEC_PATH="${SCRIPT_DIR}/build/HU_MainApp_Compositor"
else
    echo "❌ Error: HU_MainApp_Compositor executable not found!"
    echo "   Build first with: ./build.sh"
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
