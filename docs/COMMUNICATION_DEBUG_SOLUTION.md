# vsomeip ECU간 통신 실패 원인 및 해결

## 🚨 근본 원인: 물리적 네트워크 연결 문제

### 로그 분석 결과

**ECU1 (VehicleControlECU @ 192.168.1.100):**
```
eth0: <NO-CARRIER,BROADCAST,MULTICAST,UP> state DOWN
      ^^^^^^^^^^
```
- ❌ **NO-CARRIER**: Ethernet 케이블 연결되지 않음 또는 상대방 장치 꺼짐
- ❌ **state DOWN**: 인터페이스는 UP이지만 물리적 링크 없음

**ECU2 (GearApp @ 192.168.1.101):**
```
eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> state UP
                                ^^^^^^^^^
```
- ✅ **LOWER_UP**: 물리적 링크 정상
- ✅ **state UP**: 인터페이스 정상

**결론:** ECU1과 ECU2 사이의 Ethernet 케이블이 제대로 연결되지 않았습니다!

---

## ✅ 즉시 해결 방법

### 1단계: ECU1 Ethernet 케이블 물리적 확인

**ECU1에서 실행:**
```bash
# 1. 케이블 연결 상태 확인
ip link show eth0

# ❌ 문제: NO-CARRIER가 보이면 케이블 문제
# ✅ 정상: LOWER_UP이 보여야 함

# 2. 물리적 체크리스트:
# - Ethernet 케이블이 ECU1의 포트에 완전히 꽂혀있는지 확인
# - 케이블 LED 램프가 켜져있는지 확인
# - 케이블이 손상되지 않았는지 확인 (다른 케이블로 테스트)
# - ECU2가 전원이 켜져있고 eth0가 UP 상태인지 확인

# 3. 케이블 재연결 후 상태 재확인
ip link show eth0

# 정상 출력 예시:
# eth0: <BROADCAST,MULTICAST,UP,LOWER_UP>
#                               ^^^^^^^^^
```

### 2단계: 네트워크 연결 테스트

**ECU1에서 ECU2로 ping (케이블 연결 후):**
```bash
ping -c 4 192.168.1.101
```

**✅ 성공 시 출력:**
```
PING 192.168.1.101 (192.168.1.101) 56(84) bytes of data.
64 bytes from 192.168.1.101: icmp_seq=1 ttl=64 time=0.234 ms
64 bytes from 192.168.1.101: icmp_seq=2 ttl=64 time=0.187 ms
64 bytes from 192.168.1.101: icmp_seq=3 ttl=64 time=0.192 ms
64 bytes from 192.168.1.101: icmp_seq=4 ttl=64 time=0.205 ms

--- 192.168.1.101 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss
```

**❌ 실패 시 (Destination Host Unreachable):**
- 케이블을 다시 확인
- 다른 케이블로 교체
- ECU2의 전원 및 네트워크 상태 확인

### 3단계: 멀티캐스트 라우팅 추가 (ping 성공 후)

**ECU1에서:**
```bash
# 멀티캐스트 그룹 라우팅 추가
sudo route add -host 224.244.224.245 dev eth0

# 또는 (라우팅 명령어가 없는 경우)
sudo ip route add 224.244.224.245/32 dev eth0

# 확인
ip route | grep 224.244.224.245
```

**ECU2에서:**
```bash
# 멀티캐스트 그룹 라우팅 추가
sudo route add -host 224.244.224.245 dev eth0

# 또는
sudo ip route add 224.244.224.245/32 dev eth0

# 확인
ip route | grep 224.244.224.245
```

### 4단계: VehicleControlECU 재시작 (ECU1)

**ECU1에서:**
```bash
cd ~/VehicleControlECU

# 이전 프로세스 종료 (Ctrl+C)
# 또는
killall VehicleControlECU

# vsomeip 소켓 정리
sudo rm -f /tmp/vsomeip-*

# 재시작
sudo ./run.sh
```

**✅ 성공 로그 확인:**
```
[info] Instantiating routing manager [Host].
[info] create_routing_root: Routing root @ /tmp/vsomeip-0
[info] Network interface "eth0" state changed: up
[info] OFFER(1001): [1234.5678:1.0] (true)
```

**중요:** 이번에는 `eth0` 상태가 `LOWER_UP`으로 변경되어야 합니다!

### 5단계: GearApp 재시작 (ECU2)

**ECU2에서:**
```bash
cd ~/GearApp

# 이전 프로세스 종료
killall GearApp

# vsomeip 소켓 정리
sudo rm -f /tmp/vsomeip-*

# 재시작
./run.sh
```

**✅ 성공 로그 확인:**
```
[info] Instantiating routing manager [Host].
[info] REQUEST(0100): [1234.5678:1.4294967295]
[info] Service [1234.5678] is available.  ← 이 로그가 나와야 함!
✅ Connected to VehicleControl service
   - Connected: true  ← false에서 true로 변경!
```

