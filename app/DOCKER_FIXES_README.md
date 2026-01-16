# Docker Containerization - Issues Fixed

## 🔴 Problems Found

### 1. **Missing HU_MainApp (Wayland Compositor)** 
- **Issue**: The compositor that displays all apps was NOT included in `docker-compose.all.yml`
- **Result**: No central display to composite apps
- **Fix**: Added `humainapp` service as the first service

### 2. **Wrong QT Platform for Client Apps**
- **Issue**: All apps used `QT_QPA_PLATFORM=xcb` (direct X11)
- **Result**: Each app opened separate X11 windows instead of connecting to compositor
- **Fix**: Changed to `QT_QPA_PLATFORM=wayland` for all client apps

### 3. **Missing Wayland Socket Sharing**
- **Issue**: No shared volume for `wayland-1` socket
- **Result**: Client apps couldn't find compositor socket
- **Fix**: Added shared Docker volume `wayland-socket` mounted at `/tmp/runtime-root`

### 4. **No Service Dependencies**
- **Issue**: Client apps could start before compositor was ready
- **Result**: Connection failures
- **Fix**: Added `depends_on: humainapp` to all client services

### 5. **VehicleControlMock Build Not Verified**
- **Issue**: Script didn't check if build succeeded
- **Result**: Could fail silently
- **Fix**: Added error checking and validation

---

## ✅ Architecture After Fix

```
┌─────────────────────────────────────────────────┐
│ Host X11 Display (:0)                           │
└─────────────────┬───────────────────────────────┘
                  │
                  ↓
┌─────────────────────────────────────────────────┐
│ Docker: humainapp (HU_MainApp)                  │
│   - Connects to host X11 (QT_QPA_PLATFORM=xcb)  │
│   - Creates wayland-1 socket                    │
│   - Wayland Compositor                          │
└─────────────────┬───────────────────────────────┘
                  │ wayland-1 socket
                  │ (shared via Docker volume)
        ┌─────────┼─────────┬─────────┐
        │         │         │         │
        ↓         ↓         ↓         ↓
┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐
│ gearapp  │ │ pdcapp   │ │ mediaapp │ │ homescreen│
│ (wayland)│ │ (wayland)│ │ (wayland)│ │  (wayland)│
└──────────┘ └──────────┘ └──────────┘ └──────────┘
     All connect to wayland-1 socket
     QT_QPA_PLATFORM=wayland
```

---

## 📋 Changes Made

### `docker-compose.all.yml`

**Added:**
- `humainapp` service (Wayland Compositor)
- `depends_on: humainapp` for all client apps
- Shared volume: `wayland-socket`
- Proper environment variables:
  - `XDG_RUNTIME_DIR=/tmp/runtime-root`
  - `QT_QPA_PLATFORM=wayland` (for clients)
  - `WAYLAND_DISPLAY=wayland-1`
  - `QT_WAYLAND_DISABLE_WINDOWDECORATION=1`

**Changed:**
- All client apps now use `wayland` instead of `xcb`
- Volume mount changed from X11 socket to Wayland socket

### `run_docker_test.sh`

**Added:**
- Dependency checking (cmake, Qt5)
- Build verification for VehicleControlMock
- Process existence check after starting
- Runtime directory creation for Wayland socket
- Better error messages
- Container status display

**Improved:**
- Error handling with proper exit codes
- Step-by-step progress reporting
- Informative success messages

---

## 🚀 How to Run

```bash
# 1. Clean previous state
./stop_docker_test.sh

# 2. Start everything
./run_docker_test.sh

# 3. View logs
docker-compose -f docker-compose.all.yml logs -f

# 4. View specific app
docker logs -f humainapp
docker logs -f gearapp
docker logs -f pdcapp
```

---

## 🔍 Debugging

### Check if HU_MainApp is running:
```bash
docker ps | grep humainapp
docker logs humainapp
```

### Check Wayland socket:
```bash
ls -la /tmp/runtime-root/
# Should see: wayland-1 socket
```

### Check if client apps connect:
```bash
docker logs gearapp 2>&1 | grep -i wayland
# Should NOT see: "could not connect to wayland display"
```

### Check VehicleControlMock:
```bash
ps aux | grep VehicleControlMock
# Should be running with PID from /tmp/vehiclecontrolmock.pid
```

---

## ⚠️ Common Issues

### Issue: "Could not connect to wayland display"
**Cause**: HU_MainApp didn't start or wayland-1 socket not created  
**Fix**: 
```bash
docker logs humainapp  # Check for errors
docker restart humainapp
```

### Issue: Only GearApp and PDCApp visible
**Cause**: Old config with `xcb` instead of `wayland`  
**Fix**: 
```bash
./stop_docker_test.sh
rm -rf /tmp/runtime-root
./run_docker_test.sh
```

### Issue: Black screen in HU_MainApp
**Cause**: Client apps not connecting to compositor  
**Fix**: Check client app logs for Wayland connection errors

### Issue: VehicleControlMock not starting
**Cause**: Missing dependencies or port conflict  
**Fix**: 
```bash
# Check dependencies
sudo apt-get install qtbase5-dev libboost-all-dev

# Check port usage
netstat -tulpn | grep 30490
```

---

## 📊 Expected Output

When running correctly, you should see:

1. **One HU_MainApp window** showing the compositor with:
   - Left panel: GearApp
   - Main area: HomeScreenApp/MediaApp/AmbientApp (switchable)
   - Overlay: PDCApp (when gear = R)

2. **No separate windows** for client apps (they're composited)

3. **VehicleControlMock console** with gear/speed/battery broadcasts

4. **Docker logs** showing:
   - HU_MainApp: "wayland-1 socket created"
   - GearApp: "Connected to wayland-1"
   - PDCApp: "Connected to wayland-1"
   - All apps: vsomeip registration messages

---

## 🎯 Next Steps

1. **Test gear change**: Change gear in VehicleControlMock
   - GearApp should update
   - PDCApp should appear when gear = R

2. **Test modularization**: Kill one app
   ```bash
   docker stop gearapp
   # Other apps should continue working
   ```

3. **Monitor vsomeip**: Check service discovery
   ```bash
   docker logs -f gearapp | grep -i "available"
   ```

4. **Add more apps**: Follow the same pattern in `docker-compose.all.yml`

---

## 📝 Files Modified

- ✅ `docker-compose.all.yml` - Added HU_MainApp, fixed Qt platform
- ✅ `run_docker_test.sh` - Added error checking and validation
- ✅ `DOCKER_FIXES_README.md` - This documentation

## 📚 Reference

- Wayland Protocol: https://wayland.freedesktop.org/
- Qt Wayland Compositor: https://doc.qt.io/qt-5/qtwaylandcompositor-index.html
- Docker Compose: https://docs.docker.com/compose/
