#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# Jetson Orin Nano Run Script for DES_Head-Unit
# Runs the PDC test with Jetson-specific display settings
# ═══════════════════════════════════════════════════════════════════════════════

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$BASE_DIR/build_pdc_test"
COMMONAPI_GEN_DIR="$BASE_DIR/commonapi/generated"
APP_DIR="$BASE_DIR/app"

echo ""
echo "═══════════════════════════════════════════════════════════════════════════════"
echo "DES_Head-Unit - Jetson Orin Nano"
echo "═══════════════════════════════════════════════════════════════════════════════"
echo ""

# Source environment
if [ -f "$SCRIPT_DIR/env_setup.sh" ]; then
    source "$SCRIPT_DIR/env_setup.sh"
else
    echo "Warning: env_setup.sh not found. Run jetson_setup.sh first."
fi

# Ensure XDG_RUNTIME_DIR exists
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
if [ ! -d "$XDG_RUNTIME_DIR" ]; then
    sudo mkdir -p "$XDG_RUNTIME_DIR"
    sudo chown $(id -u):$(id -g) "$XDG_RUNTIME_DIR"
    sudo chmod 700 "$XDG_RUNTIME_DIR"
fi

# ───────────────────────────────────────────────────────────────────────────────
# Kill existing processes
# ───────────────────────────────────────────────────────────────────────────────
cleanup() {
    echo "Cleaning up existing processes..."
    pkill -f VehicleControlMock 2>/dev/null || true
    pkill -f HU_MainApp 2>/dev/null || true
    pkill -f GearApp 2>/dev/null || true
    pkill -f PDCApp 2>/dev/null || true
    pkill -f RemoteSpeakerApp 2>/dev/null || true
    pkill -f HomeScreenApp 2>/dev/null || true
    pkill -f MediaApp 2>/dev/null || true
    pkill -f AmbientApp 2>/dev/null || true
    sleep 1
}

