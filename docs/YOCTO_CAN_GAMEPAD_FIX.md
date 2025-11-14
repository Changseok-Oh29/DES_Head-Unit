# Yocto 이미지 수정 사항 - CAN 통신 및 Gamepad 권한 추가

## 문제 원인
- ✅ **기본 Raspberry Pi OS**: 모든 기능 정상 (컨트롤러, 속도/CAN, 배터리)
- ❌ **Yocto 이미지**: CAN 관련 패키지 및 권한 설정 누락

## 추가된 구성요소

### 1. CAN 통신 지원 (`packagegroup-vehiclecontrol.bb` + `vehiclecontrol-image.bb`)

**추가된 패키지:**
```
can-utils                  # candump, cansend 등 CAN 디버깅 도구
kernel-module-can          # CAN 프로토콜 코어
kernel-module-can-raw      # Raw CAN 소켓
kernel-module-vcan         # Virtual CAN (테스트용)
kernel-module-slcan        # Serial Line CAN
kernel-module-mcp251x      # MCP2515 SPI CAN 컨트롤러
```

### 2. CAN 인터페이스 자동 설정 (`can-setup` 레시피)

**새 파일:**
- `meta-vehiclecontrol/recipes-connectivity/can-setup/can-setup_1.0.bb`
- `meta-vehiclecontrol/recipes-connectivity/can-setup/files/can-setup.service`
- `meta-vehiclecontrol/recipes-connectivity/can-setup/files/setup-can.sh`

**기능:**
```bash
# 부팅 시 자동 실행:
# 1. CAN 커널 모듈 로드
modprobe can can-raw vcan

# 2. 물리 CAN 인터페이스 설정 (있으면)
ip link set can0 type can bitrate 500000
ip link set can0 up

# 3. 없으면 가상 CAN 생성 (테스트용)
ip link add dev vcan0 type vcan
ip link set vcan0 up
```

### 3. udev 규칙 (`udev-rules-vehiclecontrol` 레시피)

**새 파일:**
- `meta-vehiclecontrol/recipes-core/udev/udev-rules-vehiclecontrol_1.0.bb`
- `meta-vehiclecontrol/recipes-core/udev/files/99-vehiclecontrol.rules`

**권한 설정:**
```
/dev/input/js*    → group=input, mode=0660  (게임패드)
/dev/input/event* → group=input, mode=0660  (입력 이벤트)
/dev/i2c-*        → group=i2c, mode=0660    (I2C 장치)
/dev/gpio*        → group=gpio, mode=0660   (GPIO)
can*              → group=netdev, mode=0660 (CAN 인터페이스)
```

### 4. systemd 서비스 권한 (`vehiclecontrol-ecu.service`)

**변경 사항:**
```ini
[Service]
User=root
Group=root
SupplementaryGroups=input i2c gpio  # 추가된 보조 그룹
```

이제 VehicleControlECU 프로세스가:
- `/dev/input/js0` (gamepad) 접근 가능
- `/dev/i2c-1` (INA219, PCA9685) 접근 가능
- GPIO 접근 가능

## 빌드 및 배포

### 1. Yocto 이미지 재빌드

```bash
cd /home/seame/HU/DES_Head-Unit/meta

# Clean previous build (optional)
bitbake -c cleanall vehiclecontrol-image

# Build new image with CAN support
bitbake vehiclecontrol-image
```

**빌드 시간 예상:**
- 이전 빌드 캐시 있음: 10-30분
- 새 패키지만 컴파일: can-utils, can-setup, udev-rules-vehiclecontrol

### 2. SD 카드에 이미지 쓰기

```bash
# 빌드된 이미지 경로
IMAGE=/path/to/build/tmp/deploy/images/raspberrypi4/vehiclecontrol-image-raspberrypi4.rpi-sdimg

# SD 카드에 쓰기 (예: /dev/sdb)
sudo dd if=$IMAGE of=/dev/sdX bs=4M status=progress
sync
```

### 3. 부팅 후 확인

```bash
# SSH 접속
ssh root@<raspberry-pi-ip>

# CAN 인터페이스 확인
ip link show can0
# 또는
ip link show vcan0

# CAN 모듈 로드 확인
lsmod | grep can

# 서비스 상태 확인
systemctl status can-setup.service
systemctl status vehiclecontrol-ecu.service

# udev 규칙 적용 확인
ls -l /dev/input/js0
ls -l /dev/i2c-1

# CAN 테스트 (vcan0 사용 시)
candump vcan0 &
cansend vcan0 123#DEADBEEF
```

## 기대 결과

### ✅ 정상 작동 확인

1. **CAN 인터페이스**
```bash
$ ip link show can0
can0: <NOARP,UP,LOWER_UP,ECHO> mtu 16 qdisc pfifo_fast state UP mode DEFAULT group default qlen 10
    link/can
```

2. **Gamepad 권한**
```bash
$ ls -l /dev/input/js0
crw-rw---- 1 root input 13, 0 Nov 12 12:34 /dev/input/js0
```

3. **CAN 통신**
```bash
$ candump can0
can0  123   [8]  01 02 03 04 05 06 07 08
```

4. **VehicleControlECU 로그**
```bash
$ journalctl -u vehiclecontrol-ecu -f
Nov 12 12:35:01 raspberrypi4 VehicleControlECU[1234]: ✅ GamepadHandler initialized
Nov 12 12:35:01 raspberrypi4 VehicleControlECU[1234]: ✅ BatteryMonitor initialized (INA219)
Nov 12 12:35:02 raspberrypi4 VehicleControlECU[1234]: ✅ CAN interface ready
Nov 12 12:35:02 raspberrypi4 VehicleControlECU[1234]: Battery: 12.4V, 450mA
Nov 12 12:35:03 raspberrypi4 VehicleControlECU[1234]: Throttle: 0.5 → Speed: 15 km/h
```

## 추가 디버깅 (필요 시)

### 게임패드 입력 테스트
```bash
evtest /dev/input/js0
# 또는
jstest /dev/input/js0
```

### CAN 메시지 모니터링
```bash
candump -t a can0
```

### I2C 장치 확인
```bash
i2cdetect -y 1
```

## 변경된 파일 목록

### 수정된 파일:
1. `meta-vehiclecontrol/recipes-core/packagegroups/packagegroup-vehiclecontrol.bb`
2. `meta-vehiclecontrol/recipes-core/images/vehiclecontrol-image.bb`
3. `app/VehicleControlECU/vehiclecontrol-ecu.service`

### 새로 추가된 파일:
1. `meta-vehiclecontrol/recipes-connectivity/can-setup/can-setup_1.0.bb`
2. `meta-vehiclecontrol/recipes-connectivity/can-setup/files/can-setup.service`
3. `meta-vehiclecontrol/recipes-connectivity/can-setup/files/setup-can.sh`
4. `meta-vehiclecontrol/recipes-core/udev/udev-rules-vehiclecontrol_1.0.bb`
5. `meta-vehiclecontrol/recipes-core/udev/files/99-vehiclecontrol.rules`

## 결론

이제 Yocto 이미지가 기본 Raspberry Pi OS와 동일하게:
- ✅ **CAN 통신** 지원 (can-utils, 커널 모듈)
- ✅ **Gamepad 권한** 자동 설정 (udev rules)
- ✅ **I2C/GPIO 권한** 자동 설정
- ✅ **CAN 인터페이스** 부팅 시 자동 활성화

모든 기능이 정상 작동할 것입니다.
