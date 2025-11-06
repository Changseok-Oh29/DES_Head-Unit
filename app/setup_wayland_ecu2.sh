#!/bin/bash

echo "════════════════════════════════════════════════════════════"
echo "ECU2 - Wayland Compositor 환경 설정"
echo "════════════════════════════════════════════════════════════"
echo ""

# ═══════════════════════════════════════════════════════════
# 1. Qt Wayland Compositor 설치
# ═══════════════════════════════════════════════════════════
echo "1️⃣  Installing Qt Wayland Compositor..."
echo ""

sudo apt update

# 필수 패키지
PACKAGES=(
    "qtwayland5"
    "libqt5waylandcompositor5"
    "libqt5waylandcompositor5-dev"
    "qml-module-qtwayland-compositor"
)

for pkg in "${PACKAGES[@]}"; do
    if dpkg -l | grep -q "^ii  $pkg"; then
        echo "   ✅ $pkg already installed"
    else
        echo "   📦 Installing $pkg..."
        sudo apt install -y "$pkg"
    fi
done

echo ""

# ═══════════════════════════════════════════════════════════
# 2. QML 모듈 확인
# ═══════════════════════════════════════════════════════════
echo "2️⃣  Verifying QML modules..."
echo ""

QML_MODULE_PATH=$(dpkg -L qml-module-qtwayland-compositor 2>/dev/null | grep -E "Compositor.*qmldir" | head -1 | xargs dirname)

if [ ! -z "$QML_MODULE_PATH" ]; then
    echo "   ✅ QtWayland.Compositor module found:"
    echo "      $QML_MODULE_PATH"
else
    echo "   ❌ QtWayland.Compositor module NOT found!"
    echo "      Trying to install..."
    sudo apt install -y qml-module-qtwayland-compositor
fi

echo ""

# ═══════════════════════════════════════════════════════════
# 3. 런타임 디렉토리 설정
# ═══════════════════════════════════════════════════════════
echo "3️⃣  Setting up runtime directory..."
echo ""

RUNTIME_DIR="/run/user/$(id -u)"

if [ -d "$RUNTIME_DIR" ]; then
    CURRENT_PERM=$(stat -c %a "$RUNTIME_DIR")
    if [ "$CURRENT_PERM" != "700" ]; then
        echo "   ⚠️  Wrong permissions on $RUNTIME_DIR: $CURRENT_PERM"
        echo "   📝 Fixing permissions..."
        sudo chmod 0700 "$RUNTIME_DIR"
        echo "   ✅ Permissions fixed to 0700"
    else
        echo "   ✅ Runtime directory permissions correct: 0700"
    fi
else
    echo "   ⚠️  $RUNTIME_DIR not found"
    echo "   📁 Creating alternative runtime directory..."
    
    ALT_RUNTIME_DIR="/tmp/runtime-$USER"
    mkdir -p "$ALT_RUNTIME_DIR"
    chmod 0700 "$ALT_RUNTIME_DIR"
    
    echo "   ✅ Created: $ALT_RUNTIME_DIR"
    echo ""
    echo "   💡 Add to ~/.bashrc:"
    echo "      export XDG_RUNTIME_DIR=/tmp/runtime-$USER"
fi

echo ""

# ═══════════════════════════════════════════════════════════
# 4. 환경 변수 확인
# ═══════════════════════════════════════════════════════════
echo "4️⃣  Checking environment variables..."
echo ""

echo "   Current settings:"
echo "   - XDG_RUNTIME_DIR: ${XDG_RUNTIME_DIR:-<not set>}"
echo "   - QT_QPA_PLATFORM: ${QT_QPA_PLATFORM:-<not set>}"
echo "   - WAYLAND_DISPLAY: ${WAYLAND_DISPLAY:-<not set>}"

echo ""

# ═══════════════════════════════════════════════════════════
# 5. 설치 확인
# ═══════════════════════════════════════════════════════════
echo "5️⃣  Installation summary..."
echo ""

ALL_OK=true

# Qt 확인
if command -v qmake &> /dev/null; then
    echo "   ✅ Qt installed: $(qmake -v | grep 'Qt version' | awk '{print $4}')"
else
    echo "   ❌ Qt not found!"
    ALL_OK=false
fi

# Wayland Compositor 확인
if dpkg -l | grep -q "libqt5waylandcompositor5"; then
    echo "   ✅ Qt Wayland Compositor library installed"
else
    echo "   ❌ Qt Wayland Compositor library NOT installed"
    ALL_OK=false
fi

# QML 모듈 확인
if [ ! -z "$QML_MODULE_PATH" ]; then
    echo "   ✅ QtWayland.Compositor QML module available"
else
    echo "   ❌ QtWayland.Compositor QML module NOT available"
    ALL_OK=false
fi

echo ""

if [ "$ALL_OK" = true ]; then
    echo "════════════════════════════════════════════════════════════"
    echo "✅ All dependencies installed successfully!"
    echo "════════════════════════════════════════════════════════════"
    echo ""
    echo "🚀 Next steps:"
    echo "   1. Build all apps:"
    echo "      cd ~/DES_Head-Unit/app"
    echo "      ./build_all_ecu2.sh"
    echo ""
    echo "   2. Run Wayland Compositor:"
    echo "      cd HU_MainApp"
    echo "      ./start_all_wayland.sh"
    echo ""
else
    echo "════════════════════════════════════════════════════════════"
    echo "⚠️  Some dependencies are missing!"
    echo "════════════════════════════════════════════════════════════"
    echo ""
    echo "Please install missing packages manually:"
    echo "   sudo apt install qtwayland5 libqt5waylandcompositor5-dev qml-module-qtwayland-compositor"
    echo ""
fi
