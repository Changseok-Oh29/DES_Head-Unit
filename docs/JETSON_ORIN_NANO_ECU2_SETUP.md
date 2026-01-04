# Jetson Orin Nano ECU2 Setup Guide

젯슨 오린 나노에서 DES Head-Unit ECU2 앱을 빌드 및 실행하기 위한 의존성 설치 가이드입니다.

**작성일**: 2026년 1월 4일  
**대상 플랫폼**: Jetson Orin Nano (ARM64)  
**OS**: Ubuntu 22.04 LTS  
**목적**: Yocto 빌드를 위한 참고 자료

---

## 📋 개요

### ECU2 구성 요소
- **HU_MainApp_Compositor**: Wayland Compositor (앱 창 관리)
- **GearApp**: 기어 선택 UI
- **MediaApp**: 미디어 플레이어 UI
- **AmbientApp**: 앰비언트 라이팅 제어 UI
- **HomeScreenApp**: 홈 스크린 UI

### 제외 항목
- `VehicleControlECU`: ECU1(라즈베리파이)에서만 실행되며 ECU2에는 포함되지 않음

---

## 🔧 1. 시스템 패키지 설치

### 1.1 기본 빌드 도구
```bash
sudo apt-get update
sudo apt-get install -y \
    build-essential \
    cmake \
    git \
    pkg-config
```

### 1.2 Qt5 개발 라이브러리
```bash
sudo apt-get install -y \
    qtbase5-dev \
    qtdeclarative5-dev \
    qtquickcontrols2-5-dev \
    qml-module-qtquick2 \
    qml-module-qtquick-controls2 \
    qml-module-qtquick-layouts \
    qml-module-qtquick-window2 \
    libqt5waylandcompositor5-dev \
    qtwayland5
```

**중요**: Wayland Compositor 지원을 위해 `libqt5waylandcompositor5-dev`와 `qtwayland5` 필수!

### 1.3 Boost 라이브러리
```bash
sudo apt-get install -y libboost-all-dev
```

필요한 Boost 컴포넌트:
- `libboost-system-dev`
- `libboost-thread-dev`
- `libboost-filesystem-dev`
- `libboost-log-dev`

### 1.4 문서 생성 도구 (선택사항)
vsomeip 문서 빌드를 위한 도구들 (빌드에 필수는 아님):
```bash
sudo apt-get install -y \
    asciidoc \
    source-highlight \
    doxygen \
    graphviz
```

---

## 🏗️ 2. vsomeip & CommonAPI 빌드

### 2.1 설치 경로 설정
```bash
cd /home/jetson/leo/DES_Head-Unit
export INSTALL_PREFIX="/home/jetson/leo/DES_Head-Unit/install_folder"
mkdir -p $INSTALL_PREFIX
```

### 2.2 vsomeip 빌드 (v3.5.8)
```bash
cd /home/jetson/leo/DES_Head-Unit/deps

# Clone
git clone https://github.com/COVESA/vsomeip.git
cd vsomeip
git checkout 3.5.8

# Build
mkdir -p build && cd build
cmake .. \
    -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX \
    -DCMAKE_BUILD_TYPE=Release \
    -DENABLE_SIGNAL_HANDLING=1

make -j$(nproc)
make install
```

**설치 결과**:
- 라이브러리: `$INSTALL_PREFIX/lib/libvsomeip3*.so`
- 헤더: `$INSTALL_PREFIX/include/vsomeip/`
- CMake 설정: `$INSTALL_PREFIX/lib/cmake/vsomeip3/`

### 2.3 CommonAPI Core 빌드 (v3.2.4)
```bash
cd /home/jetson/leo/DES_Head-Unit/deps

# Clone
git clone https://github.com/COVESA/capicxx-core-runtime.git
cd capicxx-core-runtime
git checkout 3.2.4

# Build
mkdir -p build && cd build
cmake .. \
    -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX \
    -DCMAKE_BUILD_TYPE=Release

make -j$(nproc)
make install
```

**설치 결과**:
- 라이브러리: `$INSTALL_PREFIX/lib/libCommonAPI.so`
- 헤더: `$INSTALL_PREFIX/include/CommonAPI-3.2/`

### 2.4 CommonAPI SomeIP 빌드 (v3.2.4)
```bash
cd /home/jetson/leo/DES_Head-Unit/deps

# Clone
git clone https://github.com/COVESA/capicxx-someip-runtime.git
cd capicxx-someip-runtime
git checkout 3.2.4

# Build
mkdir -p build && cd build
cmake .. \
    -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX \
    -DCMAKE_PREFIX_PATH=$INSTALL_PREFIX \
    -DCMAKE_BUILD_TYPE=Release

make -j$(nproc)
make install
```

