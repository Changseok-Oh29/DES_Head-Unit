# ECU1 Yocto Build - 개발 일지

## 2025년 11월 10일 - ECU1 Yocto 이미지 빌드 환경 구축 완료

### 📋 작업 개요
ECU1 (VehicleControl ECU)의 Yocto 이미지 빌드 환경을 완전히 구축하고, 첫 빌드를 시작함.

### ✅ 완료된 작업

#### 1. 소스 준비 및 레이어 검증
```bash
cd /home/seame/HU/DES_Head-Unit/meta/meta-vehiclecontrol
./tools/prepare-sources.sh
./tools/verify-layer.sh
```

**결과:**
- VehicleControlECU 소스 코드 recipe로 복사 완료
- CommonAPI 생성 코드 복사 완료
- 레이어 구조 검증 통과

#### 2. Yocto Kirkstone 레이어 클론
```bash
mkdir -p ~/yocto && cd ~/yocto
git clone -b kirkstone git://git.yoctoproject.org/poky
git clone -b kirkstone https://github.com/agherzan/meta-raspberrypi.git
git clone -b kirkstone https://github.com/openembedded/meta-openembedded.git
```

**설치된 레이어:**
- poky: Yocto Project 코어 (Kirkstone 4.0.31)
- meta-raspberrypi: Raspberry Pi BSP
- meta-openembedded/meta-oe: 추가 패키지

#### 3. Yocto Kirkstone 문법 호환성 수정

**문제:** Yocto Kirkstone은 새로운 override 문법을 사용
- 구 문법: `_append`, `_prepend`, `_${PN}`
- 신 문법: `:append`, `:prepend`, `:${PN}`

**수정된 파일들:**

##### a. setup-build-env.sh
```bash
# 수정 전
DISTRO_FEATURES_append = " systemd"

# 수정 후
DISTRO_FEATURES:append = " systemd"
```

##### b. vehiclecontrol-image.bb
```bash
vim /home/seame/HU/DES_Head-Unit/meta/meta-vehiclecontrol/recipes-core/images/vehiclecontrol-image.bb
```
수정 사항:
- `IMAGE_INSTALL_append` → `IMAGE_INSTALL:append`
- `DISTRO_FEATURES_append` → `DISTRO_FEATURES:append`
- `tcpdump` 제거 (meta-networking 레이어 필요)

##### c. vehiclecontrol-ecu_1.0.bb
```bash
vim /home/seame/HU/DES_Head-Unit/meta/meta-vehiclecontrol/recipes-vehiclecontrol/vehiclecontrol-ecu/vehiclecontrol-ecu_1.0.bb
```
수정 사항:
- `SYSTEMD_SERVICE_${PN}` → `SYSTEMD_SERVICE:${PN}`
- `do_install_append()` → `do_install:append()`
- `FILES_${PN}` → `FILES:${PN}`
- `RDEPENDS_${PN}` → `RDEPENDS:${PN}`
- `cmake_qt5` → `cmake` (Qt5 미사용)
- `qtbase` 의존성 제거

##### d. packagegroup-vehiclecontrol.bb
```bash
vim /home/seame/HU/DES_Head-Unit/meta/meta-vehiclecontrol/recipes-core/packagegroups/packagegroup-vehiclecontrol.bb
```
추가 사항:
```bash
PACKAGES = "\
    ${PN} \
    ${PN}-connectivity \
    ${PN}-hardware \
    ${PN}-system \
"
```
문법 수정:
- `RDEPENDS_${PN}` → `RDEPENDS:${PN}`

##### e. systemd_%.bbappend
```bash
vim /home/seame/HU/DES_Head-Unit/meta/meta-vehiclecontrol/recipes-core/systemd/systemd_%.bbappend
```
수정 사항:
- `do_install_append()` → `do_install:append()`
- `FILES_${PN}` → `FILES:${PN}`

##### f. rpi-config_git.bbappend
```bash
vim /home/seame/HU/DES_Head-Unit/meta/meta-vehiclecontrol/recipes-bsp/bootfiles/rpi-config_git.bbappend
```
수정 사항:
- `do_deploy_append_raspberrypi4-64()` → `do_deploy:append:raspberrypi4-64()`

##### g. 의존성 레시피들 일괄 수정
```bash
# vsomeip, commonapi, pigpio 레시피 문법 수정
sed -i 's/FILES_\${PN}/FILES:${PN}/g; s/RDEPENDS_\${PN}/RDEPENDS:${PN}/g' \
  /home/seame/HU/DES_Head-Unit/meta/meta-vehiclecontrol/recipes-connectivity/commonapi/*.bb \
  /home/seame/HU/DES_Head-Unit/meta/meta-vehiclecontrol/recipes-support/pigpio/*.bb
```

