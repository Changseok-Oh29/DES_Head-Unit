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

## 🚀 빠른 시작 (3가지 방법)

### 방법 1: 전체 자동화 (권장)
```bash
cd /home/seame/HU/DES_Head-Unit/meta/meta-vehiclecontrol
./tools/build-all.sh
```
이 스크립트가 소스 준비와 빌드 환경 설정을 모두 수행합니다.

### 방법 2: 단계별 실행
```bash
# 1. 소스 준비
cd /home/seame/HU/DES_Head-Unit/meta/meta-vehiclecontrol
./tools/prepare-sources.sh

# 2. 빌드 환경 설정 (Yocto 레이어 자동 클론 포함)
./tools/setup-build-env.sh

# 3. 이미지 빌드 (위 스크립트 실행 후 자동으로 build 디렉토리에 위치)
bitbake vehiclecontrol-image
```

### 방법 3: 수동 설정 (고급 사용자)

상세한 수동 설정은 `빌드가이드.md`를 참조하세요.

## 📦 빌드 결과

빌드 완료 후:
```bash
cd ~/yocto/build-ecu1/tmp/deploy/images/raspberrypi4-64/
ls -lh *.rpi-sdimg
```

## 💾 SD 카드 플래싱

```bash
# SD 카드 장치 확인
lsblk

# 이미지 플래싱 (⚠️ /dev/sdX를 실제 SD 카드 장치로 변경!)
cd ~/yocto/build-ecu1/tmp/deploy/images/raspberrypi4-64/
sudo dd if=vehiclecontrol-image-raspberrypi4-64.rootfs.rpi-sdimg \
    of=/dev/sdX bs=4M status=progress conv=fsync && sync
```

⏱️ **빌드 시간**: 첫 빌드 2-4시간, 재빌드 10-30분

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

## 📚 문서

- **[QUICKSTART.md](QUICKSTART.md)** - 빠른 시작 가이드 (초보자 권장)
- **[빌드가이드.md](빌드가이드.md)** - 상세 빌드 방법 및 설정
- **[문제해결.md](문제해결.md)** - 자주 발생하는 문제 및 해결 방법

## 🛠️ 유틸리티 스크립트

### `tools/build-all.sh`
전체 빌드 프로세스 자동화 (소스 준비 + 환경 설정)

### `tools/prepare-sources.sh`
VehicleControlECU 소스를 recipe로 복사

### `tools/setup-build-env.sh`
Yocto 빌드 환경 자동 설정 (레이어 클론 포함)

### `tools/verify-layer.sh`
레이어 설정 검증

## 라이센스

MIT License

## 개발팀

SEA:ME DES Project Team
```
