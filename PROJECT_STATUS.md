# 프로젝트 상태 요약

## ✅ 완료된 작업 (2025-10-29)

### 1. 프로젝트 정리
- ❌ 삭제: 모든 `_local`, `_mock` 관련 파일
- ❌ 삭제: 빌드 디렉토리 (`build_local/`, `build_mock/`, `build_vsomeip/`)
- ❌ 삭제: 불필요한 가이드 문서 (BUILD_GUIDE.md, INSTALL_COMMONAPI.md 등)
- ✅ 유지: HelloWorld 예제, 실제 소스 코드, FIDL 정의

### 2. 배포 환경 설정 파일 생성

#### VehicleControlECU (ECU1 - Service Provider)
```
app/VehicleControlECU/
├── config/
│   ├── vsomeip_ecu1.json          # 192.168.1.100, routing manager
│   ├── commonapi_ecu1.ini         # CommonAPI 설정
│   ├── vsomeip_service.json       # 기존 설정 (참고용)
│   └── commonapi4someip.ini       # 기존 설정 (참고용)
├── src/
│   ├── main.cpp                   # 실제 PiRacer 제어 (진짜 구동용)
│   ├── VehicleControlStubImpl.cpp # 서비스 구현
│   ├── PiRacerController.cpp      # 하드웨어 제어
│   ├── GamepadHandler.cpp         # 게임패드 입력
│   └── BatteryMonitor.cpp         # 배터리 모니터링
├── CMakeLists.txt                 # 빌드 설정
├── build.sh                       # 배포용 빌드 스크립트
├── run.sh                         # 배포용 실행 스크립트
└── README.md                      # 프로젝트 설명
```

#### GearApp (ECU2 - Service Consumer)
```
app/GearApp/
├── config/
│   ├── vsomeip_ecu2.json          # 192.168.1.101, client
│   └── commonapi_ecu2.ini         # CommonAPI 설정
├── src/
│   ├── main.cpp                   # GUI 앱 메인
│   ├── VehicleControlClient.cpp   # vsomeip 클라이언트
│   ├── gearmanager.cpp            # Gear 관리 (UI 로직)
│   └── ipcmanager.cpp             # IC 통신
├── qml/
│   ├── main.qml                   # 메인 UI
│   └── GearSelectionWidget.qml    # Gear 선택 UI
├── CMakeLists.txt                 # 빌드 설정
├── build.sh                       # 배포용 빌드 스크립트
└── run.sh                         # 배포용 실행 스크립트
```

### 3. 문서 작성
- ✅ `DEPLOYMENT_GUIDE.md`: 라즈베리파이 배포 가이드 (네트워크 설정, 빌드, 실행, 트러블슈팅)
- ✅ `PROJECT_STATUS.md`: 프로젝트 현황 요약 (이 파일)

---

## 🎯 다음 작업 계획

### 내일 (실제 하드웨어 테스트)
1. **라즈베리파이 네트워크 설정**
   - ECU1: 192.168.1.100
   - ECU2: 192.168.1.101
   - 이더넷 케이블로 직접 연결 또는 스위치 사용

2. **VehicleControlECU 테스트 (ECU1)**
   - PiRacer 하드웨어 연결
   - `./build.sh` 실행
   - `./run.sh` 실행
   - 서비스 등록 확인

3. **GearApp 테스트 (ECU2)**
   - `./build.sh` 실행
   - `./run.sh` 실행
   - VehicleControlECU 서비스 연결 확인
   - Gear 변경 RPC 테스트
   - Event 수신 테스트

### 이후 단계
4. **Yocto 이미지 빌드**
   - meta-headunit 레이어 설정
   - vsomeip, CommonAPI 레시피 추가
   - headunit-image 빌드

5. **배포 및 통합 테스트**
   - SD 카드에 이미지 플래시
   - 두 ECU에서 부팅 테스트
   - 전체 시스템 통합 테스트

---

## 📋 ECU 아키텍처

