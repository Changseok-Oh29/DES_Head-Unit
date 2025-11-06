#!/bin/bash

echo "════════════════════════════════════════════════════════════"
echo "Wayland Compositor - 환경 진단"
echo "════════════════════════════════════════════════════════════"
echo ""

# 1. X11 확인
echo "1. X11 Display Server 확인:"
if [ -n "$DISPLAY" ]; then
    echo "   ✅ DISPLAY=$DISPLAY (X11 available)"
    X11_AVAILABLE=true
else
    echo "   ❌ DISPLAY not set (X11 not available)"
    X11_AVAILABLE=false
fi
echo ""

# 2. Wayland Display 확인
echo "2. Wayland Display Server 확인:"
if [ -n "$WAYLAND_DISPLAY" ]; then
    echo "   ✅ WAYLAND_DISPLAY=$WAYLAND_DISPLAY"
    WAYLAND_AVAILABLE=true
else
    echo "   ❌ WAYLAND_DISPLAY not set"
    WAYLAND_AVAILABLE=false
fi
echo ""

# 3. Qt 플랫폼 플러그인 확인
echo "3. 사용 가능한 Qt Platform Plugins:"
find /usr/lib/aarch64-linux-gnu/qt5/plugins/platforms -name "*.so" 2>/dev/null | while read plugin; do
    basename "$plugin" .so | sed 's/^libq/   - /'
done
echo ""

# 4. 권한 확인
echo "4. XDG_RUNTIME_DIR 확인:"
if [ -d "/run/user/$(id -u)" ]; then
    echo "   ✅ /run/user/$(id -u) exists"
    ls -ld "/run/user/$(id -u)"
else
    echo "   ❌ /run/user/$(id -u) does not exist"
fi
echo ""

# 5. GPU/DRM 장치 확인
echo "5. DRM/KMS 장치 확인:"
if [ -e "/dev/dri/card0" ]; then
    echo "   ✅ /dev/dri/card0 exists"
    ls -l /dev/dri/card0
else
    echo "   ❌ /dev/dri/card0 not found"
fi
echo ""

# 6. 권장 플랫폼
echo "════════════════════════════════════════════════════════════"
echo "권장 Compositor 플랫폼:"
if [ "$X11_AVAILABLE" = true ]; then
    echo "   🎯 QT_QPA_PLATFORM=xcb (X11 사용)"
elif [ -e "/dev/dri/card0" ]; then
    echo "   🎯 QT_QPA_PLATFORM=eglfs (DRM/KMS 사용)"
elif [ "$WAYLAND_AVAILABLE" = true ]; then
    echo "   🎯 QT_QPA_PLATFORM=wayland (Nested Compositor)"
else
    echo "   ⚠️  linuxfb 또는 VNC 고려 필요"
fi
echo "════════════════════════════════════════════════════════════"
