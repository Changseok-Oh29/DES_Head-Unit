#!/bin/bash

# ECU2 전체 시스템 시작 스크립트
# 라우팅 매니저 + 모든 HU 앱을 올바른 순서로 실행

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "=========================================="
echo "ECU2 전체 시스템 시작"
echo "=========================================="
echo "Project Root: ${PROJECT_ROOT}"
echo ""

# 1단계: 완전 클린업
echo "[1/10] Cleaning up all processes..."
killall -9 GearApp AmbientApp IC_app MediaApp PDCApp HomeScreenApp routingmanagerd HU_MainApp_Compositor 2>/dev/null
pkill -9 -f vsomeip 2>/dev/null
sudo rm -rf /tmp/vsomeip-* 2>/dev/null
sleep 1
echo "✓ Cleanup complete"
echo ""

# 2단계: 네트워크 확인
echo "[2/10] Checking network configuration..."
IP_ADDR=$(ip addr show enP8p1s0 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d'/' -f1)
if [ "$IP_ADDR" != "192.168.1.101" ]; then
    echo "⚠ Warning: Setting up network..."
    sudo nmcli device set enP8p1s0 managed no 2>/dev/null
    sudo ip link set enP8p1s0 up
    sudo ip addr flush dev enP8p1s0
    sudo ip addr add 192.168.1.101/24 dev enP8p1s0
    echo "✓ IP configured: 192.168.1.101"
else
    echo "✓ IP Address: ${IP_ADDR}"
fi

MULTICAST_ROUTE=$(ip route | grep "224.0.0.0/4")
if [ -z "$MULTICAST_ROUTE" ]; then
    echo "⚠ Adding multicast route..."
    sudo ip route add 224.0.0.0/4 dev enP8p1s0
    echo "✓ Multicast route added"
else
    echo "✓ Multicast route: OK"
fi

# ECU1 연결 확인
echo -n "⏳ Checking connection to ECU1 (192.168.1.100)... "
if ping -c 1 -W 2 192.168.1.100 &> /dev/null; then
    echo "✓ Connected"
else
    echo "✗ Failed"
    echo ""
    echo "❌ Cannot reach ECU1!"
    echo "Make sure:"
    echo "  1. ECU1 is powered on"
    echo "  2. Ethernet cable is connected"
    echo "  3. ECU1 IP is 192.168.1.100"
    exit 1
fi
echo ""

# 3단계: 라우팅 매니저 시작
echo "[3/10] Starting Routing Manager..."
cd "${SCRIPT_DIR}"
export VSOMEIP_CONFIGURATION="${SCRIPT_DIR}/routing_manager_ecu2.json"
export VSOMEIP_APPLICATION_NAME="routingmanagerd"
export LD_LIBRARY_PATH=/usr/local/lib:${LD_LIBRARY_PATH}

# routingmanagerd 또는 vsomeipd 사용
if command -v routingmanagerd &> /dev/null; then
    routingmanagerd &> /tmp/routing_manager.log &
    RM_PID=$!
    echo "✓ Routing Manager started (PID: ${RM_PID})"
elif command -v vsomeipd &> /dev/null; then
    vsomeipd &> /tmp/routing_manager.log &
    RM_PID=$!
    echo "✓ vsomeipd started (PID: ${RM_PID})"
else
    echo "✗ Error: routingmanagerd or vsomeipd not found!"
    exit 1
fi

# 라우팅 매니저 초기화 대기
sleep 3

if [ ! -e /tmp/vsomeip-0 ]; then
    echo "✗ Routing Manager failed to start!"
    echo "Check log: tail /tmp/routing_manager.log"
    exit 1
fi
echo "✓ Routing Manager ready (/tmp/vsomeip-0)"
echo ""

# 4단계: HU_MainApp Compositor 시작
echo "[4/10] Starting HU_MainApp Compositor..."
cd "${PROJECT_ROOT}/HU_MainApp"
if [ ! -f "build/HU_MainApp_Compositor" ]; then
    echo "✗ HU_MainApp_Compositor not built!"
    exit 1
fi

export QT_QPA_PLATFORM=xcb
export QML2_IMPORT_PATH=/usr/lib/aarch64-linux-gnu/qt5/qml:/usr/lib/qt5/qml
nohup ./build/HU_MainApp_Compositor > /tmp/HU_MainApp_Compositor.log 2>&1 &
COMPOSITOR_PID=$!
echo "✓ Compositor started (PID: ${COMPOSITOR_PID})"

