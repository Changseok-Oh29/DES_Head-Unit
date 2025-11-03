# 재부팅 후 빠른 복구 가이드

## 🔴 문제 증상
```
[info] Instantiating routing manager [Host].  ← ECU2가 Host로 실행됨 (문제!)
⚠️  VehicleControl service is not available
❌ Cannot request gear change: service not available
```

## ✅ 해결 방법 (순서대로 실행)

### 1단계: NetworkManager에서 eth0 제외 (WiFi 유지!)
```bash
# ECU2에서 실행
# NetworkManager가 eth0를 관리하지 않도록 설정
sudo nmcli device set eth0 managed no

# 확인
nmcli device status
# eth0가 "unmanaged" 상태여야 함
```

**⚠️ 이렇게 하면:**
- ✅ WiFi (wlan0)는 NetworkManager가 계속 관리 → SSH 유지
- ✅ eth0는 수동 설정 가능 → IP 주소 안 사라짐
- ✅ 재부팅 후에도 유지됨

### 2단계: eth0 네트워크 수동 설정
```bash
# ECU2에서 실행
sudo ip link set eth0 up
sudo ip addr add 192.168.1.101/24 dev eth0
sudo ip route add 224.0.0.0/4 dev eth0

# 확인
ip addr show eth0           # 192.168.1.101 확인
ip route | grep 224         # 224.0.0.0/4 확인
```

### 3단계: vsomeip 프로세스 완전 클린업
```bash
# ECU2에서 실행
killall -9 GearApp 2>/dev/null
killall -9 client-sample 2>/dev/null
pkill -9 -f vsomeip 2>/dev/null
sudo rm -rf /tmp/vsomeip-*
sudo rm -rf /var/run/vsomeip-*

# 확인 (아무것도 출력되지 않아야 함)
ps aux | grep -E "GearApp|vsomeip|client-sample" | grep -v grep
ls /tmp/vsomeip-* 2>&1
```

### 4단계: ECU1 먼저 시작
```bash
# ECU1 (192.168.1.100)에서 실행
cd ~/VehicleControlECU
./run.sh

# ✅ 성공 시 출력 확인:
# [info] Instantiating routing manager [Host].
# [info] OFFER(1001): [1234.5678:1.0]
```

### 5단계: 5초 대기 후 ECU2 시작
```bash
# ECU2 (192.168.1.101)에서 실행
sleep 5
cd ~/GearApp
./run.sh

# ✅ 성공 시 출력 확인:
# [info] Instantiating routing manager [Host].  ← ECU2도 Host로 실행됨
# [info] Service [1234.5678] is available.  ← 이 메시지가 나와야 함!
# ✅ Connected to VehicleControl service
# Connected: true  ← 중요!
```

---

## 🔍 현재 설정 분석

### ECU2 vsomeip_ecu2.json
```json
{
    "routing": "client-sample",  ← ECU2가 자체 Host 모드로 실행
    "applications": [
        {
            "name": "client-sample",
            "id": "0x0100"
        }
    ]
}
```

**현재 아키텍처:**
```
ECU1 (192.168.1.100)          ECU2 (192.168.1.101)
┌─────────────────┐          ┌─────────────────┐
│ VehicleControl  │          │   GearApp       │
│ [Host]          │          │   [Host]        │  ← 각자 독립적인 Host
│ /tmp/vsomeip-0  │          │   /tmp/vsomeip-0│
└─────────────────┘          └─────────────────┘
        ↓                            ↓
  Service Discovery          Service Discovery
        ↓                            ↓
    Multicast 224.244.224.245:30490  ← 네트워크로 통신
```

**✅ 이것이 올바른 아키텍처입니다!**
- 각 ECU는 독립적인 [Host] 라우팅 매니저를 실행
- Service Discovery를 통해 네트워크로 통신
- 멀티캐스트 그룹 224.244.224.245에 가입 필요

---

## ❌ 오류 원인

### 문제 1: 멀티캐스트 라우팅 누락
```bash
# 재부팅 후 멀티캐스트 라우트 삭제됨
ip route | grep 224
# (아무것도 출력 안됨)  ← 문제!
```

