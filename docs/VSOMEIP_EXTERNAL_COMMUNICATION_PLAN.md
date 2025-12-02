# vsomeip 외부 통신 설정 계획서

**작성일:** 2025년 12월 2일  
**목표:** Yocto 이미지의 VehicleControlECU (ECU1)와 다른 Raspberry Pi의 HU 앱들 (ECU2) 간 vsomeip 통신 활성화

---

## 현재 상황 분석

### 테스트 환경 비교

| 구분 | 기본 Raspberry Pi OS | Yocto 이미지 |
|------|---------------------|-------------|
| **VehicleControlECU** | 192.168.1.100 | 192.168.1.100 (예정) |
| **HU Apps (GearApp 등)** | 192.168.1.101 | 192.168.1.101 |
| **vsomeip 통신** | ✅ 작동 확인 | ❓ 설정 필요 |
| **네트워크 인터페이스** | eth0 (수동 설정) | ? |
| **CAN 통신** | - | ✅ 작동 확인 |

### 기본 OS에서의 동작 방식

**ECU1 (VehicleControlECU - 서비스 제공자):**
```bash
# 네트워크 설정
sudo ip addr add 192.168.1.100/24 dev eth0
sudo ip route add 224.0.0.0/4 dev eth0  # 멀티캐스트

# vsomeip 설정
export VSOMEIP_CONFIGURATION=/path/to/vsomeip_ecu1.json
./VehicleControlECU  # 라우팅 매니저 포함
```

**ECU2 (HU Apps - 서비스 소비자):**
```bash
# 네트워크 설정
sudo ip addr add 192.168.1.101/24 dev eth0
sudo ip route add 224.0.0.0/4 dev eth0

# 라우팅 매니저 시작
export VSOMEIP_CONFIGURATION=/path/to/routing_manager_ecu2.json
routingmanagerd &

# 앱들 시작
./GearApp &
./AmbientApp &
./IC_app &
./MediaApp &
```

### vsomeip 구성 분석

#### ECU1: vsomeip_ecu1.json
```json
{
    "unicast": "192.168.1.100",
    "routing": "VehicleControlECU",  // 자체 라우팅 매니저
    "service-discovery": {
        "enable": "true",
        "multicast": "224.244.224.245",
        "port": "30490"
    },
    "services": [
        {
            "service": "0x1234",
            "instance": "0x5678",
            "unreliable": "30501",
            "reliable": { "port": "30502" }
        }
    ]
}
```

#### ECU2: routing_manager_ecu2.json
```json
{
    "unicast": "192.168.1.101",
    "routing": "routingmanagerd",  // 독립 라우팅 매니저
    "service-discovery": {
        "enable": "true",
        "multicast": "224.244.224.245",
        "port": "30490"
    }
}
```

#### ECU2: vsomeip_ecu2.json (GearApp 등)
```json
{
    "unicast": "192.168.1.101",
    // routing 항목 없음 - 외부 라우팅 매니저 사용
    "service-discovery": { "enable": "true" },
    "clients": [
        {
            "service": "0x1234",
            "instance": "0x5678"
        }
    ]
}
```

---

## Yocto 이미지 문제점

### 1. 네트워크 인터페이스 설정

**문제:**
- Yocto 이미지에서 eth0 인터페이스 상태 불명확
- WiFi(wlan0)는 설정되어 있지만 Ethernet(eth0) 설정 없음
- 192.168.1.100 IP 할당 및 멀티캐스트 라우팅 필요

**현재 네트워크 설정:**
- wpa_supplicant (WiFi) ✅
- dhcpcd ✅
- eth0 설정? ❓

### 2. vsomeip 구성 파일 위치

**현재 상태:**
```
/etc/vsomeip/vsomeip_ecu1.json  (배포됨)
/etc/commonapi/commonapi_ecu1.ini  (배포됨)
```

**문제:**
- 환경변수 설정 필요 (`VSOMEIP_CONFIGURATION`)
- systemd 서비스에서 자동 로드되는지 확인 필요

### 3. systemd 서비스 설정

**현재 서비스 파일 확인 필요:**
- `vehiclecontrol-ecu.service` 내용
- 네트워크 설정 포함 여부
- 환경변수 설정 여부
- vsomeip 라이브러리 경로 (`LD_LIBRARY_PATH`)

---

## 해결 계획

### Phase 1: 네트워크 설정 구현

#### 옵션 A: systemd-networkd 사용 (권장)

**장점:**
- systemd와 통합, 안정적
- Yocto 표준 방식
- 재부팅 후에도 유지

**구현:**
1. `meta-vehiclecontrol/recipes-connectivity/network/files/eth0.network` 생성
   ```ini
   [Match]
   Name=eth0

   [Network]
   Address=192.168.1.100/24
   
   [Route]
   Destination=224.0.0.0/4
   ```

2. systemd-networkd 활성화
   ```python
   # vehiclecontrol-image.bb
   DISTRO_FEATURES:append = " systemd-networkd"
   IMAGE_INSTALL:append = " systemd-networkd"
   ```