#### 4. Git 소스 SRCREV 수정

**문제:** 잘못된 커밋 해시로 인한 fetch 실패

**해결 방법:** GitHub에서 정확한 태그 커밋 해시 확인
```bash
git ls-remote https://github.com/COVESA/vsomeip.git | grep "refs/tags/3.5.8"
git ls-remote https://github.com/COVESA/capicxx-core-runtime.git | grep "refs/tags/3.2.4"
git ls-remote https://github.com/COVESA/capicxx-someip-runtime.git | grep "refs/tags/3.2.4"
```

##### a. vsomeip_3.5.8.bb
```bash
vim /home/seame/HU/DES_Head-Unit/meta/meta-vehiclecontrol/recipes-connectivity/vsomeip/vsomeip_3.5.8.bb
```
```bash
SRC_URI = "git://github.com/COVESA/vsomeip.git;protocol=https;branch=master"
SRCREV = "e89240c7d5d506505326987b6a2f848658230641"
PV = "3.5.8+git${SRCPV}"
```

##### b. commonapi-core_3.2.4.bb
```bash
vim /home/seame/HU/DES_Head-Unit/meta/meta-vehiclecontrol/recipes-connectivity/commonapi/commonapi-core_3.2.4.bb
```
```bash
SRC_URI = "git://github.com/COVESA/capicxx-core-runtime.git;protocol=https;branch=master"
SRCREV = "0e1d97ef0264622194a42f20be1d6b4489b310b5"
PV = "3.2.4+git${SRCPV}"
```

##### c. commonapi-someip_3.2.4.bb
```bash
vim /home/seame/HU/DES_Head-Unit/meta/meta-vehiclecontrol/recipes-connectivity/commonapi/commonapi-someip_3.2.4.bb
```
```bash
SRC_URI = "git://github.com/COVESA/capicxx-someip-runtime.git;protocol=https;branch=master"
SRCREV = "86dfd69802e673d00aed0062f41eddea4670b571"
PV = "3.2.4+git${SRCPV}"
```

#### 5. 빌드 환경 설정 및 빌드 시작

##### 빌드 환경 초기화
```bash
cd ~/yocto
source poky/oe-init-build-env build-ecu1
```

##### 레이어 추가
```bash
bitbake-layers add-layer ../meta-raspberrypi
bitbake-layers add-layer ../meta-openembedded/meta-oe
bitbake-layers add-layer /home/seame/HU/DES_Head-Unit/meta/meta-vehiclecontrol
```

##### 레이어 확인
```bash
bitbake-layers show-layers
```

출력:
```
layer                 path                                      priority
==========================================================================
meta                  /home/seame/yocto/poky/meta               5
meta-poky             /home/seame/yocto/poky/meta-poky          5
meta-yocto-bsp        /home/seame/yocto/poky/meta-yocto-bsp     5
meta-raspberrypi      /home/seame/yocto/meta-raspberrypi        9
meta-oe               /home/seame/yocto/meta-openembedded/meta-oe  5
meta-vehiclecontrol   /home/seame/HU/DES_Head-Unit/meta/meta-vehiclecontrol  8
```

##### local.conf 자동 설정 (수동으로 한 경우)
```bash
vim ~/yocto/build-ecu1/conf/local.conf
```

추가/수정 내용:
```bash
MACHINE = "raspberrypi4-64"

# Use systemd as init manager (Kirkstone syntax)
DISTRO_FEATURES:append = " systemd"
VIRTUAL-RUNTIME_init_manager = "systemd"
VIRTUAL-RUNTIME_initscripts = "systemd-compat-units"

# Build performance (adjust based on your CPU cores)
BB_NUMBER_THREADS = "8"
PARALLEL_MAKE = "-j 8"

# Disk space monitoring
BB_DISKMON_DIRS = "\
    STOPTASKS,${TMPDIR},1G,100K \
    STOPTASKS,${DL_DIR},1G,100K \
    STOPTASKS,${SSTATE_DIR},1G,100K"

# Package management
PACKAGE_CLASSES = "package_rpm"

# Image configuration
IMAGE_FSTYPES = "tar.bz2 ext4 rpi-sdimg"

# Development features (remove for production)
EXTRA_IMAGE_FEATURES += "debug-tweaks"

# License flags (accept all for development)
LICENSE_FLAGS_ACCEPTED = "commercial"

# Enable serial console
ENABLE_UART = "1"

# Build optimization
BB_SIGNATURE_HANDLER = "OEBasicHash"
BB_HASHSERVE = "auto"
```

##### 캐시 정리 (필요시)
```bash
cd ~/yocto/build-ecu1
rm -rf tmp/cache
```

##### 빌드 시작
```bash
cd ~/yocto
source poky/oe-init-build-env build-ecu1
bitbake vehiclecontrol-image
```

