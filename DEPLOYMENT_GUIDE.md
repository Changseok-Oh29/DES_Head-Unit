# Raspberry Pi 배포 가이드

## 📋 시스템 아키텍처

### ECU 구성
- **ECU1 (Raspberry Pi #1)**: VehicleControlECU (PiRacer 제어)
  - IP: `192.168.1.100`
  - 역할: Service Provider (vsomeip routing manager)
  - 서비스: VehicleControl (0x1234:0x5678)

- **ECU2 (Raspberry Pi #2)**: Head-Unit Applications
  - IP: `192.168.1.101`
  - 역할: Service Consumer
  - 앱: GearApp, AmbientApp, MediaApp, IC_app

### 네트워크 설정
- 이더넷 직접 연결 또는 공유 스위치 사용
- 서브넷: 192.168.1.0/24
- vsomeip 멀티캐스트: 224.224.224.245:30490

---

## 🚀 배포 순서

### 1단계: 라즈베리파이 네트워크 설정

#### ECU1 (192.168.1.100)
```bash
# /etc/network/interfaces 또는 /etc/dhcpcd.conf 편집
sudo nano /etc/dhcpcd.conf

# 다음 추가:
interface eth0
static ip_address=192.168.1.100/24
static routers=192.168.1.1
```

#### ECU2 (192.168.1.101)
```bash
sudo nano /etc/dhcpcd.conf

# 다음 추가:
interface eth0
static ip_address=192.168.1.101/24
static routers=192.168.1.1
```

재부팅:
```bash
sudo reboot
```

네트워크 확인:
```bash
ip addr show eth0
ping 192.168.1.100  # ECU2에서 ECU1로
ping 192.168.1.101  # ECU1에서 ECU2로
```

---

### 2단계: 의존성 설치

두 ECU 모두에서 실행:

```bash
# Qt5 설치
sudo apt-get update
sudo apt-get install -y \
    qt5-default \
    qtbase5-dev \
    qtdeclarative5-dev \
    qtmultimedia5-dev \
    qtquickcontrols2-5-dev

# 빌드 도구
sudo apt-get install -y \
    build-essential \
    cmake \
    git

# vsomeip 및 CommonAPI 라이브러리는 이미 /usr/local/lib에 설치되어 있어야 함
# (프로젝트의 install_folder에서 복사)
```

---

### 3단계: 프로젝트 파일 전송

개발 PC에서 각 ECU로 전송:

#### ECU1으로 전송
```bash
# 개발 PC에서
cd /home/leo/SEA-ME/DES_Head-Unit
rsync -avz --exclude='build*' --exclude='.git' \
    app/VehicleControlECU/ \
    commonapi/ \
    install_folder/ \
    pi@192.168.1.100:~/DES_Head-Unit/
```

#### ECU2로 전송
```bash
# 개발 PC에서
rsync -avz --exclude='build*' --exclude='.git' \
    app/GearApp/ \
    commonapi/ \
    install_folder/ \
    pi@192.168.1.101:~/DES_Head-Unit/
```

---

### 4단계: 라이브러리 설치

두 ECU 모두에서:

```bash
cd ~/DES_Head-Unit/install_folder

# 라이브러리 복사
sudo cp -r lib/* /usr/local/lib/
sudo cp -r include/* /usr/local/include/

# 라이브러리 캐시 업데이트
sudo ldconfig

# 확인
ldconfig -p | grep vsomeip
ldconfig -p | grep CommonAPI
```

---

### 5단계: 빌드

#### ECU1 (VehicleControlECU)
```bash
cd ~/DES_Head-Unit/app/VehicleControlECU
./build.sh
```

#### ECU2 (GearApp)
```bash
cd ~/DES_Head-Unit/app/GearApp
./build.sh
```

---

### 6단계: 실행

#### 실행 순서 (중요!)

**1. ECU1 먼저 실행 (VehicleControlECU)**
```bash
# ECU1 (192.168.1.100)에서
cd ~/DES_Head-Unit/app/VehicleControlECU
./run.sh
```

출력 확인:
```
✅ VehicleControl service registered
📡 Broadcasting vehicle state at 10Hz...
Instantiating routing manager [Host]
```

**2. ECU2에서 GearApp 실행**
```bash
# ECU2 (192.168.1.101)에서
cd ~/DES_Head-Unit/app/GearApp
./run.sh
```

출력 확인:
```
✅ Connected to VehicleControl service
📡 Subscribing to VehicleControl events...
```

---

## 🔍 트러블슈팅

### 연결 안 됨
```bash
# ECU1에서 vsomeip 로그 확인
tail -f /var/log/vsomeip_ecu1.log

# ECU2에서 vsomeip 로그 확인
tail -f /var/log/vsomeip_ecu2.log

# 네트워크 트래픽 확인
sudo tcpdump -i eth0 port 30490 or port 30501 or port 30502
```

### 방화벽 확인
```bash
# 두 ECU 모두에서
sudo iptables -L

# 필요시 vsomeip 포트 열기
sudo iptables -A INPUT -p udp --dport 30490 -j ACCEPT  # Service Discovery
sudo iptables -A INPUT -p udp --dport 30501 -j ACCEPT  # Unreliable
sudo iptables -A INPUT -p tcp --dport 30502 -j ACCEPT  # Reliable
```

### 멀티캐스트 라우팅
```bash
# 멀티캐스트 지원 확인
ip maddress show eth0

# 멀티캐스트 라우트 추가
sudo route add -net 224.0.0.0 netmask 240.0.0.0 dev eth0
```

---

## 📊 테스트

### 기능 테스트

1. **Gear 변경 테스트**
   - GearApp UI에서 P, R, N, D 버튼 클릭
   - VehicleControlECU 로그에서 `setGearPosition called` 확인

2. **Event 수신 테스트**
   - VehicleControlECU에서 `vehicleStateChanged` 이벤트 발생
   - GearApp에서 이벤트 수신 및 UI 업데이트 확인

3. **재연결 테스트**
   - VehicleControlECU 중지 후 재시작
   - GearApp이 자동으로 재연결되는지 확인

---

## 📝 systemd 서비스 등록 (선택사항)

### ECU1: VehicleControlECU 자동 시작

```bash
sudo nano /etc/systemd/system/vehiclecontrol.service
```

```ini
[Unit]
Description=VehicleControlECU Service
After=network.target

[Service]
Type=simple
User=pi
WorkingDirectory=/home/pi/DES_Head-Unit/app/VehicleControlECU
Environment="VSOMEIP_CONFIGURATION=/home/pi/DES_Head-Unit/app/VehicleControlECU/config/vsomeip_ecu1.json"
Environment="COMMONAPI_CONFIG=/home/pi/DES_Head-Unit/app/VehicleControlECU/config/commonapi_ecu1.ini"
Environment="LD_LIBRARY_PATH=/usr/local/lib"
ExecStart=/home/pi/DES_Head-Unit/app/VehicleControlECU/build/VehicleControlECU
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
```

활성화:
```bash
sudo systemctl daemon-reload
sudo systemctl enable vehiclecontrol.service
sudo systemctl start vehiclecontrol.service
sudo systemctl status vehiclecontrol.service
```

### ECU2: GearApp 자동 시작

```bash
sudo nano /etc/systemd/system/gearapp.service
```

```ini
[Unit]
Description=GearApp Service
After=network.target
Requires=network.target

[Service]
Type=simple
User=pi
WorkingDirectory=/home/pi/DES_Head-Unit/app/GearApp
Environment="VSOMEIP_CONFIGURATION=/home/pi/DES_Head-Unit/app/GearApp/config/vsomeip_ecu2.json"
Environment="COMMONAPI_CONFIG=/home/pi/DES_Head-Unit/app/GearApp/config/commonapi_ecu2.ini"
Environment="LD_LIBRARY_PATH=/usr/local/lib"
Environment="QT_QPA_PLATFORM=linuxfb"
ExecStart=/home/pi/DES_Head-Unit/app/GearApp/build/GearApp
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

활성화:
```bash
sudo systemctl daemon-reload
sudo systemctl enable gearapp.service
sudo systemctl start gearapp.service
sudo systemctl status gearapp.service
```

---

## 🎯 다음 단계

1. ✅ VehicleControlECU와 GearApp vsomeip 통신 테스트
2. AmbientApp, MediaApp, IC_app 배포 설정 추가
3. Yocto 이미지 빌드 및 SD 카드 배포
4. 실제 PiRacer 하드웨어 통합 테스트

---

## 📚 참고 자료

- [vsomeip Documentation](https://github.com/COVESA/vsomeip/wiki)
- [CommonAPI C++ Tutorial](https://github.com/COVESA/capicxx-core-tools/wiki)
- [Raspberry Pi Network Configuration](https://www.raspberrypi.com/documentation/computers/configuration.html#configuring-networking)
