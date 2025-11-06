#!/bin/bash

echo "════════════════════════════════════════════════════════════"
echo "ECU2 - 전체 앱 빌드 스크립트"
echo "════════════════════════════════════════════════════════════"
echo ""

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ═══════════════════════════════════════════════════════════
# 1. HU_MainApp (Compositor) 빌드
# ═══════════════════════════════════════════════════════════
echo "1️⃣  Building HU_MainApp (Wayland Compositor)..."
cd "$BASE_DIR/HU_MainApp"

if [ ! -f "build.sh" ]; then
    echo "   ❌ build.sh not found!"
    exit 1
fi

./build.sh
if [ $? -ne 0 ]; then
    echo "   ❌ HU_MainApp build failed!"
    exit 1
fi

echo "   ✅ HU_MainApp built successfully"
echo ""

# ═══════════════════════════════════════════════════════════
# 2. GearApp 빌드
# ═══════════════════════════════════════════════════════════
echo "2️⃣  Building GearApp..."
cd "$BASE_DIR/GearApp"

if [ ! -f "build.sh" ]; then
    echo "   ❌ build.sh not found!"
    exit 1
fi

./build.sh
if [ $? -ne 0 ]; then
    echo "   ❌ GearApp build failed!"
    exit 1
fi

echo "   ✅ GearApp built successfully"
echo ""

# ═══════════════════════════════════════════════════════════
# 3. MediaApp 빌드
# ═══════════════════════════════════════════════════════════
echo "3️⃣  Building MediaApp..."
cd "$BASE_DIR/MediaApp"

if [ ! -f "build.sh" ]; then
    echo "   ❌ build.sh not found!"
    exit 1
fi

./build.sh
if [ $? -ne 0 ]; then
    echo "   ❌ MediaApp build failed!"
    exit 1
fi

echo "   ✅ MediaApp built successfully"
echo ""

# ═══════════════════════════════════════════════════════════
# 4. AmbientApp 빌드
# ═══════════════════════════════════════════════════════════
echo "4️⃣  Building AmbientApp..."
cd "$BASE_DIR/AmbientApp"

if [ ! -f "build.sh" ]; then
    echo "   ❌ build.sh not found!"
    exit 1
fi

./build.sh
if [ $? -ne 0 ]; then
    echo "   ❌ AmbientApp build failed!"
    exit 1
fi

echo "   ✅ AmbientApp built successfully"
echo ""

# ═══════════════════════════════════════════════════════════
# 5. IC_app 빌드 (선택)
# ═══════════════════════════════════════════════════════════
echo "5️⃣  Building IC_app..."
cd "$BASE_DIR/IC_app"

if [ ! -f "build.sh" ]; then
    echo "   ⚠️  IC_app build.sh not found (skipping)"
else
    ./build.sh
    if [ $? -ne 0 ]; then
        echo "   ⚠️  IC_app build failed (non-critical)"
    else
        echo "   ✅ IC_app built successfully"
    fi
fi

echo ""
echo "════════════════════════════════════════════════════════════"
echo "✅ All apps built successfully!"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "🚀 실행 방법:"
echo "   cd HU_MainApp"
echo "   ./start_all_wayland.sh"
echo ""