#### 옵션 B: systemd 서비스에서 네트워크 설정 (간단)

**장점:**
- 빠른 구현
- 기존 스크립트 로직 재사용

**구현:**
vehiclecontrol-ecu.service에 네트워크 설정 추가:
```ini
[Unit]
Description=VehicleControl ECU Service
After=network.target

[Service]
Type=simple
ExecStartPre=/bin/sh -c 'ip link set eth0 up || true'
ExecStartPre=/bin/sh -c 'ip addr flush dev eth0 || true'
ExecStartPre=/bin/sh -c 'ip addr add 192.168.1.100/24 dev eth0 || true'
ExecStartPre=/bin/sh -c 'ip route add 224.0.0.0/4 dev eth0 || true'
ExecStart=/usr/bin/VehicleControlECU
Environment="VSOMEIP_CONFIGURATION=/etc/vsomeip/vsomeip_ecu1.json"
Environment="COMMONAPI_CONFIG=/etc/commonapi/commonapi_ecu1.ini"
Environment="LD_LIBRARY_PATH=/usr/local/lib:/usr/lib"
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

### Phase 2: vsomeip 환경변수 설정

#### 방법 1: systemd 서비스 환경변수 (권장)
위의 systemd 서비스 파일에 이미 포함됨

#### 방법 2: /etc/environment
```bash
VSOMEIP_CONFIGURATION=/etc/vsomeip/vsomeip_ecu1.json
COMMONAPI_CONFIG=/etc/commonapi/commonapi_ecu1.ini
```

### Phase 3: 방화벽 및 보안 설정

**확인 사항:**
- iptables 규칙 없는지 확인
- UDP 포트 30490 (Service Discovery) 오픈
- UDP 포트 30501 (unreliable messaging) 오픈
- TCP 포트 30502 (reliable messaging) 오픈

**Yocto에서 기본적으로 방화벽 비활성화:**
```python
# vehiclecontrol-image.bb
# 방화벽 패키지 제거 (기본적으로 포함 안 됨)
```

### Phase 4: 디버깅 도구 추가

**필요한 도구:**
```python
# vehiclecontrol-image.bb
IMAGE_INSTALL:append = " \
    iproute2 \
    iputils-ping \
    tcpdump \
    netcat \
    ethtool \
"
```

**vsomeip 로깅 활성화:**
```json
// vsomeip_ecu1.json
{
    "logging": {
        "level": "debug",  // info → debug
        "console": "true"
    }
}
```

---

## 구현 우선순위

### 1단계: systemd 서비스 수정 ⭐ (최우선)

**파일:** `meta-vehiclecontrol/recipes-vehiclecontrol/vehiclecontrol-ecu/files/vehiclecontrol-ecu.service`

**수정 내용:**
- ExecStartPre로 네트워크 설정 추가
- Environment 변수 추가 (VSOMEIP_CONFIGURATION)
- LD_LIBRARY_PATH 설정

**예상 소요 시간:** 10분 (수정 + 빌드)

### 2단계: 디버깅 도구 추가

**파일:** `meta-vehiclecontrol/recipes-core/images/vehiclecontrol-image.bb`

**추가:**
```python
IMAGE_INSTALL:append = " \
    iproute2 \
    iputils-ping \
    tcpdump \
"
```

**예상 소요 시간:** 5분 (수정 + 빌드)

### 3단계: 테스트 빌드 및 검증

```bash
# 빌드
cd ~/yocto
source poky/oe-init-build-env build-ecu1
bitbake -c cleansstate vehiclecontrol-ecu
bitbake vehiclecontrol-image

# 플래싱
sudo dd if=.../vehiclecontrol-image-*.rpi-sdimg of=/dev/sda bs=4M status=progress conv=fsync

# 부팅 후 검증
ssh root@<YOCTO_IP>

# 네트워크 확인
ip addr show eth0
ip route | grep 224.0.0.0

# vsomeip 서비스 확인
systemctl status vehiclecontrol-ecu
journalctl -u vehiclecontrol-ecu -f

# ECU2에서 통신 확인
ping 192.168.1.100
```

### 4단계: 통신 검증

**ECU2 (다른 Raspberry Pi)에서:**
```bash
# GearApp 실행
cd ~/DES_Head-Unit/app
./config/start_all_ecu2.sh

