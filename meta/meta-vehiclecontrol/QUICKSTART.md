# ECU1 (VehicleControl ECU) - 빠른 시작 가이드

Raspberry Pi 4용 VehicleControl ECU Yocto 이미지 빌드 가이드입니다.

## 📋 사전 요구사항

### 시스템 요구사항
- **OS**: Ubuntu 20.04 / 22.04 LTS
- **디스크 공간**: 100GB 이상
- **RAM**: 8GB 이상 (16GB 권장)
- **CPU**: 멀티코어 프로세서 (빌드 시간 단축)
- **인터넷**: 안정적인 연결 (첫 빌드 시 많은 패키지 다운로드)

### 필수 패키지 설치

```bash
sudo apt-get update
sudo apt-get install -y \
    gawk wget git diffstat unzip texinfo gcc build-essential \
    chrpath socat cpio python3 python3-pip python3-pexpect \
    xz-utils debianutils iputils-ping python3-git python3-jinja2 \
    libegl1-mesa libsdl1.2-dev pylint3 xterm python3-subunit \
    mesa-common-dev zstd liblz4-tool
```

## 🚀 빠른 빌드 (3단계)

### 1단계: 소스 준비

```bash
cd /home/seame/HU/DES_Head-Unit/meta/meta-vehiclecontrol
./tools/prepare-sources.sh
```

이 스크립트는 VehicleControlECU 소스와 CommonAPI 생성 코드를 recipe로 복사합니다.

### 2단계: 빌드 환경 설정

```bash
cd /home/seame/HU/DES_Head-Unit/meta/meta-vehiclecontrol
./tools/setup-build-env.sh
```

이 스크립트는 자동으로:
- ✅ Yocto Kirkstone 레이어 클론 (poky, meta-raspberrypi, meta-openembedded)
- ✅ 빌드 디렉토리 생성 (`~/yocto/build-ecu1`)
- ✅ 필요한 레이어 추가
- ✅ `local.conf` 설정 (MACHINE, systemd 등)

**⏱️ 첫 실행 시 레이어 클론에 10-30분 소요될 수 있습니다.**

### 3단계: 이미지 빌드

빌드 환경 설정 스크립트 실행 후 자동으로 빌드 디렉토리로 이동됩니다:

```bash
# 전체 이미지 빌드
bitbake vehiclecontrol-image
```

**⏱️ 예상 빌드 시간:**
- 첫 빌드: 2-4시간 (패키지 다운로드 포함)
- 재빌드: 10-30분 (변경사항만)

## 📦 빌드 결과물

빌드가 완료되면 다음 위치에서 이미지를 찾을 수 있습니다:

```bash
cd ~/yocto/build-ecu1/tmp/deploy/images/raspberrypi4-64/
ls -lh *.rpi-sdimg
```

파일: `vehiclecontrol-image-raspberrypi4-64-<timestamp>.rootfs.rpi-sdimg`

## 💾 SD 카드 플래싱

### SD 카드 장치 확인

```bash
lsblk
```

예시 출력:
```
NAME   MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
sda      8:0    0 238.5G  0 disk 
└─sda1   8:1    0 238.5G  0 part /
sdb      8:16   1  29.7G  0 disk    ← SD 카드
└─sdb1   8:17   1  29.7G  0 part
```

### 이미지 플래싱

```bash
cd ~/yocto/build-ecu1/tmp/deploy/images/raspberrypi4-64/

# ⚠️ 주의: /dev/sdX를 실제 SD 카드 장치로 변경!
sudo dd if=vehiclecontrol-image-raspberrypi4-64.rootfs.rpi-sdimg \
    of=/dev/sdX bs=4M status=progress conv=fsync

# 동기화
sync
```

## 🔌 첫 부팅 및 확인

### 네트워크 설정

Raspberry Pi를 네트워크에 연결합니다:
- 이더넷 케이블로 직접 연결 또는
- DHCP가 있는 로컬 네트워크에 연결

### SSH 접속

```bash
# Raspberry Pi 부팅 후 (약 30초~1분)
# IP 주소는 DHCP로 할당되거나 정적 IP 사용
ssh root@<raspberry-pi-ip>

# 기본 비밀번호: raspberry
```

