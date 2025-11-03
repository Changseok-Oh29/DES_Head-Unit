<로그>
***1. ECU 1 (서버) 로그: ***


team06@greywolf1:~ $ cd VehicleControlECU/
team06@greywolf1:~/VehicleControlECU $ # 1. eth0 인터페이스 활성화
sudo ip link set eth0 up

# 2. IP 주소 할당 (즉시 적용됨)
sudo ip addr add 192.168.1.100/24 dev eth0

# 3. IP 확인
ip addr show eth0
# inet 192.168.1.100/24 가 보여야 함
2: eth0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc mq state DOWN group default qlen 1000
    link/ether d8:3a:dd:a9:d6:ce brd ff:ff:ff:ff:ff:ff
    inet 192.168.1.100/24 scope global eth0
       valid_lft forever preferred_lft forever
team06@greywolf1:~/VehicleControlECU $ sudo ./run.sh 
═══════════════════════════════════════════════════════
Starting VehicleControlECU - DEPLOYMENT MODE
ECU1 @ 192.168.1.100
═══════════════════════════════════════════════════════

📋 Configuration:
   Mode: DEPLOYMENT (Raspberry Pi ECU1)
   Local IP: 192.168.1.100
   Role: Service Provider (routing manager)
   VSOMEIP_CONFIGURATION=/home/team06/VehicleControlECU/config/vsomeip_ecu1.json
   COMMONAPI_CONFIG=/home/team06/VehicleControlECU/config/commonapi_ecu1.ini

🔧 Hardware:
   - PiRacer motor controller
   - Gamepad input
   - Battery monitor

Starting service...
═══════════════════════════════════════════════════════

[CAPI][INFO] Loading configuration file /etc//commonapi-someip.ini
═══════════════════════════════════════════════════════
VehicleControlECU (ECU1) Starting...
Service: VehicleControl (PiRacer Hardware Control)
═══════════════════════════════════════════════════════

🔧 Initializing GPIO library...
✅ GPIO library initialized

🚗 Initializing PiRacer hardware...
✅ BatteryMonitor initialized (INA219)
✅ PiRacerController initialized
   - Steering Controller: 0x40
   - Throttle Controller: 0x60
   - Battery Monitor: INA219
🔧 Warming up motors...
✅ Warm-up complete

🎮 Initializing gamepad...
✅ Gamepad connected: /dev/input/js0
✅ GamepadHandler initialized
🎮 Gamepad polling started
✅ Gamepad controls active
   A = Drive, B = Park, X = Neutral, Y = Reverse
   Left Stick = Steering, Right Stick = Throttle

