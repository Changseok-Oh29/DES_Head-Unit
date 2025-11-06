#!/bin/bash

echo "════════════════════════════════════════════════════════════"
echo "Wayland Compositor - Rebuild All & Test"
echo "════════════════════════════════════════════════════════════"
echo ""

# Change to app directory
cd "$(dirname "$0")"

# Step 1: Build HU_MainApp Compositor
echo "Step 1/4: Building HU_MainApp (Compositor)..."
cd HU_MainApp
./build_compositor.sh  # Compositor 전용 빌드 스크립트
if [ $? -ne 0 ]; then
    echo "❌ HU_MainApp Compositor build failed!"
    exit 1
fi
echo "✅ HU_MainApp Compositor built successfully"
echo ""
cd ..

# Step 2: Build GearApp
echo "Step 2/4: Building GearApp..."
cd GearApp
./build.sh
if [ $? -ne 0 ]; then
    echo "❌ GearApp build failed!"
    exit 1
fi
echo "✅ GearApp built successfully"
echo ""
cd ..

# Step 3: Build MediaApp
echo "Step 3/4: Building MediaApp..."
cd MediaApp
./build.sh
if [ $? -ne 0 ]; then
    echo "❌ MediaApp build failed!"
    exit 1
fi
echo "✅ MediaApp built successfully"
echo ""
cd ..

# Step 4: Build AmbientApp
echo "Step 4/4: Building AmbientApp..."
cd AmbientApp
./build.sh
if [ $? -ne 0 ]; then
    echo "❌ AmbientApp build failed!"
    exit 1
fi
echo "✅ AmbientApp built successfully"
echo ""
cd ..

echo "════════════════════════════════════════════════════════════"
echo "✅ All applications built successfully!"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "To run the Wayland Compositor with all apps:"
echo "  $ cd HU_MainApp"
echo "  $ ./start_all_wayland.sh"
echo ""
