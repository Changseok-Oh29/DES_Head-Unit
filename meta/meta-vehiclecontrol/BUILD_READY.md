# ECU1 Yocto 이미지 빌드 - 최종 요약

## ✅ 준비 완료 상태

ECU1 (VehicleControl ECU)의 Yocto 이미지 빌드를 위한 모든 파일과 스크립트가 준비되었습니다.

### 📁 준비된 구조

```
meta/meta-vehiclecontrol/
├── README.md                    # 레이어 개요
├── QUICKSTART.md                # 빠른 시작 가이드 ⭐
├── BUILD_CHECKLIST.md           # 상세 체크리스트
├── 빌드가이드.md                # 전체 빌드 가이드
├── 문제해결.md                  # 문제 해결 가이드
│
├── conf/
│   └── layer.conf              # 레이어 설정
│
├── recipes-vehiclecontrol/
│   └── vehiclecontrol-ecu/
│       ├── vehiclecontrol-ecu_1.0.bb
│       └── files/              # ✅ 소스 준비 완료
│           ├── src/
│           ├── lib/
│           ├── commonapi-generated/
│           ├── config/
│           └── CMakeLists.txt
│
├── recipes-connectivity/
│   ├── vsomeip/                # vsomeip 3.5.8
│   └── commonapi/              # CommonAPI 3.2.4
│
├── recipes-support/
│   └── pigpio/                 # GPIO 라이브러리
│
├── recipes-core/
│   ├── images/
│   │   └── vehiclecontrol-image.bb
│   └── packagegroups/
│       └── packagegroup-vehiclecontrol.bb
│
└── tools/
    ├── start-build.sh          # 🚀 여기서 시작! (권장)
    ├── build-all.sh            # 전체 자동화
    ├── prepare-sources.sh      # 소스 준비
    ├── setup-build-env.sh      # 환경 설정
    └── verify-layer.sh         # 레이어 검증 ✅
```

## 🚀 빌드 시작 방법

### 가장 쉬운 방법 (권장) ⭐

```bash
cd /home/seame/HU/DES_Head-Unit/meta/meta-vehiclecontrol
./tools/start-build.sh
```

이 스크립트가:
- ✅ 시스템 요구사항 자동 체크
- ✅ 디스크 공간, RAM, CPU 확인
- ✅ 필수 패키지 자동 설치 옵션
- ✅ 빌드 옵션 대화형 선택
- ✅ 적절한 스크립트로 자동 연결

### 빠른 자동 빌드

```bash
cd /home/seame/HU/DES_Head-Unit/meta/meta-vehiclecontrol
./tools/build-all.sh
```

자동으로:
1. 소스 준비 (`prepare-sources.sh`)
2. 빌드 환경 설정 (`setup-build-env.sh`)
3. 빌드 명령 가이드 제공

### 단계별 실행

```bash
# 1. 소스 준비
cd /home/seame/HU/DES_Head-Unit/meta/meta-vehiclecontrol
./tools/prepare-sources.sh

# 2. 빌드 환경 설정
./tools/setup-build-env.sh

# 3. 이미지 빌드 (위 스크립트 실행 후)
bitbake vehiclecontrol-image
```

## 📋 빌드 프로세스 요약

### Phase 1: 준비 (완료 ✅)
- [x] VehicleControlECU 소스 코드 복사
- [x] CommonAPI 생성 코드 복사
- [x] Recipe 파일 준비
- [x] 자동화 스크립트 생성

### Phase 2: 환경 설정 (자동화됨)
- [ ] Yocto Kirkstone 레이어 클론
  - poky
  - meta-raspberrypi
  - meta-openembedded
- [ ] 빌드 디렉토리 생성 (`~/yocto/build-ecu1`)
- [ ] 레이어 추가 및 설정
- [ ] `local.conf` 자동 설정

⏱️ **예상 시간**: 10-30분 (레이어 클론)

### Phase 3: 빌드
```bash
bitbake vehiclecontrol-image
```

⏱️ **예상 시간**: 
- 첫 빌드: 2-4시간
- 재빌드: 10-30분

### Phase 4: 배포
```bash
# 이미지 위치
cd ~/yocto/build-ecu1/tmp/deploy/images/raspberrypi4-64/

# SD 카드 플래싱
sudo dd if=vehiclecontrol-image-raspberrypi4-64.rootfs.rpi-sdimg \
    of=/dev/sdX bs=4M status=progress conv=fsync && sync
```

