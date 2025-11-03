# ECU 간 통신 오류 해결 가이드

## 📋 목차
1. [오류 1: "Couldn't connect to /tmp/vsomeip-0"](#오류-1-couldnt-connect-to-tmpvsomeip-0)
2. [오류 2: NO-CARRIER (케이블 미연결)](#오류-2-no-carrier-케이블-미연결)
3. [오류 3: Service Discovery 실패](#오류-3-service-discovery-실패)
4. [오류 4: [Proxy] 모드 실행](#오류-4-proxy-모드-실행)
5. [오류 5: "other routing manager present"](#오류-5-other-routing-manager-present)
6. [오류 6: 멀티캐스트 그룹 미가입](#오류-6-멀티캐스트-그룹-미가입)
7. [오류 7: Connected: false](#오류-7-connected-false)

---

## 오류 1: "Couldn't connect to /tmp/vsomeip-0"

### 📊 오류 로그
```
[warning] Couldn't connect to: /tmp/vsomeip-0 (No such file or directory)
[warning] on_disconnect: Resetting state to ST_DEREGISTERED
Connected: false
```

### 🔍 원인 분석
- ECU2(GearApp)가 `vsomeip_ecu2.json`에 `"routing"` 필드 없이 실행됨
- vsomeip가 기본적으로 [Proxy] 모드로 실행되어 로컬 라우팅 매니저(`/tmp/vsomeip-0`)를 찾음
- ECU2는 독립적인 [Host] 라우팅 매니저를 실행해야 하는데 [Proxy]로 동작

### ✅ 해결 방법

#### 1단계: 설정 파일 확인
```bash
cd ~/SEA-ME/DES_Head-Unit/app/GearApp/config
cat vsomeip_ecu2.json
```

#### 2단계: 파일 수정 - "routing" 필드 추가
**파일:** `/app/GearApp/config/vsomeip_ecu2.json`

**수정 전:**
```json
{
    "unicast": "192.168.1.101",
    "applications": [
        {
            "name": "client-sample",
            "id": "0xFFFF"
        }
    ],
    "service-discovery": {
        ...
    }
}
```

**수정 후:**
```json
{
    "unicast": "192.168.1.101",
    "applications": [
        {
            "name": "client-sample",
            "id": "0xFFFF"
        }
    ],
    "routing": "client-sample",  // ← 추가
    "service-discovery": {
        ...
    }
}
```

**수정 명령어:**
```bash
# 백업
cp vsomeip_ecu2.json vsomeip_ecu2.json.backup

# vim으로 편집
vim vsomeip_ecu2.json

# "routing": "client-sample" 라인을 applications 배열 다음에 추가
# :wq로 저장
```

#### 3단계: 재시작
```bash
# 프로세스 종료
killall -9 GearApp

# 재실행
cd ~/SEA-ME/DES_Head-Unit/app/GearApp
./run.sh
```

### 📈 결과
```
[info] Instantiating routing manager [Host]  // ✅ Proxy → Host 변경
[info] create_routing_root: Routing root @ /tmp/vsomeip-0  // ✅ 소켓 생성
```

---

## 오류 2: NO-CARRIER (케이블 미연결)

### 📊 오류 로그
```bash
$ ip link show eth0
2: eth0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc pfifo_fast state DOWN
```

### 🔍 원인 분석
- 이더넷 케이블이 물리적으로 연결되지 않음
- ECU1과 ECU2 간 네트워크 통신 불가능
- Service Discovery 패킷 전송/수신 불가

### ✅ 해결 방법

#### 1단계: 물리적 연결 확인
```bash
# 케이블 상태 확인
ip link show eth0

# 예상 결과 (문제 상황)
# <NO-CARRIER,BROADCAST,MULTICAST,UP> state DOWN  ← DOWN 상태
```

#### 2단계: 케이블 재연결
1. ECU1의 이더넷 포트에서 케이블 제거 후 재연결
2. ECU2의 이더넷 포트에서 케이블 제거 후 재연결
3. 케이블이 불량하면 다른 케이블로 교체

#### 3단계: 연결 확인
```bash
# 두 ECU 모두 실행
ip link show eth0

# 예상 결과 (정상)
# <BROADCAST,MULTICAST,UP,LOWER_UP> state UP  ← LOWER_UP 확인!
```

#### 4단계: IP 재설정
```bash
# ECU1
sudo ip addr flush dev eth0
sudo ip addr add 192.168.1.100/24 dev eth0
sudo ip link set eth0 up

# ECU2
sudo ip addr flush dev eth0
sudo ip addr add 192.168.1.101/24 dev eth0
sudo ip link set eth0 up
```

#### 5단계: 연결 테스트
```bash
# ECU1에서 ECU2로 ping
ping -c 3 192.168.1.101

# 예상 결과
# 3 packets transmitted, 3 received, 0% packet loss  ✅
```

### 📈 결과
```
64 bytes from 192.168.1.101: icmp_seq=1 ttl=64 time=0.5 ms
64 bytes from 192.168.1.101: icmp_seq=2 ttl=64 time=0.4 ms
64 bytes from 192.168.1.101: icmp_seq=3 ttl=64 time=0.4 ms
```

---

## 오류 3: Service Discovery 실패

### 📊 오류 로그
```
# ECU2 로그
[info] REQUEST(0100): [1234.5678:1.4294967295]
[warning] Service [1234.5678] is not available.
Connected: false
```

### 🔍 원인 분석
- ECU1은 OFFER 패킷을 멀티캐스트로 전송 중
- ECU2가 멀티캐스트 패킷을 수신하지 못함
- 멀티캐스트 라우팅 설정 누락

### ✅ 해결 방법

#### 1단계: ECU1에서 패킷 전송 확인
```bash
# ECU1에서 실행
sudo tcpdump -i eth0 -n 'host 224.244.224.245' -v

# 예상 출력
# 192.168.1.100.30490 > 224.244.224.245.30490: SOMEIP, service 65535, event 256
```

#### 2단계: ECU2에서 패킷 수신 확인
```bash
# ECU2에서 실행
sudo tcpdump -i eth0 -n 'host 224.244.224.245' -v

# 문제 상황: 아무것도 출력 안됨 ❌
```

#### 3단계: 멀티캐스트 라우팅 추가
```bash
# 두 ECU 모두 실행
sudo ip route add 224.0.0.0/4 dev eth0

# 확인
ip route | grep 224

# 예상 출력
# 224.0.0.0/4 dev eth0 scope link  ✅
```

#### 4단계: 애플리케이션 재시작
```bash
# ECU2에서 실행
killall -9 GearApp
sudo rm -rf /tmp/vsomeip-*
cd ~/SEA-ME/DES_Head-Unit/app/GearApp
./run.sh
```

#### 5단계: 패킷 수신 재확인
```bash
# ECU2에서 실행
sudo tcpdump -i eth0 -n 'host 224.244.224.245' -v

# 예상 출력 (성공)
# 192.168.1.100.30490 > 224.244.224.245.30490: SOMEIP  ✅
```

### 📈 결과
```
[info] Service [1234.5678] is available.  ✅
Connected: true  ✅
```

---

## 오류 4: [Proxy] 모드 실행

### 📊 오류 로그
```
[info] Instantiating routing manager [Proxy]  ❌
[warning] Couldn't connect to: /tmp/vsomeip-0
[error] Failed to instantiate routing manager
```

### 🔍 원인 분석
- `vsomeip_ecu2.json`에 `"routing"` 필드 없음
- vsomeip가 기본값으로 [Proxy] 모드 선택
- ECU2는 독립적인 [Host]로 실행되어야 함

### ✅ 해결 방법

#### 1단계: 디버그 로그 활성화
**파일:** `/app/GearApp/config/vsomeip_ecu2.json`

```bash
vim vsomeip_ecu2.json
```

**수정:**
```json
{
    "logging": {
        "level": "debug",  // "info" → "debug" 변경
        "console": "true"
    }
}
```

#### 2단계: 로그 확인
```bash
cd ~/SEA-ME/DES_Head-Unit/app/GearApp
./run.sh

# 로그에서 확인
# [info] Instantiating routing manager [Proxy]  ← 문제 발견!
```

#### 3단계: routing 필드 추가
**파일:** `/app/GearApp/config/vsomeip_ecu2.json`

```json
{
    "applications": [
        {
            "name": "client-sample",
            "id": "0xFFFF"
        }
    ],
    "routing": "client-sample",  // ← 추가
    "service-discovery": {
        ...
    }
}
```

**vim 편집 과정:**
```vim
# vim vsomeip_ecu2.json
# 16번째 줄 (applications 배열 닫은 후)에 추가
# i (삽입 모드)
    "routing": "client-sample",
# ESC → :wq (저장)
```

#### 4단계: 재시작 및 확인
```bash
killall -9 GearApp
sudo rm -rf /tmp/vsomeip-*
./run.sh

# 예상 로그
# [info] Instantiating routing manager [Host]  ✅
```

### 📈 결과
```
[info] Instantiating routing manager [Host]
[info] create_routing_root: Routing root @ /tmp/vsomeip-0
[info] Routing root configured!
```

---

## 오류 5: "other routing manager present"

### 📊 오류 로그
```
[error] application: client-sample configured as routing but other routing manager present. Won't instantiate routing
[warning] Couldn't connect to: /tmp/vsomeip-0
```

### 🔍 원인 분석
- 이전에 실행된 vsomeip 프로세스가 아직 살아있음
- `/tmp/vsomeip-0` 소켓이 이미 다른 프로세스에 의해 점유됨
- 새로운 라우팅 매니저가 시작되지 못함

### ✅ 해결 방법

#### 1단계: 실행 중인 프로세스 확인
```bash
ps aux | grep -E "GearApp|vsomeip|client-sample"

# 예상 출력 (문제 상황)
# leo  12345  GearApp
# leo  12346  vsomeip-daemon
# leo  12347  client-sample
```

#### 2단계: 소켓 파일 확인
```bash
ls -la /tmp/vsomeip-*

# 예상 출력 (문제 상황)
# srwxr-xr-x 1 leo leo 0 Nov 1 10:30 /tmp/vsomeip-0
# srwxr-xr-x 1 leo leo 0 Nov 1 10:30 /tmp/vsomeip-100
```

#### 3단계: 완전 클린업 (해결의 핵심!)
```bash
# 모든 vsomeip 관련 프로세스 강제 종료
killall -9 GearApp 2>/dev/null
killall -9 client-sample 2>/dev/null
pkill -9 -f vsomeip 2>/dev/null

# 프로세스 종료 확인
ps aux | grep -E "GearApp|vsomeip|client-sample"
# 아무것도 출력되지 않아야 함 ✅

# vsomeip 소켓 완전 삭제
sudo rm -rf /tmp/vsomeip-*
sudo rm -rf /var/run/vsomeip-*

# 삭제 확인
ls -la /tmp/vsomeip-* 2>/dev/null
# ls: cannot access '/tmp/vsomeip-*': No such file or directory  ✅
```

#### 4단계: 3초 대기 후 재시작
```bash
# 시스템이 리소스 정리할 시간 제공
sleep 3

# 애플리케이션 재시작
cd ~/SEA-ME/DES_Head-Unit/app/GearApp
./run.sh
```

#### 5단계: 성공 확인
```bash
# 로그 확인
# [info] Instantiating routing manager [Host]  ✅
# [info] create_routing_root: Routing root @ /tmp/vsomeip-0  ✅

# 소켓 생성 확인
ls -la /tmp/vsomeip-*
# srwxr-xr-x 1 leo leo 0 Nov 1 11:00 /tmp/vsomeip-0  ✅
```

### 📈 결과
```
[info] Instantiating routing manager [Host]
[info] create_routing_root: Routing root @ /tmp/vsomeip-0
[info] Client [0100] routes unicast:192.168.1.101
[info] Service [1234.5678] is available.
Connected: true  ✅
```

### 💡 핵심 포인트
**이 오류의 해결책은 "완전한 클린업"입니다!**
```bash
# 이 3줄 명령어가 핵심
killall -9 GearApp 2>/dev/null
pkill -9 -f vsomeip 2>/dev/null
sudo rm -rf /tmp/vsomeip-*
```

---

## 오류 6: 멀티캐스트 그룹 미가입

### 📊 오류 로그
```bash
# 멀티캐스트 그룹 확인
$ ip maddr show eth0 | grep 224.244.224.245
# (아무것도 출력 안됨)  ❌
```

### 🔍 원인 분석
- ECU2가 [Proxy] 모드로 실행되어 Service Discovery 비활성화
- 멀티캐스트 그룹 224.244.224.245에 가입하지 않음
- ECU1의 OFFER 패킷을 수신할 수 없음

### ✅ 해결 방법

#### 1단계: 현재 상태 확인
```bash
# 두 ECU에서 실행
ip maddr show eth0 | grep 224.244.224.245

# ECU1 (정상)
# inet  224.244.224.245  ✅

# ECU2 (문제)
# (아무것도 출력 안됨)  ❌
```

#### 2단계: ECU2 로그 확인
```bash
cd ~/SEA-ME/DES_Head-Unit/app/GearApp
./run.sh

# 로그 확인
# [info] Instantiating routing manager [Proxy]  ← 문제!
# Proxy 모드는 Service Discovery 비활성화
```

#### 3단계: 설정 파일 수정
**파일:** `/app/GearApp/config/vsomeip_ecu2.json`

```json
{
    "applications": [
        {
            "name": "client-sample",
            "id": "0xFFFF"
        }
    ],
    "routing": "client-sample",  // ← 이 필드 추가로 [Host] 모드 활성화
    "service-discovery": {
        "enable": "true",  // ← 이미 있어야 함
        "multicast": "224.244.224.245",
        "port": "30490"
    }
}
```

#### 4단계: 완전 클린업 및 재시작
```bash
# 클린업
killall -9 GearApp 2>/dev/null
pkill -9 -f vsomeip 2>/dev/null
sudo rm -rf /tmp/vsomeip-*

# 멀티캐스트 라우팅 확인
ip route | grep 224.0.0.0
# 없으면 추가
sudo ip route add 224.0.0.0/4 dev eth0

# 재시작
cd ~/SEA-ME/DES_Head-Unit/app/GearApp
./run.sh
```

#### 5단계: 멀티캐스트 그룹 가입 확인
```bash
# 3-5초 대기 후
ip maddr show eth0 | grep 224.244.224.245

# 예상 출력 (성공)
# inet  224.244.224.245  ✅
```

### 📈 결과
```bash
# ECU2 멀티캐스트 그룹 가입 확인
$ ip maddr show eth0
2:	eth0
	link  01:00:5e:00:00:fb
	link  33:33:00:00:00:01
	link  01:00:5e:74:e0:f5
	inet  224.244.224.245  ✅
	inet6 ff02::1
```

### 📊 비교 분석

**[Proxy] 모드 (문제):**
- Service Discovery 비활성화
- 멀티캐스트 그룹 미가입
- OFFER 패킷 수신 불가

**[Host] 모드 (정상):**
```
[info] Instantiating routing manager [Host]
[info] Service Discovery enabled
[info] Multicast group joined: 224.244.224.245
[info] Service [1234.5678] is available.  ✅
```

---

## 오류 7: Connected: false

### 📊 오류 로그
```
# GearApp GUI
Connected: false  ❌
Service Status: Not Available

# ECU2 로그
[warning] Service [1234.5678] is not available.
[warning] REQUEST(0100): Service not found
```

### 🔍 원인 분석
- 위의 모든 문제가 복합적으로 발생
- vsomeip 프로세스 클린업 누락 → [Proxy] 모드 → 멀티캐스트 미가입 → Service Discovery 실패

### ✅ 해결 방법 (종합)

#### 1단계: 완전 클린업 (최우선!)
```bash
# ECU2에서 실행
killall -9 GearApp 2>/dev/null
killall -9 client-sample 2>/dev/null
pkill -9 -f vsomeip 2>/dev/null

# 확인
ps aux | grep -E "GearApp|vsomeip|client-sample"
# 아무것도 없어야 함 ✅

# 소켓 삭제
sudo rm -rf /tmp/vsomeip-*
sudo rm -rf /var/run/vsomeip-*

# 확인
ls -la /tmp/vsomeip-* 2>/dev/null
# No such file  ✅
```

#### 2단계: 네트워크 확인
```bash
# 케이블 연결
ip link show eth0
# <BROADCAST,MULTICAST,UP,LOWER_UP> state UP  ✅

# IP 설정
sudo ip addr add 192.168.1.101/24 dev eth0
sudo ip link set eth0 up

# 멀티캐스트 라우팅
sudo ip route add 224.0.0.0/4 dev eth0

# ping 테스트
ping -c 3 192.168.1.100
# 0% packet loss  ✅
```

#### 3단계: 설정 파일 최종 확인
**파일:** `/app/GearApp/config/vsomeip_ecu2.json`

```json
{
    "unicast": "192.168.1.101",
    "netmask": "255.255.255.0",
    "logging": {
        "level": "debug",
        "console": "true"
    },
    "applications": [
        {
            "name": "client-sample",
            "id": "0x0100"  // 0xFFFF → 0x0100 변경
        }
    ],
    "routing": "client-sample",  // ✅ 필수!
    "service-discovery": {
        "enable": "true",
        "multicast": "224.244.224.245",
        "port": "30490",
        "protocol": "udp"
    },
    "clients": [  // "services" → "clients" 변경
        {
            "service": "0x1234",
            "instance": "0x5678",
            "unreliable": "30501"
        }
    ]
}
```

#### 4단계: ECU1 먼저 시작
```bash
# ECU1에서 실행
cd ~/SEA-ME/DES_Head-Unit/app/VehicleControlECU
./run.sh

# 예상 로그
# [info] Instantiating routing manager [Host]
# [info] OFFER(1001): [1234.5678:1.0]  ✅
```

#### 5단계: 5초 대기 후 ECU2 시작
```bash
# ECU2에서 실행
sleep 5
cd ~/SEA-ME/DES_Head-Unit/app/GearApp
./run.sh

# 예상 로그
# [info] Instantiating routing manager [Host]
# [info] Client [0100] routes unicast:192.168.1.101
# [info] REQUEST(0100): [1234.5678:1.4294967295]
# [info] Service [1234.5678] is available.  ✅
# Connected: true  ✅
```

#### 6단계: 검증
```bash
# ECU2에서 실행

# 멀티캐스트 그룹 확인
ip maddr show eth0 | grep 224.244.224.245
# inet  224.244.224.245  ✅

# 패킷 수신 확인
sudo tcpdump -i eth0 -n 'host 224.244.224.245' -c 5
# 192.168.1.100 → 224.244.224.245 패킷 수신  ✅

# 소켓 확인
ls -la /tmp/vsomeip-*
# srwxr-xr-x /tmp/vsomeip-0  ✅
```

### 📈 결과
```
# GearApp GUI
Connected: true  ✅
Service Status: Available  ✅

# 기어 변경 테스트
[Button Click] P → D
✅ Gear change successful  ✅
```

---

## 📊 오류 해결 우선순위

### 🥇 1순위: 프로세스 클린업
**가장 중요! 모든 문제의 90%가 이것으로 해결됨**
```bash
killall -9 GearApp VehicleControlECU 2>/dev/null
pkill -9 -f vsomeip 2>/dev/null
sudo rm -rf /tmp/vsomeip-*
```

### 🥈 2순위: 설정 파일
**vsomeip_ecu2.json 필수 필드:**
- `"routing": "client-sample"` ← [Host] 모드 활성화
- `"clients": [...]` ← "services" 아님!
- `"id": "0x0100"` ← 0xFFFF 피하기

### 🥉 3순위: 네트워크 설정
```bash
# IP 설정
sudo ip addr add 192.168.1.10X/24 dev eth0

# 멀티캐스트 라우팅
sudo ip route add 224.0.0.0/4 dev eth0

# 케이블 확인
ip link show eth0  # LOWER_UP 확인
```

---

## 🔧 원스텝 수정 스크립트

### ECU2 완전 복구 스크립트
**파일:** `~/fix_ecu2.sh`

```bash
#!/bin/bash

echo "=== ECU2 GearApp 완전 복구 ==="

# 1. 프로세스 클린업
echo "[1/5] vsomeip 프로세스 종료..."
killall -9 GearApp 2>/dev/null
killall -9 client-sample 2>/dev/null
pkill -9 -f vsomeip 2>/dev/null
sudo rm -rf /tmp/vsomeip-* /var/run/vsomeip-*
echo "✅ 클린업 완료"

# 2. 프로세스 확인
echo "[2/5] 프로세스 확인..."
RUNNING=$(ps aux | grep -E "GearApp|vsomeip|client-sample" | grep -v grep)
if [ -z "$RUNNING" ]; then
    echo "✅ 모든 프로세스 종료됨"
else
    echo "❌ 아직 실행 중인 프로세스 있음:"
    echo "$RUNNING"
    exit 1
fi

# 3. 소켓 확인
echo "[3/5] 소켓 파일 확인..."
if ls /tmp/vsomeip-* 2>/dev/null; then
    echo "❌ 소켓 파일이 아직 남아있음"
    exit 1
else
    echo "✅ 소켓 파일 삭제됨"
fi

# 4. 네트워크 설정
echo "[4/5] 네트워크 설정..."
sudo ip addr flush dev eth0
sudo ip addr add 192.168.1.101/24 dev eth0
sudo ip link set eth0 up
sudo ip route add 224.0.0.0/4 dev eth0 2>/dev/null
echo "✅ 네트워크 설정 완료"

# 5. 연결 테스트
echo "[5/5] ECU1 연결 테스트..."
if ping -c 1 -W 2 192.168.1.100 >/dev/null 2>&1; then
    echo "✅ ECU1 연결 성공"
else
    echo "❌ ECU1 연결 실패 - 케이블 확인 필요"
    exit 1
fi

echo ""
echo "========================================="
echo "✅ 모든 준비 완료!"
echo "========================================="
echo ""
echo "다음 단계:"
echo "1. ECU1에서 VehicleControlECU 실행"
echo "2. 5초 대기"
echo "3. ECU2에서 ./run.sh 실행"
echo ""
```

**사용법:**
```bash
# 실행 권한 부여
chmod +x ~/fix_ecu2.sh

# 실행
~/fix_ecu2.sh

# 성공 후
cd ~/SEA-ME/DES_Head-Unit/app/GearApp
./run.sh
```

---

## 📝 핵심 교훈 정리

### 1️⃣ vsomeip는 상태를 유지한다
- 프로세스 종료 후에도 소켓 파일이 남아있음
- 설정 변경 시 **반드시** 클린업 필요
- `killall + rm -rf`가 해결의 90%

### 2️⃣ 각 ECU는 독립적인 [Host]
- 라우팅 매니저는 네트워크로 공유 불가
- `"routing": "client-sample"` 필수
- [Proxy] 모드는 Service Discovery 비활성화

### 3️⃣ 클라이언트는 "clients" 사용
- ❌ `"services"`: 서비스 제공자용
- ✅ `"clients"`: 서비스 소비자용
- GearApp은 클라이언트이므로 "clients"

### 4️⃣ 물리 계층 먼저 확인
- LOWER_UP 상태 확인
- ping 테스트
- tcpdump로 패킷 확인

### 5️⃣ 실행 순서 중요
1. 네트워크 설정
2. 프로세스 클린업
3. ECU1 먼저 실행
4. 5초 대기
5. ECU2 실행

---

## 🎯 빠른 진단 체크리스트

```bash
# ✅ 1. 케이블 연결
ip link show eth0 | grep LOWER_UP

# ✅ 2. IP 설정
ip addr show eth0 | grep "192.168.1.10"

# ✅ 3. 멀티캐스트 라우팅
ip route | grep "224.0.0.0/4"

# ✅ 4. 프로세스 클린 상태
ps aux | grep -E "vsomeip|GearApp" | grep -v grep
# (아무것도 없어야 함)

# ✅ 5. 소켓 파일 없음
ls /tmp/vsomeip-* 2>&1 | grep "No such file"

# ✅ 6. 설정 파일 "routing" 필드
grep -A 2 '"routing"' ~/SEA-ME/DES_Head-Unit/app/GearApp/config/vsomeip_ecu2.json

# ✅ 7. ECU1 연결
ping -c 1 192.168.1.100
```

**모든 항목이 ✅이면 100% 성공!**

---

## 📚 관련 문서
- [ECU_BOOT_TO_COMMUNICATION_GUIDE.md](./ECU_BOOT_TO_COMMUNICATION_GUIDE.md) - 전체 실행 가이드
- [ECU_COMMUNICATION_FIX.md](./ECU_COMMUNICATION_FIX.md) - 아키텍처 설명
- [COMMUNICATION_DEBUG_SOLUTION.md](./COMMUNICATION_DEBUG_SOLUTION.md) - 네트워크 디버깅