# Wait for wayland-1 socket
echo "  Waiting for wayland-1 socket..."
for i in {1..30}; do
    if [ -S "${XDG_RUNTIME_DIR}/wayland-1" ]; then
        echo "  ✓ Wayland socket ready"
        break
    fi
    sleep 1
done

if [ ! -S "${XDG_RUNTIME_DIR}/wayland-1" ]; then
    echo "  ✗ Wayland socket not created. Check /tmp/HU_MainApp_Compositor.log"
    exit 1
fi

sleep 2
echo ""

# 5단계: GearApp 시작
echo "[5/10] Starting GearApp..."
cd "${PROJECT_ROOT}/GearApp/build"
if [ ! -f "GearApp" ]; then
    echo "✗ GearApp not built!"
    exit 1
fi
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export WAYLAND_DISPLAY=wayland-1
export VSOMEIP_APPLICATION_NAME=GearApp
export VSOMEIP_CONFIGURATION=${PROJECT_ROOT}/GearApp/config/vsomeip_ecu2.json
export COMMONAPI_CONFIG=${PROJECT_ROOT}/GearApp/config/commonapi_ecu2.ini
nohup ./GearApp > /tmp/gearapp.log 2>&1 &
GEARAPP_PID=$!
echo "✓ GearApp started (PID: ${GEARAPP_PID})"
cd "${PROJECT_ROOT}"
sleep 2
echo ""

# 6단계: AmbientApp 시작
echo "[6/10] Starting AmbientApp..."
cd "${PROJECT_ROOT}/AmbientApp/build"
if [ ! -f "AmbientApp" ]; then
    echo "✗ AmbientApp not built!"
    exit 1
fi
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export WAYLAND_DISPLAY=wayland-1
export VSOMEIP_APPLICATION_NAME=AmbientApp
export VSOMEIP_CONFIGURATION=${PROJECT_ROOT}/GearApp/config/vsomeip_ecu2.json
export COMMONAPI_CONFIG=${PROJECT_ROOT}/AmbientApp/commonapi_ambient.ini
nohup ./AmbientApp > /tmp/ambientapp.log 2>&1 &
AMBIENTAPP_PID=$!
echo "✓ AmbientApp started (PID: ${AMBIENTAPP_PID})"
cd "${PROJECT_ROOT}"
sleep 2
echo ""

# 7단계: IC_app 시작 (Runs in background - designed for separate cluster display)
echo "[7/10] Starting IC_app..."
if [ -f "${PROJECT_ROOT}/IC_app/build/IC_app" ]; then
    cd "${PROJECT_ROOT}/IC_app/build"
    # IC_app is designed for a separate instrument cluster display
    # It runs with Wayland but won't show on main HU display (by design)
    export QT_QPA_PLATFORM=wayland
    export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
    export WAYLAND_DISPLAY=wayland-1
    export VSOMEIP_APPLICATION_NAME=IC_app
    export VSOMEIP_CONFIGURATION=${PROJECT_ROOT}/GearApp/config/vsomeip_ecu2.json
    export COMMONAPI_CONFIG=${PROJECT_ROOT}/IC_app/commonapi.ini
    nohup ./IC_app > /tmp/ic_app.log 2>&1 &
    IC_APP_PID=$!
    echo "✓ IC_app started (background - for cluster display) (PID: ${IC_APP_PID})"
    cd "${PROJECT_ROOT}"
else
    echo "⚠ IC_app not built, skipping..."
fi
sleep 2
echo ""

# 8단계: MediaApp 시작
echo "[8/10] Starting MediaApp..."
if [ -f "${PROJECT_ROOT}/MediaApp/build/MediaApp" ]; then
    cd "${PROJECT_ROOT}/MediaApp/build"
    export QT_QPA_PLATFORM=wayland
    export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
    export WAYLAND_DISPLAY=wayland-1
    export VSOMEIP_APPLICATION_NAME=MediaApp
    export VSOMEIP_CONFIGURATION=${PROJECT_ROOT}/GearApp/config/vsomeip_ecu2.json
    export COMMONAPI_CONFIG=${PROJECT_ROOT}/MediaApp/commonapi.ini
    nohup ./MediaApp > /tmp/mediaapp.log 2>&1 &
    MEDIAAPP_PID=$!
    echo "✓ MediaApp started (PID: ${MEDIAAPP_PID})"
    cd "${PROJECT_ROOT}"
else
    echo "⚠ MediaApp not built, skipping..."
fi
sleep 2
echo ""