**해결:**
```bash
sudo ip route add 224.0.0.0/4 dev eth0
```

### 문제 2: Service Discovery 실패
- 멀티캐스트 라우팅 없으면 224.244.224.245로 패킷 전송 불가
- ECU1의 OFFER 메시지를 ECU2가 수신하지 못함
- `⚠️ VehicleControl service is not available`

### 문제 3: 멀티캐스트 그룹 미가입
```bash
# ECU2에서 확인
ip maddr show eth0 | grep 224.244.224.245
# (아무것도 출력 안됨)  ← Service Discovery 비활성화됨
```

---

## 📋 완전 복구 스크립트

### ECU2 자동 복구 스크립트
**파일: `~/fix_gearapp.sh`**

```bash
#!/bin/bash

echo "=== GearApp 완전 복구 스크립트 ==="

# 1. NetworkManager에서 eth0 제외 (WiFi 유지!)
echo "[1/6] NetworkManager에서 eth0 제외..."
sudo nmcli device set eth0 managed no
echo "✅ eth0를 unmanaged 상태로 변경 (WiFi는 유지됨)"

# 2. 네트워크 설정
echo "[2/6] 네트워크 설정..."
sudo ip link set eth0 up
sudo ip addr add 192.168.1.101/24 dev eth0 2>/dev/null
sudo ip route add 224.0.0.0/4 dev eth0 2>/dev/null
echo "✅ 네트워크 설정 완료"

# 3. 클린업
echo "[3/6] vsomeip 클린업..."
killall -9 GearApp 2>/dev/null
killall -9 client-sample 2>/dev/null
pkill -9 -f vsomeip 2>/dev/null
sudo rm -rf /tmp/vsomeip-* /var/run/vsomeip-*
echo "✅ 클린업 완료"

# 4. 프로세스 확인
echo "[4/6] 프로세스 확인..."
RUNNING=$(ps aux | grep -E "GearApp|vsomeip|client-sample" | grep -v grep)
if [ -z "$RUNNING" ]; then
    echo "✅ 모든 프로세스 종료됨"
else
    echo "❌ 아직 실행 중인 프로세스 있음:"
    echo "$RUNNING"
    exit 1
fi

# 5. 네트워크 확인
echo "[5/6] 네트워크 확인..."
if ping -c 1 -W 2 192.168.1.100 >/dev/null 2>&1; then
    echo "✅ ECU1 연결 성공"
else
    echo "⚠️  ECU1 연결 실패 - ECU1 실행 여부 확인 필요"
fi

# 6. 멀티캐스트 라우팅 확인
echo "[6/6] 멀티캐스트 라우팅 확인..."
if ip route | grep -q "224.0.0.0/4"; then
    echo "✅ 멀티캐스트 라우팅 설정됨"
else
    echo "❌ 멀티캐스트 라우팅 누락"
    exit 1
fi

echo ""
echo "========================================="
echo "✅ 모든 준비 완료!"
echo "========================================="
echo ""
echo "📡 네트워크 상태:"
echo "   - WiFi: $(nmcli device status | grep wifi | awk '{print $3}') (SSH 유지됨)"
echo "   - eth0: unmanaged (수동 설정 유지됨)"
echo ""
echo "다음 단계:"
echo "1. ECU1에서 VehicleControlECU 실행 확인"
echo "2. 이 터미널에서:"
echo "   cd ~/GearApp"
echo "   ./run.sh"
echo ""
```

**사용법:**
```bash
# 실행 권한 부여 (최초 1회)
chmod +x ~/fix_gearapp.sh

# 매번 재부팅 후 실행
~/fix_gearapp.sh

# 성공하면
cd ~/GearApp
./run.sh
```

---

## 🎯 빠른 체크리스트

재부팅 후 매번 확인:

