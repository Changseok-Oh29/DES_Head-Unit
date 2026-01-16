#!/bin/bash

set -e

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$BASE_DIR/app"
BUILD_DIR="$BASE_DIR/build_native"

echo "═══════════════════════════════════════════════════"
echo "PDC Docker Integration Test"
echo "═══════════════════════════════════════════════════"
echo ""

# Step 0: Add static IP alias for vsomeip communication
echo "Setting up static IP alias for vsomeip..."
echo "────────────────────────────────────────────────────"
VSOMEIP_IP="192.168.1.101"
NETWORK_INTERFACE="wlo1"

# Check if IP alias already exists
if ip addr show "$NETWORK_INTERFACE" | grep -q "$VSOMEIP_IP"; then
    echo "✅ IP alias $VSOMEIP_IP already configured on $NETWORK_INTERFACE"
else
    echo "Adding IP alias $VSOMEIP_IP to $NETWORK_INTERFACE..."
    if sudo ip addr add "$VSOMEIP_IP/24" dev "$NETWORK_INTERFACE" 2>/dev/null; then
        echo "✅ IP alias $VSOMEIP_IP added to $NETWORK_INTERFACE"
    else
        echo "⚠️  WARNING: Could not add IP alias (may need sudo password)"
        echo "   vsomeip communication may not work correctly"
    fi
fi
echo ""

# Step 1: Check for VehicleControlMock dependencies
echo "Checking VehicleControlMock dependencies..."
echo "────────────────────────────────────────────────────"
if ! command -v cmake &> /dev/null; then
    echo "❌ ERROR: cmake not found. Please install: sudo apt-get install cmake"
    exit 1
fi

if ! pkg-config --exists Qt5Core; then
    echo "⚠️  WARNING: Qt5 not found. VehicleControlMock build may fail."
    echo "   Install with: sudo apt-get install qtbase5-dev"
fi
echo "✅ Dependencies OK"
echo ""

# Step 2: Build VehicleControlMock natively
echo "Building VehicleControlMock (native)..."
echo "────────────────────────────────────────────────────"
mkdir -p "$BUILD_DIR/VehicleControlMock"
cd "$BUILD_DIR/VehicleControlMock"

if ! cmake "$APP_DIR/VehicleControlMock" -DCMAKE_BUILD_TYPE=Release; then
    echo "❌ ERROR: CMake configuration failed for VehicleControlMock"
    exit 1
fi

if ! make -j$(nproc); then
    echo "❌ ERROR: Build failed for VehicleControlMock"
    exit 1
fi

if [ ! -f "./VehicleControlMock" ]; then
    echo "❌ ERROR: VehicleControlMock executable not found after build"
    exit 1
fi

echo "✅ VehicleControlMock built successfully"
echo ""

# Step 3: Detect available terminal emulator
echo "Detecting terminal emulator..."
echo "────────────────────────────────────────────────────"
TERMINAL=""
if command -v gnome-terminal &> /dev/null; then
    TERMINAL="gnome-terminal --"
    echo "✅ Found: gnome-terminal"
elif command -v xterm &> /dev/null; then
    TERMINAL="xterm -hold -e"
    echo "✅ Found: xterm"
elif command -v x-terminal-emulator &> /dev/null; then
    TERMINAL="x-terminal-emulator -e"
    echo "✅ Found: x-terminal-emulator"
else
    echo "⚠️  WARNING: No terminal emulator found"
    echo "   VehicleControlMock and RemoteSpeakerApp will run in background"
fi
echo ""

# Step 4: Start VehicleControlMock in new terminal
echo "Starting VehicleControlMock in new terminal..."
echo "────────────────────────────────────────────────────"
if [ -n "$TERMINAL" ]; then
    if [[ "$TERMINAL" == "gnome-terminal"* ]]; then
        # gnome-terminal with proper title and keep-open
        gnome-terminal --title="VehicleControlMock" -- bash -c "cd '$BUILD_DIR/VehicleControlMock' && echo '═══ VehicleControlMock ═══' && ./VehicleControlMock; echo ''; echo 'Process ended. Press Ctrl+C or close window to exit.'; exec bash" &
    else
        # Other terminals
        $TERMINAL bash -c "cd '$BUILD_DIR/VehicleControlMock' && ./VehicleControlMock; read -p 'Press Enter to close...'" &
    fi
    sleep 1
    echo "✅ VehicleControlMock launched in new terminal window"
else
    # Fallback: background mode
    cd "$BUILD_DIR/VehicleControlMock"
    ./VehicleControlMock &
    MOCK_PID=$!
    echo "✅ VehicleControlMock started in background (PID: $MOCK_PID)"
fi
sleep 1
echo ""

