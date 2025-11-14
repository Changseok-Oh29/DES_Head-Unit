# DES Head Unit - 종합 분석 및 해결 방안

## 1. 하드웨어 확인 (기본 라즈베리파이 OS 기준)

### 확인된 하드웨어
- **CAN HAT**: MCP2518FD (NOT MCP2515!)
- **Oscillator**: 40MHz
- **Interrupt GPIO**: 25
- **Connection**: SPI0 CS0 (spi0.0)
- **CAN Bitrate**: 1000kbps

### 기본 라즈베리파이 OS에서 동작 확인
```bash
# Device Tree에서 확인
dtoverlay=mcp251xfd,spi0-0,interrupt=25

# 드라이버 확인
lsmod | grep mcp251xfd
# 결과: mcp251xfd 로드됨

# CAN 인터페이스 확인
ip link show can0
# 결과: can0 존재

# 커널 모듈 위치
find /lib/modules/$(uname -r) -name "*mcp251*"
# 결과: mcp251xfd.ko 존재
```

## 2. 현재 Yocto 설정 분석

### 2.1 local.conf 설정 (현재)
```bash
MACHINE = "raspberrypi4-64"
DISTRO_FEATURES:append = " systemd opengl bluetooth wifi"
MACHINE_FEATURES:append = " bluetooth wifi"

# CAN 설정
ENABLE_SPI_BUS = "1"
ENABLE_I2C = "1"
ENABLE_CAN = "1"  # ❌ 문제: 이것은 MCP2515용!
CAN_OSCILLATOR = "40000000"
CAN0_INTERRUPT_PIN = "25"
```

**문제점**: `ENABLE_CAN = "1"`은 meta-raspberrypi에서 **MCP2515용 overlay를 활성화**합니다!

### 2.2 meta-raspberrypi의 CAN 처리 방식

```bbappend
// meta-raspberrypi/recipes-bsp/bootfiles/rpi-config_git.bb (Line 243-257)

if [ "${ENABLE_DUAL_CAN}" = "1" ]; then
    echo "dtoverlay=mcp2515-can0,oscillator=${CAN_OSCILLATOR},interrupt=${CAN0_INTERRUPT_PIN}" >>$CONFIG
    echo "dtoverlay=mcp2515-can1,oscillator=${CAN_OSCILLATOR},interrupt=${CAN1_INTERRUPT_PIN}" >>$CONFIG
elif [ "${ENABLE_CAN}" = "1" ]; then
    echo "dtoverlay=mcp2515-can0,oscillator=${CAN_OSCILLATOR},interrupt=${CAN0_INTERRUPT_PIN}" >>$CONFIG
fi
```

**문제**: `ENABLE_CAN=1`은 `mcp2515-can0` overlay를 추가합니다. **MCP2518FD가 아닙니다!**

### 2.3 Team2 저장소의 올바른 방법

```bbappend
// meta-HU/recipes-bsp/bootfiles/rpi-config_git.bbappend

ENABLE_SPI_BUS = "1"
ENABLE_I2C = "1"

do_deploy:append() {
    echo "dtoverlay=mcp251xfd,spi0-0,interrupt=25" >> $CONFIG
    echo "dtoverlay=mcp251xfd,spi1-0,interrupt=24" >> $CONFIG
}
```

**핵심**: `ENABLE_CAN`을 사용하지 않고, **직접 mcp251xfd overlay를 추가**합니다!

## 3. 커널 설정 문제 분석

### 3.1 현재 커널 설정 방법
```bbappend
// meta-vehiclecontrol/recipes-kernel/linux/linux-raspberrypi_%.bbappend

SRC_URI += "file://spi-can.cfg"

do_configure:append() {
    echo "CONFIG_CAN_MCP251XFD=m" >> ${B}/.config
    oe_runmake -C ${S} O=${B} olddefconfig
}
```

**문제**: 
1. `.cfg` 파일이 적용되지 않음
2. `do_configure:append()`에서 직접 추가해도 적용 안됨
3. 근본 원인: **Yocto 커널 빌드 순서 문제**

### 3.2 올바른 Yocto 커널 설정 방법

#### 참고: Head-Unit-Team1의 설정
```bb
// meta-raspberrypi/recipes-kernel/linux/linux-raspberrypi_5.15.bb

SRC_URI = "git://... \
           file://powersave.cfg \
           file://android-drivers.cfg \
"
```