```bash
# ✅ 1. NetworkManager에서 eth0 제외 (WiFi 유지!)
sudo nmcli device set eth0 managed no

# ✅ 2. eth0 활성화
sudo ip link set eth0 up

# ✅ 3. IP 주소
sudo ip addr add 192.168.1.101/24 dev eth0

# ✅ 4. 멀티캐스트 라우팅 (중요!)
sudo ip route add 224.0.0.0/4 dev eth0

# ✅ 5. 클린업
killall -9 GearApp 2>/dev/null
sudo rm -rf /tmp/vsomeip-*

# ✅ 6. 확인
nmcli device status          # eth0: unmanaged 확인
ip route | grep 224          # 224.0.0.0/4 확인
ip addr show eth0            # 192.168.1.101 확인
ping -c 1 192.168.1.100      # ECU1 연결 확인

# ✅ 7. 실행
cd ~/GearApp
./run.sh
```

---

## 💡 핵심 포인트

### NetworkManager 관리 제외의 장점
```bash
sudo nmcli device set eth0 managed no
```

**✅ 장점:**
- WiFi (wlan0)는 NetworkManager가 계속 관리 → **SSH 연결 유지**
- eth0는 수동 설정 가능 → **IP 주소 안 사라짐**
- 재부팅 후에도 설정 유지됨

**vs. NetworkManager stop (❌ 나쁜 방법):**
```bash
sudo systemctl stop NetworkManager  # ← WiFi도 끊김!
```
- ❌ WiFi 연결 끊김 → SSH 불가능
- ❌ 모니터/키보드 필요
- ❌ 매번 재시작 필요

---

## 📊 성공 로그 예시

**ECU2 성공 시 로그:**
```
[info] Instantiating routing manager [Host].
[info] create_routing_root: Routing root @ /tmp/vsomeip-0
[info] Service Discovery enabled.
[info] Client [0100] routes unicast:192.168.1.101
[info] REQUEST(0100): [1234.5678:1.4294967295]
[info] Service [1234.5678] is available.  ← 핵심!
✅ Connected to VehicleControl service
   Domain: "local"
   Instance: "vehiclecontrol.VehicleControl"
   Connected: true  ← 중요!
```

**멀티캐스트 그룹 가입 확인:**
```bash
# 5-10초 대기 후
ip maddr show eth0 | grep 224.244.224.245
# inet  224.244.224.245  ← 출력되어야 함!
```

---

## 🔧 영구 해결책

매번 재부팅 후 수동 설정하기 번거로우면:

### 부팅 시 자동 실행 스크립트
```bash
# crontab에 추가
crontab -e

# 다음 라인 추가
@reboot sleep 10 && /home/seame2025/fix_gearapp.sh
```

### 또는 systemd 서비스
```bash
sudo nano /etc/systemd/system/ecu2-network.service
```

```ini
[Unit]
Description=ECU2 Network Setup
After=network.target

[Service]
Type=oneshot
User=root
ExecStart=/bin/bash -c 'ip link set eth0 up && ip addr add 192.168.1.101/24 dev eth0 && ip route add 224.0.0.0/4 dev eth0'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl enable ecu2-network.service
sudo systemctl start ecu2-network.service
```

---

## 🆘 여전히 문제 발생 시

### 1. ECU1이 실행 중인지 확인
```bash
# ECU1에서 실행
ps aux | grep VehicleControlECU

# 출력이 없으면 ECU1 시작
cd ~/VehicleControlECU
./run.sh
```

### 2. tcpdump로 패킷 확인
```bash
# ECU2에서 실행
sudo tcpdump -i eth0 -n 'host 224.244.224.245' -v

# ECU1의 OFFER 패킷이 보여야 함:
# 192.168.1.100.30490 > 224.244.224.245.30490: SOMEIP
```

### 3. 완전 클린 시작
```bash
# ECU2 재부팅
sudo reboot

# 재부팅 후
~/fix_gearapp.sh
cd ~/GearApp
./run.sh
```

---

## 📚 관련 문서
- [ECU_BOOT_TO_COMMUNICATION_GUIDE.md](./ECU_BOOT_TO_COMMUNICATION_GUIDE.md) - 전체 실행 가이드
- [TROUBLESHOOTING_GUIDE.md](./TROUBLESHOOTING_GUIDE.md) - 오류 해결 가이드
- [ECU_COMMUNICATION_FIX.md](./ECU_COMMUNICATION_FIX.md) - 아키텍처 설명
