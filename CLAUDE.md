# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

### Local Development (x86_64)
```bash
# Build all apps from root
cmake -B build -DCMAKE_BUILD_TYPE=Debug
cmake --build build -j$(nproc)

# Build specific apps only
cmake -B build -DBUILD_MEDIA_APP=OFF -DBUILD_GEAR_APP=OFF -DBUILD_AMBIENT_APP=OFF -DBUILD_MAIN_APP=ON
cmake --build build

# Build legacy single-process app
cd app/HU_app
cmake -B build -DCMAKE_BUILD_TYPE=Debug
cmake --build build
./build/HU_app
```

### Run Applications
```bash
# Run main UI app (requires all components)
./build/app/HU_MainApp/HU_MainApp

# Run individual process apps
./build/app/MediaApp/MediaApp
./build/app/GearApp/GearApp
./build/app/AmbientApp/AmbientApp

# Enable Qt debug logging
QT_LOGGING_RULES="*.debug=true" ./build/app/HU_MainApp/HU_MainApp
```

### Yocto Build (Raspberry Pi 4)
```bash
# Setup and build image
source oe-init-build-env
bitbake-layers add-layer ../meta-raspberrypi
bitbake-layers add-layer ../meta-openembedded/meta-oe
bitbake-layers add-layer ../meta-openembedded/meta-python
bitbake-layers add-layer ../meta-openembedded/meta-multimedia
bitbake-layers add-layer ./meta-headunit
bitbake headunit-image

# Flash to SD card (replace sdX with your device)
sudo dd if=tmp/deploy/images/raspberrypi4-64/headunit-image-raspberrypi4-64.wic of=/dev/sdX bs=4M status=progress
```

## Architecture Overview

### Multi-Process Design
This is a **multi-process automotive infotainment system** currently in transition from single-process to distributed architecture:

**Current State (Single Process):**
- HU_MainApp aggregates all manager classes (MediaManager, GearManager, AmbientManager, IpcManager)
- Direct C++ object references and Qt signal/slot connections
- All QML UI components loaded in one QGuiApplication

**Target State (Multi-Process with vsomeip):**
- Each app runs as independent process: MediaApp, GearApp, AmbientApp
- HU_MainApp becomes UI-only layer with service proxies
- Communication via vsomeip (SOME/IP middleware) instead of direct object links
- Service-oriented architecture for automotive-grade reliability

### Key Components

**HU_MainApp** - Main UI application
- Location: `app/HU_MainApp/`
- Role: Primary user interface, currently includes all manager source files
- Entry point: `main.cpp` creates all managers and loads `main.qml`
- Future: Will use vsomeip proxies instead of direct manager includes

**MediaApp** - Media playback service
- Location: `app/MediaApp/`
- Manager: `mediamanager.{cpp,h}`
- Responsibilities: USB media scanning, QMediaPlayer/QMediaPlaylist control, volume management
- Scans: `/media` and `/mnt` for MP3, WAV, FLAC, M4A, AAC, OGG, WMA files
- Hot-plug: QFileSystemWatcher monitors USB device changes

**GearApp** - Gear control + IC communication
- Location: `app/GearApp/`
- Managers: `gearmanager.{cpp,h}`, `ipcmanager.{cpp,h}`
- Responsibilities: PRND gear state management, bi-directional IC synchronization
- IPC: UDP socket (listens on port 12346, sends to IC port 12345)
- Protocol: JSON messages over UDP

**AmbientApp** - Ambient lighting service
- Location: `app/AmbientApp/`
- Manager: `ambientmanager.{cpp,h}`
- Responsibilities: RGB color control, gear-reactive lighting, brightness adjustment
- Color mapping: P→Red, R→Orange, N→Yellow, D→Green

**IpcManager** - IC communication gateway
- Protocol: UDP sockets with JSON payloads
- Message types: `gear_change`, `gear_status`, `ambient_light`, `heartbeat`
- Heartbeat: 5-second intervals, 15-second timeout for connection monitoring
- Bi-directional: Receives gear status from IC, sends HU state to IC

### Communication Flow Examples

