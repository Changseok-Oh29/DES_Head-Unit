#!/bin/bash

# Standalone 빌드 스크립트 (CommonAPI 없이)
# 하드웨어 제어만 테스트

set -e

echo "═══════════════════════════════════════════════════════"
echo "Building VehicleControlECU (Standalone Mode)"
echo "Hardware Control Only - No vsomeip"
echo "═══════════════════════════════════════════════════════"
echo ""

# 의존성 확인
echo "🔍 Checking dependencies..."

# pigpio 확인
if ! ldconfig -p | grep -q libpigpio; then
    echo "❌ libpigpio not found!"
    echo "   Install with: sudo apt install libpigpio-dev"
    exit 1
fi
echo "✅ pigpio library found"

# Qt5 확인
if ! pkg-config --exists Qt5Core; then
    echo "❌ Qt5 not found!"
    echo "   Install with: sudo apt install qtbase5-dev"
    exit 1
fi
echo "✅ Qt5 found"

# 빌드 디렉토리 생성
echo ""
echo "📁 Creating build directory..."
rm -rf build_standalone
mkdir build_standalone

# CMakeLists_standalone.txt를 build_standalone으로 복사
cp CMakeLists_standalone.txt build_standalone/CMakeLists.txt

cd build_standalone

# CMake 실행
echo ""
echo "🔧 Running CMake..."
cmake -DCMAKE_BUILD_TYPE=Release .

# 빌드
echo ""
echo "🔨 Building..."
make -j$(nproc)

# 결과 확인
if [ -f "VehicleControlECU_Standalone" ]; then
    echo ""
    echo "═══════════════════════════════════════════════════════"
    echo "✅ Build successful!"
    echo ""
    echo "Executable: build_standalone/VehicleControlECU_Standalone"
    echo ""
    echo "To run:"
    echo "  cd build_standalone"
    echo "  sudo ./VehicleControlECU_Standalone"
    echo ""
    echo "Or use the run script:"
    echo "  ./run_standalone.sh"
    echo "═══════════════════════════════════════════════════════"
else
    echo ""
    echo "❌ Build failed!"
    exit 1
fi
