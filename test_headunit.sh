#!/bin/bash

# Head Unit Test Script
# This script helps test the Head Unit application locally

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"
BUILD_DIR="$PROJECT_ROOT/app/HU_app/build"

echo "=== SEA-ME Head Unit Test Script ==="
echo "Project Root: $PROJECT_ROOT"

# Function to build the application
build_app() {
    echo "Building Head Unit application..."
    
    cd "$PROJECT_ROOT/app/HU_app"
    
    # Clean previous build
    if [ -d "build" ]; then
        rm -rf build
    fi
    
    # Configure with CMake
    cmake -B build -DCMAKE_BUILD_TYPE=Debug
    
    # Build
    cmake --build build -j$(nproc)
    
    echo "Build completed successfully!"
}

# Function to run the application
run_app() {
    echo "Running Head Unit application..."
    
    if [ ! -f "$BUILD_DIR/HU_app" ]; then
        echo "Application not found. Building first..."
        build_app
    fi
    
    # Create test media directories
    mkdir -p /tmp/test_media
    echo "Creating test media files for testing..."
    
    # Create some dummy audio files (empty files for testing)
    touch /tmp/test_media/test_song_1.mp3
    touch /tmp/test_media/test_song_2.mp3
    touch /tmp/test_media/test_song_3.mp3
    
    # Set QML import path
    export QML2_IMPORT_PATH="$BUILD_DIR"
    
    # Run the application
    cd "$BUILD_DIR"
    ./HU_app
}

# Function to clean build artifacts
clean() {
    echo "Cleaning build artifacts..."
    if [ -d "$BUILD_DIR" ]; then
        rm -rf "$BUILD_DIR"
    fi
    echo "Clean completed!"
}

# Function to run code checks
check_code() {
    echo "Running code quality checks..."
    
    # Check for Qt includes
    echo "Checking Qt includes..."
    find "$PROJECT_ROOT/app/HU_app" -name "*.cpp" -o -name "*.h" | xargs grep -l "Q_OBJECT\|#include <Q" || echo "No Qt files found"
    
    # Check QML files
    echo "Checking QML files..."
    find "$PROJECT_ROOT/app/HU_app" -name "*.qml" | while read file; do
        echo "  - $(basename "$file")"
    done
    
    echo "Code check completed!"
}

