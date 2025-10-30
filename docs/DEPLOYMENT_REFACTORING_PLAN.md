# 배포 환경 전환 및 정리 계획

## 📋 전체 현황 분석

### ✅ 완료된 앱
1. **VehicleControlECU** - vsomeip Service Provider (ECU1)
2. **GearApp** - vsomeip Client (ECU2)

### 🔄 수정 필요한 앱
3. **AmbientApp** - 부분 vsomeip 구현 (MediaControl 구독 중, VehicleControl 구독 필요)
4. **MediaApp** - vsomeip Service (완료), 불필요한 코드 정리 필요
5. **HU_MainApp** - 로컬 통합 앱, Wayland compositor 역할 재정의 필요

### 🔄 수정 필요한 앱 (계속)
6. **IC_app** - Instrument Cluster (ECU2에 배포, 별도 디스플레이 장치에 표시)

---

## 1️⃣ AmbientApp 수정 계획

### 현재 상태
- ✅ **MediaControl 클라이언트**: vsomeip로 MediaApp 볼륨 이벤트 구독 중
- ❌ **GearPosition 처리**: 로컬 시그널/슬롯 방식 사용 중
- ❌ **UDP Socket**: IC 통신용 불필요한 코드 존재

### 수정 내용

#### A. VehicleControl 클라이언트 추가
**필요한 이유**: GearApp과 동일하게 VehicleControlECU의 기어 변경 이벤트를 vsomeip로 구독해야 함

**작업:**
1. `VehicleControlClient.h/cpp` 파일 생성 (GearApp 것 복사 후 수정)
2. `main.cpp`에서 VehicleControlClient 초기화
3. `VehicleControlClient::currentGearChanged` → `AmbientManager::onGearPositionChanged` 연결

**파일:**
- 생성: `src/VehicleControlClient.h`, `src/VehicleControlClient.cpp`
- 수정: `src/main.cpp`, `CMakeLists.txt`

#### B. 불필요한 코드 삭제

**삭제할 코드:**
1. **QUdpSocket 관련 코드** (IC 통신 제거)
   - `ambientmanager.h`: `#include <QUdpSocket>`, `QUdpSocket *m_socket;`
   - `ambientmanager.cpp`: UDP 소켓 초기화, `sendAmbientStateToIC()` 함수

2. **로컬 시그널 연결** (main.cpp)
   - `onGearPositionChanged` 테스트 코드는 유지 (vsomeip 이벤트로 호출됨)

**파일:**
- 수정: `src/ambientmanager.h`, `src/ambientmanager.cpp`, `src/main.cpp`

#### C. 배포 설정 파일 생성

**필요한 파일:**
- `config/vsomeip_ambient.json` - vsomeip 클라이언트 설정
- `config/commonapi_ambient.ini` - CommonAPI 설정
- `build.sh` - 빌드 스크립트
- `run.sh` - 실행 스크립트

---

## 2️⃣ MediaApp 수정 계획

### 현재 상태
- ✅ **MediaControl Service**: vsomeip로 볼륨 이벤트 브로드캐스트 중
- ⚠️ **테스트 코드**: 5초마다 자동 볼륨 변경 (삭제 필요)
- ⚠️ **로컬 환경**: 독립 실행 가능하지만 배포 환경에 맞게 정리 필요

### 수정 내용

#### A. 테스트 코드 삭제

**삭제할 코드 (main.cpp):**
```cpp
// Test Timer: Simulate volume changes every 5 seconds
QTimer *testTimer = new QTimer(&app);
QObject::connect(testTimer, &QTimer::timeout, [&mediaManager]() {
    static qreal testVolume = 0.8;
    testVolume = (testVolume >= 1.0) ? 0.0 : (testVolume + 0.2);
    // ...
});
testTimer->start(5000);
```

**파일:**
- 수정: `src/main.cpp` (100-109줄 삭제)

#### B. 배포 설정 파일 생성

**필요한 파일:**
- `config/vsomeip_media.json` - vsomeip 서비스 제공자 설정
- `config/commonapi_media.ini` - CommonAPI 설정
- `build.sh` - 빌드 스크립트
- `run.sh` - 실행 스크립트

---

## 3️⃣ HU_MainApp 수정 계획

### 현재 상태
- ❌ **로컬 통합 앱**: 모든 Manager를 직접 생성하여 한 프로세스에서 실행
- ❌ **vSOMEIP 통신**: MediaControl Service/Client 모두 포함 (불필요)
- ❌ **역할 혼란**: Wayland compositor 역할과 앱 통합 역할 혼재