### ECU1 (Raspberry Pi #1) - VehicleControlECU
- **IP**: 192.168.1.100
- **역할**: Service Provider (vsomeip routing manager)
- **서비스**: VehicleControl (0x1234:0x5678)
- **기능**:
  - PiRacer 하드웨어 제어 (모터, 서보)
  - 게임패드 입력 처리
  - 배터리 상태 모니터링
  - RPC: `setGearPosition(gear)`
  - Event: `vehicleStateChanged(gear, speed, battery)`
  - Event: `gearChanged(newGear, oldGear)`

### ECU2 (Raspberry Pi #2) - Head-Unit
- **IP**: 192.168.1.101
- **역할**: Service Consumer
- **앱**:
  - **GearApp**: Gear 선택 UI, VehicleControl 클라이언트
  - **AmbientApp**: Ambient 조명 제어 (계획)
  - **MediaApp**: 미디어 재생 (계획)
  - **IC_app**: Instrument Cluster 통신 (계획)

---

## 🔧 vsomeip 설정 요약

### Service Discovery
- **Multicast**: 224.224.224.245:30490
- **Protocol**: UDP
- **TTL**: 3 hops

### VehicleControl Service
- **Service ID**: 0x1234
- **Instance ID**: 0x5678
- **Unreliable Port**: 30501 (UDP)
- **Reliable Port**: 30502 (TCP)

### Applications
- **VehicleControlECU**: 0x1001 (ECU1)
- **GearApp**: 0x2001 (ECU2)

---

## 📚 핵심 파일 위치

### FIDL 정의
```
commonapi/fidl/
├── VehicleControl.fidl         # 인터페이스 정의
└── VehicleControl.fdepl        # vsomeip 배포 설정
```

### 생성된 CommonAPI 코드
```
commonapi/generated/
├── core/
│   └── v1/vehiclecontrol/
│       ├── VehicleControl.hpp
│       ├── VehicleControlProxy.hpp
│       └── VehicleControlStubDefault.hpp
└── someip/
    └── v1/vehiclecontrol/
        ├── VehicleControlSomeIPProxy.cpp
        ├── VehicleControlSomeIPStubAdapter.cpp
        └── VehicleControlSomeIPDeployment.cpp
```

### 설치된 라이브러리
```
install_folder/
├── lib/
│   ├── libCommonAPI.so.3.2.4
│   ├── libCommonAPI-SomeIP.so.3.2.4
│   └── libvsomeip3.so.3.5.8
└── include/
    ├── CommonAPI/
    ├── CommonAPI/SomeIP/
    └── vsomeip/
```

---

## ⚠️ 주의사항

### 실행 순서
1. **반드시 ECU1 (VehicleControlECU) 먼저 실행**
   - vsomeip routing manager 역할
   - Service Discovery 활성화

2. **그 다음 ECU2 (GearApp 등) 실행**
   - ECU1의 서비스를 찾아 연결

### 네트워크 요구사항
- 이더넷 연결 필수
- 고정 IP 설정 필요
- 멀티캐스트 지원 확인

### 디버깅
- vsomeip 로그: `/var/log/vsomeip_ecu*.log`
- CommonAPI 로그: `/var/log/commonapi_ecu*.log`
- tcpdump로 패킷 캡처 가능

---

## 🎓 학습 내용

### vsomeip 통신
- Service Discovery 메커니즘
- Routing Manager vs Proxy 개념
- Reliable (TCP) vs Unreliable (UDP) 통신

### CommonAPI
- Proxy-Stub 패턴
- FIDL 인터페이스 정의
- 비동기 RPC 호출
- Event subscription

### Qt/QML
- Q_PROPERTY를 통한 QML 바인딩
- Signal/Slot 메커니즘
- Context Property 노출

---

## 📞 다음 작업 시 참고

### 추가 앱 구현 시
1. FIDL 정의 (필요시)
2. vsomeip 설정 파일 생성 (`config/vsomeip_*.json`)
3. CommonAPI 설정 (`config/commonapi_*.ini`)
4. 빌드 스크립트 (`build.sh`)
5. 실행 스크립트 (`run.sh`)

### Yocto 레시피 작성 시
- `meta/meta-headunit/recipes-headunit/` 참고
- vsomeip, CommonAPI 의존성 추가
- systemd 서비스 파일 포함

---

**마지막 업데이트**: 2025-10-29
**다음 테스트**: 실제 라즈베리파이 환경에서 vsomeip 통신 검증