### 📊 빌드 정보

**빌드 환경:**
```
BB_VERSION           = "2.0.0"
BUILD_SYS            = "x86_64-linux"
NATIVELSBSTRING      = "universal"
TARGET_SYS           = "aarch64-poky-linux"
MACHINE              = "raspberrypi4-64"
DISTRO               = "poky"
DISTRO_VERSION       = "4.0.31"
TUNE_FEATURES        = "aarch64 armv8a crc cortexa72"
```

**레시피 파싱 결과:**
- 총 1785개 .bb 파일
- 2830개 타겟
- 102개 스킵
- 0개 에러 ✅

**빌드 통계:**
- 총 태스크: 4,518개
- Wanted: 1,486개
- Current: 298개 (16% 캐시됨)

### 🛠️ 생성된 자동화 스크립트

#### 1. prepare-sources.sh
VehicleControlECU 소스를 recipe로 복사
```bash
cd /home/seame/HU/DES_Head-Unit/meta/meta-vehiclecontrol
./tools/prepare-sources.sh
```

#### 2. setup-build-env.sh
Yocto 빌드 환경 자동 설정 (레이어 클론 포함)
```bash
cd /home/seame/HU/DES_Head-Unit/meta/meta-vehiclecontrol
./tools/setup-build-env.sh
```

#### 3. build-all.sh
전체 프로세스 자동화 (소스 준비 + 환경 설정)
```bash
cd /home/seame/HU/DES_Head-Unit/meta/meta-vehiclecontrol
./tools/build-all.sh
```

#### 4. start-build.sh
시스템 체크 + 대화형 메뉴
```bash
cd /home/seame/HU/DES_Head-Unit/meta/meta-vehiclecontrol
./tools/start-build.sh
```

#### 5. verify-layer.sh
레이어 구조 검증
```bash
cd /home/seame/HU/DES_Head-Unit/meta/meta-vehiclecontrol
./tools/verify-layer.sh
```

### 📚 생성된 문서

1. **BUILD_READY.md** - 전체 요약 및 시작 가이드
2. **QUICKSTART.md** - 빠른 시작 가이드 (초보자 권장)
3. **BUILD_CHECKLIST.md** - 상세 단계별 체크리스트
4. **빌드가이드.md** - 완전한 빌드 가이드
5. **문제해결.md** - 문제 해결 가이드

### 🔍 주요 학습 내용

#### Yocto Kirkstone 문법 변경사항
```bash
# 구 문법 (Dunfell 이하)
VARIABLE_append = " value"
VARIABLE_prepend = "value "
FILES_${PN} = "..."
do_task_append() { }

# 신 문법 (Kirkstone 이상)
VARIABLE:append = " value"
VARIABLE:prepend = "value "
FILES:${PN} = "..."
do_task:append() { }
```

#### Git 소스 fetch 방법
```bash
# 잘못된 방법 (태그와 AUTOREV 충돌)
SRC_URI = "git://...;tag=3.2.4"
SRCREV = "${AUTOREV}"

# 올바른 방법 (태그의 커밋 해시 사용)
SRC_URI = "git://...;branch=master"
SRCREV = "정확한_커밋_해시"
PV = "3.2.4+git${SRCPV}"
```

#### Packagegroup 서브패키지 정의
```bash
# PACKAGES 명시적 정의 필요
PACKAGES = "\
    ${PN} \
    ${PN}-connectivity \
    ${PN}-hardware \
    ${PN}-system \
"

RDEPENDS:${PN} = " \
    ${PN}-connectivity \
    ${PN}-hardware \
    ${PN}-system \
"
```

### 💡 재빌드 시 빠른 명령어

#### 컴퓨터 재시작 후 빌드 재개
```bash
# 1. 빌드 환경 로드
cd ~/yocto
source poky/oe-init-build-env build-ecu1

# 2. 빌드 계속
bitbake vehiclecontrol-image

# 3. 진행 상황 확인 (다른 터미널)
tail -f tmp/log/cooker/raspberrypi4-64/console-latest.log
```

#### 특정 패키지만 재빌드
```bash
cd ~/yocto/build-ecu1
source ../poky/oe-init-build-env .

# 클린 후 재빌드
bitbake -c cleanall vehiclecontrol-ecu
bitbake vehiclecontrol-ecu
```

#### 소스 수정 후 재빌드
```bash
# 1. 소스 수정 (app/VehicleControlECU/src/)
vim /home/seame/HU/DES_Head-Unit/app/VehicleControlECU/src/main.cpp

# 2. 소스 재준비
cd /home/seame/HU/DES_Head-Unit/meta/meta-vehiclecontrol
./tools/prepare-sources.sh

# 3. 재빌드
cd ~/yocto/build-ecu1
source ../poky/oe-init-build-env .
bitbake -c cleanall vehiclecontrol-ecu
bitbake vehiclecontrol-ecu
bitbake vehiclecontrol-image
```

