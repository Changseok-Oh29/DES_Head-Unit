# ECU1 Yocto 이미지 빌드 체크리스트 ✅

ECU1 (VehicleControl ECU) Yocto 이미지 빌드를 위한 단계별 체크리스트입니다.

## 📋 사전 준비 (한 번만)

### ✅ 시스템 요구사항 확인
- [ ] Ubuntu 20.04 / 22.04 LTS
- [ ] 디스크 여유 공간: 100GB 이상
- [ ] RAM: 8GB 이상
- [ ] 안정적인 인터넷 연결

### ✅ 필수 패키지 설치
```bash
sudo apt-get update
sudo apt-get install -y \
    gawk wget git diffstat unzip texinfo gcc build-essential \
    chrpath socat cpio python3 python3-pip python3-pexpect \
    xz-utils debianutils iputils-ping python3-git python3-jinja2 \
    libegl1-mesa libsdl1.2-dev pylint3 xterm python3-subunit \
    mesa-common-dev zstd liblz4-tool
```
- [ ] 패키지 설치 완료

## 🚀 빌드 프로세스

### 방법 A: 전체 자동화 (권장) ⭐

```bash
cd /home/seame/HU/DES_Head-Unit/meta/meta-vehiclecontrol
./tools/build-all.sh
```

이 스크립트가 다음을 모두 수행합니다:
- [ ] 소스 준비 완료
- [ ] Yocto 레이어 클론 완료
- [ ] 빌드 환경 설정 완료

### 방법 B: 단계별 실행

#### Step 1: 소스 준비
```bash
cd /home/seame/HU/DES_Head-Unit/meta/meta-vehiclecontrol
./tools/prepare-sources.sh
```
- [ ] VehicleControlECU 소스 복사 완료
- [ ] CommonAPI 생성 코드 복사 완료
- [ ] CMakeLists.txt 복사 완료
- [ ] 설정 파일 복사 완료

#### Step 2: 레이어 검증
```bash
cd /home/seame/HU/DES_Head-Unit/meta/meta-vehiclecontrol
./tools/verify-layer.sh
```
- [ ] 레이어 구조 검증 통과
- [ ] 모든 레시피 파일 존재 확인

#### Step 3: 빌드 환경 설정
```bash
cd /home/seame/HU/DES_Head-Unit/meta/meta-vehiclecontrol
./tools/setup-build-env.sh
```

이 스크립트가 수행하는 작업:
- [ ] ~/yocto 디렉토리 생성
- [ ] Yocto Kirkstone poky 레이어 클론
- [ ] meta-raspberrypi 레이어 클론
- [ ] meta-openembedded 레이어 클론
- [ ] build-ecu1 빌드 디렉토리 생성
- [ ] 필요한 레이어 추가
- [ ] local.conf 설정 (MACHINE, systemd 등)

⏱️ **예상 시간**: 레이어 클론에 10-30분 소요

#### Step 4: 이미지 빌드

빌드 환경 설정 후 자동으로 build 디렉토리에 위치합니다:

```bash
# 전체 이미지 빌드
bitbake vehiclecontrol-image
```

⏱️ **예상 시간**: 
- 첫 빌드: 2-4시간 (패키지 다운로드 포함)
- 재빌드: 10-30분

- [ ] vehiclecontrol-image 빌드 시작
- [ ] 빌드 성공 확인

#### 선택: 개별 패키지 빌드 (디버깅용)
```bash
# vsomeip만 빌드
bitbake vsomeip

# CommonAPI만 빌드
bitbake commonapi-core
bitbake commonapi-someip

# VehicleControlECU만 빌드
bitbake vehiclecontrol-ecu
```

## 📦 빌드 결과 확인

```bash
cd ~/yocto/build-ecu1/tmp/deploy/images/raspberrypi4-64/
ls -lh *.rpi-sdimg
```

- [ ] `.rpi-sdimg` 이미지 파일 확인
- [ ] 이미지 크기 확인 (약 500MB~1GB)

예상 파일명: `vehiclecontrol-image-raspberrypi4-64-<timestamp>.rootfs.rpi-sdimg`

## 💾 SD 카드 플래싱

### Step 1: SD 카드 장치 확인
```bash
lsblk
```
- [ ] SD 카드 장치 식별 (예: /dev/sdb)

### Step 2: 이미지 플래싱
```bash
cd ~/yocto/build-ecu1/tmp/deploy/images/raspberrypi4-64/

# ⚠️ 주의: /dev/sdX를 실제 SD 카드 장치로 변경!
sudo dd if=vehiclecontrol-image-raspberrypi4-64.rootfs.rpi-sdimg \
    of=/dev/sdX bs=4M status=progress conv=fsync

sync
```
- [ ] 이미지 플래싱 완료
- [ ] sync 완료

⏱️ **예상 시간**: 5-10분