## 📚 문서 가이드

### 초보자
1. **QUICKSTART.md** - 시작하기 (여기서 시작!)
2. **BUILD_CHECKLIST.md** - 체크리스트 따라하기

### 중급자
1. **빌드가이드.md** - 상세 빌드 과정
2. **문제해결.md** - 문제 발생 시

### 고급자
- **README.md** - 레이어 아키텍처
- 개별 recipe 파일 직접 수정

## 🎯 다음 단계

### 지금 바로 시작
```bash
cd /home/seame/HU/DES_Head-Unit/meta/meta-vehiclecontrol
./tools/start-build.sh
```

### 문서 먼저 읽기
```bash
cd /home/seame/HU/DES_Head-Unit/meta/meta-vehiclecontrol
cat QUICKSTART.md | less
```

## 💡 주요 기능

### ✅ 포함된 패키지
- **vsomeip** 3.5.8 - Service-Oriented Middleware
- **CommonAPI** 3.2.4 - Core & SOME/IP
- **pigpio** - Raspberry Pi GPIO 라이브러리
- **boost** - C++ 라이브러리
- **Qt5** - UI 프레임워크 (필요시)
- **systemd** - Init 시스템

### ✅ 서비스 설정
- VehicleControlECU systemd 서비스
- 자동 시작 활성화
- vsomeip 설정 파일 포함
- CommonAPI 설정 파일 포함

### ✅ 하드웨어 지원
- Raspberry Pi 4 (64-bit)
- I2C 장치 지원 (PCA9685, INA219)
- GPIO 접근 권한 설정
- 시리얼 콘솔 활성화

## 🔧 빌드 설정

### 타겟 머신
- **MACHINE**: raspberrypi4-64

### Init 시스템
- **systemd** 사용

### 이미지 타입
- `.rpi-sdimg` (SD 카드 직접 플래싱용)
- `.tar.bz2` (rootfs 압축)
- `.ext4` (루트 파일시스템)

### 루트 파일시스템
- 크기: 512MB (확장 가능)
- 추가 공간: 100MB

## 📊 시스템 요구사항

### 최소 사양
- Ubuntu 20.04 / 22.04 LTS
- 디스크: 100GB
- RAM: 8GB
- CPU: 멀티코어 (빌드 병렬화)

### 권장 사양
- 디스크: 150GB+
- RAM: 16GB
- CPU: 8코어 이상
- SSD 스토리지

## 🐛 문제 발생 시

### 빌드 실패
```bash
# 자세한 로그 확인
bitbake vehiclecontrol-image -v

# 패키지 클린 후 재시도
bitbake -c cleanall vehiclecontrol-ecu
bitbake vehiclecontrol-ecu
```

### 디스크 공간 부족
```bash
# 캐시 정리
rm -rf ~/yocto/build-ecu1/downloads/*
rm -rf ~/yocto/build-ecu1/sstate-cache/*
```

### 네트워크 문제
- 안정적인 인터넷 연결 확인
- 프록시 설정 필요 시 `local.conf`에 추가

### 자세한 도움말
**문제해결.md** 문서 참조

## 🎉 ECU2 비교

| 항목 | ECU1 (VehicleControl) | ECU2 (Head-Unit) |
|------|----------------------|------------------|
| **상태** | 빌드 준비 완료 🚀 | 빌드 완료 ✅ |
| **레이어** | meta-vehiclecontrol | meta-headunit |
| **역할** | Service Provider | Service Consumer |
| **하드웨어** | PiRacer + RPi4 | 터치스크린 + RPi4 |
| **앱** | VehicleControlECU | GearApp, MediaApp 등 |

## 📞 지원

- **문서**: 모든 문서가 `meta/meta-vehiclecontrol/` 안에 있습니다
- **스크립트**: `tools/` 디렉토리에 자동화 스크립트 제공
- **로그**: 빌드 로그는 `~/yocto/build-ecu1/tmp/log/` 참조

---

## 🚀 시작하세요!

```bash
cd /home/seame/HU/DES_Head-Unit/meta/meta-vehiclecontrol
./tools/start-build.sh
```

**Happy Building! 🎉**