**설치 결과**:
- 라이브러리: `$INSTALL_PREFIX/lib/libCommonAPI-SomeIP.so`
- 헤더: `$INSTALL_PREFIX/include/CommonAPI-3.2/CommonAPI/SomeIP/`

---

## 🚀 3. 앱 빌드

### 3.1 환경변수 설정
```bash
export DEPLOY_PREFIX="/home/jetson/leo/DES_Head-Unit/install_folder"
export LD_LIBRARY_PATH="$DEPLOY_PREFIX/lib:$LD_LIBRARY_PATH"
```

### 3.2 각 앱 빌드
```bash
# AmbientApp
cd /home/jetson/leo/DES_Head-Unit/app/AmbientApp
./build.sh

# GearApp
cd /home/jetson/leo/DES_Head-Unit/app/GearApp
./build.sh

# MediaApp
cd /home/jetson/leo/DES_Head-Unit/app/MediaApp
./build.sh

# HomeScreenApp
cd /home/jetson/leo/DES_Head-Unit/app/HomeScreenApp
./build.sh

# HU_MainApp Compositor
cd /home/jetson/leo/DES_Head-Unit/app/HU_MainApp
./build_compositor.sh
```

---

## ⚠️ 4. 현재 개발 환경에서의 실행 제약사항

### 4.1 Wayland 관련 에러
```
Failed to create wl_display (No such file or directory)
qt.qpa.plugin: Could not load the Qt platform plugin "wayland"
```

**원인**: 데스크톱 Ubuntu 환경에서는 Wayland Compositor가 실행되지 않음

**해결 방법**: 
1. **Yocto 환경에서는 문제 없음**: Yocto 이미지에는 Wayland/Weston이 포함되어 자동으로 실행됨
2. **개발 환경 테스트**: offscreen 모드로 로직 테스트 가능
   ```bash
   export QT_QPA_PLATFORM=offscreen  # UI 없이 로직만 실행
   ./build/AmbientApp
   ```

### 4.2 젯슨 오린 나노 기본 이미지 테스트 결과 (2026-01-04)

✅ **성공한 부분**:
- vsomeip 3.5.8 빌드 및 설치 완료
- CommonAPI 3.2.4 빌드 및 설치 완료
- 모든 ECU2 앱 빌드 성공 (GearApp, MediaApp, AmbientApp, HU_MainApp)
- vsomeip 통신 정상 작동 확인
- 앱 간 메시지 교환 확인 (Gear → Ambient 색상 변경)
- QML 파일 로딩 성공

⚠️ **제약사항**:
- offscreen 모드에서 OpenGL 컨텍스트 생성 실패로 UI 렌더링 불가
- 실제 화면 출력은 Wayland compositor 환경 필요

### 4.3 실제 ECU2 환경에서의 실행 순서
Yocto 이미지에서는 다음 순서로 자동 실행:
1. **Weston/Wayland Compositor** 시작 (자동)
2. **HU_MainApp_Compositor** 시작 (Wayland 서버)
3. **각 앱들** 순차 시작 (Wayland 클라이언트)

### 4.4 필수 QML 모듈
다음 패키지들이 반드시 필요합니다 (젯슨 테스트 완료):
```bash
sudo apt-get install -y \
    qml-module-qtgraphicaleffects \
    qml-module-qt-labs-settings \
    qml-module-qt-labs-folderlistmodel \
    qml-module-qtmultimedia \
    qtmultimedia5-dev \
    libqt5multimedia5-plugins
```

---

## 📦 5. Yocto 빌드를 위한 레시피 정보

### 5.1 기존 Yocto 파일 위치
```
/home/jetson/leo/DES_Head-Unit/meta/
├── meta-headunit/          # Head Unit 레이어
├── meta-instrumentcluster/ # IC 레이어
├── meta-middleware/        # CommonAPI/vsomeip 레이어
└── meta-vehiclecontrol/    # Vehicle Control 레이어 (ECU1용)
```

### 5.2 Yocto 레시피에 포함해야 할 패키지

#### Qt5 패키지
```
qtbase
qtdeclarative
qtquickcontrols2
qtwayland
```

#### Boost 패키지
```
boost
boost-system
boost-thread
boost-filesystem
boost-log
```

#### vsomeip & CommonAPI
- `vsomeip_3.5.8.bb` (직접 빌드)
- `commonapi-core_3.2.4.bb` (직접 빌드)
- `commonapi-someip_3.2.4.bb` (직접 빌드)