🌐 Initializing vsomeip service...
✅ VehicleControlStubImpl initialized
[CAPI][INFO] Loading configuration file '/home/team06/VehicleControlECU/config/commonapi_ecu1.ini'
[CAPI][INFO] Using default binding 'someip'
[CAPI][INFO] Using default shared library folder '/usr/local/lib/commonapi'
[CAPI][INFO] Registering function for creating "vehiclecontrol.VehicleControl:v1_0" stub adapter.
[CAPI][INFO] Registering stub for "local:vehiclecontrol.VehicleControl:v1_0:vehiclecontrol.VehicleControl"
2025-11-01 16:50:37.811684 VehicleControlECU [info] Using configuration file: "/home/team06/VehicleControlECU/config/vsomeip_ecu1.json".
2025-11-01 16:50:37.811844 VehicleControlECU [info] Parsed vsomeip configuration in 4ms
2025-11-01 16:50:37.811887 VehicleControlECU [info] Configuration module loaded.
2025-11-01 16:50:37.811924 VehicleControlECU [info] Security disabled!
2025-11-01 16:50:37.811937 VehicleControlECU [info] Initializing vsomeip (3.5.8) application "VehicleControlECU".
2025-11-01 16:50:37.812077 VehicleControlECU [info] Instantiating routing manager [Host].
2025-11-01 16:50:37.814142 VehicleControlECU [info] create_routing_root: Routing root @ /tmp/vsomeip-0
2025-11-01 16:50:37.814395 VehicleControlECU [info] Service Discovery enabled. Trying to load module.
2025-11-01 16:50:37.826711 VehicleControlECU [info] Service Discovery module loaded.
2025-11-01 16:50:37.826856 VehicleControlECU [info] Application(VehicleControlECU, 1001) is initialized (11, 100).
2025-11-01 16:50:37.827269 VehicleControlECU [info] offer_event: Event [1234.5678.9c40] uses configured cycle time 0ms
2025-11-01 16:50:37.827241 VehicleControlECU [info] Starting vsomeip application "VehicleControlECU" (1001) using 2 threads I/O nice 0 boost event loop period 0
2025-11-01 16:50:37.827607 VehicleControlECU [info] main dispatch thread id from application: 1001 (VehicleControlECU) is: 7f89cde100 TID: 2750
2025-11-01 16:50:37.827742 VehicleControlECU [info] shutdown thread id from application: 1001 (VehicleControlECU) is: 7f894ce100 TID: 2751
2025-11-01 16:50:37.829086 VehicleControlECU [info] Client [1001] routes unicast:192.168.1.100, netmask:255.255.255.0
2025-11-01 16:50:37.829131 VehicleControlECU [info] REGISTER EVENT(1001): [1234.5678.9c40:is_provider=true]
2025-11-01 16:50:37.829160 VehicleControlECU [info] offer_event: Event [1234.5678.9c41] uses configured cycle time 0ms
2025-11-01 16:50:37.829190 VehicleControlECU [info] REGISTER EVENT(1001): [1234.5678.9c41:is_provider=true]
2025-11-01 16:50:37.829234 VehicleControlECU [info] netlink: from 0 to 1, if=0, mc=0, count=0
2025-11-01 16:50:37.829268 VehicleControlECU [info] rmi::offer_service added service: 1234 to pending_sd_offers_.size = 1
2025-11-01 16:50:37.829469 VehicleControlECU [info] create_local_server: Listening @ /tmp/vsomeip-1001
2025-11-01 16:50:37.829497 VehicleControlECU [info] Watchdog is disabled!
2025-11-01 16:50:37.829663 VehicleControlECU [info] OFFER(1001): [1234.5678:1.0] (true)
✅ VehicleControl service registered
2025-11-01 16:50:37.829805 VehicleControlECU [info] io thread id from application: 1001 (VehicleControlECU) is: 7f8a4ee100 TID: 2749
   Domain: "local"
2025-11-01 16:50:37.829812 VehicleControlECU [info] io thread id from application: 1001 (VehicleControlECU) is: 7f7bfff100 TID: 2753
   Instance: "vehiclecontrol.VehicleControl"

📡 Setting up periodic state broadcast...
2025-11-01 16:50:37.829954 VehicleControlECU [info] netlink: from 1 to 2, if=2, mc=0, count=0
2025-11-01 16:50:37.829984 VehicleControlECU [info] vSomeIP 3.5.8 | (default)
✅ Broadcasting vehicle state at 10Hz

═══════════════════════════════════════════════════════
✅ VehicleControlECU is running!

📌 Current State:
   - Gear: "P"
2025-11-01 16:50:37.830128 VehicleControlECU [info] netlink: from 2 to 3, if=2, mc=0, count=1
2025-11-01 16:50:37.830218 VehicleControlECU [warning] Network interface "eth0" state changed: up
   - Speed: 0 km/h
   - Battery: 70 %

🎮 Gamepad Controls:
   A = Drive   B = Park   X = Neutral   Y = Reverse
   Left Analog = Steering   Right Analog Y = Throttle

Press Ctrl+C to stop...
═══════════════════════════════════════════════════════
📡 [Event] vehicleStateChanged: Gear: "P" Speed: 0 Battery: 71 %
📡 [Event] vehicleStateChanged: Gear: "P" Speed: 0 Battery: 71 %