# Step 5: Build RemoteSpeakerApp natively
echo "Building RemoteSpeakerApp (native)..."
echo "────────────────────────────────────────────────────"
mkdir -p "$BUILD_DIR/RemoteSpeakerApp"
cd "$BUILD_DIR/RemoteSpeakerApp"

if ! cmake "$APP_DIR/RemoteSpeakerApp" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCOMMONAPI_GEN_DIR="$BASE_DIR/commonapi/generated" \
    -DCMAKE_PREFIX_PATH=/usr/local; then
    echo "⚠️  WARNING: RemoteSpeakerApp build failed (will skip)"
else
    if make -j$(nproc); then
        echo "✅ RemoteSpeakerApp built successfully"
    else
        echo "⚠️  WARNING: RemoteSpeakerApp build failed (will skip)"
    fi
fi
echo ""

# Step 6: Start RemoteSpeakerApp in new terminal (if built)
if [ -f "./RemoteSpeakerApp" ]; then
    echo "Starting RemoteSpeakerApp in new terminal (for SSH audio)..."
    echo "────────────────────────────────────────────────────"
    if [ -n "$TERMINAL" ]; then
        if [[ "$TERMINAL" == "gnome-terminal"* ]]; then
            # gnome-terminal with proper title and keep-open
            gnome-terminal --title="RemoteSpeakerApp (SSH Audio)" -- bash -c "cd '$BUILD_DIR/RemoteSpeakerApp' && echo '═══ RemoteSpeakerApp - PDC Audio (SSH) ═══' && ./RemoteSpeakerApp; echo ''; echo 'Process ended. Press Ctrl+C or close window to exit.'; exec bash" &
        else
            # Other terminals
            $TERMINAL bash -c "cd '$BUILD_DIR/RemoteSpeakerApp' && ./RemoteSpeakerApp; read -p 'Press Enter to close...'" &
        fi
        sleep 1
        echo "✅ RemoteSpeakerApp launched in new terminal window"
    else
        # Fallback: background mode
        ./RemoteSpeakerApp &
        SPEAKER_PID=$!
        echo "✅ RemoteSpeakerApp started in background (PID: $SPEAKER_PID)"
    fi
    sleep 1
    echo ""
else
    echo "⚠️  RemoteSpeakerApp not built, skipping..."
    SPEAKER_PID=""
    echo ""
fi

# Step 7: Create runtime directory for Wayland socket
echo "Setting up Wayland runtime directory..."
echo "────────────────────────────────────────────────────"
RUNTIME_DIR="/tmp/runtime-root"

# Clean and recreate runtime directory with proper permissions
if [ -d "$RUNTIME_DIR" ]; then
    echo "Cleaning existing runtime directory..."
    sudo rm -rf "$RUNTIME_DIR"
fi

mkdir -p "$RUNTIME_DIR"
chmod 700 "$RUNTIME_DIR"
echo "✅ Runtime directory ready: $RUNTIME_DIR"
echo ""

# Step 7: Allow X11 access for Docker
echo "Allowing X11 access for Docker..."
echo "────────────────────────────────────────────────────"
xhost +local:docker
echo "✅ X11 access granted"
echo ""

# Step 8: Build and run containerized apps
echo "Building and starting containerized apps..."
echo "────────────────────────────────────────────────────"
cd "$APP_DIR"

echo ""
echo "🔨 Building HU_MainApp (Wayland Compositor) first..."
if ! docker-compose -f docker-compose.all.yml build humainapp; then
    echo "❌ ERROR: Failed to build HU_MainApp"
    kill $MOCK_PID 2>/dev/null
    exit 1
fi

echo ""
echo "🚀 Starting all apps..."
if ! docker-compose -f docker-compose.all.yml up -d; then
    echo "❌ ERROR: Failed to start containers"
    kill $MOCK_PID 2>/dev/null
    exit 1
fi

echo ""
echo "⏳ Waiting for containers to initialize..."
sleep 3

echo ""
echo "═══════════════════════════════════════════════════"
echo "✅ All apps started!"
echo ""
echo "📊 Status:"
echo "   VehicleControlMock: Running in separate terminal"
echo "   RemoteSpeakerApp: Running in separate terminal (if built)"
echo "   Wayland socket: $RUNTIME_DIR/wayland-1"
echo ""
echo "🐳 Docker Containers:"
docker-compose -f docker-compose.all.yml ps
echo ""
echo "📝 Commands:"
echo "   View all logs:          docker-compose -f docker-compose.all.yml logs -f"
echo "   View HU_MainApp logs:   docker logs -f humainapp"
echo "   View GearApp logs:      docker logs -f gearapp"
echo "   Stop all:               ./stop_docker_test.sh"
echo ""
echo "💡 Native apps are running in separate terminal windows"
echo "   Close terminal windows or run stop script to stop them"
echo "═══════════════════════════════════════════════════"

# Note: PIDs are not saved when running in separate terminals
# User should close terminal windows manually or use pkill if needed
