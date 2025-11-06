#!/bin/bash

echo "════════════════════════════════════════════════════════════"
echo "HU_MainApp - 불필요한 파일 정리"
echo "════════════════════════════════════════════════════════════"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# 백업 디렉토리 생성
BACKUP_DIR="_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "📦 백업 디렉토리 생성: $BACKUP_DIR"
echo ""

# ═══════════════════════════════════════════════════════════
# 1. Integrated 방식 파일들 (사용 안 함)
# ═══════════════════════════════════════════════════════════
echo "1️⃣  Integrated 방식 파일 정리 중..."

FILES_TO_BACKUP=(
    "CMakeLists_integrated.txt"
    "build_integrated.sh"
    "run_integrated.sh"
    "qml_integrated.qrc"
    "README_INTEGRATED.md"
    "src/main_integrated.cpp"
    "qml/IntegratedMainApp.qml"
    "qml/MediaAppContent.qml"
    "qml/AmbientAppContent.qml"
)

for file in "${FILES_TO_BACKUP[@]}"; do
    if [ -e "$file" ]; then
        echo "   📁 백업: $file"
        mkdir -p "$BACKUP_DIR/$(dirname "$file")"
        mv "$file" "$BACKUP_DIR/$file"
    fi
done

echo ""

# ═══════════════════════════════════════════════════════════
# 2. Prototype 파일들 (사용 안 함)
# ═══════════════════════════════════════════════════════════
echo "2️⃣  Prototype 파일 정리 중..."

PROTOTYPE_FILES=(
    "src/main.cpp"
    "qml/compositor.qml"
)

for file in "${PROTOTYPE_FILES[@]}"; do
    if [ -e "$file" ]; then
        echo "   📁 백업: $file"
        mkdir -p "$BACKUP_DIR/$(dirname "$file")"
        mv "$file" "$BACKUP_DIR/$file"
    fi
done

echo ""

# ═══════════════════════════════════════════════════════════
# 3. Compositor 관련 중복 파일들
# ═══════════════════════════════════════════════════════════
echo "3️⃣  중복 파일 정리 중..."

DUPLICATE_FILES=(
    "CMakeLists_compositor.txt"
    "build_compositor.sh"
    "run_compositor.sh"
    "qml_compositor.qrc"
    "src/main_compositor.cpp"
    "README_WAYLAND_COMPOSITOR.md"
)

for file in "${DUPLICATE_FILES[@]}"; do
    if [ -e "$file" ]; then
        echo "   📁 백업: $file"
        mkdir -p "$BACKUP_DIR/$(dirname "$file")"
        mv "$file" "$BACKUP_DIR/$file"
    fi
done

echo ""

# ═══════════════════════════════════════════════════════════
# 4. vsomeip 관련 파일 (Compositor는 vsomeip 불필요)
# ═══════════════════════════════════════════════════════════
echo "4️⃣  vsomeip 설정 파일 정리 중..."

VSOMEIP_FILES=(
    "commonapi.ini"
    "vsomeip.json"
)

for file in "${VSOMEIP_FILES[@]}"; do
    if [ -e "$file" ]; then
        echo "   📁 백업: $file"
        mv "$file" "$BACKUP_DIR/"
    fi
done

echo ""

# ═══════════════════════════════════════════════════════════
# 5. 기타 불필요 파일
# ═══════════════════════════════════════════════════════════
echo "5️⃣  기타 파일 정리 중..."

if [ -e "ECU2_DEPLOYMENT.md" ]; then
    echo "   📁 백업: ECU2_DEPLOYMENT.md"
    mv "ECU2_DEPLOYMENT.md" "$BACKUP_DIR/"
fi

echo ""

# ═══════════════════════════════════════════════════════════
# 최종 상태 확인
# ═══════════════════════════════════════════════════════════
echo "════════════════════════════════════════════════════════════"
echo "✅ 정리 완료!"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "📂 남은 파일들:"
echo ""
ls -lh --color=auto

echo ""
echo "📦 백업된 파일들: $BACKUP_DIR/"
echo ""
echo "⚠️  백업이 불필요하면 삭제하세요:"
echo "   rm -rf $BACKUP_DIR"
echo ""
