#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# Run HeadUnit Apps on Jetson via SSH
# ═══════════════════════════════════════════════════════════════════════════════

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$SCRIPT_DIR"
BUILD_DIR="$BASE_DIR/build_pdc_test"

# Ensure XDG_RUNTIME_DIR is set
if [ -z "$XDG_RUNTIME_DIR" ]; then
    export XDG_RUNTIME_DIR=/run/user/$(id -u)
fi

# Set DISPLAY if not set
if [ -z "$DISPLAY" ]; then
    export DISPLAY=:1
fi

echo ""
echo "═══════════════════════════════════════════════════════════════════════════════"
echo "Running HeadUnit Apps on Jetson"
echo "═══════════════════════════════════════════════════════════════════════════════"
echo ""
echo "Build directory: $BUILD_DIR"
echo "DISPLAY: $DISPLAY"
echo "XDG_RUNTIME_DIR: $XDG_RUNTIME_DIR"
echo ""

# Check if build directory exists
if [ ! -d "$BUILD_DIR" ]; then
    echo "ERROR: Build directory not found: $BUILD_DIR"
    echo "Please run the build first with: cd $BASE_DIR/app && ./run_pdc_test.sh"
    exit 1
fi

cd "$BUILD_DIR"

# ───────────────────────────────────────────────────────────────────────────────
# VehicleControlECU runs on Raspberry Pi (192.168.1.100)
# No need to start it here
# ───────────────────────────────────────────────────────────────────────────────

# ───────────────────────────────────────────────────────────────────────────────
# Launch HU_MainApp Compositor
# ───────────────────────────────────────────────────────────────────────────────
echo "Starting HU_MainApp Compositor..."
cd HU_MainApp
export QT_QPA_PLATFORM=xcb
export QML2_IMPORT_PATH=/usr/lib/aarch64-linux-gnu/qt5/qml:/usr/lib/qt5/qml
nohup ./HU_MainApp_Compositor > /tmp/HU_MainApp_Compositor.log 2>&1 &
COMP_PID=$!
echo "  PID: $COMP_PID"
cd ..

# Wait for wayland-1 socket
echo "Waiting for wayland-1 socket..."
for i in {1..30}; do
    if [ -S "$XDG_RUNTIME_DIR/wayland-1" ]; then
        echo "  Socket found!"
        break
    fi
    echo "  Waiting... ($i/30)"
    sleep 1
done

if [ ! -S "$XDG_RUNTIME_DIR/wayland-1" ]; then
    echo "ERROR: wayland-1 socket not created."
    echo "Check log: /tmp/HU_MainApp_Compositor.log"
    exit 1
fi

sleep 2

# ───────────────────────────────────────────────────────────────────────────────
# Launch GearApp
# ───────────────────────────────────────────────────────────────────────────────
echo "Starting GearApp..."
cd GearApp
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export WAYLAND_DISPLAY=wayland-1
export VSOMEIP_APPLICATION_NAME=GearApp
export VSOMEIP_CONFIGURATION=$BASE_DIR/app/GearApp/config/vsomeip_ecu2.json
export COMMONAPI_CONFIG=$BASE_DIR/app/GearApp/config/commonapi_ecu2.ini
nohup ./GearApp > /tmp/GearApp.log 2>&1 &
GEAR_PID=$!
echo "  PID: $GEAR_PID"
cd ..

sleep 1

# ───────────────────────────────────────────────────────────────────────────────
# Launch HomeScreenApp
# ───────────────────────────────────────────────────────────────────────────────
echo "Starting HomeScreenApp..."
cd HomeScreenApp
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export WAYLAND_DISPLAY=wayland-1
export VSOMEIP_APPLICATION_NAME=HomeScreenApp
export VSOMEIP_CONFIGURATION=$BASE_DIR/app/GearApp/config/vsomeip_ecu2.json
export COMMONAPI_CONFIG=$BASE_DIR/app/HomeScreenApp/commonapi_homescreen.ini
nohup ./HomeScreenApp > /tmp/HomeScreenApp.log 2>&1 &
HS_PID=$!
echo "  PID: $HS_PID"
cd ..

sleep 1

