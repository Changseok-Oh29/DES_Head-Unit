# HU_MainApp - Wayland Compositor Architecture

## 개요

HU_MainApp은 **Qt Wayland Compositor**로 동작하며, GearApp, MediaApp, AmbientApp을 하나의 화면에 통합합니다.

```
┌─────────────────────────────────────────────────────────┐
│  Display 1: HU_MainApp (1280x480)                       │
│  ┌───────────┬──────────────────────────────────────┐  │
│  │  GearApp  │  [Media Tab] [Ambient Tab]           │  │
│  │  (300px)  │         (980px)                      │  │
│  │           │                                      │  │
│  │  ┌─────┐  │  ┌────────────────────────────────┐ │  │
│  │  │  D  │  │  │                                │ │  │
│  │  └─────┘  │  │  MediaApp / AmbientApp         │ │  │
│  │           │  │  (Tabbed content)              │ │  │
│  │  [P][R]   │  │                                │ │  │
│  │  [N][D]   │  └────────────────────────────────┘ │  │
│  └───────────┴──────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│  Display 2: IC_app (독립 실행)                          │
│  ┌───────────────────────────────────────────────────┐  │
│  │  Speedometer | Battery | Gear                    │  │
│  └───────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

## 아키텍처

### Wayland Compositor 방식

- **HU_MainApp**: Qt Wayland Compositor (서버 역할)
  - 1280x480 메인 윈도우
  - 좌측 패널(300px): GearApp 영역
  - 우측 패널(980px): MediaApp/AmbientApp 탭 영역

- **Client Apps**: Wayland 클라이언트로 실행
  - **GearApp**: 좌측 패널에 embed
  - **MediaApp**: 우측 Media 탭에 embed
  - **AmbientApp**: 우측 Ambient 탭에 embed

### 통신 구조

```
┌─────────────────────────────────────────────────────────┐
│  ECU1 (192.168.1.100)                                   │
│  ┌────────────────────────────────────────────────────┐ │
│  │  VehicleControlECU (vsomeip Service Provider)     │ │
│  └────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
                           │
                           │ vsomeip (UDP multicast)
                           │
┌─────────────────────────────────────────────────────────┐
│  ECU2 (192.168.1.101)                                   │
│  ┌────────────────────────────────────────────────────┐ │
│  │  routingmanagerd (vsomeip routing manager)        │ │
│  └────────────────────────────────────────────────────┘ │
│                         │                               │
│         ┌───────────────┼───────────────┐               │
│         │               │               │               │
│  ┌──────▼─────┐  ┌──────▼─────┐  ┌──────▼─────┐       │
│  │  GearApp   │  │ MediaApp   │  │ AmbientApp │       │
│  │  (client)  │  │  (client)  │  │  (client)  │       │
│  └──────┬─────┘  └──────┬─────┘  └──────┬─────┘       │
│         │               │               │               │
│         └───────────────┼───────────────┘               │
│                         │ Wayland Protocol              │
│  ┌──────────────────────▼────────────────────────────┐ │
│  │  HU_MainApp (Wayland Compositor)                 │ │
│  │  ┌───────────┬──────────────────────────────┐    │ │
│  │  │ GearApp   │ [Media] [Ambient]            │    │ │
│  │  │ Surface   │  MediaApp / AmbientApp       │    │ │
│  │  └───────────┴──────────────────────────────┘    │ │
│  └──────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

## 빌드 및 실행

### 1. Compositor 빌드

```bash
cd /home/leo/SEA-ME/DES_Head-Unit/app/HU_MainApp
./build_compositor.sh
```

### 2. 통합 실행 (권장)

모든 앱을 한 번에 실행:

```bash
./start_all_wayland.sh
```

이 스크립트는 다음 순서로 실행합니다:
1. HU_MainApp (Wayland Compositor)
2. GearApp (Wayland Client)
3. MediaApp (Wayland Client)
4. AmbientApp (Wayland Client)

### 3. 개별 실행 (디버깅용)

**Terminal 1: Compositor 시작**
```bash
cd /home/leo/SEA-ME/DES_Head-Unit/app/HU_MainApp
./run_compositor.sh
```

