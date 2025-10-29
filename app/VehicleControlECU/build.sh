#!/bin/bash

# Build script for VehicleControlECU
# Run this on the Raspberry Pi

set -e

echo "═══════════════════════════════════════════════════════"
echo "Building VehicleControlECU"
echo "═══════════════════════════════════════════════════════"
echo ""

# Check if running on Raspberry Pi
if [ ! -d "/sys/firmware/devicetree/base/model" ]; then
    echo "⚠️  Warning: Not running on Raspberry Pi!"
    echo "   This build is intended for Raspberry Pi hardware."
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check for pigpio
echo "🔍 Checking dependencies..."
if ! ldconfig -p | grep -q libpigpio; then
    echo "❌ libpigpio not found!"
    echo "   Install with: sudo apt install libpigpio-dev"
    exit 1
fi
echo "✅ pigpio library found"

# Check for Qt5
if ! pkg-config --exists Qt5Core; then
    echo "❌ Qt5 not found!"
    echo "   Install with: sudo apt install qtbase5-dev"
    exit 1
fi
echo "✅ Qt5 found"

# Create build directory
echo ""
echo "📁 Creating build directory..."
mkdir -p build
cd build

# Run CMake
echo ""
echo "🔧 Running CMake..."
cmake .. -DCMAKE_BUILD_TYPE=Release

# Build
echo ""
echo "🔨 Building..."
make -j$(nproc)

# Check if build succeeded
if [ -f "VehicleControlECU" ]; then
    echo ""
    echo "═══════════════════════════════════════════════════════"
    echo "✅ Build successful!"
    echo ""
    echo "Executable: build/VehicleControlECU"
    echo ""
    echo "To run:"
    echo "  cd build"
    echo "  sudo ./VehicleControlECU"
    echo ""
    echo "Or use the run script:"
    echo "  ./run.sh"
    echo "═══════════════════════════════════════════════════════"
else
    echo ""
    echo "❌ Build failed!"
    exit 1
fi
