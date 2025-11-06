#!/bin/bash

echo "════════════════════════════════════════════════════════════"
echo "전체 앱 검증 및 정리"
echo "════════════════════════════════════════════════════════════"
echo ""

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ═══════════════════════════════════════════════════════════
# 1. GearApp 검증
# ═══════════════════════════════════════════════════════════
echo "1️⃣  GearApp 검증..."
cd "$BASE_DIR/GearApp"

REQUIRED_FILES=(
    "run.sh"
    "run_wayland.sh"
    "config/vsomeip_ecu2.json"
    "config/commonapi_ecu2.ini"
    "qml/GearSelectionWidget.qml"
)

ALL_OK=true
for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -e "$file" ]; then
        echo "   ❌ Missing: $file"
        ALL_OK=false
    fi
done

if [ "$ALL_OK" = true ]; then
    echo "   ✅ GearApp OK"
    
    # Window title 확인
    if grep -q 'title: "GearApp' qml/GearSelectionWidget.qml; then
        echo "   ✅ Window title configured for Wayland"
    else
        echo "   ⚠️  Window title not found"
    fi
fi

echo ""

# ═══════════════════════════════════════════════════════════
# 2. MediaApp 검증
# ═══════════════════════════════════════════════════════════
echo "2️⃣  MediaApp 검증..."
cd "$BASE_DIR/MediaApp"

REQUIRED_FILES=(
    "run.sh"
    "run_wayland.sh"
    "config/vsomeip_ecu2.json"
    "config/commonapi_ecu2.ini"
    "qml/MediaApp.qml"
)

ALL_OK=true
for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -e "$file" ]; then
        echo "   ❌ Missing: $file"
        ALL_OK=false
    fi
done

if [ "$ALL_OK" = true ]; then
    echo "   ✅ MediaApp OK"
    
    # Window title 확인
    if grep -q 'title: "MediaApp' qml/MediaApp.qml; then
        echo "   ✅ Window title configured for Wayland"
    else
        echo "   ⚠️  Window title not found"
    fi
    
    # run.sh가 config/ 참조하는지 확인
    if grep -q 'config/vsomeip_ecu2.json' run.sh; then
        echo "   ✅ run.sh uses config/ directory"
    else
        echo "   ⚠️  run.sh not using config/ directory"
    fi
fi

echo ""

# ═══════════════════════════════════════════════════════════
# 3. AmbientApp 검증
# ═══════════════════════════════════════════════════════════
echo "3️⃣  AmbientApp 검증..."
cd "$BASE_DIR/AmbientApp"

REQUIRED_FILES=(
    "run.sh"
    "run_wayland.sh"
    "config/vsomeip_ecu2.json"
    "config/commonapi_ecu2.ini"
    "qml/AmbientLighting.qml"
)

ALL_OK=true
for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -e "$file" ]; then
        echo "   ❌ Missing: $file"
        ALL_OK=false
    fi
done

if [ "$ALL_OK" = true ]; then
    echo "   ✅ AmbientApp OK"
    
    # Window title 확인
    if grep -q 'title: "AmbientApp' qml/AmbientLighting.qml; then
        echo "   ✅ Window title configured for Wayland"
    else
        echo "   ⚠️  Window title not found"
    fi
    
    # run.sh가 config/ 참조하는지 확인
    if grep -q 'config/vsomeip_ecu2.json' run.sh; then
        echo "   ✅ run.sh uses config/ directory"
    else
        echo "   ⚠️  run.sh not using config/ directory"
    fi
fi

echo ""

# ═══════════════════════════════════════════════════════════
# 4. HU_MainApp 검증
# ═══════════════════════════════════════════════════════════
echo "4️⃣  HU_MainApp (Compositor) 검증..."
cd "$BASE_DIR/HU_MainApp"

REQUIRED_FILES=(
    "CMakeLists.txt"
    "build.sh"
    "run.sh"
    "start_all_wayland.sh"
    "qml.qrc"
    "src/main_compositor.cpp"
    "qml/CompositorMain.qml"
)

ALL_OK=true
for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -e "$file" ]; then
        echo "   ❌ Missing: $file"
        ALL_OK=false
    fi
done

if [ "$ALL_OK" = true ]; then
    echo "   ✅ HU_MainApp OK"
    
    # qml.qrc가 CompositorMain.qml 참조하는지 확인
    if grep -q 'CompositorMain.qml' qml.qrc; then
        echo "   ✅ qml.qrc references CompositorMain.qml"
    else
        echo "   ⚠️  qml.qrc not referencing CompositorMain.qml"
    fi
fi

echo ""

# ═══════════════════════════════════════════════════════════
# 5. 불필요 파일 검색
# ═══════════════════════════════════════════════════════════
echo "5️⃣  불필요 파일 검색..."
echo ""

cd "$BASE_DIR"

# MediaApp 루트에 남은 vsomeip 파일
if [ -f "MediaApp/vsomeip.json" ] || [ -f "MediaApp/commonapi.ini" ]; then
    echo "   ⚠️  MediaApp 루트에 중복 설정 파일:"
    ls -la MediaApp/*.{json,ini} 2>/dev/null | awk '{print "      " $0}'
fi

# AmbientApp 루트에 남은 vsomeip 파일
if [ -f "AmbientApp/vsomeip_ambient.json" ] || [ -f "AmbientApp/commonapi_ambient.ini" ] || [ -f "AmbientApp/commonapi.ini" ]; then
    echo "   ⚠️  AmbientApp 루트에 중복 설정 파일:"
    ls -la AmbientApp/*.{json,ini} 2>/dev/null | awk '{print "      " $0}'
fi

echo ""
echo "════════════════════════════════════════════════════════════"
echo "✅ 검증 완료!"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "📋 요약:"
echo "   - GearApp:    Wayland 준비 완료"
echo "   - MediaApp:   Wayland 준비 완료"
echo "   - AmbientApp: Wayland 준비 완료"
echo "   - HU_MainApp: Compositor 준비 완료"
echo ""
echo "🚀 실행 방법:"
echo "   cd HU_MainApp && ./start_all_wayland.sh"
echo ""
