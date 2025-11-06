#!/bin/bash

echo "════════════════════════════════════════════════════════════"
echo "ECU2 - Wayland Compositor 통합 실행 가이드"
echo "════════════════════════════════════════════════════════════"
echo ""

cat << 'EOF'
📋 ECU2 (Raspberry Pi) 실행 순서
════════════════════════════════════════════════════════════

┌─────────────────────────────────────────────────────────┐
│  Display 1: HU_MainApp Compositor (1280x480)            │
│  ┌───────────┬──────────────────────────────────────┐  │
│  │  GearApp  │  [Media Tab] [Ambient Tab]           │  │
│  │  (300px)  │         (980px)                      │  │
│  └───────────┴──────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│  Display 2: IC_app (독립 실행)                          │
│  └─ Speedometer | Battery | Gear                       │
└─────────────────────────────────────────────────────────┘


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1️⃣  준비 작업 (최초 1회)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Qt Wayland Compositor 설치
sudo apt update
sudo apt install -y qtwayland5 libqt5waylandcompositor5-dev

# 확인
dpkg -l | grep qtwayland5


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
2️⃣  빌드 (최초 1회 또는 코드 변경 시)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

cd ~/DES_Head-Unit/app

# HU_MainApp (Compositor) 빌드
cd HU_MainApp
./build.sh

# 각 앱 빌드 (필요한 경우)
cd ../GearApp && ./build.sh
cd ../MediaApp && ./build.sh
cd ../AmbientApp && ./build.sh
cd ../IC_app && ./build.sh


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
3️⃣  실행 방법
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

방법 A: 통합 실행 (권장) - 한 번에 모든 앱 시작
────────────────────────────────────────────────────────

cd ~/DES_Head-Unit/app/HU_MainApp
./start_all_wayland.sh

# 종료: Ctrl+C


방법 B: 개별 실행 (디버깅용) - 터미널 4개 필요
────────────────────────────────────────────────────────

# Terminal 1: Compositor 시작
cd ~/DES_Head-Unit/app/HU_MainApp
./run.sh

# Terminal 2: GearApp (Wayland Client)
cd ~/DES_Head-Unit/app/GearApp
./run_wayland.sh

# Terminal 3: MediaApp (Wayland Client)
cd ~/DES_Head-Unit/app/MediaApp
./run_wayland.sh

# Terminal 4: AmbientApp (Wayland Client)
cd ~/DES_Head-Unit/app/AmbientApp
./run_wayland.sh


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
4️⃣  Display 2에 IC_app 실행
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# 별도 터미널에서 (또는 Display 2에서)
cd ~/DES_Head-Unit/app/IC_app
./run.sh

# Multi-display 환경이면:
DISPLAY=:1 ./run.sh


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
5️⃣  ECU1 (VehicleControlECU) 확인
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ECU1에서 VehicleControlECU가 실행 중이어야 합니다
# (GearApp, IC_app이 데이터를 받으려면 필요)

ssh ecu1  # 또는 ECU1 터미널에서
cd ~/DES_Head-Unit/app/VehicleControlECU
./run.sh


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
6️⃣  전체 시스템 시작 순서 (권장)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. ECU1에서:
   cd ~/DES_Head-Unit/app/VehicleControlECU
   ./run.sh

2. ECU2에서:
   # routingmanagerd 시작 (백그라운드)
   routingmanagerd &
   
   # Display 1: HU_MainApp + 3개 앱
   cd ~/DES_Head-Unit/app/HU_MainApp
   ./start_all_wayland.sh
   
   # Display 2: IC_app (별도 터미널)
   cd ~/DES_Head-Unit/app/IC_app
   ./run.sh


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔧 트러블슈팅
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

문제: "Qt5WaylandCompositor not found"
해결: sudo apt install qtwayland5 libqt5waylandcompositor5-dev

문제: Wayland 클라이언트가 compositor에 연결 안 됨
확인: 
  1. Compositor 먼저 실행했는지
  2. ps aux | grep HU_MainApp_Compositor
  3. ls -l /tmp/wayland-*

문제: vsomeip 통신 안 됨
확인:
  1. ECU1에서 VehicleControlECU 실행 중인지
  2. routingmanagerd 실행 중인지: ps aux | grep routingmanagerd
  3. 네트워크 연결: ping 192.168.1.100

문제: IC_app 계기판 바늘이 안 움직임
확인:
  1. vsomeip 통신 되는지 (위 참조)
  2. IC_app 로그에서 "Speed changed" 메시지 확인
  3. ECU1에서 속도 데이터 전송되는지 확인


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 프로세스 확인
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ECU2에서 실행 중인 프로세스 확인
ps aux | grep -E '(routing|HU_Main|GearApp|MediaApp|AmbientApp|IC_app)'

# 정상 상태라면 다음이 보여야 합니다:
# - routingmanagerd
# - HU_MainApp_Compositor
# - GearApp
# - MediaApp
# - AmbientApp
# - IC_app


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🛑 종료
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# 통합 실행 모드: Ctrl+C (자동으로 모든 앱 종료)

# 개별 실행 모드: 각 터미널에서 Ctrl+C

# 강제 종료:
killall HU_MainApp_Compositor GearApp MediaApp AmbientApp IC_app


════════════════════════════════════════════════════════════

EOF

echo ""
echo "💡 빠른 시작:"
echo ""
echo "   cd ~/DES_Head-Unit/app/HU_MainApp"
echo "   ./start_all_wayland.sh"
echo ""