***2. ECU 2 (클라이언트) 로그:***


seame2025@seameteam7:~ $ cd GearApp/
seame2025@seameteam7:~/GearApp $ # 1. eth0 활성화
sudo ip link set eth0 up

# 2. IP 주소 할당
sudo ip addr add 192.168.1.101/24 dev eth0

# 3. IP 확인
ip addr show eth0
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP group default qlen 1000
    link/ether d8:3a:dd:0f:55:ba brd ff:ff:ff:ff:ff:ff
    inet 192.168.1.101/24 scope global eth0
       valid_lft forever preferred_lft forever
seame2025@seameteam7:~/GearApp $ ./run.sh 
═══════════════════════════════════════════════════════
Starting GearApp - vsomeip Client
ECU2 @ 192.168.1.101
═══════════════════════════════════════════════════════

📋 Configuration:
   Mode: vsomeip Client (ECU2)
   Local IP: 192.168.1.101
   Role: Service Consumer (connects to ECU1)
   VSOMEIP_CONFIGURATION=/home/seame2025/GearApp/config/vsomeip_ecu2.json
   COMMONAPI_CONFIG=/home/seame2025/GearApp/config/commonapi_ecu2.ini

🎯 Connecting to:
   - VehicleControlECU @ ECU1 (192.168.1.100)

Starting application...
═══════════════════════════════════════════════════════

[CAPI][INFO] Loading configuration file /etc//commonapi-someip.ini
QStandardPaths: wrong permissions on runtime directory /run/user/1000, 0770 instead of 0700
═══════════════════════════════════════════════════════
GearApp Process Starting...
Service: GearManager (Gear Control + vsomeip Client)
═══════════════════════════════════════════════════════
VehicleControlClient created
🔌 Connecting to VehicleControl service...
[CAPI][INFO] Loading configuration file '/home/seame2025/GearApp/config/commonapi_ecu2.ini'
[CAPI][INFO] Using default binding 'someip'
[CAPI][INFO] Using default shared library folder '/usr/local/lib/commonapi'
2025-11-01 17:51:00.366016 GearApp [info] Using configuration file: "/home/seame2025/GearApp/config/vsomeip_ecu2.json".
2025-11-01 17:51:00.366223 GearApp [info] Parsed vsomeip configuration in 4ms
2025-11-01 17:51:00.366267 GearApp [info] Configuration module loaded.
2025-11-01 17:51:00.366300 GearApp [info] Security disabled!
2025-11-01 17:51:00.366327 GearApp [info] Initializing vsomeip (3.5.8) application "client-sample".
2025-11-01 17:51:00.366485 GearApp [info] Instantiating routing manager [Host].
2025-11-01 17:51:00.368467 GearApp [info] create_routing_root: Routing root @ /tmp/vsomeip-0
2025-11-01 17:51:00.368704 GearApp [info] Service Discovery enabled. Trying to load module.
2025-11-01 17:51:00.380471 GearApp [info] Service Discovery module loaded.
2025-11-01 17:51:00.380621 GearApp [info] Application(client-sample, 0100) is initialized (11, 100).
2025-11-01 17:51:00.380977 GearApp [info] Starting vsomeip application "client-sample" (0100) using 2 threads I/O nice 0 boost event loop period 0
2025-11-01 17:51:00.381237 GearApp [info] main dispatch thread id from application: 0100 (client-sample) is: 7fa134f100 TID: 2831
2025-11-01 17:51:00.381381 GearApp [info] shutdown thread id from application: 0100 (client-sample) is: 7fa0b3f100 TID: 2832
2025-11-01 17:51:00.383862 GearApp [info] Client [0100] routes unicast:192.168.1.101, netmask:255.255.255.0
2025-11-01 17:51:00.383912 GearApp [info] REGISTER EVENT(0100): [1234.5678.9c40:is_provider=false]
2025-11-01 17:51:00.383949 GearApp [info] REGISTER EVENT(0100): [1234.5678.9c41:is_provider=false]
2025-11-01 17:51:00.384008 GearApp [info] netlink: from 0 to 1, if=0, mc=0, count=0
2025-11-01 17:51:00.384020 GearApp [info] REQUEST(0100): [1234.5678:1.4294967295]
2025-11-01 17:51:00.384215 GearApp [info] create_local_server: Listening @ /tmp/vsomeip-100
2025-11-01 17:51:00.384281 GearApp [info] Watchdog is disabled!
✅ Proxy created successfully
2025-11-01 17:51:00.384464 GearApp [info] io thread id from application: 0100 (client-sample) is: 7fa1b5f100 TID: 2830
📡 Subscribing to VehicleControl events...
⚠️  VehicleControl service is not available
2025-11-01 17:51:00.384642 GearApp [info] netlink: from 1 to 2, if=2, mc=0, count=0
2025-11-01 17:51:00.384702 GearApp [info] SUBSCRIBE(0100): [1234.5678.1234:9c41:1]
2025-11-01 17:51:00.384525 GearApp [info] io thread id from application: 0100 (client-sample) is: 7f937ef100 TID: 2834
2025-11-01 17:51:00.384799 GearApp [info] SUBSCRIBE(0100): [1234.5678.1234:9c40:1]
✅ Event subscriptions setup complete
2025-11-01 17:51:00.384875 GearApp [info] vSomeIP 3.5.8 | (default)
✅ Connected to VehicleControl service
2025-11-01 17:51:00.385003 GearApp [info] netlink: from 2 to 3, if=2, mc=0, count=1
   Domain: "local"
   Instance: "vehiclecontrol.VehicleControl"
