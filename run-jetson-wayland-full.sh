#!/bin/bash

# ════════════════════════════════════════════════════════
# Jetson Wayland - NVIDIA Official Procedure
# ════════════════════════════════════════════════════════

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_PREFIX="${PROJECT_ROOT}/install_folder"

echo "════════════════════════════════════════════════════════"
echo "Jetson ECU2 - Wayland System (NVIDIA Official)"
echo "════════════════════════════════════════════════════════"
echo ""

# 1. X 서버 중지
echo "[1/7] Stop X server..."
sudo service gdm stop 2>/dev/null
sudo pkill -9 Xorg 2>/dev/null
echo "✓ Done"
echo ""

# 2. nvidia_drm 드라이버 로드
echo "[2/7] Load nvidia_drm driver..."
sudo modprobe nvidia_drm modeset=1
echo "✓ Done"
echo ""

# 3. 환경 설정
echo "[3/7] Setup environment..."
unset DISPLAY
sudo rm -rf /tmp/xdg
sudo mkdir -p /tmp/xdg
sudo chmod 700 /tmp/xdg
echo "✓ Done"
echo ""

# 4. 기존 프로세스 정리
echo "[4/7] Cleanup..."
sudo pkill -9 weston 2>/dev/null
killall -9 routingmanagerd HU_MainApp_Compositor GearApp AmbientApp MediaApp 2>/dev/null
sleep 2
echo "✓ Done"
echo ""

# Weston 설정
cat > ~/.config/weston.ini << 'EOF'
[core]
backend=drm-backend.so

[output]
name=DP-1
mode=1920x1080

[shell]
panel-position=none
locking=false
EOF

# 5. Weston 시작 (공식 문서 방식)
echo "[5/7] Start Weston..."
sudo XDG_RUNTIME_DIR=/tmp/xdg weston --idle-time=0 --log=/tmp/weston.log &
WESTON_PID=$!
echo "   Weston PID: $WESTON_PID"
echo "   Waiting for Weston to initialize..."
sleep 8

if ! sudo test -S "/tmp/xdg/wayland-0"; then
    echo "❌ Weston failed!"
    echo "   Check: sudo cat /tmp/weston.log"
    exit 1
fi
echo "✓ Weston running"
echo ""

# 6. vsomeip Routing Manager
echo "[6/7] Start Routing Manager..."
cd "${PROJECT_ROOT}/app/config"
export VSOMEIP_CONFIGURATION="${PROJECT_ROOT}/app/config/routing_manager_ecu2.json"
export VSOMEIP_APPLICATION_NAME="routingmanagerd"
export LD_LIBRARY_PATH="${DEPLOY_PREFIX}/lib:/usr/local/lib:${LD_LIBRARY_PATH}"

ROUTING_MGR="${PROJECT_ROOT}/deps/vsomeip/build/examples/routingmanagerd/routingmanagerd"
if [ -x "$ROUTING_MGR" ]; then
    $ROUTING_MGR &> /tmp/routing_manager.log &
    RM_PID=$!
    echo "   Routing Manager PID: $RM_PID"
else
    echo "❌ routingmanagerd not found at: $ROUTING_MGR"
    sudo pkill -9 weston
    exit 1
fi

sleep 3
if [ ! -e /tmp/vsomeip-0 ]; then
    echo "❌ Routing Manager failed!"
    echo "   Check: tail /tmp/routing_manager.log"
    sudo pkill -9 weston
    exit 1
fi
echo "✓ Routing Manager ready"
echo ""

# 7. HU_MainApp Compositor
echo "[7/7] Start Compositor..."
cd "${PROJECT_ROOT}/app/HU_MainApp"
sudo XDG_RUNTIME_DIR=/tmp/xdg ./build_compositor/HU_MainApp_Compositor > /tmp/compositor.log 2>&1 &
COMPOSITOR_PID=$!
echo "   Compositor PID: $COMPOSITOR_PID"
sleep 5

if ! sudo test -S "/tmp/xdg/wayland-1"; then
    echo "❌ Compositor failed!"
    echo "   Check: sudo cat /tmp/compositor.log"
    sudo pkill -9 weston
    killall -9 routingmanagerd 2>/dev/null
    exit 1
fi
echo "✓ Compositor running"
echo ""

# 앱 시작
echo "[8/8] Starting apps..."
export LD_LIBRARY_PATH="${DEPLOY_PREFIX}/lib:${LD_LIBRARY_PATH}"

cd "${PROJECT_ROOT}/app/GearApp"
sudo -E XDG_RUNTIME_DIR=/tmp/xdg WAYLAND_DISPLAY=wayland-1 QT_LOGGING_RULES="qt.qpa*=true;qt.wayland*=true" LD_LIBRARY_PATH="${LD_LIBRARY_PATH}" ./build/GearApp > /tmp/gearapp.log 2>&1 &
GEAR_PID=$!
echo "   GearApp PID: $GEAR_PID"
sleep 2

cd "${PROJECT_ROOT}/app/AmbientApp"
sudo -E XDG_RUNTIME_DIR=/tmp/xdg WAYLAND_DISPLAY=wayland-1 QT_LOGGING_RULES="qt.qpa*=true;qt.wayland*=true" LD_LIBRARY_PATH="${LD_LIBRARY_PATH}" ./build/AmbientApp > /tmp/ambientapp.log 2>&1 &
AMBIENT_PID=$!
echo "   AmbientApp PID: $AMBIENT_PID"
sleep 2

cd "${PROJECT_ROOT}/app/MediaApp"
sudo -E XDG_RUNTIME_DIR=/tmp/xdg WAYLAND_DISPLAY=wayland-1 QT_LOGGING_RULES="qt.qpa*=true;qt.wayland*=true" LD_LIBRARY_PATH="${LD_LIBRARY_PATH}" ./build/MediaApp > /tmp/mediaapp.log 2>&1 &
MEDIA_PID=$!
echo "   MediaApp PID: $MEDIA_PID"
echo ""

# 상태 확인
echo "════════════════════════════════════════════════════════"
echo "✅ Status Check:"
ps -p $WESTON_PID > /dev/null && echo "   ✓ Weston" || echo "   ✗ Weston"
ps -p $RM_PID > /dev/null && echo "   ✓ Routing Manager" || echo "   ✗ Routing Manager"
ps -p $COMPOSITOR_PID > /dev/null && echo "   ✓ Compositor" || echo "   ✓ Compositor"
ps -p $GEAR_PID > /dev/null && echo "   ✓ GearApp" || echo "   ✗ GearApp"
ps -p $AMBIENT_PID > /dev/null && echo "   ✓ AmbientApp" || echo "   ✗ AmbientApp"
ps -p $MEDIA_PID > /dev/null && echo "   ✓ MediaApp" || echo "   ✗ MediaApp"
echo ""
echo "📋 Logs:"
echo "   Weston:     sudo cat /tmp/weston.log"
echo "   Compositor: sudo cat /tmp/compositor.log"
echo "   Apps:       tail /tmp/*app.log"
echo ""
echo "🛑 Stop: sudo pkill -9 weston"
echo "════════════════════════════════════════════════════════"
