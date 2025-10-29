#!/bin/bash

echo "========================================="
echo "  IC_app Build (with vsomeip)"
echo "========================================="
echo ""

# CMake 빌드
cd build
cmake ..
make -j$(nproc)

if [ $? -eq 0 ]; then
    echo ""
    echo "========================================="
    echo "✅ IC_app build successful!"
    echo "========================================="
    echo "Executable: build/IC_app"
    echo ""
else
    echo ""
    echo "❌ Build failed!"
    exit 1
fi