GearManager initialized with position: "P"
✅ Connection established: VehicleControlClient → GearManager
✅ Connection established: GearManager → VehicleControlClient

✅ GearManager initialized
2025-11-01 17:51:00.385232 GearApp [warning] Network interface "eth0" state changed: up
   - Current Gear: "P"

✅ VehicleControlClient initialized
   - Connected: false
   - Service: VehicleControl @ ECU1 (192.168.1.100)

📌 NOTE: vsomeip 통합 완료 - VehicleControlECU와 통신합니다

GearApp is running...
═══════════════════════════════════════════════════════
qrc:/qml/GearSelectionWidget.qml:236: ReferenceError: ipcManager is not defined
qrc:/qml/GearSelectionWidget.qml:241: ReferenceError: ipcManager is not defined
✅ QML GUI loaded: GearSelectionWidget.qml
🖥️  Window should appear now!

2025-11-01 17:51:10.385147 GearApp [info] vSomeIP 3.5.8 | (default)
GearManager: Requesting gear change via vsomeip: "P" -> "R"
[GearManager → vsomeip] Requesting gear change: "R"
❌ Cannot request gear change: service not available
qml: Gear changed to: R
2025-11-01 17:51:20.385378 GearApp [info] vSomeIP 3.5.8 | (default)
GearManager: Requesting gear change via vsomeip: "P" -> "N"
[GearManager → vsomeip] Requesting gear change: "N"
❌ Cannot request gear change: service not available
qml: Gear changed to: N
GearManager: Requesting gear change via vsomeip: "P" -> "D"
[GearManager → vsomeip] Requesting gear change: "D"
❌ Cannot request gear change: service not available
qml: Gear changed to: D
2025-11-01 17:51:30.385475 GearApp [info] vSomeIP 3.5.8 | (default)













<디버깅 가이드>

제공해주신 'ECU 서버 클라이언트 JSON 설정' 소스를 분석하고, 기존 대화에서 논의된 **내부 라우팅(IPC) 문제**와 **외부 통신(SD) 전제 조건**을 결합하여 현재 통신이 안 되는 문제를 점검하기 위한 상세 가이드를 제공하겠습니다.

