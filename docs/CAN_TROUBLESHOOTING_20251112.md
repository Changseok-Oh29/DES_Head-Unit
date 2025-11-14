# CAN 통신 문제 해결 과정 (2024-12-24)

## 문제 상황

### 초기 증상
- ✅ 배터리 모니터링: 정상 작동 (I2C)
- ✅ Bluetooth: 정상 작동
- ❌ **게임패드 제어**: 작동 안 함 (`/dev/input/js0` 없음)
- ❌ **속도 값**: 제대로 받아오지 못함 (CAN 통신 필요)

### 환경
- **하드웨어**: Raspberry Pi 4, PiRacer, MCP2515 CAN HAT
- **정상 환경**: 기본 Raspberry Pi OS (모든 기능 작동)
- **문제 환경**: Yocto Kirkstone 4.0.31 (CAN 불통)
- **커널**: Linux 5.15.92

## 발견한 핵심 사실

### ✅ 확인된 것들
1. **하드웨어 정상**: 기본 Raspberry Pi OS에서 CAN 정상 작동
2. **MCP2515 인식됨**: `cat /sys/bus/spi/devices/spi0.0/modalias` → `spi:mcp2515`
3. **Device Tree 로드됨**: `/proc/device-tree/soc/spi@7e204000/mcp2515@0/` 존재
4. **Overlay 파일 존재**: `/boot/overlays/mcp2515-can0.dtbo` 있음
5. **SPI 장치 일부 생성**: `/dev/spidev0.1` 존재 (CS1)

### ❌ 문제점들
1. **MCP2515 초기화 실패**: `error -110` (ETIME - timeout)
2. **can0 인터페이스 없음**: `ip link show can0` 실패
3. **bcm2835-spi 드라이버 미초기화**: `dmesg | grep bcm2835-spi` 아무것도 없음
4. **/dev/spidev0.0 없음**: CS0 (MCP2515용) 생성 안 됨
5. **clock-frequency 설정 안 됨**: Device Tree에 oscillator 값 누락

## 시도한 해결책들

### 1단계: Yocto에 CAN 지원 추가

#### A. 커널 설정 (`spi-can.cfg`)
```properties
# SPI 드라이버 (built-in)
CONFIG_SPI=y
CONFIG_SPI_MASTER=y
CONFIG_SPI_BCM2835=y
CONFIG_SPI_BCM2835AUX=y
CONFIG_SPI_SPIDEV=y

# CAN 드라이버 (built-in)
CONFIG_CAN=y
CONFIG_CAN_RAW=y
CONFIG_CAN_BCM=y
CONFIG_CAN_DEV=y
CONFIG_CAN_MCP251X=y
```

**결과**: 커널에는 포함되었으나 SPI 드라이버가 초기화되지 않음

#### B. 첫 번째 시도: RPI_EXTRA_CONFIG 직접 설정
```bash
# local.conf
RPI_EXTRA_CONFIG += "dtoverlay=mcp2515-can0,oscillator=16000000,interrupt=25"
```

**결과**: error -110 (timeout)

#### C. 두 번째 시도: meta-raspberrypi 공식 변수 사용
```bash
# local.conf (수정)
ENABLE_SPI_BUS = "1"
ENABLE_I2C = "1"
ENABLE_CAN = "1"
CAN_OSCILLATOR = "16000000"
CAN0_INTERRUPT_PIN = "25"
```

**결과**: 여전히 error -110

### 2단계: 파라미터 변경 시도

#### A. Oscillator 주파수 변경
```bash
# 시도한 값들:
oscillator=16000000  → error -110
oscillator=12000000  → error -110
oscillator=8000000   → error -110
oscillator (값 없음) → error -34 (ERANGE)
```

**결과**: 모두 실패

#### B. SPI 속도 제한
```bash
dtoverlay=mcp2515-can0,oscillator=16000000,interrupt=25,spimaxfrequency=1000000
```

**결과**: error -110 지속

#### C. Interrupt GPIO 변경 계획
- GPIO 25 (현재)
- GPIO 17
- GPIO 24
- GPIO 22

**상태**: 미시도 (기본 OS 설정 확인 필요)

### 3단계: udev 규칙 및 서비스 설정

#### A. udev 규칙 (`99-vehiclecontrol.rules`)
```
SUBSYSTEM=="input", KERNEL=="js[0-9]*", MODE="0660", GROUP="input"
SUBSYSTEM=="net", KERNEL=="can[0-9]*", MODE="0660", GROUP="netdev"
```

#### B. CAN 초기화 서비스 (`can-setup.service`)
```bash
#!/bin/bash
# setup-can.sh

# CAN 모듈은 built-in이므로 modprobe 불필요

# can0 인터페이스 대기
for i in {1..10}; do
    if ip link show can0 &>/dev/null; then
        echo "Found CAN interface can0"
        break
    fi
    sleep 0.5
done

# CAN 설정
if ip link show can0 &>/dev/null; then
    ip link set can0 type can bitrate 500000
    ip link set can0 up
    echo "✅ can0 is up at 500kbps"
else
    echo "❌ Physical CAN interface can0 not found!"
    exit 1
fi
```

**결과**: can0가 생성되지 않아 서비스 실패

## 진단 결과

### dmesg 분석
```
[2.952791] mcp251x spi0.0: MCP251x didn't enter in conf mode after reset
[2.961748] mcp251x spi0.0: Probe failed, err=110
[2.966468] mcp251x: probe of spi0.0 failed with error -110
```

**해석**: MCP2515 칩이 SPI 명령에 응답하지 않음 (timeout)