---

## 📊 통신 성공 확인 방법

### ECU1 로그 확인

**Service Discovery 송신:**
```
[info] OFFER(1001): [1234.5678:1.0] (true)
[info] Service Discovery: Offering service 0x1234
```

**ECU2 연결 감지:**
```
[info] Registering client 0x100
[info] REMOTE SUBSCRIBE(0100): [1234.5678.1234:9c40]
[info] REMOTE SUBSCRIBE(0100): [1234.5678.1234:9c41]
```

### ECU2 로그 확인

**Service 발견:**
```
[info] Service [1234.5678] is available.
[info] SUBSCRIBE ACK(0100): [1234.5678.1234:9c40]
✅ Connected to VehicleControl service
   - Connected: true
```

**RPC 호출 성공:**
```
GearManager: Requesting gear change via vsomeip: "P" -> "D"
[GearManager → vsomeip] Requesting gear change: "D"
✅ Gear change successful  ← "service not available" 에러 사라짐!
```

---

## 🔧 추가 디버깅 도구

### 네트워크 패킷 모니터링 (선택사항)

**ECU1에서 Service Discovery 패킷 확인:**
```bash
sudo tcpdump -i eth0 -n 'udp and port 30490' -v
```

**예상 출력 (통신 성공 시):**
```
IP 192.168.1.100.30490 > 224.244.224.245.30490: UDP, length 32 (OFFER)
IP 192.168.1.101.30490 > 224.244.224.245.30490: UDP, length 24 (FIND)
```

### vsomeip 진단 스크립트

**ECU1에서 실행:**
```bash
cat > /tmp/check_ecu1.sh << 'EOF'
#!/bin/bash
echo "=== ECU1 VehicleControlECU Status ==="
echo ""
echo "1. Process:"
ps aux | grep VehicleControlECU | grep -v grep
echo ""
echo "2. Network Interface:"
ip link show eth0
echo ""
echo "3. IP Address:"
ip addr show eth0 | grep "inet "
echo ""
echo "4. Routes:"
ip route | grep eth0
echo ""
echo "5. Multicast Groups:"
ip maddr show eth0 | grep 224.244.224.245 || echo "Not joined"
echo ""
echo "6. vsomeip Sockets:"
ls -la /tmp/vsomeip-* 2>/dev/null || echo "No sockets"
echo ""
echo "7. Listening Ports:"
sudo netstat -unlp | grep -E '30490|30501'
EOF

chmod +x /tmp/check_ecu1.sh
/tmp/check_ecu1.sh
```

**ECU2에서 실행:**
```bash
cat > /tmp/check_ecu2.sh << 'EOF'
#!/bin/bash
echo "=== ECU2 GearApp Status ==="
echo ""
echo "1. Process:"
ps aux | grep GearApp | grep -v grep
echo ""
echo "2. Network Interface:"
ip link show eth0
echo ""
echo "3. Ping ECU1:"
ping -c 2 192.168.1.100 2>/dev/null && echo "✅ Reachable" || echo "❌ Unreachable"
echo ""
echo "4. vsomeip Sockets:"
ls -la /tmp/vsomeip-* 2>/dev/null || echo "No sockets"
EOF

chmod +x /tmp/check_ecu2.sh
/tmp/check_ecu2.sh
```

---

## ✅ 성공 체크리스트

- [ ] ECU1: `eth0` 상태가 `LOWER_UP` (케이블 연결됨)
- [ ] ECU2: `eth0` 상태가 `LOWER_UP` (케이블 연결됨)
- [ ] 양방향 ping 성공 (0% packet loss)
- [ ] 멀티캐스트 라우팅 추가 완료 (양쪽 ECU)
- [ ] ECU1: "OFFER(1001): [1234.5678:1.0]" 로그 출력
- [ ] ECU2: "Service [1234.5678] is available" 로그 출력
- [ ] ECU2: "Connected: true" 표시
- [ ] 기어 변경 시 "service not available" 에러 사라짐
- [ ] ECU1 로그에 "REMOTE SUBSCRIBE" 메시지 출력

---

## 📝 요약

**근본 원인:**
- ECU1의 Ethernet 포트에 케이블이 제대로 연결되지 않음 (`NO-CARRIER`)

**해결 방법:**
1. ✅ Ethernet 케이블 재연결 (물리적 체크)
2. ✅ `ip link show eth0`로 `LOWER_UP` 확인
3. ✅ 양방향 ping 테스트
4. ✅ 멀티캐스트 라우팅 추가 (양쪽 ECU)
5. ✅ vsomeip 소켓 정리 후 앱 재시작 (순서: ECU1 → ECU2)

**예상 결과:**
- Service Discovery 성공
- RPC 호출 성공
- Event 브로드캐스트 수신 성공

---

**작성일:** 2025-11-01  
**버전:** 1.0 - 물리적 네트워크 문제 진단 및 해결
