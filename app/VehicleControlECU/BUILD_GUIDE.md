# VehicleControlECU - 빌드 가이드

## 🎯 개발 단계

### Phase A: 하드웨어 제어 (현재)
**목적**: PiRacer 하드웨어 제어 동작 확인
- ✅ 모터/스티어링 제어
- ✅ 배터리 모니터링
- ✅ 게임패드 입력
- ❌ vsomeip 통신 없음

### Phase B: vsomeip 통신 (향후)
**목적**: 다른 앱과 통신
- ✅ Phase A 기능 유지
- ✅ vsomeip 서비스 추가
- ✅ 이벤트 브로드캐스트

---

## 📦 라즈베리파이 준비사항

### 1. 하드웨어
- Raspberry Pi 4
- PiRacer AI Kit
- I2C 장치:
  - PCA9685 (0x40) - Steering
  - PCA9685 (0x60) - Throttle
  - INA219 (0x41) - Battery
- ShanWan Gamepad (선택사항)

### 2. 소프트웨어 설치

```bash
# 기본 패키지
sudo apt update
sudo apt install -y \
    qtbase5-dev \
    libpigpio-dev \
    cmake \
    build-essential \
    i2c-tools

# I2C 활성화
sudo raspi-config
# Interface Options → I2C → Enable
sudo reboot
```

---

## 🚀 Phase A: Standalone 빌드 (vsomeip 없이)

### 빠른 시작

```bash
# 라즈베리파이에서

# 1. 프로젝트 폴더만 복사 (전체 프로젝트 불필요)
scp -r VehicleControlECU pi@raspberrypi.local:~/

# 또는 Git에서 해당 폴더만 클론
cd ~
git clone <repo>
cd DES_Head-Unit/app/VehicleControlECU

# 2. Standalone 빌드
./build_standalone.sh

# 3. 실행
sudo ./run_standalone.sh
```

### 상세 설명

#### 빌드
```bash
cd ~/VehicleControlECU

# Standalone 모드 빌드
./build_standalone.sh

# 빌드 결과:
#   build_standalone/VehicleControlECU_Standalone
```

#### 실행
```bash
# sudo 필수! (GPIO 접근)
sudo ./run_standalone.sh

# 예상 출력:
# ═══════════════════════════════════════════════════════
# VehicleControlECU - Standalone Mode
# Hardware Control Only (No vsomeip)
# ═══════════════════════════════════════════════════════
# 
# ✅ GPIO library initialized
# ✅ PiRacerController initialized
# ✅ Gamepad controls active
# ✅ VehicleControlECU is running!
```

#### 테스트
```bash
# 게임패드로 제어:
# - A 버튼: Drive
# - B 버튼: Park
# - X 버튼: Neutral
# - Y 버튼: Reverse
# - 왼쪽 스틱: 스티어링
# - 오른쪽 스틱 Y: 스로틀

# 콘솔에서 상태 확인:
# 📊 [Status] Gear: D | Speed: 25 km/h | Battery: 87 %
```

---

## 🌐 Phase B: vsomeip 빌드 (통신 포함)

**나중에 사용할 명령어 (지금은 실행 안함)**

### 추가 설치 필요
```bash
# CommonAPI 라이브러리 설치
cd ~/DES_Head-Unit
./install_commonapi_rpi.sh
```

### vsomeip 버전 빌드
```bash
cd ~/DES_Head-Unit/app/VehicleControlECU

# 일반 빌드 (vsomeip 포함)
./build.sh

# 실행
sudo ./run.sh
```

---

## 🛠️ 문제 해결

### GPIO 초기화 실패
```
Error: Failed to initialize pigpio!
Solution: sudo로 실행 → sudo ./run_standalone.sh
```

### I2C 장치 없음
```bash
# I2C 활성화 확인
sudo raspi-config
# Interface Options → I2C → Enable

# I2C 장치 스캔
i2cdetect -y 1
# 0x40, 0x41, 0x60이 보여야 함
```

### Gamepad 인식 안됨
```bash
# 장치 확인
ls /dev/input/js*

# 권한 부여
sudo chmod 666 /dev/input/js0

# 앱은 Gamepad 없이도 동작 가능
```

### 빌드 에러
```bash
# Qt5 없음
sudo apt install qtbase5-dev

# pigpio 없음
sudo apt install libpigpio-dev

# CMake 버전 낮음
cmake --version  # 3.16 이상 필요
```

---

## 📂 파일 구조

```
VehicleControlECU/
├── CMakeLists_standalone.txt    # Standalone 빌드 설정
├── CMakeLists.txt               # vsomeip 빌드 설정 (Phase B)
├── build_standalone.sh          # Standalone 빌드 스크립트
├── run_standalone.sh            # Standalone 실행 스크립트
├── build.sh                     # vsomeip 빌드 스크립트 (Phase B)
├── run.sh                       # vsomeip 실행 스크립트 (Phase B)
├── src/
│   ├── main_standalone.cpp      # Standalone 메인 (vsomeip 없음)
│   ├── main.cpp                 # vsomeip 메인 (Phase B)
│   ├── BatteryMonitor.*         # 배터리 모니터링
│   ├── GamepadHandler.*         # 게임패드 입력
│   ├── PiRacerController.*      # 차량 제어
│   └── VehicleControlStubImpl.* # vsomeip 서비스 (Phase B)
├── lib/                         # 하드웨어 라이브러리
│   ├── Adafruit_INA219.*
│   ├── Adafruit_PCA9685.*
│   └── ShanwanGamepad.*
└── config/                      # vsomeip 설정 (Phase B)
    ├── vsomeip_ecu1.json
    └── commonapi4someip_ecu1.ini
```

---

## ✅ 체크리스트

### Phase A (현재)
- [ ] 라즈베리파이에 Qt5, pigpio 설치
- [ ] I2C 활성화
- [ ] I2C 장치 연결 확인 (i2cdetect -y 1)
- [ ] VehicleControlECU 폴더 복사
- [ ] `./build_standalone.sh` 실행
- [ ] `sudo ./run_standalone.sh` 실행
- [ ] 게임패드로 제어 테스트
- [ ] 모터 동작 확인

### Phase B (향후)
- [ ] CommonAPI 설치 (`./install_commonapi_rpi.sh`)
- [ ] `./build.sh` 실행
- [ ] vsomeip 설정 파일 작성
- [ ] 다른 앱과 통신 테스트

---

## 📝 참고사항

- **Standalone 모드**: vsomeip 없이 하드웨어만 제어 (현재)
- **vsomeip 모드**: 통신 기능 포함 (Phase B)
- **빌드 시간**: Standalone ~2분, vsomeip ~30분 (CommonAPI 설치 포함)
- **실행 권한**: 항상 sudo 필요 (GPIO 접근)

---

## 다음 단계

1. ✅ **Standalone 빌드 및 테스트** ← 지금 여기
2. ⏭️ MediaApp 통합
3. ⏭️ GearApp, AmbientApp, IC_app 개발
4. ⏭️ vsomeip 통신 연결
5. ⏭️ Yocto 빌드
