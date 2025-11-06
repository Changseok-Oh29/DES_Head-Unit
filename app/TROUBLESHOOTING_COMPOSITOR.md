# Wayland Compositor 오류 해결 가이드

## 🔍 발생한 오류

```
Failed to create wl_display (No such file or directory)
qt.qpa.plugin: Could not load the Qt platform plugin "wayland"
```

## 📋 문제 원인

Qt Wayland Compositor가 실행 환경을 찾지 못하고 있습니다.
- Compositor는 **Wayland 서버**로 작동해야 하지만
- **Wayland 클라이언트**로 실행되려고 시도하고 있습니다

## 🎯 해결 방법

### 1단계: 환경 진단 (ECU2에서 실행)

```bash
cd ~/seame2025/DES_Head-Unit/app
./diagnose_compositor_platform.sh
```

이 스크립트가 출력하는 **권장 플랫폼**을 확인하세요.

---

### 2단계: 환경별 해결책

#### Case A: X11이 실행 중인 경우
```bash
# 확인:
echo $DISPLAY
# 결과: :0 또는 :1 등

# 해결: run_compositor.sh가 자동으로 xcb 선택
```

#### Case B: DRM/KMS만 있는 경우 (X11 없음)
```bash
# 확인:
ls -l /dev/dri/card0

# 해결: run_compositor.sh가 자동으로 eglfs 선택
```

#### Case C: SSH 원격 접속인 경우
```bash
# 문제: 디스플레이 서버가 없음
# 해결: VNC 또는 물리 디스플레이로 전환 필요
```

---

### 3단계: 수동 플랫폼 지정 (자동 선택이 실패할 경우)

**run_compositor.sh 수정:**

```bash
# Option 1: X11 사용 (X11이 있는 경우)
export QT_QPA_PLATFORM=xcb

# Option 2: DRM/KMS 사용 (콘솔에서 직접 실행)
export QT_QPA_PLATFORM=eglfs
export QT_QPA_EGLFS_INTEGRATION=eglfs_kms

# Option 3: Framebuffer 사용 (마지막 대안)
export QT_QPA_PLATFORM=linuxfb
```

---

### 4단계: 권한 문제 해결

Compositor가 GPU/DRM에 접근하려면 권한이 필요합니다:

```bash
# 현재 사용자를 video 그룹에 추가
sudo usermod -a -G video $USER

# 로그아웃 후 재로그인
# 또는
newgrp video

# 권한 확인
groups
# 결과에 'video'가 포함되어야 함
```

---

### 5단계: 재시도

```bash
cd ~/seame2025/DES_Head-Unit/app
./rebuild_and_test_wayland.sh

cd HU_MainApp
./start_all_wayland.sh
```

---

## 🔧 추가 트러블슈팅

### Qt Wayland Compositor 플러그인 확인

```bash
# Qt Wayland Compositor 모듈 설치 확인
dpkg -l | grep qtwayland

# QML 모듈 확인
find /usr -name "*WaylandCompositor*" 2>/dev/null
```

설치 안 되어 있으면:
```bash
sudo apt-get update
sudo apt-get install qtwayland5 libqt5waylandcompositor5 qml-module-qtwayland-compositor
```

---

## 📌 참고: 간단한 테스트

Compositor 없이 단일 앱만 xcb로 실행:

```bash
cd ~/seame2025/DES_Head-Unit/app/GearApp
export QT_QPA_PLATFORM=xcb  # X11이 있는 경우
./run.sh  # Wayland 대신 독립 실행
```

이게 작동하면 환경은 정상이고, Wayland Compositor 설정만 수정하면 됩니다.