IP 주소를 모르는 경우:
```bash
# 네트워크 스캔 (nmap 필요)
sudo nmap -sn 192.168.1.0/24
```

### 서비스 상태 확인

```bash
# VehicleControlECU 서비스 상태
systemctl status vehiclecontrol-ecu

# 실시간 로그 확인
journalctl -u vehiclecontrol-ecu -f

# vsomeip 설정 확인
cat /etc/vsomeip/vsomeip_ecu1.json

# CommonAPI 설정 확인
cat /etc/commonapi/commonapi_ecu1.ini
```

### 서비스 제어

```bash
# 서비스 시작
systemctl start vehiclecontrol-ecu

# 서비스 중지
systemctl stop vehiclecontrol-ecu

# 서비스 재시작
systemctl restart vehiclecontrol-ecu

# 부팅 시 자동 시작 활성화
systemctl enable vehiclecontrol-ecu
```

## 🛠️ 개발 워크플로우

### 코드 수정 후 재빌드

1. **소스 코드 수정** (`app/VehicleControlECU/src/`)
2. **소스 재준비**:
   ```bash
   cd /home/seame/HU/DES_Head-Unit/meta/meta-vehiclecontrol
   ./tools/prepare-sources.sh
   ```
3. **재빌드**:
   ```bash
   cd ~/yocto/build-ecu1
   source ../poky/oe-init-build-env .
   bitbake -c cleanall vehiclecontrol-ecu
   bitbake vehiclecontrol-ecu
   ```

### 개별 패키지 빌드 (디버깅용)

```bash
# vsomeip만 빌드
bitbake vsomeip

# CommonAPI Core만 빌드
bitbake commonapi-core

# VehicleControlECU만 빌드
bitbake vehiclecontrol-ecu

# 의존성 확인
bitbake-layers show-recipes vehiclecontrol-ecu
bitbake -e vehiclecontrol-ecu | grep ^DEPENDS=
```

### 빌드 캐시 정리

```bash
# 특정 패키지만 클린
bitbake -c cleanall vehiclecontrol-ecu

# 전체 빌드 클린 (주의!)
rm -rf ~/yocto/build-ecu1/tmp
```

## 📊 빌드 문제 해결

### 빌드 실패 시

```bash
# 자세한 로그 확인
bitbake vehiclecontrol-image -v

# 에러 로그 위치
cat ~/yocto/build-ecu1/tmp/log/cooker/raspberrypi4-64/*.log
```

### 디스크 공간 부족

```bash
# 다운로드 캐시 정리
rm -rf ~/yocto/build-ecu1/downloads/*

# sstate 캐시 정리
rm -rf ~/yocto/build-ecu1/sstate-cache/*
```

### 네트워크 다운로드 실패

```bash
# 프록시 설정이 필요한 경우 local.conf에 추가
# http_proxy = "http://proxy.example.com:8080"
# https_proxy = "http://proxy.example.com:8080"
```

## 📁 주요 디렉토리 구조

```
~/yocto/
├── poky/                          # Yocto Project 코어
├── meta-raspberrypi/              # Raspberry Pi BSP 레이어
├── meta-openembedded/             # 추가 패키지 레이어
│   └── meta-oe/
└── build-ecu1/                    # 빌드 디렉토리
    ├── conf/
    │   ├── local.conf            # 로컬 빌드 설정
    │   └── bblayers.conf         # 레이어 설정
    ├── downloads/                 # 다운로드된 소스
    ├── sstate-cache/              # 공유 상태 캐시
    └── tmp/
        └── deploy/
            └── images/
                └── raspberrypi4-64/
                    └── *.rpi-sdimg   # 최종 이미지
```

## 🔗 관련 문서

- **상세 빌드 가이드**: `빌드가이드.md`
- **문제 해결**: `문제해결.md`
- **메인 README**: `README.md`
- **전체 프로젝트**: `/home/seame/HU/DES_Head-Unit/README.md`

## 📞 지원

문제가 발생하면:
1. `문제해결.md` 확인
2. 빌드 로그 검토
3. GitHub Issues 확인

---

**Happy Building! 🚀**