# 로그 확인
tail -f /tmp/gearapp.log | grep "0x1234"
```

**ECU1 (Yocto)에서:**
```bash
# vsomeip 로그 확인
journalctl -u vehiclecontrol-ecu | grep -E "OFFER|SUBSCRIBE|REQUEST"
```

**성공 조건:**
- ECU1: Service Discovery OFFER 메시지 전송
- ECU2: Service Discovery FIND 메시지 수신
- ECU2: SUBSCRIBE 요청
- ECU1: 속도 데이터 전송
- ECU2: 속도 데이터 수신

---

## 네트워크 토폴로지

```
┌─────────────────────────────────────────┐
│         Ethernet Switch/Router          │
│         (192.168.1.0/24 network)        │
└───────────┬──────────────┬──────────────┘
            │              │
            │              │
    ┌───────▼──────┐  ┌───▼──────────┐
    │   ECU1       │  │   ECU2       │
    │   Yocto      │  │   RasPi OS   │
    │              │  │              │
    │ 192.168.1.100│  │192.168.1.101 │
    │              │  │              │
    │ VehicleCtrl  │  │ GearApp      │
    │   (서비스)    │  │ AmbientApp   │
    │ + Routing    │  │ IC_app       │
    │   Manager    │  │ MediaApp     │
    │              │  │ + Routing    │
    │              │  │   Manager    │
    └──────────────┘  └──────────────┘
         │                   │
         └───────────────────┘
         vsomeip UDP/TCP
         - SD: 224.244.224.245:30490
         - Service: 0x1234:0x5678
         - Unreliable: 30501
         - Reliable: 30502
```

---

## 예상 문제 및 해결책

### 문제 1: eth0 인터페이스가 없음

**증상:**
```bash
root@vehiclecontrol-ecu:~# ip link show eth0
Device "eth0" does not exist.
```

**원인:**
- 커널에 Ethernet 드라이버 미포함
- 또는 인터페이스 이름이 다름 (enp0s3, ens33 등)

**해결:**
```bash
# 실제 인터페이스 확인
ip link show

# 이더넷 인터페이스 찾기
ip link show | grep -E "eth|enp|ens"

# systemd 서비스 수정하여 올바른 인터페이스명 사용
```

### 문제 2: vsomeip 라이브러리를 찾을 수 없음

**증상:**
```bash
error while loading shared libraries: libvsomeip3.so.3
```

**원인:**
- LD_LIBRARY_PATH 설정 안 됨
- vsomeip 라이브러리 패키지 미설치

**해결:**
```bash
# 라이브러리 확인
find /usr -name "libvsomeip*"

# systemd 서비스에 LD_LIBRARY_PATH 추가
Environment="LD_LIBRARY_PATH=/usr/local/lib:/usr/lib"
```

### 문제 3: 멀티캐스트 라우팅 실패

**증상:**
- Service Discovery 작동 안 함
- "No route to host" 에러

**원인:**
- 멀티캐스트 라우트 설정 안 됨
- 스위치/라우터가 멀티캐스트 차단

**해결:**
```bash
# 멀티캐스트 라우트 확인
ip route | grep 224.0.0.0

# 수동 추가
sudo ip route add 224.0.0.0/4 dev eth0

# 영구 설정: systemd 서비스 ExecStartPre
```

### 문제 4: vsomeip 설정 파일을 찾을 수 없음

**증상:**
```bash
vsomeip configuration file not found
```

**원인:**
- VSOMEIP_CONFIGURATION 환경변수 설정 안 됨
- 파일 경로 오류

**해결:**
```bash
# 파일 존재 확인
ls -la /etc/vsomeip/vsomeip_ecu1.json

# systemd 서비스에 환경변수 추가
Environment="VSOMEIP_CONFIGURATION=/etc/vsomeip/vsomeip_ecu1.json"
```

---

## 체크리스트

### 빌드 전
- [ ] systemd 서비스 파일 수정 (네트워크 설정 추가)
- [ ] vsomeip 환경변수 추가
- [ ] 디버깅 도구 패키지 추가
- [ ] vsomeip_ecu1.json 로깅 레벨 debug로 변경 (선택)

### 빌드 후
- [ ] SD 이미지 플래싱
- [ ] Raspberry Pi 부팅
- [ ] SSH 접속 확인

### 네트워크 검증
- [ ] `ip addr show eth0` - 192.168.1.100 확인
- [ ] `ip route | grep 224` - 멀티캐스트 라우트 확인
- [ ] `ping 192.168.1.101` - ECU2 연결 확인

### vsomeip 검증
- [ ] `systemctl status vehiclecontrol-ecu` - 서비스 실행 확인
- [ ] `journalctl -u vehiclecontrol-ecu` - 로그에서 OFFER 메시지 확인
- [ ] ECU2에서 GearApp 실행 후 통신 확인

---

## 다음 단계

1. ✅ 계획 수립 (현재)
2. ⏭️ systemd 서비스 파일 수정
3. ⏭️ 디버깅 도구 추가
4. ⏭️ Yocto 이미지 빌드
5. ⏭️ 플래싱 및 테스트
6. ⏭️ 통신 검증 및 디버깅
7. ⏭️ 최종 문서화

---

## 참고 사항

- 기본 Raspberry Pi OS에서 통신이 정상 작동하므로, vsomeip 설정 자체는 문제없음
- Yocto 환경의 네트워크 설정과 서비스 시작 순서가 핵심
- systemd의 의존성 관리를 활용하면 안정적 구동 가능
- 최소한의 수정으로 빠르게 테스트하는 것이 중요
