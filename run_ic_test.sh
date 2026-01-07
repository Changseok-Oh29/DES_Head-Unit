#!/bin/bash

# Run all Instrument Cluster apps on x86-64 local environment
# This script launches all apps in separate terminal windows
# IC_MainApp runs as Wayland compositor, client apps connect via wayland-2

BASE_DIR="/home/seame/PDC/headunit/DES_Head-Unit"
BUILD_DIR="${BASE_DIR}/build"
INSTALL_DIR="${BASE_DIR}/install_folder"

echo "════════════════════════════════════════════════════════"
echo "Launching Instrument Cluster System on x86-64"
echo "════════════════════════════════════════════════════════"
echo ""

# Check if build directory exists
if [ ! -d "$BUILD_DIR" ]; then
    echo "ERROR: Build directory not found: $BUILD_DIR"
    echo "Please build the project first:"
    echo "  cd ${BASE_DIR}"
    echo "  mkdir -p build && cd build"
    echo "  cmake .. && make -j4"
    exit 1
fi

# Terminal 1: IC_MainApp Compositor
# IC_MainApp uses xcb (X11) to display its window, but creates wayland-2 socket for clients
echo "Starting IC_MainApp Wayland Compositor..."
gnome-terminal --title="IC_MainApp Compositor" -- bash -c "
cd ${BUILD_DIR}/app/IC_MainApp
export QT_QPA_PLATFORM=xcb
export QML2_IMPORT_PATH=/usr/lib/x86_64-linux-gnu/qt5/qml
export XDG_RUNTIME_DIR=/run/user/\$(id -u)
./IC_MainApp
exec bash"

echo "Waiting for compositor to initialize..."
sleep 3

# Terminal 2: SpeedApp
echo "Starting SpeedApp..."
gnome-terminal --title="SpeedApp" -- bash -c "
cd ${BUILD_DIR}/app/SpeedApp
export XDG_RUNTIME_DIR=/run/user/\$(id -u)
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export WAYLAND_DISPLAY=wayland-2
export LD_LIBRARY_PATH=${INSTALL_DIR}/lib:\$LD_LIBRARY_PATH
./SpeedApp
exec bash"

sleep 1

# Terminal 3: BatteryApp
echo "Starting BatteryApp..."
gnome-terminal --title="BatteryApp" -- bash -c "
cd ${BUILD_DIR}/app/BatteryApp
export XDG_RUNTIME_DIR=/run/user/\$(id -u)
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export WAYLAND_DISPLAY=wayland-2
export LD_LIBRARY_PATH=${INSTALL_DIR}/lib:\$LD_LIBRARY_PATH
./BatteryApp
exec bash"

sleep 1

# Terminal 4: ICGearApp
echo "Starting ICGearApp..."
gnome-terminal --title="ICGearApp" -- bash -c "
cd ${BUILD_DIR}/app/ICGearApp
export XDG_RUNTIME_DIR=/run/user/\$(id -u)
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export WAYLAND_DISPLAY=wayland-2
export LD_LIBRARY_PATH=${INSTALL_DIR}/lib:\$LD_LIBRARY_PATH
./ICGearApp
exec bash"

echo ""
echo "════════════════════════════════════════════════════════"
echo "All IC apps launched successfully!"
echo ""
echo "  - IC_MainApp: Wayland Compositor (wayland-2)"
echo "  - SpeedApp: Speedometer display"
echo "  - BatteryApp: Battery status display"
echo "  - ICGearApp: Gear indicator display"
echo ""
echo "To stop all processes, run:"
echo "  pkill -9 IC_MainApp && pkill -9 SpeedApp && pkill -9 BatteryApp && pkill -9 ICGearApp"
echo "════════════════════════════════════════════════════════"