# 9단계: PDCApp 시작
echo "[9/10] Starting PDCApp..."
if [ -f "${PROJECT_ROOT}/PDCApp/build/PDCApp" ]; then
    cd "${PROJECT_ROOT}/PDCApp/build"
    export QT_QPA_PLATFORM=wayland
    export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
    export WAYLAND_DISPLAY=wayland-1
    export VSOMEIP_APPLICATION_NAME=PDCApp
    export VSOMEIP_CONFIGURATION=${PROJECT_ROOT}/PDCApp/config/vsomeip_pdc.json
    export COMMONAPI_CONFIG=${PROJECT_ROOT}/PDCApp/config/commonapi_pdc.ini
    nohup ./PDCApp > /tmp/pdcapp.log 2>&1 &
    PDCAPP_PID=$!
    echo "✓ PDCApp started (PID: ${PDCAPP_PID})"
    cd "${PROJECT_ROOT}"
else
    echo "⚠ PDCApp not built, skipping..."
fi
sleep 2
echo ""

# 10단계: HomeScreenApp 시작
echo "[10/10] Starting HomeScreenApp..."
if [ -f "${PROJECT_ROOT}/HomeScreenApp/build/HomeScreenApp" ]; then
    cd "${PROJECT_ROOT}/HomeScreenApp/build"
    export QT_QPA_PLATFORM=wayland
    export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
    export WAYLAND_DISPLAY=wayland-1
    export VSOMEIP_APPLICATION_NAME=HomeScreenApp
    export VSOMEIP_CONFIGURATION=${PROJECT_ROOT}/GearApp/config/vsomeip_ecu2.json
    export COMMONAPI_CONFIG=${PROJECT_ROOT}/HomeScreenApp/commonapi_homescreen.ini
    nohup ./HomeScreenApp > /tmp/homescreenapp.log 2>&1 &
    HOMESCREEN_PID=$!
    echo "✓ HomeScreenApp started (PID: ${HOMESCREEN_PID})"
    cd "${PROJECT_ROOT}"
else
    echo "⚠ HomeScreenApp not built, skipping..."
fi
echo ""

# 완료
echo "=========================================="
echo "✅ ECU2 시스템 시작 완료!"
echo "=========================================="
echo ""
echo "실행 중인 프로세스:"
echo "  - Routing Manager: PID ${RM_PID}"
if [ ! -z "$COMPOSITOR_PID" ]; then
    echo "  - HU_MainApp Compositor: PID ${COMPOSITOR_PID}"
fi
echo "  - GearApp:         PID ${GEARAPP_PID}"
echo "  - AmbientApp:      PID ${AMBIENTAPP_PID}"
if [ ! -z "$IC_APP_PID" ]; then
    echo "  - IC_app:          PID ${IC_APP_PID}"
fi
if [ ! -z "$MEDIAAPP_PID" ]; then
    echo "  - MediaApp:        PID ${MEDIAAPP_PID}"
fi
if [ ! -z "$PDCAPP_PID" ]; then
    echo "  - PDCApp:          PID ${PDCAPP_PID}"
fi
if [ ! -z "$HOMESCREEN_PID" ]; then
    echo "  - HomeScreenApp:   PID ${HOMESCREEN_PID}"
fi
echo ""
echo "로그 파일:"
echo "  - Routing Manager: /tmp/routing_manager.log"
echo "  - GearApp:         /tmp/gearapp.log"
echo "  - AmbientApp:      /tmp/ambientapp.log"
if [ ! -z "$IC_APP_PID" ]; then
    echo "  - IC_app:          /tmp/ic_app.log"
fi
if [ ! -z "$MEDIAAPP_PID" ]; then
    echo "  - MediaApp:        /tmp/mediaapp.log"
fi
if [ ! -z "$PDCAPP_PID" ]; then
    echo "  - PDCApp:          /tmp/pdcapp.log"
fi
if [ ! -z "$HOMESCREEN_PID" ]; then
    echo "  - HomeScreenApp:   /tmp/homescreenapp.log"
fi
echo ""
echo "실시간 로그 확인:"
echo "  tail -f /tmp/gearapp.log"
echo "  tail -f /tmp/ambientapp.log"
echo "  tail -f /tmp/mediaapp.log"
echo "  tail -f /tmp/pdcapp.log"
echo "  tail -f /tmp/homescreenapp.log"
echo ""
echo "전체 종료:"
echo "  killall -9 GearApp AmbientApp IC_app MediaApp PDCApp HomeScreenApp routingmanagerd"
echo "  sudo rm -rf /tmp/vsomeip-*"
echo ""