두 ECU의 JSON 구성 자체는 **SOME/IP 통신에 필요한 필수 파라미터가 대부분 일관되게 정의**되어 있어 설정 파일 구문상의 문제는 없어 보입니다. 하지만 통신이 실패하는 것은 **환경 설정**이나 **내부 라우팅 관리자(RM)의 역할 충돌** 때문일 가능성이 높습니다.

---

## I. JSON 설정 일관성 검증 (외부 통신)

두 JSON 파일은 SOME/IP Service Discovery (SD) 및 데이터 통신을 위해 다음 핵심 요소를 정확하게 정의하고 있습니다. 이 부분은 **"정상"**으로 가정하고 다음 단계로 넘어갑니다.

| 항목 | ECU1 (서버) | ECU2 (클라이언트) | 상태 |
| :--- | :--- | :--- | :--- |
| **유니캐스트 IP** | `192.168.1.100` | `192.168.1.101` | **정상** (각 장치 고유) |
| **서비스 ID** | `0x1234` | `0x1234` | **정상** |
| **인스턴스 ID** | `0x5678` | `0x5678` | **정상** |
| **UDP 포트** | `30501` (Unreliable) | `30501` | **정상** (데이터 채널 일치) |
| **SD 멀티캐스트** | `224.244.224.245` | `224.244.224.245` | **정상** (SD 채널 일치) |
| **SD 포트** | `30490` | `30490` | **정상** (SOME/IP-SD 표준 포트) |

## II. 문제 해결을 위한 4단계 점검 가이드

통신이 안 되는 문제는 크게 **RM 충돌 (내부 IPC)**, **SD 환경 (멀티캐스트 수신)**, **ID 불일치 (네트워크 유일성)** 세 가지로 압축될 수 있습니다.

### 단계 1: RM Host/Proxy 역할 충돌 점검 (가장 유력한 문제)

vSomeIP는 장치당 **하나의 중앙 Routing Manager (RM) Host**만 있어야 합니다. 클라이언트 ECU2의 설정이 RM Host 역할을 맡으려 하거나, ECU1의 RM Host 초기화가 실패하면 내부 IPC가 막혀 외부 통신이 시작되지 않습니다.

| ECU | 점검 항목 | 조치 사항 (필수) | 근거 |
| :--- | :--- | :--- | :--- |
| **ECU 1 (서버)** | **RM Host 로그 확인** | **Host** 역할 시작 (`Instantiating routing manager [Host]`) 및 UDS (`/tmp/vsomeip-0`) 생성 (`create_routing_root: Routing root @ /tmp/vsomeip-0`) 로그를 확인합니다. | |
| | **UDS 파일 확인** | ECU1에서 `/tmp/vsomeip-0` 소켓 파일이 존재하는지 (`ls -l /tmp/vsomeip-0`) 확인합니다. 없으면 RM Host가 실패한 것입니다. | |
| **ECU 2 (클라이언트)** | **JSON Routing 설정 수정** | ECU2 JSON 파일에 `routing` 필드가 **없거나** `false`로 설정되어 있는지 확인합니다. 현재 소스에는 `routing` 필드가 없으므로, **ECU2에서 RM Host 역할을 수행하는 다른 앱이 없는지** 확인하거나, RM 충돌 오류가 발생하는지 확인해야 합니다. | 대화 기록 |
| | **RM Proxy 로그 확인** | **Proxy** 역할 시작 (`Instantiating routing manager [Proxy]`) 및 UDS 연결 시도 (`Client [....] is connecting to  at /tmp/vsomeip-0`) 로그를 확인합니다. **`Couldn't connect to: /tmp/vsomeip-0`** 오류가 반복되면 RM Host (ECU1)에 문제가 있거나 ECU2가 Proxy 연결에 실패한 것입니다. | |
| **양쪽 ECU** | **잔여 소켓 정리** | 문제가 지속되면 애플리케이션 종료 후 `/tmp/vsomeip*` 파일을 삭제하고 다시 시작합니다. | |

### 단계 2: 네트워크/OS 레벨 멀티캐스트 설정 점검 (SD 수신 전제 조건)

