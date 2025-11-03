# 파일 명명 규칙 (File Naming Convention)

## 📋 개요

이 프로젝트는 **로컬 개발 환경**과 **실제 배포 환경**을 명확히 구분하기 위해 파일 명명 규칙을 사용합니다.

---

## 🏷️ 명명 규칙

### **`_local`** - 로컬 개발 환경용
- **대상**: 개발자의 PC에서 실행
- **네트워크**: `127.0.0.1` (localhost)
- **하드웨어**: Mock/시뮬레이션
- **목적**: 개발, 디버깅, 테스트

**예시 파일:**
```
CMakeLists_local.txt
vsomeip_local.json
commonapi_local.ini
build_local.sh
run_local.sh
```

### **`_deploy`** 또는 **`_ecu1`/`_ecu2`** - 배포 환경용
- **대상**: 실제 라즈베리파이 ECU
- **네트워크**: 실제 IP 주소 (예: `192.168.1.100`, `192.168.1.101`)
- **하드웨어**: 실제 PiRacer, 센서, 액추에이터
- **목적**: 프로덕션 배포, 실차 테스트

**예시 파일:**
```
CMakeLists_deploy.txt
vsomeip_ecu1.json      (ECU1용 - 192.168.1.100)
vsomeip_ecu2.json      (ECU2용 - 192.168.1.101)
commonapi_deploy.ini
build_deploy.sh
run_deploy.sh
```

---

## 📂 애플리케이션별 파일 구성

### **VehicleControlECU** (ECU1)

#### 로컬 개발용:
```
app/VehicleControlECU/
├── CMakeLists_local.txt          # Local 빌드 설정
├── build_local.sh                 # Local 빌드 스크립트
├── run_local.sh                   # Local 실행 스크립트
├── config/
│   ├── vsomeip_local.json        # vsomeip 로컬 설정 (127.0.0.1)
│   └── commonapi_local.ini       # CommonAPI 로컬 설정
└── src/
    └── main_mock.cpp              # Mock 하드웨어용 메인
```

#### 배포용:
```
app/VehicleControlECU/
├── CMakeLists_deploy.txt         # 배포 빌드 설정
├── build_deploy.sh                # 배포 빌드 스크립트
├── run_deploy.sh                  # 배포 실행 스크립트
├── config/
│   ├── vsomeip_ecu1.json         # vsomeip ECU1 설정 (192.168.1.100)
│   └── commonapi_deploy.ini      # CommonAPI 배포 설정
└── src/
    └── main.cpp                   # 실제 하드웨어용 메인
```

---

### **GearApp** (ECU2)

#### 로컬 개발용:
```
app/GearApp/
├── CMakeLists_local.txt          # Local 빌드 설정
├── build_local.sh                 # Local 빌드 스크립트
├── run_local.sh                   # Local 실행 스크립트
└── config/
    ├── vsomeip_local.json        # vsomeip 로컬 설정
    └── commonapi_local.ini       # CommonAPI 로컬 설정
```

#### 배포용:
```
app/GearApp/
├── CMakeLists_deploy.txt         # 배포 빌드 설정
├── build_deploy.sh                # 배포 빌드 스크립트
├── run_deploy.sh                  # 배포 실행 스크립트
└── config/
    ├── vsomeip_ecu2.json         # vsomeip ECU2 설정 (192.168.1.101)
    └── commonapi_deploy.ini      # CommonAPI 배포 설정
```

---

## 🚀 사용 방법

### 로컬 개발 시:
```bash
# VehicleControlECU 빌드 및 실행
cd app/VehicleControlECU
./build_local.sh
./run_local.sh

# 다른 터미널에서 GearApp 빌드 및 실행
cd app/GearApp
./build_local.sh
cd build_local
./GearApp_local
```

### 실제 배포 시:
```bash
# ECU1 (Raspberry Pi #1)
cd app/VehicleControlECU
./build_deploy.sh
./run_deploy.sh

# ECU2 (Raspberry Pi #2)
cd app/GearApp
./build_deploy.sh
./run_deploy.sh
```

---

## ⚙️ 환경별 주요 차이점

| 항목 | 로컬 개발 (_local) | 실제 배포 (_deploy) |
|------|------------------|-------------------|
| **IP 주소** | 127.0.0.1 | 192.168.1.100/101 |
| **통신 방식** | IPC (같은 PC) | 네트워크 (2개 라즈베리파이) |
| **하드웨어** | Mock/시뮬레이션 | 실제 센서/액추에이터 |
| **빌드 타겟** | build_local/ | build_deploy/ |
| **실행 파일** | *_local | *_deploy 또는 기본 이름 |

---

## 📝 주의사항

1. **절대 로컬용 설정을 배포 환경에 사용하지 마세요**
   - IP 주소가 다르면 통신 실패합니다.

2. **Git에 커밋 시 두 버전 모두 유지**
   - 다른 개발자도 로컬 개발을 할 수 있어야 합니다.

3. **새 앱 추가 시 동일한 규칙 적용**
   - 일관성 있는 프로젝트 구조 유지

---

## 🔄 파일 전환

배포용 파일은 나중에 작성하며, 현재는 **로컬 개발용 파일만 사용**합니다.

배포 준비가 되면:
1. `*_local.*` 파일을 복사하여 `*_deploy.*` 생성
2. IP 주소 및 하드웨어 관련 설정 수정
3. Yocto 레시피에서 적절한 버전 선택
