# DES Head Unit Project - Clean Structure

## 📁 Project Structure

```
DES_Head-Unit/
├── README.md                    # 이 파일
├── DEVELOPMENT_SUMMARY.md       # 개발 요약
├── COMMONAPI_PLAN.md           # CommonAPI 계획
├── test_headunit.sh            # 전체 시스템 테스트
│
├── app/                        # 메인 애플리케이션들
│   ├── Design/                 # Qt Designer 프로젝트
│   ├── HU_app/                 # Head Unit 애플리케이션 (Qt5/QML)
│   ├── IC_app/                 # Instrument Cluster 애플리케이션
│   └── src/                    # 추가 소스 코드들
│
├── meta/                       # Yocto 관련 메타 레이어
│   └── meta-headunit/          # 커스텀 Yocto 레이어
│
├── mock_test_vsomeip/          # 🆕 vsomeip Mock 통신 테스트
│   ├── vsomeip_mock_test.cpp   # Mock 서버/클라이언트 구현
│   ├── CMakeLists.txt          # 빌드 설정
│   ├── vsomeip-config.json     # vsomeip 설정
│   ├── test_mock_communication.sh  # 테스트 스크립트
│   └── build/                  # 빌드 결과물
│
├── commonapi/                  # CommonAPI 관련
│   ├── PHASE1_COMPLETE_GUIDE.md  # 환경 구축 가이드
│   ├── PHASE2_PLAN.md            # 다음 단계 계획
│   ├── fidl/                     # FIDL 인터페이스 정의
│   │   ├── VehicleControl.fidl
│   │   ├── MediaControl.fidl
│   │   └── AmbientLight.fidl
│   └── vehiclecontrol/          # 생성된 CommonAPI 코드
│       ├── generate_code.sh     # 코드 생성 스크립트
│       └── generated/           # 자동 생성된 C++ 코드들
│
└── deps/                       # 외부 의존성 라이브러리들
    ├── capicxx-core-runtime/   # CommonAPI Core 런타임
    ├── capicxx-someip-runtime/ # CommonAPI SomeIP 바인딩
    ├── vsomeip/                # SOME/IP 통신 라이브러리
    └── commonapi-generators/   # 코드 생성 도구들
```

## 🎯 Current Status

### ✅ Working Features
- **vsomeip Mock Communication**: 실시간 서버/클라이언트 통신 테스트
- **Qt5 Head Unit UI**: 기본 인포테인먼트 인터페이스
- **CommonAPI Environment**: FIDL 기반 코드 생성 환경

### 🚀 Quick Start

#### 1. vsomeip Mock 테스트 실행
```bash
cd mock_test_vsomeip
./test_mock_communication.sh
```

#### 2. Head Unit 앱 실행
```bash
cd app/HU_app/build
./HU_app
```

#### 3. CommonAPI 코드 생성
```bash
cd commonapi/vehiclecontrol
./generate_code.sh
```

## 📚 Documentation

- `commonapi/PHASE1_COMPLETE_GUIDE.md`: CommonAPI + vsomeip 환경 구축 완전 가이드
- `commonapi/PHASE2_PLAN.md`: 다음 개발 단계 계획
- `DEVELOPMENT_SUMMARY.md`: 전체 개발 과정 요약

## 🔧 Development Environment

### Required Tools
- Ubuntu 22.04 LTS
- Qt 5.15+
- CMake 3.15+
- CommonAPI 3.2.4
- vsomeip 3.5.8

### Build Dependencies
```bash
sudo apt install qt5-default cmake build-essential libboost-all-dev
```

## 🎮 Testing

### Mock Communication Test
- **Location**: `mock_test_vsomeip/`
- **Purpose**: vsomeip 기반 실시간 ECU 간 통신 시뮬레이션
- **Features**: 기어/배터리/속도 데이터 실시간 교환

### Integration Test
- **Script**: `test_headunit.sh`
- **Purpose**: 전체 시스템 통합 테스트

---

**Note**: 이 구조는 불필요한 중복 파일들을 제거하고 핵심 기능들만 남긴 정리된 버전입니다.
