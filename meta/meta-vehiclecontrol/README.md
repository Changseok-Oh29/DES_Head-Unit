# meta-vehiclecontrol

ECU1 (VehicleControl ECU)용 Yocto 레이어 - PiRacer 차량 제어 시스템

## 개요

Raspberry Pi 4에서 실행되는 VehicleControl ECU를 위한 최소 Linux 이미지 빌드 레이어입니다.
vsomeip/CommonAPI 미들웨어를 사용하여 PiRacer 차량을 제어합니다.

## 시스템 구성

**ECU1 - VehicleControl ECU**
- **역할**: Service Provider + Routing Manager
- **하드웨어**: Raspberry Pi 4 + PiRacer AI Kit
- **통신**: vsomeip 3.5.8 + CommonAPI 3.2.4
- **주요 기능**:
  - 차량 제어 (조향, 스로틀, 기어 관리)
  - 배터리 모니터링 (INA219)
  - 게임패드 입력 처리
  - vsomeip 서비스 제공 (Service ID: 0x1234)

## 필수 레이어

**Yocto 4.0 Kirkstone (LTS)** 버전 사용:
- `meta` (poky) - **kirkstone** 브랜치
- `meta-raspberrypi` - **kirkstone** 브랜치
- `meta-openembedded/meta-oe` - **kirkstone** 브랜치

## 빠른 시작

### 1. 소스 준비
```bash
cd /home/leo/SEA-ME/DES_Head-Unit/meta/meta-vehiclecontrol
./tools/prepare-sources.sh
```

### 2. Yocto 레이어 클론 (처음 한 번만)
```bash
mkdir -p ~/yocto && cd ~/yocto
git clone -b kirkstone git://git.yoctoproject.org/poky
git clone -b kirkstone https://github.com/agherzan/meta-raspberrypi.git
git clone -b kirkstone https://github.com/openembedded/meta-openembedded.git
```

### 3. 빌드 환경 설정
```bash
cd ~/yocto
source poky/oe-init-build-env build-ecu1

bitbake-layers add-layer ../meta-raspberrypi
bitbake-layers add-layer ../meta-openembedded/meta-oe
bitbake-layers add-layer /home/leo/SEA-ME/DES_Head-Unit/meta/meta-vehiclecontrol
```

### 4. 설정 파일 수정
`conf/local.conf`에 추가:
```
MACHINE = "raspberrypi4-64"
DISTRO_FEATURES_append = " systemd"
VIRTUAL-RUNTIME_init_manager = "systemd"
```

### 5. 이미지 빌드
```bash
bitbake vehiclecontrol-image
```
⏱️ 예상 시간: 2-4시간 (첫 빌드)

### 6. SD 카드 플래싱
```bash
cd tmp/deploy/images/raspberrypi4-64
sudo dd if=vehiclecontrol-image-raspberrypi4-64.rpi-sdimg \
    of=/dev/sdX bs=4M status=progress && sync
```

## 포함된 패키지

### 통신 미들웨어
- `vsomeip` (3.5.8)
- `commonapi-core` (3.2.4)
- `commonapi-someip` (3.2.4)

### 하드웨어 지원
- `pigpio` - GPIO 제어 라이브러리

### 애플리케이션
- `vehiclecontrol-ecu` - 메인 차량 제어 애플리케이션

## 네트워크 설정

- **고정 IP**: 192.168.1.100/24
- **멀티캐스트 라우팅**: 224.0.0.0/4 (vsomeip Service Discovery용)

## 기본 계정

- **사용자명**: root
- **비밀번호**: raspberry

## 하드웨어 설정

- I2C 활성화 (400kHz)
- GPIO 접근 권한 설정
- 지원 장치:
  - PCA9685 (0x40) - 조향 서보
  - PCA9685 (0x60) - 모터 컨트롤러
  - INA219 (0x41) - 배터리 모니터

## 서비스

VehicleControl ECU는 systemd 서비스로 실행:
- **서비스명**: `vehiclecontrol-ecu.service`
- **자동 시작**: 활성화
- **재시작 정책**: on-failure

## 추가 문서

- **빌드가이드.md** - 상세 빌드 방법 및 설정
- **문제해결.md** - 자주 발생하는 문제 및 해결 방법

## 라이센스

MIT License

## 개발팀

SEA:ME DES Project Team
