# 적용된 변경 사항 (2025-01-14)

## 문제 요약
1. **CAN 드라이버**: MCP2518FD 하드웨어인데 `ENABLE_CAN=1`이 MCP2515용 overlay를 추가함
2. **WiFi/Bluetooth**: `kmod` + `kernel-modules` 패키지 누락으로 드라이버 로드 불가
3. **커널 설정**: `.cfg` 파일이 적용되지 않음

## 적용된 해결책

### 1. local.conf 수정
**위치**: `~/yocto/build-ecu1/conf/local.conf`

**변경 전**:
```bash
ENABLE_CAN = "1"  # ❌ MCP2515용 overlay 추가됨
CAN_OSCILLATOR = "40000000"
CAN0_INTERRUPT_PIN = "25"
```

**변경 후**:
```bash
# ❌ ENABLE_CAN 제거 - MCP2515용이므로 사용하지 않음
# ✅ 대신 rpi-config_git.bbappend에서 MCP251XFD overlay 추가

# SPI/I2C만 활성화
ENABLE_SPI_BUS = "1"
ENABLE_I2C = "1"

# 커널 모듈 자동 로드
KERNEL_MODULE_AUTOLOAD:rpi += "can can-dev can-raw mcp251xfd"
```

**근거**: 
- `ENABLE_CAN=1`은 meta-raspberrypi에서 `dtoverlay=mcp2515-can0`를 추가
- MCP2518FD는 `mcp251xfd` 드라이버 필요
- Team2 저장소 참고 (직접 overlay 추가)

### 2. rpi-config_git.bbappend 수정
**위치**: `meta/meta-vehiclecontrol/recipes-bsp/bootfiles/rpi-config_git.bbappend`

**추가된 내용**:
```bbappend
do_deploy:append:raspberrypi4-64() {
    # ... (기존 I2C, GPIO, Bluetooth 설정) ...
    
    # ========================================
    # MCP2518FD CAN Controller (Team2 방식)
    # ========================================
    # 중요: ENABLE_CAN=1은 MCP2515용이므로 사용하지 않음
    # 대신 meta-raspberrypi의 built-in mcp251xfd overlay 사용
    echo "" >> ${DEPLOYDIR}/${BOOTFILES_DIR_NAME}/config.txt
    echo "# MCP2518FD CAN Controller" >> ${DEPLOYDIR}/${BOOTFILES_DIR_NAME}/config.txt
    echo "dtoverlay=mcp251xfd,spi0-0,interrupt=25,oscillator=40000000" >> ${DEPLOYDIR}/${BOOTFILES_DIR_NAME}/config.txt
}
```

**효과**:
- `/boot/config.txt`에 올바른 overlay 추가
- MCP2518FD 하드웨어 매개변수 정확히 전달
  - `spi0-0`: SPI0 CS0
  - `interrupt=25`: GPIO 25
  - `oscillator=40000000`: 40MHz 크리스탈

### 3. vehiclecontrol-image.bb (이미 수정 완료)
**위치**: `meta/meta-vehiclecontrol/recipes-core/images/vehiclecontrol-image.bb`

**핵심 패키지**:
```bb
IMAGE_INSTALL:append = " \
    kmod \                    # modprobe, lsmod, rmmod 명령어
    kernel-modules \          # 모든 컴파일된 커널 모듈 포함
    linux-firmware \          # WiFi/Bluetooth 펌웨어
    wpa-supplicant \
    wifi-autoconnect \
    can-utils \
    ...
"
```

## 예상 결과

### 빌드 후 확인사항
```bash
# 1. config.txt 확인
cat /path/to/bootfiles/config.txt | grep mcp251xfd
# 출력: dtoverlay=mcp251xfd,spi0-0,interrupt=25,oscillator=40000000

# 2. 커널 모듈 확인
tar -tzf modules-*.tgz | grep mcp251xfd
# 출력: lib/modules/5.15.92/kernel/drivers/net/can/spi/mcp251xfd.ko

# 3. WiFi 모듈 확인
tar -tzf modules-*.tgz | grep brcmfmac
# 출력: lib/modules/5.15.92/kernel/drivers/net/wireless/broadcom/brcm80211/brcmfmac/brcmfmac.ko
```

### 라즈베리파이에서 확인사항
```bash
# 1. modprobe 명령어 존재 확인
which modprobe
# 출력: /usr/sbin/modprobe

# 2. 커널 모듈 로드 확인
lsmod | grep -E "mcp251|brcmfmac"
# 출력:
# mcp251xfd           ...
# brcmfmac            ...

# 3. CAN 인터페이스 확인
ip link show can0
# 출력: can0: <NOARP,ECHO> ...

# 4. WiFi 인터페이스 확인
ip link show wlan0
# 출력: wlan0: <BROADCAST,MULTICAST> ...

# 5. dmesg 확인
dmesg | grep -i "mcp251xfd"
# 출력: mcp251xfd spi0.0: MCP2518FD successfully initialized

dmesg | grep -i "brcmfmac"
# 출력: brcmfmac: Firmware loaded successfully
```

### CAN 통신 테스트
```bash
# 1. CAN 인터페이스 설정 (1000kbps)
ip link set can0 type can bitrate 1000000
ip link set can0 up

# 2. CAN 데이터 수신 (아두이노 speed 데이터)
candump can0
# 출력: can0  0F6   [8]  XX XX XX XX XX XX XX XX
```

### WiFi 연결 테스트
```bash
# 1. WiFi 상태 확인
wpa_cli status
# 출력: ssid=SEA:ME WiFi Access
#       wpa_state=COMPLETED

# 2. IP 주소 확인
ip addr show wlan0
# 출력: inet 192.168.x.x/24 ...

# 3. 인터넷 연결 확인
ping -c 3 8.8.8.8
# 출력: 3 packets transmitted, 3 received
```

## 참고 자료

### Team2 저장소 분석
- Repository: Team2-DES-Head-Unit/DES_Head-Unit
- File: `meta-HU/recipes-bsp/bootfiles/rpi-config_git.bbappend`
- 방법: Built-in `mcp251xfd` overlay 사용 (커스텀 DTS 아님)

### meta-raspberrypi 공식 문서
- File: `docs/extra-build-config.md`
- CAN 설정: `ENABLE_CAN` 변수는 MCP2515용
- MCP251XFD: 별도 overlay 필요 (`mcp251xfd`)

### Device Tree Overlay 확인
```bash
# meta-raspberrypi에 포함된 overlay들
ls poky/meta-raspberrypi/recipes-kernel/linux/linux-raspberrypi/overlays/
# 출력:
# mcp2515-can0.dtbo  ← ENABLE_CAN=1이 사용
# mcp251xfd.dtbo     ← 우리가 사용해야 할 것
```

## 다음 단계

1. **빌드 완료 대기**
2. **이미지 플래시**: `sudo dd if=vehiclecontrol-image-*.wic.bz2 of=/dev/sdX bs=4M status=progress`
3. **부팅 및 검증**: 위의 확인사항들 실행
4. **문제 발생 시**: `dmesg`, `journalctl -xe` 로그 분석

## 백업
- `local.conf.backup_enable_can`: ENABLE_CAN 사용하던 이전 설정
- `COMPREHENSIVE_ANALYSIS.md`: 전체 분석 문서