# Function to run vsomeip mock communication test
test_vsomeip() {
    echo "Starting vsomeip Mock Communication Test..."
    
    MOCK_DIR="$PROJECT_ROOT/mock_test_vsomeip"
    
    # Check if mock test directory exists
    if [ ! -d "$MOCK_DIR" ]; then
        echo "❌ Mock test directory not found: $MOCK_DIR"
        exit 1
    fi
    
    # Check if build directory exists
    if [ ! -d "$MOCK_DIR/build" ] || [ ! -f "$MOCK_DIR/build/vsomeip_mock_test" ]; then
        echo "❌ vsomeip mock test not built. Please build it first:"
        echo "   cd $MOCK_DIR && mkdir -p build && cd build && cmake .. && make"
        exit 1
    fi
    
    echo "🚀 Opening 2 terminals for vsomeip Mock test..."
    
    # Kill any existing vsomeip processes
    pkill -f vsomeip_mock_test 2>/dev/null || true
    rm -rf /tmp/vsomeip* 2>/dev/null || true
    sleep 1
    
    # Check which terminal emulator is available
    if command -v gnome-terminal >/dev/null 2>&1; then
        TERMINAL="gnome-terminal"
    elif command -v xterm >/dev/null 2>&1; then
        TERMINAL="xterm"
    elif command -v konsole >/dev/null 2>&1; then
        TERMINAL="konsole"
    else
        echo "❌ No supported terminal emulator found (gnome-terminal, xterm, konsole)"
        echo "💡 Running in background instead..."
        run_vsomeip_background
        return
    fi
    
    echo "📡 Starting vsomeip Mock Server in Terminal 1..."
    if [ "$TERMINAL" = "gnome-terminal" ]; then
        gnome-terminal --title="vsomeip Mock Server" -- bash -c "
            cd '$MOCK_DIR' && 
            export VSOMEIP_CONFIGURATION='$MOCK_DIR/vsomeip-config.json' &&
            export VSOMEIP_APPLICATION_NAME='vehicle_service' &&
            echo '🚀 Starting vsomeip Mock Server...' &&
            echo '🛑 Press Ctrl+C to stop' &&
            ./build/vsomeip_mock_test server;
            echo '👋 Server stopped. Press Enter to close...';
            read
        " &
        
        # Wait a moment for server to start
        sleep 3
        
        echo "📱 Starting vsomeip Mock Client in Terminal 2..."
        gnome-terminal --title="vsomeip Mock Client" -- bash -c "
            cd '$MOCK_DIR' &&
            export VSOMEIP_CONFIGURATION='$MOCK_DIR/vsomeip-config.json' &&
            export VSOMEIP_APPLICATION_NAME='vehicle_client' &&
            echo '🔍 Starting vsomeip Mock Client...' &&
            echo '🛑 Press Ctrl+C to stop' &&
            ./build/vsomeip_mock_test client;
            echo '👋 Client stopped. Press Enter to close...';
            read
        " &
    else
        # For xterm and konsole
        $TERMINAL -T "vsomeip Mock Server" -e bash -c "
            cd '$MOCK_DIR' && 
            export VSOMEIP_CONFIGURATION='$MOCK_DIR/vsomeip-config.json' &&
            export VSOMEIP_APPLICATION_NAME='vehicle_service' &&
            echo '🚀 Starting vsomeip Mock Server...' &&
            ./build/vsomeip_mock_test server;
            echo 'Press Enter to close...';
            read
        " &
        
        sleep 3
        
        $TERMINAL -T "vsomeip Mock Client" -e bash -c "
            cd '$MOCK_DIR' &&
            export VSOMEIP_CONFIGURATION='$MOCK_DIR/vsomeip-config.json' &&
            export VSOMEIP_APPLICATION_NAME='vehicle_client' &&
            echo '🔍 Starting vsomeip Mock Client...' &&
            ./build/vsomeip_mock_test client;
            echo 'Press Enter to close...';
            read
        " &
    fi
    
    echo "✅ Both terminals opened successfully!"
    echo "📊 You should see:"
    echo "   Terminal 1: Mock server with real-time data updates"
    echo "   Terminal 2: Mock client receiving data every 5 seconds"
    echo ""
    echo "🛑 To stop: Press Ctrl+C in each terminal"
}

# Function to run vsomeip in background (fallback)
run_vsomeip_background() {
    echo "🔄 Running vsomeip mock test in background..."
    
    MOCK_DIR="$PROJECT_ROOT/mock_test_vsomeip"
    cd "$MOCK_DIR"
    
    # Start server in background
    export VSOMEIP_CONFIGURATION="$MOCK_DIR/vsomeip-config.json"
    export VSOMEIP_APPLICATION_NAME="vehicle_service"
    ./build/vsomeip_mock_test server &
    SERVER_PID=$!
    echo "🚀 Server started (PID: $SERVER_PID)"
    
    # Wait for server to initialize
    sleep 3
    
    # Start client in background
    export VSOMEIP_APPLICATION_NAME="vehicle_client"
    ./build/vsomeip_mock_test client &
    CLIENT_PID=$!
    echo "📱 Client started (PID: $CLIENT_PID)"
    
    echo "✅ Both processes running in background"
    echo "📊 Check logs or use: ps aux | grep vsomeip_mock_test"
    echo "🛑 To stop: pkill -f vsomeip_mock_test"
    
    # Wait and show some output
    echo "⏰ Showing output for 30 seconds..."
    sleep 30
    
    echo "🔄 Processes still running. To monitor:"
    echo "   tail -f /var/log/syslog | grep vsomeip"
}

# Function to show help
show_help() {
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  build     - Build the Head Unit application"
    echo "  run       - Run the Head Unit application" 
    echo "  clean     - Clean build artifacts"
    echo "  check     - Run code quality checks"
    echo "  vsomeip   - Run vsomeip Mock communication test (2 terminals)"
    echo "  help      - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 build"
    echo "  $0 run"
    echo "  $0 vsomeip   # Opens 2 terminals for mock communication test"
}

# Main script logic
case "${1:-help}" in
    build)
        build_app
        ;;
    run)
        run_app
        ;;
    clean)
        clean
        ;;
    check)
        check_code
        ;;
    vsomeip)
        test_vsomeip
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo "Unknown command: $1"
        show_help
        exit 1
        ;;
esac
