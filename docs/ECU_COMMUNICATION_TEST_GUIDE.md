# ECU간 통신 테스트 가이드 (라즈베리파이 2대)

## 📋 목차
1. [테스트 환경 개요](#테스트-환경-개요)
2. [하드웨어 준비](#하드웨어-준비)
3. [네트워크 설정](#네트워크-설정)
4. [ECU1 설정 (VehicleControlECU)](#ecu1-설정-vehiclecontrolecu)
5. [ECU2 설정 (GearApp)](#ecu2-설정-gearapp)
6. [통신 테스트](#통신-테스트)
7. [문제 해결](#문제-해결)

---

## 테스트 환경 개요

### 아키텍처
```
┌─────────────────────────────────────────────────────────────┐
│              vsomeip Network (SOME/IP Protocol)              │
└─────────────────────────────────────────────────────────────┘
           ↑                                    ↑
           │                                    │
    ┌──────┴────────┐                   ┌──────┴────────┐
    │   ECU1 (RPi1) │                   │   ECU2 (RPi2) │
    │ 192.168.1.100 │◄──── Ethernet ────│ 192.168.1.101 │
    └───────────────┘                   └───────────────┘
    │                                    │
    │ VehicleControlECU                  │ GearApp
    │ - Routing Manager                  │ - Client
    │ - Service Provider                 │ - GUI
    │ - PiRacer 하드웨어                 │ - RPC Caller
    └───────────────┘                   └───────────────┘
```

### 역할 분담

| ECU | 역할 | IP 주소 | 애플리케이션 | vsomeip 역할 |
|-----|------|---------|-------------|-------------|
| ECU1 | Service Provider | 192.168.1.100 | VehicleControlECU | Routing Manager |
| ECU2 | Service Consumer | 192.168.1.101 | GearApp | Client |

---

## 하드웨어 준비

### 필요한 장비
- ✅ 라즈베리파이 2대 (라즈베리파이 OS 설치됨)
- ✅ Ethernet 케이블 1개 (직접 연결용)
- ✅ 전원 어댑터 2개
- ✅ (선택) PiRacer 하드웨어 (ECU1에 연결)
- ✅ (선택) 모니터, 키보드 (초기 설정용)

### 물리적 연결
```
RPi1 (ECU1) ◄────── Ethernet Cable ──────► RPi2 (ECU2)
    ↑                                           ↑
 PiRacer                                    Monitor/KB
(선택사항)                                  (GUI 확인)
```

---

## 네트워크 설정

### ECU1 (라즈베리파이 1) - 192.168.1.100

#### 1. SSH 접속 (또는 직접 연결)
```bash
# 다른 PC에서 SSH 접속하거나
ssh pi@raspberrypi1.local

# 또는 직접 모니터/키보드 연결
```

#### 2. Ethernet 인터페이스 확인
```bash
ip link show
# eth0 또는 enp... 형태의 이름 확인
```

#### 3. 고정 IP 설정 (netplan 사용)
```bash
# /etc/netplan/01-netcfg.yaml 생성
sudo nano /etc/netplan/01-netcfg.yaml
```

다음 내용 입력:
```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:  # 실제 인터페이스 이름으로 변경
      dhcp4: no
      addresses:
        - 192.168.1.100/24
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]
```

적용:
```bash
sudo netplan apply
```

#### 4. 대안: /etc/network/interfaces 사용 (구형 Raspberry Pi OS)
```bash
sudo nano /etc/network/interfaces
```

다음 내용 추가:
```
auto eth0
iface eth0 inet static
    address 192.168.1.100
    netmask 255.255.255.0
```

재시작:
```bash
sudo systemctl restart networking
# 또는
sudo ifdown eth0 && sudo ifup eth0
```

#### 5. IP 확인
```bash
ip addr show eth0
# 192.168.1.100/24가 설정되었는지 확인
```

---

### ECU2 (라즈베리파이 2) - 192.168.1.101

위의 ECU1 설정과 동일하되 IP 주소만 변경:

```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: no
      addresses:
        - 192.168.1.101/24  # 101로 변경
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]
```

또는 /etc/network/interfaces:
```
auto eth0
iface eth0 inet static
    address 192.168.1.101  # 101로 변경
    netmask 255.255.255.0
```

---

### 네트워크 연결 테스트

#### ECU1에서 ECU2로 ping
```bash
ping -c 4 192.168.1.101
```

#### ECU2에서 ECU1로 ping
```bash
ping -c 4 192.168.1.100
```

**✅ 성공 예시:**
```
PING 192.168.1.101 (192.168.1.101) 56(84) bytes of data.
64 bytes from 192.168.1.101: icmp_seq=1 ttl=64 time=0.234 ms
64 bytes from 192.168.1.101: icmp_seq=2 ttl=64 time=0.187 ms
```

**❌ 실패 시:**
- Ethernet 케이블 연결 확인
- IP 설정 재확인
- 방화벽 확인: `sudo ufw status`

---

## ECU1 설정 (VehicleControlECU)

### ⚠️ 빌드 환경 차이점 및 주의사항

#### 로컬 PC vs 라즈베리파이 빌드 차이

**현재 CMakeLists.txt 문제:**
```cmake
# ❌ 문제: 하드코딩된 경로
set(CMAKE_PREFIX_PATH "${CMAKE_PREFIX_PATH};/home/seam/DES_Head-Unit/install_folder")
set(CMAKE_INSTALL_RPATH "/home/seam/DES_Head-Unit/install_folder/lib")
```

**이로 인한 문제점:**
1. **로컬 PC에서 빌드 성공** - `/home/seam` 경로에 라이브러리가 있으면 빌드됨
2. **라즈베리파이에서 빌드 실패** - `/home/pi/...` 경로를 사용하므로 경로 불일치
3. **다른 사용자 환경에서 실패** - 사용자 이름에 따라 경로가 달라짐

**해결 방법 (Phase 3에서 적용):**

환경변수 사용으로 유연하게 경로 설정:
```cmake
# 환경변수로 경로 설정
if(DEFINED ENV{DEPLOY_PREFIX})
    set(INSTALL_PREFIX $ENV{DEPLOY_PREFIX})
else()
    # 기본값 (로컬 개발용)
    set(INSTALL_PREFIX "$ENV{HOME}/DES_Head-Unit/install_folder")
endif()

set(CMAKE_PREFIX_PATH "${CMAKE_PREFIX_PATH};${INSTALL_PREFIX}")
set(CMAKE_INSTALL_RPATH "${INSTALL_PREFIX}/lib")
```

사용 방법:
```bash
# 라즈베리파이에서
export DEPLOY_PREFIX=/home/pi/DES_Head-Unit/install_folder
./build.sh

# 로컬 PC에서
export DEPLOY_PREFIX=/home/leo/SEA-ME/DES_Head-Unit/install_folder
./build.sh
```

#### 빌드 vs 실행 차이점

| 단계 | 로컬 PC | 라즈베리파이 |
|------|---------|-------------|
| 빌드 | ✅ 성공 (로컬 라이브러리 있음) | ✅ 성공 (경로만 맞으면) |
| 실행 | ⚠️ 서비스 대기 (서버 없음) | ✅ 정상 (ECU1↔ECU2 통신) |

**로컬 PC에서 실행 시:**
```
✅ 앱 시작 성공
✅ vsomeip 초기화 성공
❌ MediaApp 서비스 찾을 수 없음 → 대기 상태
❌ VehicleControlECU 서비스 찾을 수 없음 → 대기 상태
⚠️ GUI는 뜨지만 통신 불가
```

**이는 정상 동작입니다!** 
- 서비스가 실행 중이 아니므로 연결 대기 상태로 유지됩니다.
- 라즈베리파이 2대를 연결해야 실제 통신이 작동합니다.

**주의:** 현재 CMakeLists.txt는 하드코딩된 경로를 사용 중입니다. Phase 3에서 환경변수 방식으로 변경할 예정입니다.

---

### 1. 필요한 파일 전송

개발 PC에서 ECU1으로 파일 전송:

```bash
# 개발 PC에서 실행
cd ~/SEA-ME/DES_Head-Unit/app/VehicleControlECU

# ECU1으로 전송
scp -r ~/SEA-ME/DES_Head-Unit/app/VehicleControlECU pi@192.168.1.100:~/
scp -r ~/SEA-ME/DES_Head-Unit/commonapi/generated pi@192.168.1.100:~/commonapi/
```

### 2. ECU1 SSH 접속
```bash
ssh pi@192.168.1.100
```

### 3. 의존성 설치
```bash
cd ~/VehicleControlECU

# 스크립트 실행 권한 부여
chmod +x install_dependencies.sh
chmod +x build_vsomeip_rpi.sh
chmod +x cleanup_x86_libs.sh
chmod +x build.sh
chmod +x run.sh

# 시스템 패키지 설치
sudo apt update
sudo apt install -y \
    build-essential \
    cmake \
    git \
    qtbase5-dev \
    qtdeclarative5-dev \
    qtquickcontrols2-5-dev \
    libboost-system-dev \
    libboost-thread-dev \
    libboost-filesystem-dev \
    libboost-log-dev \
    libi2c-dev \
    i2c-tools

# PiRacer 하드웨어 사용 시
sudo apt install -y pigpio
sudo systemctl enable pigpiod
sudo systemctl start pigpiod
```

### 4. vsomeip & CommonAPI 빌드 (ARM64용)
```bash
cd ~/VehicleControlECU

# x86_64 라이브러리가 있다면 제거
./cleanup_x86_libs.sh

# vsomeip 및 CommonAPI 네이티브 빌드 (15-20분 소요)
./build_vsomeip_rpi.sh
```

**⏰ 빌드 완료까지 대기...**

### 5. VehicleControlECU 빌드
```bash
cd ~/VehicleControlECU

# CommonAPI generated code 경로 설정
export COMMONAPI_GEN_DIR=~/commonapi/generated

# 빌드
./build.sh
```

### 6. 설정 파일 확인
```bash
# vsomeip 설정 확인
cat ~/VehicleControlECU/config/vsomeip_ecu1.json
```

주요 설정 확인:
- `"unicast": "192.168.1.100"` ✅
- `"routing": "VehicleControlECU"` ✅
- `"service-discovery": { "enable": "true" }` ✅

### 7. VehicleControlECU 실행
```bash
cd ~/VehicleControlECU

# PiRacer 하드웨어 사용 시 sudo 필요
sudo ./run.sh

# 또는 하드웨어 없이 테스트
./run.sh
```

**✅ 성공 시 출력 예시:**
```
═══════════════════════════════════════════════════════
Starting VehicleControlECU - vsomeip Service
ECU1 @ 192.168.1.100
═══════════════════════════════════════════════════════

[info] Initializing vsomeip application "VehicleControlECU"
[info] Instantiating routing manager [Host].
[info] Service VehicleControl registered
[info] Application(VehicleControlECU) is initialized
```

---

## ECU2 설정 (GearApp)

### 1. 필요한 파일 전송

개발 PC에서 ECU2로 파일 전송:

```bash
# 개발 PC에서 실행
cd ~/SEA-ME/DES_Head-Unit/app/GearApp

# ECU2로 전송
scp -r ~/SEA-ME/DES_Head-Unit/app/GearApp pi@192.168.1.101:~/
scp -r ~/SEA-ME/DES_Head-Unit/commonapi/generated pi@192.168.1.101:~/commonapi/
```

### 2. ECU2 SSH 접속
```bash
ssh pi@192.168.1.101
```

### 3. 의존성 설치
```bash
cd ~/GearApp

# 스크립트 실행 권한 부여
chmod +x build.sh
chmod +x run.sh

# 시스템 패키지 설치
sudo apt update
sudo apt install -y \
    build-essential \
    cmake \
    git \
    qtbase5-dev \
    qtdeclarative5-dev \
    qtquickcontrols2-5-dev \
    qml-module-qtquick-controls \
    qml-module-qtquick-controls2 \
    libboost-system-dev \
    libboost-thread-dev \
    libboost-filesystem-dev \
    libboost-log-dev
```

### 4. vsomeip & CommonAPI 빌드 (ARM64용)

**중요: ECU1에서 이미 빌드했다면, 빌드된 라이브러리를 복사하는 것이 더 빠릅니다.**

#### 옵션 A: ECU1에서 복사 (추천)
```bash
# ECU2에서 실행
scp -r pi@192.168.1.100:/usr/local/lib/libvsomeip* /usr/local/lib/
scp -r pi@192.168.1.100:/usr/local/lib/libCommonAPI* /usr/local/lib/
scp -r pi@192.168.1.100:/usr/local/include/vsomeip /usr/local/include/
scp -r pi@192.168.1.100:/usr/local/include/CommonAPI* /usr/local/include/
scp -r pi@192.168.1.100:/usr/local/lib/cmake/vsomeip3 /usr/local/lib/cmake/
scp -r pi@192.168.1.100:/usr/local/lib/cmake/CommonAPI* /usr/local/lib/cmake/

sudo ldconfig
```

#### 옵션 B: 직접 빌드
```bash
# VehicleControlECU의 빌드 스크립트 복사
scp pi@192.168.1.100:~/VehicleControlECU/build_vsomeip_rpi.sh ~/

chmod +x build_vsomeip_rpi.sh
./build_vsomeip_rpi.sh
```

### 5. GearApp 빌드
```bash
cd ~/GearApp

# CommonAPI generated code 경로 설정
export COMMONAPI_GEN_DIR=~/commonapi/generated

# 빌드
./build.sh
```

### 6. 설정 파일 확인
```bash
# vsomeip 설정 확인
cat ~/GearApp/config/vsomeip_ecu2.json
```

주요 설정 확인:
- `"unicast": "192.168.1.101"` ✅
- `"routing": "VehicleControlECU"` ✅
- `"routing-manager": { "host": "192.168.1.100" }` ✅

### 7. GearApp 실행

**X11 디스플레이 설정 (GUI 표시용):**

```bash
# 로컬 모니터에 표시
export DISPLAY=:0

# 또는 SSH X11 포워딩 사용 (개발 PC에서 SSH 접속 시)
ssh -X pi@192.168.1.101
```

**애플리케이션 실행:**
```bash
cd ~/GearApp
./run.sh
```

**✅ 성공 시 출력 예시:**
```
═══════════════════════════════════════════════════════
Starting GearApp - vsomeip Client
ECU2 @ 192.168.1.101
═══════════════════════════════════════════════════════

[info] Initializing vsomeip application "GearApp"
[info] Instantiating routing manager [Proxy].
[info] Client is connecting to routing manager at 192.168.1.100
✅ Proxy created successfully
✅ Connected to VehicleControl service
GearApp is running...
```

---

## 통신 테스트

### 1. 서비스 디스커버리 확인

**ECU1 로그 (VehicleControlECU):**
```
[info] OFFER(1234): [1234.5678:0.0]
[info] Service Discovery: Offering service 0x1234
```

**ECU2 로그 (GearApp):**
```
[info] REQUEST(1234): [1234.5678:0.0]
[info] Service 0x1234 is available
✅ Connected to VehicleControl service
```

### 2. RPC 호출 테스트

**ECU2 (GearApp)에서:**
- GUI에서 기어 버튼 클릭 (P → D)

**ECU1 로그:**
```
[VehicleControlStubImpl] Gear change requested: D
[VehicleControlStubImpl] Gear changed to: D
```

**ECU2 로그:**
```
[GearManager → vsomeip] Requesting gear change: "D"
✅ Gear change successful
[vsomeip → GearManager] Gear changed to: D
```

### 3. Event 브로드캐스트 테스트

**ECU1에서 PiRacer 조작 (또는 코드에서 이벤트 발생):**

**ECU1 로그:**
```
[VehicleControlStubImpl] Broadcasting vehicle state: Speed=15, Battery=85%
```

**ECU2 로그:**
```
[VehicleControlClient] Event received: Speed=15, Battery=85%
UI updated: Speed 15 km/h, Battery 85%
```

### 4. 양방향 통신 시나리오

**전체 통신 플로우:**

1. **ECU2**: 사용자가 GUI에서 "D" 버튼 클릭
2. **ECU2**: `requestGearChange("D")` RPC 호출
3. **Network**: SOME/IP 메시지 전송 (192.168.1.101 → 192.168.1.100)
4. **ECU1**: RPC 수신, 기어 변경 로직 실행
5. **ECU1**: 기어 변경 완료, RPC 응답 전송
6. **ECU1**: `GearChanged` 이벤트 브로드캐스트
7. **Network**: SOME/IP 이벤트 전송 (192.168.1.100 → 192.168.1.101)
8. **ECU2**: 이벤트 수신, UI 업데이트

---

## 문제 해결

### 문제 1: "Couldn't connect to routing manager"

**증상:**
```
[warning] local_client_endpoint::connect: Couldn't connect
[error] Routing manager not reachable
```

**해결:**
```bash
# ECU1에서 VehicleControlECU가 실행 중인지 확인
ps aux | grep VehicleControlECU

# 네트워크 연결 확인
ping 192.168.1.100

# ECU1의 vsomeip 로그 확인
# "Instantiating routing manager [Host]" 메시지가 있어야 함
```

### 문제 2: "Service not available"

**증상:**
```
⚠️  VehicleControl service is not available
```

**해결:**
```bash
# 1. 서비스 디스커버리 패킷 확인 (ECU1에서)
sudo tcpdump -i eth0 port 30490

# 2. 멀티캐스트 확인
ip maddr show eth0
# 224.244.224.245가 있어야 함

# 3. 방화벽 확인
sudo ufw status
# 비활성화 또는 포트 30490, 30509 열기
sudo ufw allow 30490/udp
sudo ufw allow 30509/udp
```

### 문제 3: 빌드 에러 "cannot find -lvsomeip3"

**증상:**
```
/usr/bin/ld: cannot find -lvsomeip3
```

**해결:**
```bash
# vsomeip 라이브러리 확인
ls -la /usr/local/lib/libvsomeip*

# 라이브러리 캐시 업데이트
sudo ldconfig

# CMake 캐시 삭제 후 재빌드
rm -rf build
./build.sh
```

### 문제 4: Qt GUI가 표시되지 않음

**증상:**
```
Could not find the Qt platform plugin "wayland"
```

**해결:**
```bash
# X11 디스플레이 설정
export DISPLAY=:0
export QT_QPA_PLATFORM=xcb

# 또는 SSH X11 포워딩 사용
ssh -X pi@192.168.1.101

# Qt 플랫폼 플러그인 설치
sudo apt install -y \
    libqt5gui5 \
    qt5-gtk-platformtheme \
    qml-module-qtquick-window2
```

### 문제 5: 권한 에러 (PiRacer 하드웨어)

**증상:**
```
Permission denied: /dev/i2c-1
```

**해결:**
```bash
# i2c 그룹에 사용자 추가
sudo usermod -a -G i2c,gpio pi
sudo reboot

# 또는 sudo로 실행
sudo ./run.sh
```

### 문제 6: IP 주소가 할당되지 않음

**해결:**
```bash
# 네트워크 인터페이스 재시작
sudo ip link set eth0 down
sudo ip link set eth0 up

# 수동 IP 설정 (임시)
sudo ip addr add 192.168.1.100/24 dev eth0

# 영구 설정 확인
sudo nano /etc/netplan/01-netcfg.yaml
sudo netplan apply
```

---

## 디버깅 팁

### 1. vsomeip 로그 레벨 증가
```json
// vsomeip_ecu1.json 또는 vsomeip_ecu2.json
{
  "logging": {
    "level": "debug",  // info → debug로 변경
    "console": "true"
  }
}
```

### 2. 네트워크 패킷 모니터링
```bash
# ECU1에서 SOME/IP 트래픽 확인
sudo tcpdump -i eth0 -n 'udp and (port 30490 or port 30509)'

# 또는 Wireshark 사용
sudo apt install wireshark
sudo wireshark &
# Filter: someip || udp.port == 30490
```

### 3. 실시간 로그 확인
```bash
# 터미널 분할 (tmux 사용)
sudo apt install tmux

tmux
# Ctrl+B, % : 화면 세로 분할
# Ctrl+B, " : 화면 가로 분할
# Ctrl+B, 방향키 : 창 이동

# 한쪽에서 ECU1 로그, 다른 쪽에서 ECU2 로그 동시 확인
```

### 4. 서비스 상태 확인 스크립트

**ECU1에서 실행:**
```bash
cat > check_service.sh << 'EOF'
#!/bin/bash
echo "=== VehicleControlECU Status ==="
echo "Process: $(ps aux | grep VehicleControlECU | grep -v grep)"
echo "IP: $(ip addr show eth0 | grep 'inet ')"
echo "Multicast: $(ip maddr show eth0 | grep 224.244.224.245)"
echo "Ports: $(sudo netstat -unlp | grep -E '30490|30509')"
EOF

chmod +x check_service.sh
./check_service.sh
```

**ECU2에서 실행:**
```bash
cat > check_client.sh << 'EOF'
#!/bin/bash
echo "=== GearApp Status ==="
echo "Process: $(ps aux | grep GearApp | grep -v grep)"
echo "IP: $(ip addr show eth0 | grep 'inet ')"
echo "Routing Manager reachable: $(ping -c 1 192.168.1.100 > /dev/null && echo 'YES' || echo 'NO')"
EOF

chmod +x check_client.sh
./check_client.sh
```

---

## 성공 체크리스트

- [ ] 라즈베리파이 2대 Ethernet 케이블로 연결됨
- [ ] ECU1 IP: 192.168.1.100 설정 완료
- [ ] ECU2 IP: 192.168.1.101 설정 완료
- [ ] ECU1 ↔ ECU2 ping 성공
- [ ] ECU1: vsomeip & CommonAPI 빌드 완료
- [ ] ECU2: vsomeip & CommonAPI 빌드 완료
- [ ] ECU1: VehicleControlECU 빌드 완료
- [ ] ECU2: GearApp 빌드 완료
- [ ] ECU1: VehicleControlECU 실행 중 (Routing Manager 로그 확인)
- [ ] ECU2: GearApp 실행 중 (Service available 로그 확인)
- [ ] RPC 호출 성공 (기어 변경 동작 확인)
- [ ] Event 수신 성공 (속도/배터리 정보 표시 확인)

---

## 다음 단계

성공적으로 통신이 확인되면:

1. **성능 측정**: RPC 호출 지연시간, 이벤트 전송 주기 측정
2. **안정성 테스트**: 장시간 실행, 네트워크 단절/복구 시나리오
3. **추가 ECU 연결**: 다른 애플리케이션 (MediaApp, AmbientApp) 추가
4. **Yocto 이미지 빌드**: 최종 배포용 커스텀 이미지 생성
5. **실제 차량 통합**: CAN 통신 추가, 차량 시그널 연동

---

## 참고 자료

- vsomeip 공식 문서: https://github.com/COVESA/vsomeip
- CommonAPI 가이드: https://github.com/COVESA/capicxx-core-tools
- SOME/IP 프로토콜: https://www.autosar.org/
- 프로젝트 문서: `/docs` 폴더의 다른 가이드 참조
