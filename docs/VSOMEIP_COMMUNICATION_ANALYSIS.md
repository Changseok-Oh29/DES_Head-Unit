# vsomeip 통신 전체 분석 및 설정 가이드

## 📊 전체 시스템 아키텍처

```
┌─────────────────────────────────────────────────────────────┐
│                    vsomeip Network                           │
│              (SOME/IP over Ethernet)                         │
└─────────────────────────────────────────────────────────────┘
                ↑                                    ↑
                │                                    │
         ┌──────┴────────┐                   ┌──────┴────────┐
         │   ECU1 (RPi1) │                   │   ECU2 (RPi2) │
         │ 192.168.1.100 │◄─── Ethernet ────│ 192.168.1.101 │
         └───────────────┘                   └───────────────┘
         │                                    │
         │ VehicleControlECU                  │ Client Apps:
         │ - Routing Manager                  │ - GearApp
         │ - Service Provider                 │ - AmbientApp  
         │ - PiRacer HW                       │ - IC_app
         │ - Service: 0x1234:0x5678          │ - MediaApp (로컬)
         └───────────────┘                   └───────────────┘
```

---

## 🔍 전체 설정 분석 결과

### ✅ 정상 설정 앱

#### 1. **VehicleControlECU** (ECU1)
- **위치**: `/app/VehicleControlECU/config/vsomeip_ecu1.json`
- **IP**: `192.168.1.100`
- **역할**: Service Provider + Routing Manager
- **서비스**: `0x1234:0x5678` (VehicleControl)
- **포트**: `30501` (unreliable), `30502` (reliable)
- **멀티캐스트**: `224.244.224.245` ✅
- **Application ID**: `0x1001`
- **상태**: ✅ **올바르게 설정됨**

#### 2. **GearApp** (ECU2)
- **위치**: `/app/GearApp/config/vsomeip_ecu2.json`
- **IP**: `192.168.1.101`
- **역할**: Client
- **서비스**: `0x1234:0x5678` (VehicleControl 구독)
- **멀티캐스트**: `224.244.224.245` ✅
- **Application ID**: `0xFFFF`
- **Routing**: `VehicleControlECU`
- **상태**: ⚠️ **services 섹션 추가 필요**

#### 3. **AmbientApp** (ECU2)
- **위치**: `/app/AmbientApp/vsomeip_ambient.json`
- **IP**: `192.168.1.101`
- **역할**: Client
- **서비스**: 
  - `0x1234:0x5678` (VehicleControl 구독)
  - `0x1235:0x5679` (MediaControl)
- **포트**: `30509`, `30510`
- **멀티캐스트**: `224.244.224.245` ✅
- **Application ID**: `0x0300`
- **Routing**: `vsomeipd`
- **상태**: ✅ **올바르게 설정됨**

#### 4. **IC_app** (ECU2)
- **위치**: `/app/IC_app/vsomeip_ic.json`
- **IP**: `192.168.1.101`
- **역할**: Client
- **서비스**: `0x1234:0x5678` (VehicleControl 구독)
- **포트**: `30508`
- **멀티캐스트**: `224.244.224.245` ✅
- **Application ID**: `0x0400`
- **Routing**: `vsomeipd`
- **상태**: ✅ **올바르게 설정됨**

---

### ❌ 문제 있는 설정

#### 5. **MediaApp** (로컬 전용)
- **위치**: `/app/MediaApp/vsomeip.json`
- **IP**: `127.0.0.1` ⚠️
- **역할**: Service Provider (로컬)
- **서비스**: `0x1235:0x5679` (MediaControl)
- **포트**: `30509`
- **멀티캐스트**: `224.0.0.1` ❌ **잘못된 멀티캐스트 주소**
- **Application ID**: `0x1234` ❌ **VehicleControlECU와 충돌**
- **Routing**: `MediaApp` (로컬 routing manager)
- **상태**: ❌ **네트워크 통신 불가 (로컬 전용 설정)**

#### 6. **HU_MainApp** (로컬 전용)
- **위치**: `/app/HU_MainApp/vsomeip.json`
- **IP**: `127.0.0.1` ⚠️
- **역할**: Service Provider (로컬)
- **서비스**: `0x1235:0x5679` (MediaControl)
- **포트**: `30509`
- **멀티캐스트**: `224.0.0.1` ❌ **잘못된 멀티캐스트 주소**
- **Application ID**: `0x1237`
- **Routing**: `HU_MainApp` (로컬 routing manager)
- **상태**: ❌ **네트워크 통신 불가 (로컬 전용 설정)**

---

## 🚨 발견된 주요 문제점

### 1. **서비스 ID 충돌** ⚠️
- `MediaApp` Application ID: `0x1234` 
- `VehicleControlECU` Service ID: `0x1234`
- **충돌 가능성**: Application ID와 Service ID가 같은 값 사용

