# VehicleControlECU 배포 가이드

## 라즈베리파이 준비사항

### 1. 하드웨어 체크리스트
- [ ] Raspberry Pi 4 전원 연결
- [ ] PiRacer 하드웨어 조립 완료
- [ ] I2C 장치 연결 확인:
  - PCA9685 (0x40) - Steering Controller
  - PCA9685 (0x60) - Throttle Controller  
  - INA219 (0x41) - Battery Monitor
- [ ] ShanWan USB Gamepad 연결 (선택사항)
- [ ] 네트워크 연결 (SSH 접속용)

### 2. 소프트웨어 설치

```bash
# SSH로 라즈베리파이 접속
ssh pi@raspberrypi.local
# 또는
ssh pi@<라즈베리파이_IP>

# 시스템 업데이트
sudo apt update
sudo apt upgrade -y

# 필수 패키지 설치
sudo apt install -y \
    qtbase5-dev \
    libpigpio-dev \
    cmake \
    build-essential \
    git \
    i2c-tools

# I2C 활성화 확인
sudo raspi-config
# Interface Options → I2C → Enable 선택
# 재부팅 필요시: sudo reboot
```

### 3. I2C 장치 확인

```bash
# I2C 장치 스캔
i2cdetect -y 1

# 예상 출력:
#      0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f
# 00:          -- -- -- -- -- -- -- -- -- -- -- -- -- 
# 10: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
# 20: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
# 30: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
# 40: 40 41 -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
# 50: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
# 60: 60 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
# 70: -- -- -- -- -- -- -- --

# 보여야 할 주소:
# 0x40 - PCA9685 Steering
# 0x41 - INA219 Battery  
# 0x60 - PCA9685 Throttle
```

### 4. Gamepad 확인 (선택사항)

```bash
# Gamepad 장치 확인
ls /dev/input/js*

# 예상 출력:
# /dev/input/js0

# Gamepad 테스트
jstest /dev/input/js0
```

### 5. pigpio 데몬 시작

```bash
# pigpio 데몬 시작 (선택사항, 앱이 직접 초기화 가능)
sudo pigpiod

# 부팅 시 자동 시작 설정 (선택사항)
sudo systemctl enable pigpiod
sudo systemctl start pigpiod
```

## 프로젝트 배포

### Option A: Git Clone (권장)

```bash
# 작업 디렉토리로 이동
cd ~
mkdir -p workspace
cd workspace

# 프로젝트 클론
git clone https://github.com/Changseok-Oh29/DES_Head-Unit.git
cd DES_Head-Unit

# CommonAPI 의존성이 필요한 경우
cd deps
# CommonAPI 라이브러리 빌드 (이미 설치되어 있다면 생략)
```

### Option B: SCP로 파일 전송

```bash
# Host PC에서 실행
scp -r /home/leo/SEA-ME/DES_Head-Unit/app/VehicleControlECU pi@raspberrypi.local:~/

# 라즈베리파이에서
cd ~/VehicleControlECU
```

## 빌드

```bash
cd ~/workspace/DES_Head-Unit/app/VehicleControlECU

# 빌드 스크립트 실행 권한 부여
chmod +x build.sh run.sh

# 빌드 실행
./build.sh

# 빌드 성공 시 출력:
# ✅ Build successful!
# Executable: build/VehicleControlECU
```

### 빌드 문제 해결

#### CMake 에러: CommonAPI not found
```bash
# CommonAPI 라이브러리가 없는 경우
cd ~/workspace/DES_Head-Unit/deps

# capicxx-core-runtime 빌드
cd capicxx-core-runtime
mkdir build && cd build
cmake ..
make -j4
sudo make install

# capicxx-someip-runtime 빌드
cd ../../capicxx-someip-runtime
mkdir build && cd build
cmake ..
make -j4
sudo make install

# vsomeip 빌드
cd ../../vsomeip
mkdir build && cd build
cmake ..
make -j4
sudo make install

# 라이브러리 경로 업데이트
sudo ldconfig
```

#### CMake 에러: Generated code not found
```bash
# CommonAPI 코드 생성 (Host PC 또는 라즈베리파이에서)
cd ~/workspace/DES_Head-Unit/commonapi
./generate_code.sh

# 생성된 파일 확인
ls -la generated/core/v1/vehiclecontrol/
ls -la generated/someip/v1/vehiclecontrol/
```

