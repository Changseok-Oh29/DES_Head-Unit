#!/bin/bash

# vsomeip Mock 데이터 통신 테스트 스크립트

echo "🚀 vsomeip Mock 데이터 통신 테스트 시작"

# 빌드 디렉토리로 이동
BUILD_DIR="/home/leo/SEA-ME/DES_Head-Unit/mock_test_vsomeip/build"
cd "$BUILD_DIR"

# 기존 프로세스 정리
echo "🧹 기존 프로세스 정리 중..."
pkill -f vsomeip_mock_test 2>/dev/null || true
rm -rf /tmp/vsomeip* 2>/dev/null || true
sleep 2

# vsomeip 설정
export VSOMEIP_CONFIGURATION="$BUILD_DIR/vsomeip-config.json"

echo "� vsomeip Mock 서버 시작 중..."
export VSOMEIP_APPLICATION_NAME="vehicle_service"
"$BUILD_DIR/vsomeip_mock_test" server &
SERVER_PID=$!
echo "🔧 서버 PID: $SERVER_PID"

# 서버 시작 대기
echo "⏰ 서버 초기화 대기 중..."
sleep 3

echo "📱 vsomeip Mock 클라이언트 시작 중..."
export VSOMEIP_APPLICATION_NAME="vehicle_client" 
"$BUILD_DIR/vsomeip_mock_test" client &
CLIENT_PID=$!
echo "🔧 클라이언트 PID: $CLIENT_PID"

# 클라이언트 연결 대기
echo "⏰ 클라이언트 연결 대기 중..."
sleep 3

echo "✅ vsomeip Mock 통신 테스트 준비 완료"
echo "🎯 현재 테스트되고 있는 기능들:"
echo "   - 기어 상태 (P/R/N/D 자동 순환)"
echo "   - 엔진 상태 (ON/OFF 자동 토글)"
echo "   - 속도 시뮬레이션 (엔진 상태에 따른 변화)"
echo "   - 배터리 레벨 (충전/방전 시뮬레이션)"
echo "   - 실시간 vsomeip 통신"

# 로그 확인 명령어들
echo ""
echo "🎮 실시간 로그 확인 명령어:"
echo "1. 서버 로그: tail -f /tmp/vsomeip.log (서버 측 로그)"
echo "2. 클라이언트 응답: 터미널에서 직접 확인 가능"
echo "3. 통신 상태: ps aux | grep vsomeip_mock_test"

# 프로세스 상태 확인
echo ""
echo "📊 프로세스 상태:"
if ps -p $SERVER_PID > /dev/null; then
    echo "✅ vsomeip Mock 서버가 성공적으로 실행 중입니다. (PID: $SERVER_PID)"
else
    echo "❌ vsomeip Mock 서버 실행에 문제가 있습니다."
fi

if ps -p $CLIENT_PID > /dev/null; then
    echo "✅ vsomeip Mock 클라이언트가 성공적으로 실행 중입니다. (PID: $CLIENT_PID)"
else
    echo "❌ vsomeip Mock 클라이언트 실행에 문제가 있습니다."
fi

echo ""
echo "🛑 테스트 종료: pkill -f vsomeip_mock_test"
echo "📈 실시간 모니터링: 터미널 출력을 확인하세요!"
