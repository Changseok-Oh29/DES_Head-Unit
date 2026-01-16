# Docker Containerization Fixes

## Problem
All Docker containers were stuck in "Restarting" state after containerizing the Head Unit applications.

## Root Causes Identified

### 1. Missing Qt Dependencies
- **HU_MainApp**: Missing `QtGraphicalEffects` QML module
  - Error: `module 'QtGraphicalEffects' is not installed`
  - Caused compositor to fail loading QML files
  
- **Client Apps** (GearApp, PDCApp, MediaApp, AmbientApp, HomeScreenApp): Missing Wayland Qt platform plugin
  - Error: `Could not find the Qt platform plugin 'wayland'`
  - Apps couldn't connect to Wayland compositor

### 2. vsomeip Routing Manager Conflict
- **VehicleControlMock** (native) and **HomeScreenApp** (Docker) both configured as routing managers
- vsomeip requires exactly ONE routing manager per network
- Error: `routing manager present. Won't instantiate routing`

### 3. Wayland Configuration Issues
- Client apps configured with `QT_QPA_PLATFORM=xcb` (X11 mode) instead of `wayland`
- Missing HU_MainApp compositor service in docker-compose
- No shared Wayland socket volume between compositor and clients

## Fixes Applied

### 1. HU_MainApp Dockerfile
**File**: `HU_MainApp/Dockerfile`

**Change**: Added QtGraphicalEffects module to runtime dependencies
```dockerfile
# Stage 2: Runtime dependencies (around line 93)
qml-module-qtgraphicaleffects \
```

### 2. Client App Dockerfiles
**Files**: 
- `GearApp/Dockerfile`
- `PDCApp/Dockerfile`
- `MediaApp/Dockerfile`
- `AmbientApp/Dockerfile`
- `HomeScreenApp/Dockerfile`

**Change**: Added qtwayland5 package to runtime dependencies
```dockerfile
# Stage 2: Runtime dependencies
qtwayland5 \
```

### 3. HomeScreenApp vsomeip Configuration
**File**: `HomeScreenApp/vsomeip_homescreen.json`

**Change**: Removed routing manager role (only VehicleControlMock should be routing manager)
```json
{
    "services": [],
    // REMOVED: "routing": "HomeScreenApp",
    "service-discovery": {
```

**Why**: When running natively, HomeScreenApp was the routing manager. Now with Docker, VehicleControlMock (native) manages routing for the entire network.

### 4. docker-compose.all.yml
**File**: `docker-compose.all.yml`

**Changes**:
1. Added HU_MainApp compositor service
2. Changed all client apps from `QT_QPA_PLATFORM=xcb` to `QT_QPA_PLATFORM=wayland`
3. Added shared `wayland-socket` volume (`/tmp/runtime-root`)
4. Added `depends_on: humainapp` to all client services
5. Removed RemoteSpeakerApp service (runs natively for SSH audio)

### 5. Run/Stop Scripts
**File**: `run_docker_test.sh`

**Changes**:
- Added terminal emulator detection (gnome-terminal/xterm)
- Launches VehicleControlMock in separate terminal as routing manager
- Launches RemoteSpeakerApp in separate terminal for SSH audio
- Creates Wayland runtime directory with chmod 700

**File**: `stop_docker_test.sh`

**Changes**:
- Uses `pkill -f` for native app termination
- Uses `docker-compose down` for containers

## Architecture

### Native Applications (run in separate terminals)
- **VehicleControlMock**: vsomeip routing manager + mock ECU service
- **RemoteSpeakerApp**: Audio beep player over SSH

### Dockerized Applications
- **HU_MainApp**: Wayland compositor (connects to host X11 via `QT_QPA_PLATFORM=xcb`)
- **GearApp**: Gear display client (`QT_QPA_PLATFORM=wayland`)
- **PDCApp**: Parking sensor overlay client (`QT_QPA_PLATFORM=wayland`)
- **MediaApp**: Media player client (`QT_QPA_PLATFORM=wayland`)
- **AmbientApp**: Ambient lighting client (`QT_QPA_PLATFORM=wayland`)
- **HomeScreenApp**: Home screen client (`QT_QPA_PLATFORM=wayland`)

## Communication Flow

```
VehicleControlMock (routing manager)
    ↓ vsomeip service discovery
GearApp ←→ VehicleControlMock (gear status)
    ↓ window title change
HU_MainApp (compositor) → shows/hides PDCApp
    ↓ Wayland protocol (wayland-1 socket)
All client apps (GearApp, PDCApp, etc.)
```

## Testing Steps

1. Stop any running containers:
   ```bash
   ./stop_docker_test.sh
   ```

2. Rebuild and launch:
   ```bash
   ./run_docker_test.sh
   ```

3. Verify all containers are "Up" (not "Restarting"):
   ```bash
   docker ps
   ```

4. Check logs for successful startup:
   ```bash
   docker-compose logs humainapp  # Should show QML loaded successfully
   docker-compose logs gearapp    # Should show Wayland connection
   ```

5. Test gear change triggers PDCApp:
   - In VehicleControlMock terminal, send gear="R"
   - PDCApp overlay should appear in HU_MainApp window

## Files NOT Modified

- **VehicleControlECU/config/vsomeip_ecu1.json**: Different application, not part of current test setup
- **VehicleControlMock/config/vsomeip_mock.json**: Already correctly configured as routing manager
- All other vsomeip config files (GearApp, PDCApp, MediaApp, AmbientApp): No routing manager configured

## Known Limitations

- **Modularization Issue**: HU_MainApp relies on window title parsing from GearApp
  - If GearApp crashes, PDCApp won't display even if gear is "R"
  - **Recommended Future Fix**: HU_MainApp should subscribe to vsomeip VehicleControl service directly