### 배포 환경에서의 역할 재정의

#### 옵션 A: Wayland Compositor Only (추천)
**역할:**
- 각 독립 앱(GearApp, AmbientApp, MediaApp)을 Wayland 서버로 합성
- 앱 간 통신은 vsomeip로 처리 (HU_MainApp은 관여하지 않음)
- 단순히 화면 레이아웃만 관리

**장점:**
- 명확한 역할 분리
- 앱 독립성 유지
- 배포 환경과 일치

**수정 내용:**
1. Manager 클래스 모두 제거 (MediaManager, GearManager, AmbientManager)
2. vsomeip 통신 코드 모두 제거
3. Wayland compositor 기능만 유지
4. QML에서 각 앱의 Window를 합성하는 코드만 유지

#### 옵션 B: 제거 (고려 사항)
**이유:**
- 각 앱이 이미 독립적으로 실행 가능
- Wayland compositor는 시스템 레벨에서 제공 (Weston, Mutter 등)
- HU_MainApp의 역할이 불명확

**대안:**
- 시스템 Wayland compositor 사용 (Weston)
- 각 앱을 독립 프로세스로 실행
- 화면 레이아웃은 Wayland 설정 파일로 관리

### 권장 방향: 옵션 A (Wayland Compositor Only)

**수정할 파일:**
- `src/main.cpp` - Manager 인스턴스 생성 제거, vsomeip 코드 제거
- `qml/main.qml` - 각 앱 Window를 합성하는 코드만 유지
- `CMakeLists.txt` - Manager 의존성 제거

---

## 4️⃣ vsomeip로 대체해야 할 시그널/슬롯

### GearApp
- ✅ **이미 vsomeip로 구현됨**: VehicleControlClient ↔ VehicleControlECU
- ❌ **삭제 필요**: QUdpSocket (IpcManager) - IC 통신용

### AmbientApp
- ❌ **vsomeip로 대체 필요**: 
  - 현재: 로컬 `onGearPositionChanged()` 슬롯
  - 변경: VehicleControlClient의 `currentGearChanged` 이벤트 구독

### MediaApp
- ✅ **이미 vsomeip로 구현됨**: MediaControlStubImpl (볼륨 이벤트 브로드캐스트)
- ⚠️ **테스트 코드 삭제**: 자동 볼륨 변경 타이머

### HU_MainApp
- ❌ **모두 제거**: 
  - MediaControlStubImpl, MediaControlClient
  - Manager 간 시그널/슬롯 연결 모두 제거

---

## 5️⃣ 불필요한 파일/코드 삭제 계획

### GearApp
**삭제할 파일:**
- `src/ipcmanager.h` - IC 통신용, vsomeip로 대체됨
- `src/ipcmanager.cpp`

**삭제할 코드:**
- `src/gearmanager.h`: `#include <QUdpSocket>`, `QUdpSocket *m_socket;`
- `src/gearmanager.cpp`: UDP 소켓 초기화 및 사용 코드
- `src/main.cpp`: IpcManager 관련 코드

**수정할 파일:**
- `CMakeLists.txt` - ipcmanager 제거

### AmbientApp
**삭제할 코드:**
- `src/ambientmanager.h`: `#include <QUdpSocket>`, `QUdpSocket *m_socket;`
- `src/ambientmanager.cpp`: `sendAmbientStateToIC()` 함수 및 UDP 소켓 코드
- `src/main.cpp`: 테스트 타이머 (기어 변경 시뮬레이션)

### MediaApp
**삭제할 코드:**
- `src/main.cpp`: 볼륨 자동 변경 테스트 타이머 (100-109줄)

### HU_MainApp
**옵션 A (Compositor Only) 선택 시 삭제:**
- `src/MediaControlStubImpl.h/cpp`
- `src/MediaControlClient.h/cpp`
- Manager 인스턴스 생성 코드
- vsomeip 관련 모든 코드

**또는 옵션 B (전체 제거) 선택 시:**
- `app/HU_MainApp/` 전체 디렉토리

### IC_app
**현재 상태:**
- UDP Socket으로 GearApp/AmbientApp과 통신 중
- 별도 디스플레이 장치에 표시 (ECU2에 함께 배포)

**수정 내용:**
- UDP Socket 제거
- vsomeip Client로 전환 (VehicleControl 이벤트 구독)
- 배포 설정 파일 생성

---

## 📋 작업 순서