**핵심**: Yocto 커널은 `SRC_URI`에 추가된 `.cfg` 파일을 **자동으로 처리**합니다.

#### 문제가 되는 부분
```bash
# 현재 설정
SRC_URI += "file://spi-can.cfg"

# 파일 위치
meta-vehiclecontrol/recipes-kernel/linux/files/spi-can.cfg
```

**확인 필요**: 파일 경로와 FILESEXTRAPATHS가 올바른가?

## 4. 근본 원인 분석

### 4.1 CAN이 안 되는 이유
1. ❌ **Device Tree Overlay가 잘못됨**: `mcp2515-can0` 사용 (MCP2518FD 아님)
2. ❌ **커널 드라이버가 컴파일 안됨**: `mcp251xfd.ko` 없음
3. ❌ **커널 모듈이 포함 안됨**: `kernel-modules` 패키지 누락

### 4.2 WiFi가 안 되는 이유
1. ❌ **kmod 패키지 없음**: `modprobe`, `lsmod` 명령어 없음
2. ❌ **kernel-modules 없음**: WiFi 드라이버(`brcmfmac.ko`) 없음
3. ❌ **wpa_supplicant 설정 파일 없음**: `/etc/wpa_supplicant/` 디렉토리 없음
4. ❌ **DISTRO_FEATURES 누락**: `bluetooth wifi` 없었음 (최근 추가됨)

## 5. 해결 방안

### 5.1 즉시 수정해야 할 사항

#### A. local.conf 수정
```bash
# ❌ 제거
# ENABLE_CAN = "1"

# ✅ 추가 (이미 되어있음)
DISTRO_FEATURES:append = " systemd opengl bluetooth wifi"
MACHINE_FEATURES:append = " bluetooth wifi"

# SPI/I2C만 활성화
ENABLE_SPI_BUS = "1"
ENABLE_I2C = "1"
```

#### B. rpi-config_git.bbappend 생성
```bash
# 경로: meta-vehiclecontrol/recipes-bsp/bootfiles/rpi-config_git.bbappend

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

do_deploy:append() {
    # MCP2518FD overlay 추가
    echo "# Enable MCP2518FD CAN controller" >> $CONFIG
    echo "dtoverlay=mcp251xfd,spi0-0,interrupt=25,oscillator=40000000" >> $CONFIG
}
```

#### C. vehiclecontrol-image.bb (이미 수정됨)
```bb
IMAGE_INSTALL:append = " \
    kmod \                    # ✅ modprobe, lsmod 명령어
    kernel-modules \          # ✅ 모든 커널 모듈 (WiFi, CAN 포함)
    linux-firmware \          # ✅ WiFi 펌웨어
    wpa-supplicant \
    dhcpcd \
    wifi-autoconnect \
    ...
"
```

### 5.2 커널 설정 확인

#### 방법 1: KERNEL_FEATURES 사용 (권장)
```bb
// meta-vehiclecontrol/recipes-kernel/linux/linux-raspberrypi_%.bbappend

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# cfg 파일을 KERNEL_FEATURES로 추가
KERNEL_FEATURES:append = " ${THISDIR}/files/spi-can.cfg"
```

#### 방법 2: defconfig 사용
```bb
SRC_URI += "file://defconfig"

# defconfig 파일에 모든 설정 포함
do_configure:prepend() {
    if [ -f ${WORKDIR}/defconfig ]; then
        cp ${WORKDIR}/defconfig ${B}/.config
    fi
}
```

### 5.3 검증 방법

#### 빌드 후 확인
```bash
# 1. 커널 모듈 확인
find ~/yocto/build-ecu1/tmp/deploy/images/raspberrypi4-64/ -name "modules-*.tgz"
tar -tzf modules-*.tgz | grep -E "mcp251|brcmfmac"

# 2. Device Tree Overlay 확인
ls ~/yocto/build-ecu1/tmp/deploy/images/raspberrypi4-64/bcm2711-rpi-4-b.dtb
ls ~/yocto/build-ecu1/tmp/deploy/images/raspberrypi4-64/overlays/

# 3. config.txt 확인
cat ~/yocto/build-ecu1/tmp/deploy/images/raspberrypi4-64/bootfiles/config.txt | grep -E "can|mcp"
```

