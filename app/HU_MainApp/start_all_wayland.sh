#!/bin/bash

echo "════════════════════════════════════════════════════════════"
echo "HU_MainApp - Wayland Compositor 통합 실행"
echo "════════════════════════════════════════════════════════════"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"

# ═══════════════════════════════════════════════════════════
# 0. 기존 Wayland 프로세스 정리
# ═══════════════════════════════════════════════════════════
echo "Step 0/4: Cleaning up existing Wayland processes..."

# 기존 compositor 종료
killall weston 2>/dev/null
killall HU_MainApp_Compositor 2>/dev/null
sleep 1

# Wayland 소켓 삭제 (커스텀 소켓 이름 사용)
if [ -f "/run/user/$(id -u)/wayland-hu.lock" ]; then
    echo "   Removing old Wayland socket (wayland-hu)..."
    rm -f /run/user/$(id -u)/wayland-hu
    rm -f /run/user/$(id -u)/wayland-hu.lock
fi

echo "   ✅ Cleanup complete"
echo ""

# 1. Compositor 시작
echo "Step 1/4: Starting Wayland Compositor..."
cd "$SCRIPT_DIR"
./run_compositor.sh &  # run.sh 대신 run_compositor.sh 사용
COMPOSITOR_PID=$!

sleep 3

# 2. GearApp 시작
echo ""
echo "Step 2/4: Starting GearApp (Wayland Client)..."
cd "$BASE_DIR/GearApp"
./run_wayland.sh &
GEARAPP_PID=$!

sleep 2

# 3. MediaApp 시작
echo ""
echo "Step 3/4: Starting MediaApp (Wayland Client)..."
cd "$BASE_DIR/MediaApp"
./run_wayland.sh &
MEDIAAPP_PID=$!

sleep 2

# 4. AmbientApp 시작
echo ""
echo "Step 4/4: Starting AmbientApp (Wayland Client)..."
cd "$BASE_DIR/AmbientApp"
./run_wayland.sh &
AMBIENTAPP_PID=$!

echo ""
echo "════════════════════════════════════════════════════════════"
echo "✅ All applications started!"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "Process IDs:"
echo "  Compositor: $COMPOSITOR_PID"
echo "  GearApp:    $GEARAPP_PID"
echo "  MediaApp:   $MEDIAAPP_PID"
echo "  AmbientApp: $AMBIENTAPP_PID"
echo ""
echo "Press Ctrl+C to stop all applications"
echo ""

# Cleanup function
cleanup() {
    echo ""
    echo "Stopping all applications..."
    kill $COMPOSITOR_PID $GEARAPP_PID $MEDIAAPP_PID $AMBIENTAPP_PID 2>/dev/null
    echo "✅ All applications stopped"
    exit 0
}

trap cleanup SIGINT SIGTERM

# Wait for compositor to finish
wait $COMPOSITOR_PID