### Phase 1: 불필요한 코드 삭제 (안전한 작업부터)
1. **MediaApp 테스트 코드 삭제**
2. **GearApp IpcManager 삭제** (UDP → vsomeip 완료)
3. **AmbientApp UDP 코드 삭제** (IC 통신 제거)
4. **IC_app UDP 코드 삭제** (IC 통신 제거)

### Phase 2: vsomeip 통합
1. **AmbientApp**: VehicleControlClient 추가
2. **IC_app**: VehicleControlClient 추가
3. 각 앱 main.cpp, CMakeLists.txt 수정
4. 빌드 스크립트 작성
5. 설정 파일 작성

### Phase 3: 배포 설정 파일 생성
1. **MediaApp 배포 설정** (vsomeip_media.json, build.sh, run.sh)
2. **AmbientApp 배포 설정** (vsomeip_ambient.json, build.sh, run.sh)
3. **IC_app 배포 설정** (vsomeip_ic.json, build.sh, run.sh)

### Phase 4: HU_MainApp 재정의
1. **역할 결정** (Compositor Only vs 제거)
2. **불필요한 코드 제거**
3. **Wayland 합성 기능만 유지** (옵션 A 선택 시)

### Phase 5: 통합 테스트
1. **라즈베리파이 배포 테스트**
2. **ECU 간 통신 검증**

---

## 🎯 최종 ECU 배포 구조

### ECU1 (VehicleControlECU) @ 192.168.1.100
- **역할**: Service Provider, Routing Manager
- **앱**: VehicleControlECU
- **하드웨어**: PiRacer
- **서비스**: VehicleControl (RPC: changeGear, Events: gearChanged, vehicleStateChanged)

### ECU2 (HU - Head Unit) @ 192.168.1.101
- **역할**: Service Consumers, GUI
- **앱**: 
  - **HU 디스플레이:**
    - GearApp (VehicleControl 클라이언트)
    - AmbientApp (VehicleControl + MediaControl 클라이언트)
    - MediaApp (MediaControl 서비스)
    - (옵션) HU_MainApp (Wayland Compositor)
  - **IC 디스플레이 (별도 화면):**
    - IC_app (VehicleControl 클라이언트)
- **통신**:
  - GearApp → VehicleControlECU (RPC: 기어 변경 요청)
  - VehicleControlECU → GearApp (Event: 기어 상태 변경)
  - VehicleControlECU → AmbientApp (Event: 기어 상태 변경, 색상 동기화)
  - VehicleControlECU → IC_app (Event: 차량 상태 표시)
  - MediaApp → AmbientApp (Event: 볼륨 변경, 밝기 동기화)

### 통신 다이어그램
```
ECU1 (192.168.1.100)                ECU2 (192.168.1.101)
┌─────────────────────┐             ┌──────────────────────────────────┐
│ VehicleControlECU   │             │ HU Display                       │
│ (Routing Manager)   │◄────RPC─────│ - GearApp (VehicleCtrl Client)   │
│                     │─────Event───►│ - AmbientApp (VehicleCtrl Client)│
│                     │             │ - MediaApp (MediaCtrl Service)   │
│                     │             │ - HU_MainApp (Wayland Compositor)│
│                     │             └──────────────────────────────────┘
│                     │             
│                     │             ┌──────────────────────────────────┐
│                     │─────Event───►│ IC Display (별도 화면)            │
│                     │             │ - IC_app (VehicleCtrl Client)    │
└─────────────────────┘             └──────────────────────────────────┘
                                    
                    MediaApp ────Event────► AmbientApp
                             (볼륨 → 밝기)
```

---

## ⚠️ 주의사항

1. **백업**: 수정 전 현재 상태 커밋
2. **단계별 검증**: 각 Phase마다 빌드 및 기본 테스트 수행
3. **vsomeip 설정**: 각 앱의 application name이 고유해야 함
4. **IP 주소**: 배포 환경에 맞게 vsomeip 설정 파일 수정

---

## 📝 다음 단계 선택

작업을 시작하려면 다음 중 선택해주세요:

### A. 단계별 진행 (안전)
1. **Phase 1부터 시작**: 불필요한 코드 삭제
2. 각 단계마다 확인 후 다음 단계 진행

### B. 전체 자동화 (빠름)
- 모든 수정 사항을 한 번에 적용
- 위험: 한 번에 많은 변경, 디버깅 어려움

### C. HU_MainApp 역할 결정 후 진행
- 옵션 A (Compositor Only) vs 옵션 B (제거)
- 결정 후 나머지 작업 진행

**어떤 방식으로 진행하시겠습니까?**