### 2. **멀티캐스트 주소 불일치** ❌
| 앱 | 멀티캐스트 주소 | 상태 |
|-----|----------------|------|
| VehicleControlECU | `224.244.224.245` | ✅ 표준 |
| GearApp | `224.244.224.245` | ✅ 표준 |
| AmbientApp | `224.244.224.245` | ✅ 표준 |
| IC_app | `224.244.224.245` | ✅ 표준 |
| MediaApp | `224.0.0.1` | ❌ 비표준 |
| HU_MainApp | `224.0.0.1` | ❌ 비표준 |

### 3. **포트 충돌** ⚠️
| 앱 | 서비스 | 포트 | 충돌 여부 |
|-----|--------|------|-----------|
| VehicleControlECU | `0x1234:0x5678` | `30501` | - |
| IC_app | `0x1234:0x5678` | `30508` | ⚠️ 다른 포트 |
| AmbientApp | `0x1234:0x5678` | `30509` | ⚠️ 다른 포트 |
| MediaApp | `0x1235:0x5679` | `30509` | ⚠️ AmbientApp과 충돌 |
| HU_MainApp | `0x1235:0x5679` | `30509` | ⚠️ 충돌 |

### 4. **Routing Manager 설정 불일치**
- **ECU1**: `VehicleControlECU` (Host)
- **GearApp**: `VehicleControlECU` (올바름) ✅
- **AmbientApp**: `vsomeipd` (다름) ⚠️
- **IC_app**: `vsomeipd` (다름) ⚠️
- **MediaApp**: `MediaApp` (로컬) ⚠️
- **HU_MainApp**: `HU_MainApp` (로컬) ⚠️

### 5. **GearApp services 섹션 누락**
- 클라이언트 앱도 구독할 서비스를 명시해야 함

---

## 🔧 수정 사항

### 1. GearApp 설정 수정

```json
{
    "unicast": "192.168.1.101",
    "logging": {
        "level": "info",
        "console": "true",
        "file": {
            "enable": "false"
        },
        "dlt": "false"
    },
    "applications": [
        {
            "name": "client-sample",
            "id": "0xFFFF"
        }
    ],
    "routing": "VehicleControlECU",
    "service-discovery": {
        "enable": "true",
        "multicast": "224.244.224.245",
        "port": "30490",
        "protocol": "udp",
        "initial_delay_min": "10",
        "initial_delay_max": "100",
        "repetitions_base_delay": "200",
        "repetitions_max": "3",
        "ttl": "3",
        "cyclic_offer_delay": "2000",
        "request_response_delay": "1500"
    },
    "services": [
        {
            "service": "0x1234",
            "instance": "0x5678",
            "unreliable": "30501"
        }
    ]
}
```

### 2. MediaApp 설정 수정 (네트워크 통신용)

```json
{
    "unicast": "192.168.1.101",
    "logging": {
        "level": "info",
        "console": "true"
    },
    "applications": [
        {
            "name": "MediaApp",
            "id": "0x1238"
        }
    ],
    "services": [
        {
            "service": "0x1235",
            "instance": "0x5679",
            "unreliable": "30510"
        }
    ],
    "routing": "VehicleControlECU",
    "service-discovery": {
        "enable": "true",
        "multicast": "224.244.224.245",
        "port": "30490",
        "protocol": "udp"
    }
}
```

### 3. HU_MainApp 설정 수정 (네트워크 통신용)

```json
{
    "unicast": "192.168.1.101",
    "logging": {
        "level": "info",
        "console": "true"
    },
    "applications": [
        {
            "name": "HU_MainApp",
            "id": "0x1239"
        }
    ],
    "routing": "VehicleControlECU",
    "service-discovery": {
        "enable": "true",
        "multicast": "224.244.224.245",
        "port": "30490",
        "protocol": "udp"
    }
}
```

---

## 📋 Application ID 할당 정리

| 앱 | Application ID | 용도 | ECU |
|----|---------------|------|-----|
| VehicleControlECU | `0x1001` | Service Provider | ECU1 |
| GearApp | `0xFFFF` | Client | ECU2 |
| AmbientApp | `0x0300` | Client | ECU2 |
| IC_app | `0x0400` | Client | ECU2 |
| MediaApp | `0x1238` | Service/Client | ECU2 |
| HU_MainApp | `0x1239` | Client | ECU2 |

---

## 📋 Service ID 할당 정리

| 서비스 | Service ID | Instance ID | 제공자 | 포트 |
|--------|-----------|-------------|--------|------|
| VehicleControl | `0x1234` | `0x5678` | VehicleControlECU | `30501` |
| MediaControl | `0x1235` | `0x5679` | MediaApp | `30510` |

---

## 🔄 통신 플로우

### VehicleControl Service (0x1234:0x5678)