# ───────────────────────────────────────────────────────────────────────────────
# Run apps
# ───────────────────────────────────────────────────────────────────────────────
run_apps() {
    echo "═══════════════════════════════════════════════════════════════════════════════"
    echo "Launching applications..."
    echo "═══════════════════════════════════════════════════════════════════════════════"
    echo ""

    # Check if build exists
    if [ ! -d "$BUILD_DIR" ]; then
        echo "Build directory not found. Building apps first..."
        cd "$APP_DIR"
        ./run_pdc_test.sh build
    fi

    # Terminal 1: VehicleControlMock
    echo "Starting VehicleControlMock..."
    gnome-terminal --title="VehicleControlMock" -- bash -c "
source $SCRIPT_DIR/env_setup.sh
cd $BUILD_DIR/VehicleControlMock
export VSOMEIP_APPLICATION_NAME=VehicleControlMock
export VSOMEIP_CONFIGURATION=$APP_DIR/VehicleControlMock/config/vsomeip_mock.json
./VehicleControlMock
exec bash" &

    sleep 2

    # Terminal 2: HU_MainApp Compositor
    # On Jetson: Use eglfs or xcb depending on display setup
    echo "Starting HU_MainApp Compositor..."
    gnome-terminal --title="HU_MainApp Compositor" -- bash -c "
source $SCRIPT_DIR/env_setup.sh
cd $BUILD_DIR/HU_MainApp
# Use xcb for X11 desktop, or eglfs for framebuffer
export QT_QPA_PLATFORM=xcb
export QML2_IMPORT_PATH=/usr/lib/aarch64-linux-gnu/qt5/qml
export XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR
./HU_MainApp_Compositor
exec bash" &

    echo "Waiting for compositor to create wayland-1 socket..."
    for i in {1..30}; do
        if [ -S "$XDG_RUNTIME_DIR/wayland-1" ]; then
            echo "wayland-1 socket found!"
            break
        fi
        echo "  Waiting... ($i/30)"
        sleep 1
    done

    if [ ! -S "$XDG_RUNTIME_DIR/wayland-1" ]; then
        echo "ERROR: wayland-1 socket not created."
        echo "Check HU_MainApp terminal for errors."
        exit 1
    fi

    sleep 2

    # Terminal 3: GearApp
    echo "Starting GearApp..."
    gnome-terminal --title="GearApp" -- bash -c "
source $SCRIPT_DIR/env_setup.sh
cd $BUILD_DIR/GearApp
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR
export WAYLAND_DISPLAY=wayland-1
export VSOMEIP_APPLICATION_NAME=GearApp
export VSOMEIP_CONFIGURATION=$APP_DIR/GearApp/config/vsomeip_ecu2.json
./GearApp
exec bash" &

    sleep 1

    # Terminal 4: PDCApp
    echo "Starting PDCApp..."
    gnome-terminal --title="PDCApp" -- bash -c "
source $SCRIPT_DIR/env_setup.sh
cd $BUILD_DIR/PDCApp
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR
export WAYLAND_DISPLAY=wayland-1
export VSOMEIP_APPLICATION_NAME=PDCApp
export VSOMEIP_CONFIGURATION=$APP_DIR/PDCApp/config/vsomeip_pdc.json
./PDCApp
exec bash" &

    sleep 1

    # Terminal 5: RemoteSpeakerApp
    echo "Starting RemoteSpeakerApp..."
    gnome-terminal --title="RemoteSpeakerApp" -- bash -c "
source $SCRIPT_DIR/env_setup.sh
cd $BUILD_DIR/RemoteSpeakerApp
export VSOMEIP_APPLICATION_NAME=RemoteSpeakerApp
export VSOMEIP_CONFIGURATION=$APP_DIR/RemoteSpeakerApp/config/vsomeip_speaker.json
./RemoteSpeakerApp
exec bash" &

    sleep 1

    # Terminal 6: HomeScreenApp
    echo "Starting HomeScreenApp..."
    gnome-terminal --title="HomeScreenApp" -- bash -c "
source $SCRIPT_DIR/env_setup.sh
cd $BUILD_DIR/HomeScreenApp
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR
export WAYLAND_DISPLAY=wayland-1
export VSOMEIP_APPLICATION_NAME=HomeScreenApp
export VSOMEIP_CONFIGURATION=$APP_DIR/GearApp/config/vsomeip_ecu2.json
./HomeScreenApp
exec bash" &

    sleep 1

    # Terminal 7: MediaApp
    echo "Starting MediaApp..."
    gnome-terminal --title="MediaApp" -- bash -c "
source $SCRIPT_DIR/env_setup.sh
cd $BUILD_DIR/MediaApp
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR
export WAYLAND_DISPLAY=wayland-1
export VSOMEIP_APPLICATION_NAME=MediaApp
export VSOMEIP_CONFIGURATION=$APP_DIR/GearApp/config/vsomeip_ecu2.json
./MediaApp
exec bash" &

    sleep 1

    # Terminal 8: AmbientApp
    echo "Starting AmbientApp..."
    gnome-terminal --title="AmbientApp" -- bash -c "
source $SCRIPT_DIR/env_setup.sh
cd $BUILD_DIR/AmbientApp
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR
export WAYLAND_DISPLAY=wayland-1
export VSOMEIP_APPLICATION_NAME=AmbientApp
export VSOMEIP_CONFIGURATION=$APP_DIR/GearApp/config/vsomeip_ecu2.json
./AmbientApp
exec bash" &

    echo ""
    echo "═══════════════════════════════════════════════════════════════════════════════"
    echo "All apps launched!"
    echo "═══════════════════════════════════════════════════════════════════════════════"
    echo ""
    echo "Test Instructions:"
    echo "  1. Click on GearApp panel (left side) to change gear"
    echo "  2. Click 'R' (Reverse) to see PDCApp overlay appear"
    echo "  3. Watch distance simulation in VehicleControlMock terminal"
    echo "  4. Click 'P', 'N', or 'D' to hide PDCApp overlay"
    echo ""
    echo "To stop all processes:"
    echo "  $0 stop"
    echo ""
}

# ───────────────────────────────────────────────────────────────────────────────
# Main
# ───────────────────────────────────────────────────────────────────────────────
case "${1:-run}" in
    run)
        cleanup
        run_apps
        ;;
    stop)
        cleanup
        echo "All processes stopped."
        ;;
    *)
        echo "Usage: $0 [run|stop]"
        echo "  run  - Start all applications (default)"
        echo "  stop - Stop all running applications"
        exit 1
        ;;
esac
