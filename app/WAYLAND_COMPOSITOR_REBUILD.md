# Wayland Compositor - 재구성 완료 (2025-11-06)

## 🎯 목표
- **하나의 디스플레이**에 GearApp, MediaApp, AmbientApp을 Wayland Compositor로 통합
- Qt Wayland Compositor 사용 (Weston/Louvre 불필요)
- vsomeip 통신은 그대로 유지

## 🏗️ 아키텍처 (제안 문서와 완벽히 일치)

```
┌──────────────────────────────────────────────────┐
│   HU_MainApp (Qt Wayland Compositor)             │
│   - WaylandCompositor + WaylandOutput            │
│   - XdgShell (클라이언트 창 관리)                │
│   - ShellSurfaceItem (고정 레이아웃)             │
│   - Platform: xcb (X11에서 실행, Wayland 서버 제공) │
├──────────────────────────────────────────────────┤
│  GearApp   │   MediaApp   │   AmbientApp        │
│  (독립 프로세스) │  (독립 프로세스)  │  (독립 프로세스)    │
│  Platform: wayland (Wayland 클라이언트)          │
└──────────────────────────────────────────────────┘
         ↕           ↕             ↕
    vsomeip 통신 (내부 IPC - 이미 구현 완료)
```

## 📋 핵심 개선 사항 (제안 문서 반영)

### 1. **Compositor 플랫폼 수정**

## 📋 핵심 개선 사항 (제안 문서 반영)

### 1. **Compositor 플랫폼 수정** ⭐ 중요!
**HU_MainApp/run_compositor.sh:**
```bash
export QT_QPA_PLATFORM=xcb  # Compositor는 X11에서 실행
export WAYLAND_DISPLAY=wayland-hu  # 커스텀 소켓 (충돌 방지)
```
- ❌ 이전: `QT_QPA_PLATFORM=wayland` (잘못됨!)
- ✅ 현재: `QT_QPA_PLATFORM=xcb` (Compositor는 Wayland 서버 역할)

### 2. **클라이언트 식별 강화**
**각 앱의 run_wayland.sh:**
```bash
export APP_ID=GearApp  # 환경 변수로 명확한 식별
export WAYLAND_DISPLAY=wayland-hu  # HU Compositor의 커스텀 소켓
```

### 3. **ShellSurfaceItem 개선**
**CompositorMain.qml:**
```qml
var item = surfaceItem.createObject(root, {
    "shellSurface": toplevel,
    "sizeFollowsSurface": false  // Compositor가 크기 제어
});
```

### 4. **클라이언트 앱 QML 수정**
**GearApp/qml/GearSelectionWidget.qml**
```qml
Window {
    id: window
    visible: true
    title: "Gear"  // ← Compositor가 매칭할 이름
    // width/height 제거 (Compositor가 제어)
}
```

**MediaApp/qml/MediaApp.qml**
```qml
Window {
    id: window
    visible: true
    title: "Media"
}
```

**AmbientApp/qml/AmbientLighting.qml**
```qml
Window {
    id: window
    visible: true
    title: "Ambient"
}
```

### 2. 실행 스크립트 수정
**run_wayland.sh (GearApp, MediaApp, AmbientApp 공통)**
- ❌ 제거: `./AppName --platform wayland`
- ✅ 수정: `./AppName` (환경변수로만 Wayland 설정)

환경변수:
```bash
export QT_QPA_PLATFORM=wayland
export WAYLAND_DISPLAY=wayland-0
export XDG_RUNTIME_DIR=/run/user/$(id -u)
export QT_WAYLAND_SOCKET_PATH=$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY
export QT_QUICK_BACKEND=software
export LIBGL_ALWAYS_SOFTWARE=1
```

### 3. Compositor QML 개선
**HU_MainApp/qml/CompositorMain.qml**
- title과 appId 모두 체크
- 명확한 로깅 추가
- 기본 포지셔닝 개선

### 4. main.cpp에 appId 설정
**각 앱의 main.cpp**
```cpp
app.setDesktopFileName("GearApp");  // for Wayland appId
app.setDesktopFileName("MediaApp");
app.setDesktopFileName("AmbientApp");
```

## 🚀 ECU2에서 실행 방법

### 빌드
```bash
cd ~/seame2025/DES_Head-Unit/app
./rebuild_and_test_wayland.sh
```

### 실행
```bash
cd HU_MainApp
./start_all_wayland.sh
```

## 📐 레이아웃

```
┌─────────────────────────────────────────────────┐
│         HU_MainApp Compositor (1280x480)        │
├──────┬──────────────────────────────────────────┤
│ Gear │           Media / Ambient                │
│      │                                          │
│ 300px│              980px                       │
│      │                                          │
│ P R  │  [Tab: Media | Ambient]                 │
│ N D  │                                          │
│      │  App content area                        │
│      │                                          │
└──────┴──────────────────────────────────────────┘
```

## 🔧 핵심 변경점 요약

1. **`--platform wayland` 인자 제거**
   - 이유: Qt가 환경변수만으로 Wayland 사용
   - 명령행 인자는 충돌 발생 가능

2. **Window 크기를 Compositor에 위임**
   - 클라이언트: `width/height` 속성 제거
   - Compositor: `item.width = 300` 등으로 강제 설정

3. **명확한 window title**
   - "Gear", "Media", "Ambient" (짧고 명확하게)
   - Compositor가 `indexOf()`로 매칭

4. **소프트웨어 렌더링**
   - `QT_QUICK_BACKEND=software`
   - `LIBGL_ALWAYS_SOFTWARE=1`
   - EGL 하드웨어 가속 문제 회피

## 🐛 트러블슈팅

### Segmentation fault 발생 시
- 원인: EGL 초기화 실패
- 해결: 소프트웨어 렌더링 사용 (위 환경변수)

### AppId가 비어있을 때
- 원인: `setDesktopFileName()` 누락
- 해결: main.cpp에 추가됨

### Window가 표시 안 됨
- 원인: title 매칭 실패
- 해결: title을 "Gear", "Media", "Ambient"로 단순화

## ✅ 예상 결과

```
qml: New XDG toplevel - Title: Gear AppId: GearApp
qml: → GearApp positioned: Left panel (300x480)

qml: New XDG toplevel - Title: Media AppId: MediaApp
qml: → MediaApp positioned: Right panel (980x420)

qml: New XDG toplevel - Title: Ambient AppId: AmbientApp
qml: → AmbientApp positioned: Right panel (980x420)
```

## 📌 다음 단계

1. ✅ 빌드 성공 확인
2. ✅ Compositor 실행 확인
3. ✅ 각 앱 연결 확인
4. ⏳ Tab 전환 로직 구현 (Media ↔ Ambient)
5. ⏳ vsomeip 통신 테스트