**Terminal 2: GearApp 시작**
```bash
cd /home/leo/SEA-ME/DES_Head-Unit/app/GearApp
./run_wayland.sh
```

**Terminal 3: MediaApp 시작**
```bash
cd /home/leo/SEA-ME/DES_Head-Unit/app/MediaApp
./run_wayland.sh
```

**Terminal 4: AmbientApp 시작**
```bash
cd /home/leo/SEA-ME/DES_Head-Unit/app/AmbientApp
./run_wayland.sh
```

## Display 2: IC_app 실행

IC_app은 독립적으로 실행됩니다 (다른 디스플레이에 표시):

```bash
# ECU2에서 실행
cd ~/DES_Head-Unit/IC_app
./run.sh
```

디스플레이 환경 변수로 분리:
```bash
# Display 1에 HU_MainApp
DISPLAY=:0 ./start_all_wayland.sh

# Display 2에 IC_app
DISPLAY=:1 ./IC_app/run.sh
```

## 종료

통합 실행 모드에서 `Ctrl+C`를 누르면 모든 앱이 종료됩니다.

## 요구사항

### Qt 모듈
- Qt5::Core
- Qt5::Quick
- Qt5::Qml
- **Qt5::WaylandCompositor** ← 필수!

### 설치 확인
```bash
# Qt Wayland Compositor 모듈 확인
dpkg -l | grep qtwayland5

# 없으면 설치
sudo apt install qtwayland5 libqt5waylandcompositor5-dev
```

## 트러블슈팅

### 1. Qt Wayland Compositor 없음
```bash
sudo apt install qtwayland5 libqt5waylandcompositor5-dev
```

### 2. Wayland display 연결 실패
```bash
# XDG_RUNTIME_DIR 설정 확인
export XDG_RUNTIME_DIR=/tmp
export WAYLAND_DISPLAY=wayland-0
```

### 3. 클라이언트 앱이 안 보임
- Compositor가 먼저 실행되어 있는지 확인
- QML의 `windowTitle`이 올바르게 설정되어 있는지 확인:
  - GearApp: "Gear..."
  - MediaApp: "Media..."
  - AmbientApp: "Ambient..."

### 4. vsomeip 통신 안 됨
- routingmanagerd가 실행 중인지 확인:
```bash
ps aux | grep routingmanagerd
```

## 파일 구조

```
HU_MainApp/
├── build_compositor.sh          # Compositor 빌드 스크립트
├── run_compositor.sh            # Compositor 실행 스크립트
├── start_all_wayland.sh         # 통합 실행 스크립트
├── CMakeLists_compositor.txt    # Compositor CMake
├── qml_compositor.qrc           # Compositor QML 리소스
├── src/
│   └── main_compositor.cpp      # Compositor main
└── qml/
    └── CompositorMain.qml       # Compositor UI & 레이아웃

GearApp/
└── run_wayland.sh               # Wayland 클라이언트 모드

MediaApp/
└── run_wayland.sh               # Wayland 클라이언트 모드

AmbientApp/
└── run_wayland.sh               # Wayland 클라이언트 모드
```

## 장점

### 1. 프로세스 독립성
- 각 앱이 별도 프로세스로 실행
- 한 앱이 크래시해도 다른 앱 영향 없음

### 2. vsomeip 통신 유지
- 각 앱이 독립적으로 vsomeip 통신
- HU_MainApp은 순수 UI compositor 역할만

### 3. 유연한 레이아웃
- QML로 위치/크기 조정 가능
- 탭 전환으로 MediaApp/AmbientApp 전환

### 4. 개발/디버깅 용이
- 각 앱 개별 개발/테스트 가능
- Compositor 독립 실행 가능

## 다음 단계

1. ✅ Wayland Compositor 구현
2. ✅ 클라이언트 앱 Wayland 모드 지원
3. ✅ 통합 실행 스크립트
4. ⏳ QML 창 제목 설정 (windowTitle)
5. ⏳ Tab 전환 로직 구현
6. ⏳ Display 분리 테스트 (HU_MainApp vs IC_app)