#### 앱 패키지
- `hu-mainapp-compositor_2.0.bb`
- `gearapp_1.0.bb`
- `mediaapp_1.0.bb`
- `ambientapp_1.0.bb`
- `homescreenapp_1.0.bb`

---

## 🔍 6. 의존성 검증

### 6.1 설치된 라이브러리 확인
```bash
ls -la $INSTALL_PREFIX/lib/
```

예상 파일:
- `libvsomeip3.so*`
- `libvsomeip3-sd.so*`
- `libCommonAPI.so*`
- `libCommonAPI-SomeIP.so*`

### 6.2 빌드된 앱 확인
```bash
find /home/jetson/leo/DES_Head-Unit/app -name "*.so" -o -name "GearApp" -o -name "AmbientApp" -o -name "MediaApp" -o -name "HomeScreenApp" -o -name "HU_MainApp_Compositor"
```

### 6.3 CommonAPI 코드 생성 확인
```bash
ls -la /home/jetson/leo/DES_Head-Unit/commonapi/generated/
```

---

## 📝 7. 주요 차이점: 라즈베리파이 vs 젯슨 오린 나노

| 항목 | 라즈베리파이 (ECU1) | 젯슨 오린 나노 (ECU2) |
|------|-------------------|---------------------|
| 역할 | VehicleControl Service Provider | HU Apps (Service Consumer) |
| 주요 앱 | VehicleControlECU | Compositor + UI Apps |
| IP 주소 | 192.168.1.100 | 192.168.1.101 |
| vsomeip 역할 | Routing Manager | Client Applications |
| 하드웨어 제어 | PiRacer (motor, servo) | 없음 (UI만) |
| 디스플레이 | 필요 없음 | HDMI 출력 필요 |

---

## 🎯 8. 다음 단계: Yocto 빌드

### 8.1 Yocto 레이어 구조 제안
```
meta-jetson-ecu2/
├── conf/
│   └── layer.conf
├── recipes-core/
│   └── images/
│       └── jetson-ecu2-image.bb
├── recipes-middleware/
│   ├── vsomeip/
│   │   └── vsomeip_3.5.8.bb
│   ├── commonapi-core/
│   │   └── commonapi-core_3.2.4.bb
│   └── commonapi-someip/
│       └── commonapi-someip_3.2.4.bb
└── recipes-apps/
    ├── hu-mainapp/
    │   └── hu-mainapp-compositor_2.0.bb
    ├── gearapp/
    │   └── gearapp_1.0.bb
    ├── mediaapp/
    │   └── mediaapp_1.0.bb
    ├── ambientapp/
    │   └── ambientapp_1.0.bb
    └── homescreenapp/
        └── homescreenapp_1.0.bb
```

### 8.2 필수 환경 설정 (systemd 서비스)
- Weston/Wayland 자동 시작
- 네트워크 설정 (192.168.1.101)
- Multicast 라우팅 설정
- 앱 자동 실행 순서

---

## ⚙️ 9. 빌드 시간 및 리소스

### 젯슨 오린 나노 빌드 시간 (참고)
- vsomeip: ~3-5분
- CommonAPI Core: ~1-2분
- CommonAPI SomeIP: ~1-2분
- 각 앱: ~30초-1분

### 디스크 공간
- 소스 코드: ~500MB
- 빌드 결과물: ~200MB
- install_folder: ~50MB

---

## 📞 트러블슈팅

### Qt Wayland 플러그인 에러
**증상**: `Could not load the Qt platform plugin "wayland"`

**원인**: 개발 환경에서 Wayland compositor 미실행

**해결**: 
- Yocto 환경에서는 문제 없음
- 개발 환경 테스트: `export QT_QPA_PLATFORM=xcb` 사용

### vsomeip 통신 실패
**증상**: 앱 간 통신 불가

**원인**: 
- Routing manager 미실행
- 네트워크 설정 오류
- Multicast 라우팅 누락

**해결**: `/home/jetson/leo/DES_Head-Unit/app/config/start_all_ecu2.sh` 참고

---

## 📚 참고 문서

- [vsomeip GitHub](https://github.com/COVESA/vsomeip)
- [CommonAPI C++ GitHub](https://github.com/COVESA/capicxx-core-runtime)
- [Qt5 Wayland Compositor](https://doc.qt.io/qt-5/qtwaylandcompositor-index.html)
- 프로젝트 내부 문서:
  - `/home/jetson/leo/DES_Head-Unit/BUILD_X86_README.md`
  - `/home/jetson/leo/DES_Head-Unit/meta/README.md`

---

**작성자**: GitHub Copilot  
**최종 업데이트**: 2026년 1월 4일