#### 라즈베리파이에서 확인
```bash
# 1. modprobe 명령어 확인
which modprobe

# 2. 커널 모듈 로드
modprobe mcp251xfd
modprobe brcmfmac

# 3. 드라이버 확인
lsmod | grep -E "mcp251|brcmfmac"

# 4. 인터페이스 확인
ip link show can0
ip link show wlan0

# 5. dmesg 확인
dmesg | grep -i "mcp251"
dmesg | grep -i "brcmfmac"
```

## 6. Yocto 공식 가이드 준수 사항

### 6.1 Kernel Configuration
- ✅ `.cfg` 파일을 `SRC_URI`에 추가
- ✅ `KERNEL_FEATURES`를 사용하여 기능 추가
- ❌ `do_configure:append()`에서 직접 `.config` 수정 (권장하지 않음)

### 6.2 Device Tree Overlays
- ✅ BSP 레이어의 `rpi-config_git.bbappend` 사용
- ✅ `RPI_EXTRA_CONFIG` 또는 `do_deploy:append()` 사용
- ❌ 커스텀 overlay를 별도로 컴파일 (필요시에만)

### 6.3 Image Configuration
- ✅ `IMAGE_INSTALL`에 필요한 패키지 추가
- ✅ `kernel-modules` 패키지로 모든 모듈 포함
- ✅ `DISTRO_FEATURES`와 `MACHINE_FEATURES` 일치

## 7. 최종 체크리스트

### 빌드 전 확인
- [ ] `local.conf`에서 `ENABLE_CAN = "1"` 제거
- [ ] `rpi-config_git.bbappend`에 `mcp251xfd` overlay 추가
- [ ] `vehiclecontrol-image.bb`에 `kmod`, `kernel-modules` 포함
- [ ] WiFi 비밀번호 설정 (`wpa_supplicant-wlan0.conf`)
- [ ] `DISTRO_FEATURES`에 `bluetooth wifi` 포함

### 빌드 중 확인
- [ ] `spi-can.cfg`가 커널 빌드에 포함되는지 로그 확인
- [ ] `mcp251xfd.ko` 모듈이 컴파일되는지 확인
- [ ] `brcmfmac.ko` 모듈이 포함되는지 확인

### 빌드 후 확인
- [ ] `config.txt`에 `dtoverlay=mcp251xfd` 존재
- [ ] `modules-*.tgz`에 `mcp251xfd.ko` 포함
- [ ] `modules-*.tgz`에 `brcmfmac.ko` 포함

### 라즈베리파이에서 확인
- [ ] `modprobe` 명령어 존재
- [ ] `can0` 인터페이스 존재
- [ ] `wlan0` 인터페이스 존재
- [ ] `lsmod | grep mcp251xfd` 결과 있음
- [ ] `lsmod | grep brcmfmac` 결과 있음

## 8. 참고 자료

### 공식 문서
- Yocto Kernel Development Manual: https://docs.yoctoproject.org/kernel-dev/
- meta-raspberrypi CAN Documentation: https://github.com/agherzan/meta-raspberrypi/blob/master/docs/extra-build-config.md#enable-can

### 유사 프로젝트
- Team2-DES-Head-Unit: `poky/meta-HU/recipes-bsp/bootfiles/rpi-config_git.bbappend`
- Head-Unit-Team1: kernel configuration 방식
- meta-raspberrypi: CAN enable configuration

### MCP2518FD 사양
- Controller: Microchip MCP2518FD
- Interface: SPI (up to 20MHz)
- CAN FD: Supported
- Oscillator: 40MHz
- Interrupt: Active low
- Driver: `mcp251xfd` (Linux kernel mainline)

## 9. 다음 단계

1. **즉시 실행**:
   ```bash
   # rpi-config_git.bbappend 생성
   # local.conf에서 ENABLE_CAN 제거
   # 다시 빌드
   ```

2. **빌드 완료 후**:
   ```bash
   # 이미지 플래시
   # 라즈베리파이 부팅
   # 위의 검증 방법 실행
   ```

3. **문제 발생 시**:
   ```bash
   # 커널 .config 확인
   # Device Tree 확인
   # dmesg 로그 분석
   ```