**Gear Change (QML → IC):**
1. User clicks gear button in QML → `gearManager.setGearPosition("D")`
2. GearManager updates state → emits `gearPositionChanged("D")`
3. AmbientManager slot receives signal → changes color to green (#27ae60)
4. GearManager sends UDP message to IC: `{"type": "gear_change", "gear": "D", "timestamp": ...}`

**IC Gear Status (IC → HU):**
1. IpcManager receives UDP packet on port 12346 from IC
2. Parses JSON → emits `gearStatusReceivedFromIC("D")`
3. GearManager slot updates internal state → emits `gearPositionChanged("D")`
4. QML UI updates via property binding

**Media Volume to Ambient Brightness (Planned):**
- MediaManager emits `volumeChanged()` → AmbientManager adjusts brightness
- Currently commented out in code, ready to enable

### Qt/QML Patterns Used

**Q_PROPERTY for QML Binding:**
```cpp
Q_PROPERTY(QString gearPosition READ gearPosition WRITE setGearPosition NOTIFY gearPositionChanged)
Q_PROPERTY(QStringList mediaFiles READ mediaFiles NOTIFY mediaFilesChanged)
Q_PROPERTY(QString ambientColor READ ambientColor WRITE setAmbientColor NOTIFY ambientColorChanged)
```

**Context Property Exposure:**
```cpp
// main.cpp pattern
engine.rootContext()->setContextProperty("mediaManager", &mediaManager);
engine.rootContext()->setContextProperty("gearManager", &gearManager);
```

**Signal/Slot Inter-Manager Communication:**
```cpp
// Connect managers in same process
QObject::connect(&ipcManager, &IpcManager::gearStatusReceivedFromIC,
                 &gearManager, &GearManager::onGearStatusReceivedFromIC);
QObject::connect(&gearManager, &GearManager::gearPositionChanged,
                 &ambientManager, &AmbientManager::onGearPositionChanged);
```

**QML Reactive Updates:**
```qml
Connections {
    target: ambientManager
    function onAmbientColorChanged() {
        window.currentAmbientColor = ambientManager.ambientColor
    }
}
```

## File Navigation

**Manager Classes (Business Logic):**
- Media: `app/MediaApp/mediamanager.{cpp,h}`, duplicated in `app/HU_app/`
- Gear: `app/GearApp/gearmanager.{cpp,h}`, duplicated in `app/HU_app/`
- Ambient: `app/AmbientApp/ambientmanager.{cpp,h}`, duplicated in `app/HU_app/`
- IPC: `app/GearApp/ipcmanager.{cpp,h}`, duplicated in `app/HU_app/`

**QML UI Components:**
- Main window: `app/HU_MainApp/main.qml`
- Navigation: `app/HU_MainApp/MainMenu.qml`
- Media UI: `app/HU_MainApp/MediaApp.qml`
- Gear UI: `app/HU_MainApp/GearSelectionWidget.qml`
- Ambient UI: `app/HU_MainApp/AmbientLighting.qml`

**Build Configuration:**
- Root: `CMakeLists.txt` (controls which apps to build via BUILD_* options)
- Per-app: `app/{AppName}/CMakeLists.txt`
- Yocto: `meta/meta-headunit/recipes-headunit/`, `meta/meta-headunit/recipes-images/`

## Code Modification Guidelines

### Adding New Features to Managers

When modifying manager classes (e.g., MediaManager):
1. Edit both locations: `app/{AppName}/` AND `app/HU_app/` (currently duplicated)
2. Add Q_PROPERTY if QML needs to access new data
3. Add signals for state changes that other managers/QML need to react to
4. Update `main.cpp` to wire new signals between managers if cross-component communication needed

### QML UI Changes

- QML files are embedded via `qml.qrc` resource files
- After modifying QML, rebuild to update resources: `cmake --build build`
- QML hot-reload not configured; requires app restart to see changes

### Adding New IPC Messages

1. Update IpcManager to handle new message type in `onDataReceived()`
2. Add corresponding signal emission
3. Add JSON serialization in sender (e.g., `sendAmbientLightData()` pattern)
4. Update IC application to handle new message type
5. Document message format in code comments

### vsomeip Migration (Future)

When implementing vsomeip:
1. Create proxy classes: `proxies/MediaProxy.h`, `proxies/GearProxy.h`, `proxies/AmbientProxy.h`
2. Replace direct includes in `HU_MainApp/main.cpp`:
   ```cpp
   // Before:
   #include "../MediaApp/mediamanager.h"

   // After:
   #include "proxies/MediaProxy.h"
   ```
3. Proxy classes should expose same Q_PROPERTY interface to minimize QML changes
4. Configure vsomeip JSON configuration files for service discovery
5. Update CMakeLists.txt to link vsomeip libraries

## Testing

### USB Media Testing
```bash
# Create test media directory
mkdir -p /tmp/test_media
cp ~/Music/*.mp3 /tmp/test_media/

# MediaManager scans /media and /mnt by default
# Use QML UI to trigger manual scan at custom path
```

### IPC Communication Testing
```bash
# Monitor UDP traffic between HU and IC
sudo tcpdump -i lo -A port 12345 or port 12346

# Send test gear status to HU (simulating IC)
echo '{"type":"gear_status","gear":"D","timestamp":1697750000000}' | nc -u localhost 12346
```

### Manual UI Testing
1. Run HU_MainApp
2. Test gear buttons: P, R, N, D (check ambient color changes)
3. Test media player: scan USB, play/pause, volume control
4. Test ambient controls: color picker, brightness slider

## Dependencies

**Required Qt5 Modules:**
- Qt5::Core - Base Qt functionality
- Qt5::Qml - QML engine
- Qt5::Quick - Qt Quick UI framework
- Qt5::Multimedia - Audio/video playback
- Qt5::Network - UDP socket communication

**Build Requirements:**
- CMake 3.16+
- C++17 compiler
- Qt5 development packages
- (Yocto) meta-raspberrypi, meta-openembedded layers

**Runtime Requirements:**
- Qt5 runtime libraries
- USB mount points at `/media` or `/mnt`
- (Optional) Instrument Cluster application listening on UDP port 12345
