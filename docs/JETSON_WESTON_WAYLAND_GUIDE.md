# Jetson Orin Nano - Weston/Wayland GUI 구성 가이드

> 📅 작성일: 2026-01-05  
> 🎯 목적: Jetson에서 Weston Wayland Compositor를 사용하여 다중 Qt 앱 GUI 구성

---

## 📋 목차
1. [NVIDIA 공식 문서 기반 Weston 설정](#1-nvidia-공식-문서-기반-weston-설정)
2. [Qt Application 설정](#2-qt-application-설정)
3. [Qt Wayland Compositor 설정](#3-qt-wayland-compositor-설정)
4. [실행 스크립트 구성](#4-실행-스크립트-구성)
5. [트러블슈팅](#5-트러블슈팅)

---

## 1. NVIDIA 공식 문서 기반 Weston 설정

### 1.1 공식 문서 참조
- **URL**: https://docs.nvidia.com/jetson/archives/r36.4.4/DeveloperGuide/SD/WindowingSystems/WestonWayland.html
- **버전 주의**: 본 프로젝트는 R36.4.4 사용 (문서는 R35.5.0 기준이지만 절차 동일)

### 1.2 Weston 설치 확인
```bash
which weston && weston --version
# 출력: weston 13.0.0 (R36.4.4의 경우)
```

### 1.3 Weston 설정 파일 (`~/.config/weston.ini`)
```ini
[core]
backend=drm-backend.so

[output]
name=DP-1                    # Jetson Orin Nano는 DisplayPort 사용
mode=1920x1080               # 모니터 해상도
transform=normal

[shell]
panel-position=none          # 패널 없음 (nested compositor 사용)
locking=false                # 화면 잠금 비활성화
background-color=0xff002244  # 배경색 (선택사항)
```

**중요**: Jetson Orin Nano는 HDMI가 아닌 **DP-1 (DisplayPort)** 사용

### 1.4 Display 확인
```bash
# 연결된 디스플레이 확인
for connector in /sys/class/drm/card*/card*-DP-*; do
    if [ -e "$connector/status" ]; then
        status=$(cat "$connector/status")
        echo "$(basename $connector): $status"
    fi
done
```

### 1.5 Weston 실행 절차 (NVIDIA 공식)

#### Step 1: X Server 중지
```bash
sudo service gdm stop
sudo pkill -9 Xorg
```

#### Step 2: NVIDIA DRM Driver 로드
```bash
sudo modprobe nvidia_drm modeset=1
```

#### Step 3: XDG Runtime Directory 설정
```bash
export XDG_RUNTIME_DIR=/tmp/xdg
sudo mkdir -p $XDG_RUNTIME_DIR
sudo chmod 700 $XDG_RUNTIME_DIR
```

**중요**: `/tmp/xdg`는 root 소유이므로 모든 프로세스를 `sudo`로 실행해야 함

#### Step 4: 이전 Weston 정리
```bash
sudo pkill -9 weston
sudo rm -rf /tmp/xdg/wayland-*
```

#### Step 5: Weston 시작
```bash
sudo XDG_RUNTIME_DIR=/tmp/xdg weston --idle-time=0 &
```

- `--idle-time=0`: 화면 절전 비활성화
- `--tty` 옵션은 Weston 13.0.0에서 지원 안 함 (문서와 차이)

#### Step 6: 소켓 확인
```bash
sudo ls -la /tmp/xdg/wayland-0
# 출력: srwxr-xr-x 1 root root 0 Jan 5 14:00 /tmp/xdg/wayland-0
```

---

## 2. Qt Application 설정

### 2.1 필수 의존성
```bash
sudo apt-get install -y \
    qtbase5-dev \
    qtdeclarative5-dev \
    qtwayland5 \
    libqt5waylandclient5 \
    qml-module-qtwayland-compositor
```

### 2.2 main.cpp 환경 변수 설정
```cpp
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickWindow>

int main(int argc, char *argv[])
{
    // Wayland 환경 변수
    qputenv("QT_QPA_PLATFORM", "wayland");
    qputenv("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1");
    qputenv("WAYLAND_DISPLAY", "wayland-1");  // nested compositor 사용
    qputenv("XDG_RUNTIME_DIR", "/tmp/xdg");
    
    QGuiApplication app(argc, argv);
    
    // ⭐ 중요: Wayland App ID 설정 (Compositor가 앱 식별에 사용)
    app.setApplicationName("MyApp");
    app.setDesktopFileName("MyApp.desktop");
    
    QQmlApplicationEngine engine;
    engine.load(QUrl(QStringLiteral("qrc:/main.qml")));
    
    // ⭐ QML Window 생성 후 App ID 설정
    if (!engine.rootObjects().isEmpty()) {
        QObject *rootObject = engine.rootObjects().first();
        QQuickWindow *window = qobject_cast<QQuickWindow*>(rootObject);
        if (window) {
            window->setProperty("_q_waylandAppId", "MyApp");
        }
    }
    
    return app.exec();
}
```

### 2.3 CMakeLists.txt 설정
```cmake
find_package(Qt5 REQUIRED COMPONENTS 
    Core 
    Gui 
    Quick 
    WaylandClient
)

target_link_libraries(${PROJECT_NAME}
    Qt5::Core
    Qt5::Gui
    Qt5::Quick
    Qt5::WaylandClient
)
```

### 2.4 QML Window 설정
```qml
import QtQuick 2.12
import QtQuick.Window 2.12

Window {
    id: window
    width: 800
    height: 600
    visible: true
    title: "MyApp"
    
    // Wayland 플랫폼 확인
    Component.onCompleted: {
        console.log("Platform:", Qt.platform.pluginName)
        // 출력: "wayland"
    }
}
```

---

## 3. Qt Wayland Compositor 설정

### 3.1 Compositor 역할
- Weston의 `wayland-0` 소켓에 **클라이언트**로 연결
- `wayland-1` 소켓 생성하여 앱들의 **서버** 역할
- 여러 앱 창을 하나의 레이아웃으로 합성(Compositing)

### 3.2 main.cpp OpenGL 설정 (필수!)
```cpp
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QSurfaceFormat>

int main(int argc, char *argv[])
{
    // Wayland 환경 변수
    qputenv("QT_QPA_PLATFORM", "wayland");
    qputenv("WAYLAND_DISPLAY", "wayland-0");  // Weston에 연결
    
    // ⭐ OpenGL Surface Format 설정 (필수!)
    QSurfaceFormat format = QSurfaceFormat::defaultFormat();
    format.setDepthBufferSize(24);
    format.setStencilBufferSize(8);
    format.setVersion(2, 0);  // OpenGL ES 2.0
    format.setRenderableType(QSurfaceFormat::OpenGLES);
    format.setSwapBehavior(QSurfaceFormat::DoubleBuffer);
    QSurfaceFormat::setDefaultFormat(format);
    
    // ⭐ OpenGL Context 공유 (중요!)
    QCoreApplication::setAttribute(Qt::AA_ShareOpenGLContexts);
    
    QGuiApplication app(argc, argv);
    app.setApplicationName("MyCompositor");
    app.setDesktopFileName("MyCompositor");
    
    QQmlApplicationEngine engine;
    engine.load(QUrl(QStringLiteral("qrc:/compositor.qml")));
    
    return app.exec();
}
```

**중요**: `AA_ShareOpenGLContexts` 설정하지 않으면:
```
ERROR: EglClientBufferIntegration: creating texture with no current context
```

### 3.3 compositor.qml 구조
```qml
import QtQuick 2.12
import QtQuick.Window 2.12
import QtWayland.Compositor 1.3

WaylandCompositor {
    id: compositor
    
    // ⭐ 소켓 이름 설정
    socketName: "wayland-1"
    
    WaylandOutput {
        compositor: compositor
        sizeFollowsWindow: true
        
        window: Window {
            width: 1024
            height: 600
            visible: true
            
            // OpenGL context 초기화 확인
            Component.onCompleted: {
                console.log("Compositor window ready")
            }
        }
    }
    
    // ⭐ XDG Shell 처리
    XdgShell {
        onToplevelCreated: {
            var appId = toplevel.appId || ""
            var title = toplevel.title || ""
            
            console.log("New surface:", appId, title)
            
            // ShellSurfaceItem 생성
            var chrome = chromeComponent.createObject(layout, {
                "shellSurface": xdgSurface
            })
            
            // ⭐ 초기 configure 전송 (필수!)
            // 크기를 보내지 않으면 Qt client가 EGL surface 생성 실패
            var size = Qt.size(800, 600)
            toplevel.sendConfigure(size, [])
            
            // Title 변경 시 routing
            toplevel.titleChanged.connect(function() {
                routeSurface(chrome, toplevel.title)
            })
        }
    }
    
    Component {
        id: chromeComponent
        
        ShellSurfaceItem {
            autoCreatePopupItems: true
            
            // 초기 크기 설정
            width: 800
            height: 600
        }
    }
}
```

### 3.4 Surface Routing 로직
```qml
function routeSurface(chrome, identifier) {
    // App ID나 Title로 적절한 컨테이너에 배치
    if (identifier === "GearApp" || identifier.includes("gear")) {
        chrome.parent = gearContainer
        chrome.anchors.fill = chrome.parent
        
        // 배치 후 크기 재설정
        var size = Qt.size(130, 520)
        chrome.shellSurface.toplevel.sendConfigure(size, [])
    } else {
        chrome.parent = mainContainer
        chrome.anchors.fill = chrome.parent
        
        var size = Qt.size(880, 520)
        chrome.shellSurface.toplevel.sendConfigure(size, [])
    }
}
```

**핵심 원리**:
1. Surface 생성 시 초기 configure 전송 (0x0 방지)
2. Routing 완료 후 올바른 크기로 재configure
3. `chrome.parent`를 확인하여 어느 컨테이너에 있는지 판단

---

## 4. 실행 스크립트 구성

### 4.1 전체 시스템 시작 순서
```bash
#!/bin/bash

PROJECT_ROOT="/home/jetson/leo/DES_Head-Unit"

# 1. X Server 중지
sudo service gdm stop
sudo pkill -9 Xorg

# 2. NVIDIA DRM 로드
sudo modprobe nvidia_drm modeset=1

# 3. XDG 환경 설정
export XDG_RUNTIME_DIR=/tmp/xdg
sudo mkdir -p $XDG_RUNTIME_DIR
sudo chmod 700 $XDG_RUNTIME_DIR

# 4. 이전 프로세스 정리
sudo pkill -9 weston
sudo rm -rf /tmp/xdg/wayland-*

# 5. Weston 시작
sudo XDG_RUNTIME_DIR=/tmp/xdg weston --idle-time=0 > /tmp/weston.log 2>&1 &
sleep 3

# 6. vsomeip Routing Manager (선택사항)
if [ -f "${PROJECT_ROOT}/deps/vsomeip/build/examples/routingmanagerd/routingmanagerd" ]; then
    ${PROJECT_ROOT}/deps/vsomeip/build/examples/routingmanagerd/routingmanagerd > /tmp/routing_manager.log 2>&1 &
    sleep 2
    
    # vsomeip.lck 권한 설정
    sudo touch /tmp/vsomeip.lck
    sudo chmod 666 /tmp/vsomeip.lck
fi

# 7. Compositor 시작
cd "${PROJECT_ROOT}/app/HU_MainApp"
sudo XDG_RUNTIME_DIR=/tmp/xdg ./build_compositor/HU_MainApp_Compositor > /tmp/compositor.log 2>&1 &
sleep 5

# 8. 앱들 시작
export LD_LIBRARY_PATH="${PROJECT_ROOT}/install_folder/lib:${LD_LIBRARY_PATH}"

# GearApp
cd "${PROJECT_ROOT}/app/GearApp"
sudo -E XDG_RUNTIME_DIR=/tmp/xdg WAYLAND_DISPLAY=wayland-1 \
    LD_LIBRARY_PATH="${LD_LIBRARY_PATH}" \
    ./build/GearApp > /tmp/gearapp.log 2>&1 &

sleep 2

# MediaApp (vsomeip 사용)
cd "${PROJECT_ROOT}/app/MediaApp"
sudo -E XDG_RUNTIME_DIR=/tmp/xdg WAYLAND_DISPLAY=wayland-1 \
    VSOMEIP_APPLICATION_NAME=MediaApp \
    LD_LIBRARY_PATH="${LD_LIBRARY_PATH}" \
    ./build/MediaApp > /tmp/mediaapp.log 2>&1 &

sleep 2

# AmbientApp (vsomeip 사용)
cd "${PROJECT_ROOT}/app/AmbientApp"
sudo -E XDG_RUNTIME_DIR=/tmp/xdg WAYLAND_DISPLAY=wayland-1 \
    VSOMEIP_APPLICATION_NAME=AmbientApp \
    LD_LIBRARY_PATH="${LD_LIBRARY_PATH}" \
    ./build/AmbientApp > /tmp/ambientapp.log 2>&1 &

sleep 2

# HomeScreenApp
cd "${PROJECT_ROOT}/app/HomeScreenApp"
sudo -E XDG_RUNTIME_DIR=/tmp/xdg WAYLAND_DISPLAY=wayland-1 \
    LD_LIBRARY_PATH="${LD_LIBRARY_PATH}" \
    ./build/HomeScreenApp > /tmp/homescreenapp.log 2>&1 &

echo "✅ All apps started"
echo "Logs: /tmp/*.log"
```

### 4.2 종료 스크립트
```bash
#!/bin/bash
sudo pkill -9 weston
sudo pkill -9 routingmanagerd
sudo pkill -9 HU_MainApp_Compositor
killall -9 GearApp AmbientApp MediaApp HomeScreenApp 2>/dev/null
sudo rm -rf /tmp/xdg
```

---

## 5. 트러블슈팅

### 5.1 문제: "Could not create EGL surface (EGL error 0x321c)"

**원인**: Qt가 0x0 크기로 EGL surface 생성 시도

**해결**:
```qml
XdgShell {
    onToplevelCreated: {
        // ⭐ 반드시 초기 configure 전송
        toplevel.sendConfigure(Qt.size(800, 600), [])
    }
}
```

### 5.2 문제: "EglClientBufferIntegration: creating texture with no current context"

**원인**: Compositor가 OpenGL context 없이 클라이언트 buffer 처리 시도

**해결**:
```cpp
// main.cpp에 추가
QCoreApplication::setAttribute(Qt::AA_ShareOpenGLContexts);

QSurfaceFormat format = QSurfaceFormat::defaultFormat();
format.setVersion(2, 0);
format.setRenderableType(QSurfaceFormat::OpenGLES);
QSurfaceFormat::setDefaultFormat(format);
```

### 5.3 문제: 앱이 실행되지만 화면에 안 나타남

**원인**: App ID가 전달되지 않아 Compositor가 routing 실패

**해결**:
```cpp
// 1. QGuiApplication에 설정
app.setDesktopFileName("MyApp.desktop");

// 2. QML Window에 설정
QQuickWindow *window = qobject_cast<QQuickWindow*>(rootObject);
window->setProperty("_q_waylandAppId", "MyApp");
```

### 5.4 문제: Permission denied - /tmp/vsomeip.lck

**원인**: vsomeip 사용 앱들이 동시에 routing manager 시작 시도

**해결**:
```bash
# 메인 routing manager 시작 후
sudo touch /tmp/vsomeip.lck
sudo chmod 666 /tmp/vsomeip.lck

# 앱 실행 시 VSOMEIP_APPLICATION_NAME 설정
VSOMEIP_APPLICATION_NAME=MyApp ./MyApp
```

### 5.5 문제: 앱 크기가 이상함

**원인**: 초기 configure와 routing 후 configure 크기가 다름

**해결**:
```qml
toplevel.titleChanged.connect(function() {
    routeSurface(chrome, toplevel.title)
    
    // Routing 완료 후 크기 재설정
    var size = (chrome.parent === gearContainer) ? 
        Qt.size(130, 520) : Qt.size(880, 520)
    toplevel.sendConfigure(size, [])
})
```

---

## 6. 핵심 체크리스트

### Weston 설정
- [ ] `weston.ini`에 올바른 output 설정 (DP-1)
- [ ] X Server 중지 확인
- [ ] `nvidia_drm` 모듈 로드
- [ ] `/tmp/xdg` 디렉토리 생성 및 권한 설정
- [ ] `wayland-0` 소켓 생성 확인

### Qt Application
- [ ] `QT_QPA_PLATFORM=wayland` 환경변수
- [ ] `WAYLAND_DISPLAY=wayland-1` (nested compositor 사용)
- [ ] `app.setDesktopFileName()` 설정
- [ ] QML Window 생성 후 `_q_waylandAppId` 설정

### Qt Wayland Compositor
- [ ] `AA_ShareOpenGLContexts` 속성 설정
- [ ] OpenGL Surface Format 구성 (ES 2.0)
- [ ] `socketName: "wayland-1"` 설정
- [ ] `onToplevelCreated`에서 초기 configure 전송
- [ ] Surface routing 로직 구현
- [ ] Routing 후 크기 재configure

### 실행 순서
- [ ] 1. Weston 시작
- [ ] 2. (선택) vsomeip Routing Manager
- [ ] 3. Qt Wayland Compositor
- [ ] 4. 각 앱들 (wayland-1 연결)

---

## 7. 참고 자료

### NVIDIA 공식 문서
- Weston/Wayland: https://docs.nvidia.com/jetson/archives/r36.4.4/DeveloperGuide/SD/WindowingSystems/WestonWayland.html
- JetPack SDK: https://developer.nvidia.com/embedded/jetpack

### Qt Documentation
- Qt Wayland Compositor: https://doc.qt.io/qt-5/qtwaylandcompositor-index.html
- Qt QPA Wayland: https://doc.qt.io/qt-5/qpa.html

### 프로젝트 파일
- Compositor: `app/HU_MainApp/qml/compositor_modular.qml`
- 실행 스크립트: `run-jetson-wayland-full.sh`
- 앱 예시: `app/GearApp/src/main.cpp`

---

## 8. 작동 원리 요약

```
1. 앱 렌더링 (OpenGL)
   ↓
2. 공유 버퍼(Surface)에 저장
   ↓
3. Wayland protocol로 Compositor에 전달
   ↓
4. Compositor가 여러 Surface 합성(Compositing)
   ↓
5. Weston이 최종 출력 버퍼 생성
   ↓
6. DRM이 모니터로 scan-out
```

**핵심**: 
- 각 단계에서 OpenGL context 필요
- Wayland protocol로 buffer 소유권 전달
- Compositor는 클라이언트 + 서버 역할 동시 수행

---

✅ 이 가이드대로 설정하면 Jetson Orin Nano에서 Weston/Wayland 기반 다중 앱 GUI 구성 가능!
