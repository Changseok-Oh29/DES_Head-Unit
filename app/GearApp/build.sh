#!/bin/bash

set -e

echo "========================================="
echo "  GearApp - DEPLOYMENT BUILD"
echo "  (Raspberry Pi - ECU2 @ 192.168.1.101)"
echo "========================================="
echo ""

# Clean previous build
if [ -d "build" ]; then
    echo "🧹 Cleaning previous build..."
    rm -rf build
fi

mkdir -p build
cd build

# Copy CMakeLists.txt to build directory
cp ../CMakeLists.txt .

echo "🔧 Running CMake..."
cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_COMPILER=g++ \
    -DCMAKE_C_COMPILER=gcc

echo ""
echo "🔨 Building..."
make -j$(nproc)

echo ""
echo "========================================="
echo "✅ Build Successful!"
echo "========================================="
echo "Executable: build/GearApp"
echo ""
echo "To run: ./run.sh"
echo ""
echo "NOTE: Make sure VehicleControlECU is running on ECU1 first!"
echo "========================================="
