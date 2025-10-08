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

# Function to show help
show_help() {
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  build     - Build the Head Unit application"
    echo "  run       - Run the Head Unit application"
    echo "  clean     - Clean build artifacts"
    echo "  check     - Run code quality checks"
    echo "  help      - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 build"
    echo "  $0 run"
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
    help|--help|-h)
        show_help
        ;;
    *)
        echo "Unknown command: $1"
        show_help
        exit 1
        ;;
esac