## 실행

```bash
cd ~/workspace/DES_Head-Unit/app/VehicleControlECU

# 실행 (sudo 필수!)
sudo ./run.sh

# 예상 출력:
# ═══════════════════════════════════════════════════════
# VehicleControlECU (ECU1) Starting...
# ═══════════════════════════════════════════════════════
# 
# 🔧 Initializing GPIO library...
# ✅ GPIO library initialized
# 
# 🚗 Initializing PiRacer hardware...
# ✅ PiRacerController initialized
# 
# 🎮 Initializing gamepad...
# ✅ Gamepad connected: /dev/input/js0
# 
# 🌐 Initializing vsomeip service...
# ✅ VehicleControl service registered
# 
# ✅ VehicleControlECU is running!
```

## 테스트

### 1. Gamepad 테스트
```bash
# 앱 실행 후 게임패드 조작
# A 버튼 → Gear: D
# B 버튼 → Gear: P
# X 버튼 → Gear: N
# Y 버튼 → Gear: R

# 콘솔 로그에서 확인:
# 🎮 Gear change requested: D
# ⚙️  Gear changed: P → D
# 📡 [Event] Broadcasting gearChanged: P → D
```

### 2. vsomeip 통신 테스트
```bash
# 다른 터미널에서 GearApp 또는 IC_app 실행
# VehicleControl 서비스를 구독하여 이벤트 수신 확인
```

### 3. 모터 동작 테스트
```bash
# 게임패드 오른쪽 스틱 Y축으로 Throttle 조작
# 실제로 PiRacer 바퀴가 회전하는지 확인

# ⚠️ 주의: 차량이 바닥에서 들려있는지 확인!
```

## 종료

```bash
# Ctrl+C로 정상 종료
# 또는
sudo killall VehicleControlECU
```

## 로그 확인

```bash
# 실시간 로그 보기
sudo ./run.sh | tee vehicle_ecu.log

# vsomeip 로그 (설정 파일에서 활성화 시)
tail -f /tmp/vsomeip.log
```

## 자동 시작 설정 (선택사항)

```bash
# systemd 서비스 파일 생성
sudo nano /etc/systemd/system/vehicle-ecu.service

# 내용:
[Unit]
Description=VehicleControlECU Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/home/pi/workspace/DES_Head-Unit/app/VehicleControlECU
Environment="VSOMEIP_CONFIGURATION=/home/pi/workspace/DES_Head-Unit/app/VehicleControlECU/config/vsomeip_ecu1.json"
Environment="COMMONAPI_CONFIG=/home/pi/workspace/DES_Head-Unit/app/VehicleControlECU/config/commonapi4someip_ecu1.ini"
ExecStart=/home/pi/workspace/DES_Head-Unit/app/VehicleControlECU/build/VehicleControlECU
Restart=always

[Install]
WantedBy=multi-user.target

# 서비스 활성화
sudo systemctl daemon-reload
sudo systemctl enable vehicle-ecu.service
sudo systemctl start vehicle-ecu.service

# 상태 확인
sudo systemctl status vehicle-ecu.service
```

## 문제 해결

### GPIO 초기화 실패
```
Error: Failed to initialize pigpio!
Solution: sudo로 실행: sudo ./run.sh
```

### I2C 장치 없음
```
Error: Failed to open I2C bus for PCA9685/INA219
Solution:
1. i2cdetect -y 1로 장치 확인
2. 배선 확인
3. I2C 활성화: sudo raspi-config
```

### vsomeip 서비스 등록 실패
```
Error: Failed to register VehicleControl service
Solution:
1. 포트 충돌 확인: sudo netstat -tuln | grep 30509
2. 다른 인스턴스 종료: sudo killall VehicleControlECU
3. 설정 파일 확인: config/vsomeip_ecu1.json
```

### Gamepad 인식 안됨
```
Warning: Gamepad not found
Solution:
1. USB 재연결
2. ls /dev/input/js* 확인
3. 권한 확인: sudo chmod 666 /dev/input/js0
```
