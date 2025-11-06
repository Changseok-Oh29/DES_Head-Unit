#!/bin/bash

echo "════════════════════════════════════════════════════════════"
echo "ECU2 - 빠른 재빌드 및 실행"
echo "════════════════════════════════════════════════════════════"
echo ""

cd ~/DES_Head-Unit/app/HU_MainApp

echo "1️⃣  Rebuilding HU_MainApp Compositor..."
./build.sh

if [ $? -ne 0 ]; then
    echo ""
    echo "❌ Build failed!"
    exit 1
fi

echo ""
echo "✅ Build successful!"
echo ""
echo "2️⃣  Starting all apps..."
echo ""

./start_all_wayland.sh