#### 레시피 수정 후
```bash
# 1. 레시피 수정
vim /home/seame/HU/DES_Head-Unit/meta/meta-vehiclecontrol/recipes-vehiclecontrol/vehiclecontrol-ecu/vehiclecontrol-ecu_1.0.bb

# 2. 캐시 정리
cd ~/yocto/build-ecu1
rm -rf tmp/cache

# 3. 재빌드
source ../poky/oe-init-build-env .
bitbake vehiclecontrol-image
```

### 🐛 발생한 문제 및 해결

#### 문제 1: 구 문법 사용으로 인한 파싱 에러
```
ERROR: Variable DISTRO_FEATURES_append contains an operation using the old override syntax.
```
**해결:** 모든 `_append`, `_prepend` 등을 `:append`, `:prepend`으로 변경

#### 문제 2: Git fetch 실패 (잘못된 SRCREV)
```
ERROR: Unable to find revision 47a3bb0c1dc1b8c2de3e2e70b2e94e6b7d88ae13 in branch master
```
**해결:** GitHub에서 정확한 태그 커밋 확인
```bash
git ls-remote https://github.com/COVESA/capicxx-core-runtime.git | grep "refs/tags/3.2.4"
```

#### 문제 3: tcpdump RPROVIDES 에러
```
ERROR: Nothing RPROVIDES 'tcpdump'
```
**해결:** vehiclecontrol-image.bb에서 tcpdump 제거 (meta-networking 레이어 필요)

#### 문제 4: packagegroup 서브패키지 에러
```
ERROR: Nothing RPROVIDES 'packagegroup-vehiclecontrol-hardware'
```
**해결:** PACKAGES 변수 명시적 정의

#### 문제 5: Qt5 관련 cmake_qt5 클래스 없음
```
ERROR: Could not inherit file classes/cmake_qt5.bbclass
```
**해결:** VehicleControlECU는 QCoreApplication만 사용하므로 일반 cmake 상속으로 변경

### ⏱️ 빌드 시간

- **레이어 클론**: 10-30분 (처음 한 번만)
- **첫 빌드**: 2-4시간 예상
- **재빌드** (소스만 변경): 10-30분

### 📦 빌드 결과물 위치

```bash
~/yocto/build-ecu1/tmp/deploy/images/raspberrypi4-64/
└── vehiclecontrol-image-raspberrypi4-64.rootfs.rpi-sdimg
```

### 🔄 다음 단계 (빌드 완료 후)

1. **이미지 확인**
```bash
cd ~/yocto/build-ecu1/tmp/deploy/images/raspberrypi4-64/
ls -lh *.rpi-sdimg
```

2. **SD 카드 플래싱**
```bash
# SD 카드 장치 확인
lsblk

# 플래싱 (⚠️ /dev/sdX를 실제 장치로 변경!)
sudo dd if=vehiclecontrol-image-raspberrypi4-64.rootfs.rpi-sdimg \
    of=/dev/sdX bs=4M status=progress conv=fsync && sync
```

3. **부팅 및 테스트**
```bash
# SSH 접속 (Raspberry Pi 부팅 후)
ssh root@<raspberry-pi-ip>
# 비밀번호: raspberry

# 서비스 확인
systemctl status vehiclecontrol-ecu
journalctl -u vehiclecontrol-ecu -f
```

### 📝 참고사항

- **작업 디렉토리**: `/home/seame/HU/DES_Head-Unit/meta/meta-vehiclecontrol`
- **빌드 디렉토리**: `~/yocto/build-ecu1`
- **타겟 머신**: Raspberry Pi 4 (64-bit)
- **OS**: Yocto Kirkstone 4.0.31
- **Init 시스템**: systemd

### 🎯 핵심 명령어 요약

```bash
# === 준비 ===
cd /home/seame/HU/DES_Head-Unit/meta/meta-vehiclecontrol
./tools/prepare-sources.sh

# === 빌드 시작 ===
cd ~/yocto
source poky/oe-init-build-env build-ecu1
bitbake vehiclecontrol-image

# === 진행 상황 확인 (다른 터미널) ===
tail -f ~/yocto/build-ecu1/tmp/log/cooker/raspberrypi4-64/console-latest.log

# === 빌드 완료 후 ===
cd ~/yocto/build-ecu1/tmp/deploy/images/raspberrypi4-64/
ls -lh *.rpi-sdimg
```

---

**빌드 시작 시각**: 2025년 11월 10일
**빌드 상태**: 진행 중 (4,518개 태스크)
**예상 완료**: 2-4시간 후
