#!/bin/bash

echo "========================================="
echo "  IC_app Runner (vsomeip client)"
echo "========================================="
echo ""

# 빌드 확인
if [ ! -f "build/IC_app" ]; then
    echo "❌ IC_app not found!"
    echo "   Please build first: cd build && cmake .. && make"
    exit 1
fi

# 설정 파일 복사
echo "📋 Setting up vsomeip configuration..."
cp vsomeip_ic.json build/
cp commonapi4someip.ini build/

cd build

# 환경 변수 설정
export VSOMEIP_CONFIGURATION=vsomeip_ic.json
export COMMONAPI_CONFIG=commonapi4someip.ini
export LD_LIBRARY_PATH=../../../deps/capicxx-core-runtime/build:../../../deps/capicxx-someip-runtime/build:../../../deps/vsomeip/build:$LD_LIBRARY_PATH

echo "✅ Configuration ready"
echo ""
echo "🚀 Starting IC_app..."
echo "   VSOMEIP_CONFIGURATION=$VSOMEIP_CONFIGURATION"
echo "   COMMONAPI_CONFIG=$COMMONAPI_CONFIG"
echo ""
echo "⚠️  Make sure VehicleControlECU is running on Raspberry Pi!"
echo ""
echo "========================================="
echo ""

# 앱 실행
./IC_app