### Step 3: SD 카드 안전 제거
```bash
sudo eject /dev/sdX
```
- [ ] SD 카드 안전하게 제거

## 🔌 첫 부팅 및 테스트

### Step 1: 하드웨어 연결
- [ ] SD 카드를 Raspberry Pi 4에 삽입
- [ ] 네트워크 케이블 연결 (이더넷)
- [ ] 전원 연결

### Step 2: 부팅 대기
- [ ] 부팅 완료 대기 (약 30초~1분)
- [ ] 네트워크 LED 확인

### Step 3: SSH 접속
```bash
# IP 주소 찾기 (필요시)
sudo nmap -sn 192.168.1.0/24

# SSH 접속
ssh root@<raspberry-pi-ip>
# 비밀번호: raspberry
```
- [ ] SSH 접속 성공

### Step 4: 서비스 상태 확인
```bash
# VehicleControlECU 서비스 확인
systemctl status vehiclecontrol-ecu

# 로그 확인
journalctl -u vehiclecontrol-ecu -f

# vsomeip 설정 확인
cat /etc/vsomeip/vsomeip_ecu1.json

# CommonAPI 설정 확인
cat /etc/commonapi/commonapi_ecu1.ini
```
- [ ] vehiclecontrol-ecu 서비스 running 상태
- [ ] 로그에 에러 없음
- [ ] vsomeip 설정 파일 존재
- [ ] CommonAPI 설정 파일 존재

### Step 5: 하드웨어 테스트 (PiRacer 연결 시)
```bash
# I2C 장치 확인
i2cdetect -y 1
```

예상 출력:
```
     0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f
00:          -- -- -- -- -- -- -- -- -- -- -- -- -- 
10: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
20: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
30: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
40: 40 41 -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
50: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
60: 60 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
70: -- -- -- -- -- -- -- --
```
- [ ] PCA9685 (0x40) 감지 - 조향 서보
- [ ] INA219 (0x41) 감지 - 배터리 모니터
- [ ] PCA9685 (0x60) 감지 - 모터 컨트롤러

## 🔄 개발 워크플로우

### 코드 수정 후 재빌드

#### 1. 소스 코드 수정
- [ ] `app/VehicleControlECU/src/` 파일 수정

#### 2. 소스 재준비
```bash
cd /home/seame/HU/DES_Head-Unit/meta/meta-vehiclecontrol
./tools/prepare-sources.sh
```
- [ ] 수정된 소스 recipe로 복사

#### 3. 재빌드
```bash
cd ~/yocto/build-ecu1
source ../poky/oe-init-build-env .
bitbake -c cleanall vehiclecontrol-ecu
bitbake vehiclecontrol-ecu
```
- [ ] 재빌드 완료

#### 4. 이미지 재생성 (필요시)
```bash
bitbake vehiclecontrol-image
```
- [ ] 새 이미지 생성

#### 5. SD 카드 업데이트
- [ ] 새 이미지로 SD 카드 재플래싱

## 🐛 문제 해결

### 빌드 실패 시
```bash
# 자세한 로그 확인
bitbake vehiclecontrol-image -v

# 특정 패키지 로그 확인
bitbake -c compile vehiclecontrol-ecu -f -v

# 빌드 클린 후 재시도
bitbake -c cleanall vehiclecontrol-ecu
bitbake vehiclecontrol-ecu
```
- [ ] 에러 메시지 확인
- [ ] `문제해결.md` 참조

### 디스크 공간 부족 시
```bash
# 다운로드 캐시 정리
rm -rf ~/yocto/build-ecu1/downloads/*

# sstate 캐시 정리
rm -rf ~/yocto/build-ecu1/sstate-cache/*

# tmp 디렉토리 정리 (전체 재빌드 필요)
rm -rf ~/yocto/build-ecu1/tmp
```
- [ ] 디스크 공간 확보

### 네트워크 연결 문제
```bash
# Raspberry Pi에서 네트워크 확인
ip addr show
ping 8.8.8.8

# vsomeip 통신 확인
journalctl -u vehiclecontrol-ecu | grep vsomeip
```
- [ ] 네트워크 연결 확인
- [ ] vsomeip 통신 확인

## 📚 참고 문서

- **QUICKSTART.md** - 빠른 시작 가이드
- **빌드가이드.md** - 상세 빌드 방법
- **문제해결.md** - 문제 해결 가이드
- **README.md** - 레이어 개요

## ✅ 최종 확인

- [ ] 이미지 빌드 완료
- [ ] SD 카드 플래싱 완료
- [ ] Raspberry Pi 부팅 성공
- [ ] SSH 접속 가능
- [ ] VehicleControlECU 서비스 실행 중
- [ ] vsomeip 통신 정상
- [ ] 하드웨어 장치 감지 (PiRacer 연결 시)

---

**축하합니다! ECU1 Yocto 이미지가 성공적으로 빌드되고 배포되었습니다! 🎉**
