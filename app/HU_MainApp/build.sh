#!/bin/bash

echo "════════════════════════════════════════════════════════"
echo "Building HU_MainApp - Wayland Compositor"
echo "════════════════════════════════════════════════════════"

cd "$(dirname "$0")"

# Clean build
echo "Cleaning build directory..."
rm -rf build
mkdir -p build
cd build

# CMake
echo "Running CMake..."
cmake -DCMAKE_BUILD_TYPE=Debug ..
if [ $? -ne 0 ]; then
    echo "❌ CMake configuration failed!"
    exit 1
fi

# Build
echo "Building..."
make -j$(nproc)
if [ $? -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
fi

echo "✅ Build successful!"
echo ""
echo "To run HU_MainApp Compositor:"
echo "  ./run.sh"
echo ""
echo "Note: This is a Wayland compositor only."
echo "Run independent apps separately:"
echo "  - cd ../GearApp && ./run.sh"
echo "  - cd ../MediaApp && ./run.sh"
echo "  - cd ../AmbientApp && ./run.sh"
echo "════════════════════════════════════════════════════════"