SOME/IP Service Discovery (SD)는 **UDP 멀티캐스트 포트 30490**을 사용하며, 양쪽 ECU 모두 이 멀티캐스트 그룹을 수신할 수 있도록 OS 레벨에서 설정되어야 합니다.

1.  **멀티캐스트 라우팅 추가:** 양쪽 ECU의 셸에서 **sudo 권한**으로 다음 명령어를 실행하여 SD 멀티캐스트 주소(`224.244.224.245`)를 네트워크 인터페이스(예: `eth0`)에 바인딩합니다.
    ```bash
    sudo route add -host 224.244.224.245 dev <인터페이스 이름>
    ```
2.  **로그 확인:** ECU1의 RM Host 로그에서 **멀티캐스트 그룹 조인 성공** (`Joining to multicast group 224.224.224.245 from 170.170.170.2`와 유사한 메시지)이 출력되었는지 확인합니다.

### 단계 3: SOME/IP ID 불일치 및 버전 점검

모든 vsomeip 애플리케이션은 네트워크 내에서 고유해야 하며, 서비스 세부 정보가 일치해야 합니다.

1.  **Client ID 유일성:** JSON 파일의 `"applications"` 섹션에서 ECU1 (`0x1001`)과 ECU2 (`0xFFFF`)의 **Client ID**가 설정되어 있습니다. vsomeip에서 Client ID는 **네트워크 전체에서 고유해야** 통신이 작동합니다. 자동 할당으로 인해 중복될 위험을 피하기 위해 명시적으로 고유한 ID가 할당되어 있는지 확인합니다. ECU2의 `0xFFFF`는 `client-sample`의 ID로 보이며, ECU1의 `0x1001`과 겹치지 않으므로 정상입니다.
2.  **Interface Version:** JSON 파일에 Interface Version (`Interface version`)에 대한 정보가 직접 명시되어 있지 않다면, 애플리케이션 코드 내에서 **Major Version**이 일치하는지 확인해야 합니다. **Interface Version이 안 맞으면** 통신이 실패하고 `E_WRONG_INTERFACE_VERSION` (0x08) 에러가 발생합니다.
3.  **서비스 ID 및 인스턴스 ID 일치:** 서버 (`0x1234.0x5678`)와 클라이언트 (`0x1234.0x5678`)가 찾는 서비스 ID 및 인스턴스 ID가 정확히 일치하는지 확인합니다. 이는 이미 JSON에서 확인되었습니다.

### 단계 4: 서비스 가용성 및 RPC 호출 확인 (Wireshark 또는 로그)

앞선 단계가 모두 해결되었다면, 클라이언트가 SD를 통해 서버를 발견하고 RPC 호출을 시도하는지 확인합니다.

1.  **SD 성공 확인:**
    *   ECU1이 주기적으로 **Offer Service** 메시지를 멀티캐스트(`224.244.224.245:30490`)로 전송하는지 **Wireshark**로 확인합니다.
    *   ECU2 로그에서 **`Service [0x1234.0x5678] is available.`** 로그가 출력되는지 확인합니다.
2.  **데이터 채널 확인:**
    *   SD 성공 후, 클라이언트가 RPC를 호출할 때 **서버의 유니캐스트 주소와 포트**(`192.168.1.100:30501`)로 **UDP 유니캐스트 패킷**이 전송되는지 확인합니다. RM Host는 이 포트를 리스닝하고 있어야 합니다.
3.  **오류 코드 확인:** 통신 실패 시 로그에서 `Return Code`를 확인합니다. 예를 들어, `E_UNKNOWN_METHOD` (0x03)는 서비스는 찾았지만 요청된 메소드가 서버에 등록되지 않았음을 의미합니다.

**핵심 점검 순서:** **내부 RM 연결 성공(로그 확인) $\rightarrow$ 멀티캐스트 라우팅 설정(OS 레벨) $\rightarrow$ SD 메시지 교환(로그/Wireshark) $\rightarrow$ RPC 호출 시도.**