# ───────────────────────────────────────────────────────────────────────────────
# Launch MediaApp
# ───────────────────────────────────────────────────────────────────────────────
echo "Starting MediaApp..."
cd MediaApp
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export WAYLAND_DISPLAY=wayland-1
export VSOMEIP_APPLICATION_NAME=MediaApp
export VSOMEIP_CONFIGURATION=$BASE_DIR/app/GearApp/config/vsomeip_ecu2.json
export COMMONAPI_CONFIG=$BASE_DIR/app/MediaApp/commonapi.ini
nohup ./MediaApp > /tmp/MediaApp.log 2>&1 &
MEDIA_PID=$!
echo "  PID: $MEDIA_PID"
cd ..

sleep 1

# ───────────────────────────────────────────────────────────────────────────────
# Launch PDCApp
# ───────────────────────────────────────────────────────────────────────────────
echo "Starting PDCApp..."
cd PDCApp
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export WAYLAND_DISPLAY=wayland-1
export VSOMEIP_APPLICATION_NAME=PDCApp
export VSOMEIP_CONFIGURATION=$BASE_DIR/app/PDCApp/config/vsomeip_pdc.json
export COMMONAPI_CONFIG=$BASE_DIR/app/PDCApp/config/commonapi_pdc.ini
nohup ./PDCApp > /tmp/PDCApp.log 2>&1 &
PDC_PID=$!
echo "  PID: $PDC_PID"
cd ..

sleep 1

# ───────────────────────────────────────────────────────────────────────────────
# Launch RemoteSpeakerApp
# ───────────────────────────────────────────────────────────────────────────────
echo "Starting RemoteSpeakerApp..."
cd RemoteSpeakerApp
export VSOMEIP_APPLICATION_NAME=RemoteSpeakerApp
export VSOMEIP_CONFIGURATION=$BASE_DIR/app/RemoteSpeakerApp/config/vsomeip_speaker.json
export COMMONAPI_CONFIG=$BASE_DIR/app/RemoteSpeakerApp/config/commonapi_speaker.ini
nohup ./RemoteSpeakerApp > /tmp/RemoteSpeakerApp.log 2>&1 &
SPEAKER_PID=$!
echo "  PID: $SPEAKER_PID"
cd ..

sleep 1

# ───────────────────────────────────────────────────────────────────────────────
# Launch AmbientApp (if needed)
# ───────────────────────────────────────────────────────────────────────────────
if [ -d "AmbientApp" ] && [ -f "AmbientApp/AmbientApp" ]; then
    echo "Starting AmbientApp..."
    cd AmbientApp
    export QT_QPA_PLATFORM=wayland
    export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
    export WAYLAND_DISPLAY=wayland-1
    export VSOMEIP_APPLICATION_NAME=AmbientApp
    export VSOMEIP_CONFIGURATION=$BASE_DIR/app/GearApp/config/vsomeip_ecu2.json
    export COMMONAPI_CONFIG=$BASE_DIR/app/AmbientApp/commonapi_ambient.ini
    nohup ./AmbientApp > /tmp/AmbientApp.log 2>&1 &
    AMBIENT_PID=$!
    echo "  PID: $AMBIENT_PID"
    cd ..
fi

echo ""
echo "═══════════════════════════════════════════════════════════════════════════════"
echo "All apps started!"
echo "═══════════════════════════════════════════════════════════════════════════════"
echo ""
echo "Process IDs:"
echo "  HU_MainApp Compositor: $COMP_PID"
echo "  GearApp:               $GEAR_PID"
echo "  HomeScreenApp:         $HS_PID"
echo "  MediaApp:              $MEDIA_PID"
echo "  PDCApp:                $PDC_PID"
echo "  RemoteSpeakerApp:      $SPEAKER_PID"
if [ -n "$AMBIENT_PID" ]; then
    echo "  AmbientApp:            $AMBIENT_PID"
fi
echo ""
echo "VehicleControlECU should be running on Raspberry Pi (192.168.1.100)"
echo "Logs are in /tmp/*.log"
echo ""
echo "To stop all apps, run:"
echo "  pkill -f 'HU_MainApp|GearApp|HomeScreenApp|MediaApp|PDCApp|RemoteSpeakerApp|AmbientApp'"
echo ""