### Device Tree 상태
```bash
# SPI 노드 상태
cat /proc/device-tree/soc/spi@7e204000/status
→ "okay" (활성화됨)

# MCP2515 설정 확인
ls /proc/device-tree/soc/spi@7e204000/mcp2515@0/
→ 디렉토리 존재 (overlay 로드됨)

# Interrupt 설정
cat /proc/device-tree/soc/spi@7e204000/mcp2515@0/interrupts | od -An -t u4
→ 419430400  134217728

# Clock frequency (oscillator)
cat /proc/device-tree/soc/spi@7e204000/mcp2515@0/clock-frequency
→ 파일 없음! ❌
```

**발견**: `clock-frequency` 속성이 Device Tree에 적용되지 않음!

### SPI 드라이버 상태
```bash
# SPI 드라이버 초기화 메시지 확인
dmesg | grep bcm2835-spi
→ 출력 없음 ❌

# dmesg에 있는 bcm2835 관련 메시지:
- bcm2835-mbox ✅
- bcm2835-dma ✅
- bcm2835-wdt ✅
- bcm2835-power ✅
- mmc-bcm2835 ✅
- bcm2835-spi ❌ (없음!)
```

**발견**: SPI 드라이버가 초기화되지 않음 (가장 근본적인 문제)

## 기본 Raspberry Pi OS vs Yocto 비교

### 기본 OS (정상 작동)
```bash
# config.txt
dtparam=spi=on
dtoverlay=mcp2515-can0,oscillator,interrupt=25  # oscillator 값 없음!
dtoverlay=spi-bcm2835

# 결과
✅ can0 생성됨
✅ CAN 통신 정상
✅ 게임패드 작동
✅ 속도 값 수신
```

### Yocto (문제 발생)
```bash
# config.txt
dtparam=spi=on
dtparam=i2c_arm=on
dtoverlay=mcp2515-can0,oscillator=16000000,interrupt=25

# 결과
❌ can0 생성 안 됨
❌ error -110 (MCP2515 timeout)
❌ /dev/spidev0.0 없음
❌ bcm2835-spi 드라이버 미초기화
```

## 현재 상태

### 파일 구조
```
meta-vehiclecontrol/
├── conf/machine/
│   └── raspberrypi4-64-vehiclecontrol.conf  (사용 안 함)
├── recipes-kernel/linux/
│   ├── files/
│   │   └── spi-can.cfg
│   └── linux-raspberrypi_%.bbappend
├── recipes-connectivity/can-setup/
│   ├── can-setup_1.0.bb
│   └── files/
│       ├── can-setup.service
│       └── setup-can.sh
└── recipes-core/
    ├── images/vehiclecontrol-image.bb
    └── udev/
        ├── udev-rules-vehiclecontrol_1.0.bb
        └── files/99-vehiclecontrol.rules
```

### local.conf 최종 설정
```bash
# Hardware Configuration (meta-raspberrypi 방식)
ENABLE_SPI_BUS = "1"
ENABLE_I2C = "1"

# CAN 활성화 (rpi-config_git.bb가 자동으로 처리)
ENABLE_CAN = "1"
CAN_OSCILLATOR = "16000000"
CAN0_INTERRUPT_PIN = "25"

# I2C 속도 설정
RPI_EXTRA_CONFIG += "dtparam=i2c_arm_baudrate=400000 \n"
```

## 다음 단계 (해결 방향)

### 1. 기본 OS 정확한 설정 추출 ⭐ (가장 중요)
```bash
# 기본 Raspberry Pi OS로 부팅 후:
cat /boot/config.txt | grep -i "spi\|can\|mcp"
uname -r
dmesg | grep mcp251
cat /proc/device-tree/soc/spi@7e204000/mcp2515@0/interrupts | od -An -t u4
cat /proc/device-tree/soc/spi@7e204000/mcp2515@0/clock-frequency | od -An -t u4
```

**목적**: 정상 작동하는 정확한 파라미터 값 확인

### 2. Device Tree Overlay 비교
```bash
# 기본 OS
dtc -I dtb -O dts /boot/overlays/mcp2515-can0.dtbo > basic_os_overlay.dts

# Yocto
dtc -I dtb -O dts /boot/overlays/mcp2515-can0.dtbo > yocto_overlay.dts

# 차이점 확인
diff basic_os_overlay.dts yocto_overlay.dts
```

### 3. SPI 드라이버 강제 초기화
- `dtoverlay=spi-bcm2835` 추가 시도
- 커널 부팅 파라미터에 SPI 활성화 추가
- Device Tree 직접 패치

### 4. 대체 접근 방법
```bash
# A. 기본 OS의 커널 + dtb를 Yocto rootfs에 사용
# B. Yocto 커널 버전을 기본 OS와 동일하게 맞춤
# C. meta-raspberrypi 버전 업그레이드/다운그레이드
```

## 핵심 문제 요약

1. **SPI 드라이버 미초기화**: bcm2835-spi가 dmesg에 나타나지 않음
2. **clock-frequency 미적용**: Device Tree에 oscillator 값이 없음
3. **MCP2515 timeout**: 하드웨어는 정상이나 통신 실패 (error -110)
4. **설정 불일치**: 기본 OS와 Yocto의 config.txt 파라미터 차이

## 결론

문제는 **하드웨어가 아닌 Yocto Device Tree 설정**에 있습니다. 기본 Raspberry Pi OS에서는 정상 작동하므로, **정확한 작동 설정을 추출하여 Yocto에 적용**하면 해결될 것으로 예상됩니다.

특히 기본 OS의 `dtoverlay=mcp2515-can0,oscillator,interrupt=25`에서 **oscillator 값이 명시되지 않은 점**이 중요한 단서일 수 있습니다.