```
VehicleControlECU (ECU1)
    ↓ OFFER (Service Discovery)
    ↓ Multicast: 224.244.224.245:30490
    ↓
    ↓ → GearApp (ECU2) - RPC: setGearPosition()
    ↓ → AmbientApp (ECU2) - Event: gearChanged
    ↓ → IC_app (ECU2) - Event: vehicleStateChanged
```

### MediaControl Service (0x1235:0x5679)

```
MediaApp (ECU2)
    ↓ OFFER (Service Discovery)
    ↓ Multicast: 224.244.224.245:30490
    ↓
    ↓ → AmbientApp (ECU2) - Media state events
    ↓ → HU_MainApp (ECU2) - Media control
```

---

## 🧪 테스트 시나리오

### 시나리오 1: ECU간 통신 (GearApp ↔ VehicleControlECU)

**목표**: ECU2의 GearApp에서 ECU1의 VehicleControlECU로 기어 변경 요청

**절차**:
1. ECU1에서 VehicleControlECU 시작
2. ECU2에서 GearApp 시작
3. GearApp GUI에서 기어 변경 (P → D)
4. VehicleControlECU에서 기어 변경 이벤트 브로드캐스트

**예상 로그**:
```
[ECU1] OFFER(1234): [1234.5678:0.0]
[ECU2] REQUEST(1234): [1234.5678:0.0]
[ECU2] Service 0x1234 is available
[ECU2] → setGearPosition("D")
[ECU1] ← setGearPosition("D") received
[ECU1] → gearChanged("D", "P") broadcast
[ECU2] ← gearChanged event received
```

### 시나리오 2: 로컬 통신 (MediaApp ↔ AmbientApp)

**목표**: ECU2 내부 앱간 통신

**절차**:
1. ECU2에서 MediaApp 시작 (Service Provider)
2. ECU2에서 AmbientApp 시작 (Client)
3. MediaApp에서 미디어 재생 시작
4. AmbientApp에서 미디어 상태에 따라 조명 변경

---

## 🛠️ 디버깅 도구

### 1. 네트워크 패킷 캡처

```bash
# Service Discovery 패킷 확인
sudo tcpdump -i eth0 -n 'udp and port 30490' -v

# VehicleControl 서비스 패킷 확인
sudo tcpdump -i eth0 -n 'udp and port 30501' -v

# 모든 vsomeip 트래픽
sudo tcpdump -i eth0 -n 'udp and (port 30490 or port 30501 or port 30508 or port 30509 or port 30510)' -w vsomeip.pcap
```

### 2. 멀티캐스트 그룹 확인

```bash
# 멀티캐스트 그룹 가입 확인
ip maddr show eth0 | grep 224.244.224.245

# 멀티캐스트 라우팅 확인
ip route show | grep 224.0.0.0
```

### 3. vsomeip 로그 레벨 변경

```json
"logging": {
    "level": "debug",  // trace, debug, info, warning, error, fatal
    "console": "true"
}
```

### 4. 실시간 통신 모니터링

```bash
# ECU1에서
watch -n 1 'sudo netstat -unlp | grep -E "30490|30501|30508|30509|30510"'

# ECU2에서
watch -n 1 'sudo netstat -unlp | grep -E "30490|30501|30508|30509|30510"'
```

---

## 📌 체크리스트

### 시작 전 확인사항

- [ ] 네트워크 설정
  - [ ] ECU1: `192.168.1.100/24` 설정됨
  - [ ] ECU2: `192.168.1.101/24` 설정됨
  - [ ] 양방향 ping 성공
  - [ ] 라우팅 테이블에 `192.168.1.0/24 dev eth0` 존재

- [ ] vsomeip 설정
  - [ ] 모든 앱의 멀티캐스트: `224.244.224.245`
  - [ ] Service Discovery 포트: `30490`
  - [ ] Application ID 중복 없음
  - [ ] Service 포트 충돌 없음

- [ ] 방화벽 설정
  - [ ] UDP 30490 (Service Discovery) 열림
  - [ ] UDP 30501-30510 (Services) 열림
  - [ ] 멀티캐스트 허용

- [ ] 실행 순서
  - [ ] ECU1 먼저 시작 (Routing Manager)
  - [ ] ECU2 앱들 시작

### 통신 성공 확인

- [ ] ECU1 로그에서 `OFFER(1234)` 확인
- [ ] ECU2 로그에서 `Service 0x1234 is available` 확인
- [ ] RPC 호출 성공 (기어 변경)
- [ ] Event 수신 성공 (상태 업데이트)

---

## 🔗 참고 자료

- [vsomeip GitHub](https://github.com/COVESA/vsomeip)
- [CommonAPI Documentation](https://github.com/COVESA/capicxx-core-tools)
- [SOME/IP Protocol Specification](https://www.autosar.org/)
- [프로젝트 README](/README.md)
- [ECU 통신 테스트 가이드](/docs/ECU_COMMUNICATION_TEST_GUIDE.md)
