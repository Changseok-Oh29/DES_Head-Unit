# Qt Creator Quick Start Guide

## ✅ Issues Fixed

All CMakeLists.txt files have been updated to correctly reference source files in `src/` directories. The project should now open cleanly in Qt Creator.

## 🚀 Quick Steps to Open in Qt Creator

### 1. Open Project
- Launch Qt Creator
- **File → Open File or Project**
- Navigate to: `/home/seam/DES_Head-Unit/`
- Select: **CMakeLists.txt** (the root one)
- Click **Open**

### 2. Configure Project
When the "Configure Project" screen appears:

1. **Select Kit:** Desktop Qt 5.15.2 GCC 64bit (or your Qt5 kit)

2. **CMake Arguments:**
   - Click **Details** next to "CMake"
   - In "Additional CMake options" field, add:
   ```
   -DBUILD_MAIN_APP=ON -DBUILD_MEDIA_APP=OFF -DBUILD_GEAR_APP=OFF -DBUILD_AMBIENT_APP=OFF -DBUILD_LEGACY_APP=OFF
   ```

3. Click **Configure Project**

### 3. Select Run Target
- Bottom-left corner: Click on the **Run configuration dropdown**
- Select: **HU_MainApp**

### 4. Set Environment Variables
This is **IMPORTANT** for the app to run:

1. Click **Projects** (wrench icon on left sidebar)
2. Under "Build & Run", select **Desktop Qt 5.x.x** → **Run**
3. In the "Run" section, find **Environment**
4. Click **Details** to expand
5. Click **Add** button and add:
   - Variable: `QT_QPA_PLATFORM`
   - Value: `wayland` (or `xcb` if you prefer X11)

6. Optional - disable window decoration:
   - Variable: `QT_WAYLAND_DISABLE_WINDOWDECORATION`
   - Value: `1`

### 5. Build and Run
- Press **Ctrl+B** to build (or click hammer icon)
- Press **Ctrl+R** to run (or click green play icon)
- The Head Unit window should appear!

## 📋 What Was Fixed

The following CMakeLists.txt files were updated to fix the "Cannot find source file: main.cpp" errors:

1. **`app/MediaApp/CMakeLists.txt`** - Updated paths to `src/main.cpp`, `src/mediamanager.cpp`
2. **`app/GearApp/CMakeLists.txt`** - Updated paths to `src/main.cpp`, `src/gearmanager.cpp`, `src/ipcmanager.cpp`
3. **`app/AmbientApp/CMakeLists.txt`** - Created complete CMakeLists.txt with correct paths
4. **`app/HU_MainApp/CMakeLists.txt`** - Already correct (uses `src/main.cpp`)

Also created missing `qml.qrc` files for individual apps.

## 🎯 Recommended Build Configuration

**For Qt Creator development, use:**
```
-DBUILD_MAIN_APP=ON
-DBUILD_MEDIA_APP=OFF
-DBUILD_GEAR_APP=OFF
-DBUILD_AMBIENT_APP=OFF
-DBUILD_LEGACY_APP=OFF
```

This builds only the main UI application (HU_MainApp), which is what you'll be working with most of the time.

**Why?**
- HU_MainApp already includes all the manager code (MediaManager, GearManager, AmbientManager, IpcManager)
- The individual apps (MediaApp, GearApp, AmbientApp) are for future multi-process architecture
- Building only HU_MainApp is faster and simpler for development

## 🔧 Alternative: Build All Apps

If you want to build all apps (for testing the multi-process setup), use:
```
-DBUILD_MAIN_APP=ON
-DBUILD_MEDIA_APP=ON
-DBUILD_GEAR_APP=ON
-DBUILD_AMBIENT_APP=ON
-DBUILD_LEGACY_APP=OFF
```

Then you can select different run targets:
- HU_MainApp (recommended)
- MediaApp
- GearApp
- AmbientApp

## ✨ Quick Tips

- **Edit Mode**: Press `F2` to switch between edit/design mode
- **Build**: `Ctrl+B`
- **Run**: `Ctrl+R`
- **Stop**: `Ctrl+Shift+R`
- **Find File**: `Ctrl+K` then type filename
- **Switch Header/Source**: `F4`

## 🐛 Troubleshooting

### "CMake Error: Cannot find source file"
This should be fixed now. If you still see it:
1. Close Qt Creator
2. Delete the build directory: `rm -rf build`
3. Re-open the project in Qt Creator

### "Qt5 not found"
Install Qt5 development packages:
```bash
sudo apt-get install qtbase5-dev qtdeclarative5-dev qtmultimedia5-dev qtquickcontrols2-5-dev
```

### Application doesn't start / Black window
1. Check environment variables (Step 4 above)
2. Try changing `QT_QPA_PLATFORM` from `wayland` to `xcb`
3. Check Application Output panel in Qt Creator for error messages

### "Failed to bind to port 12346"
This is normal - the IpcManager will work but won't receive IC data. It's just a warning.

---

**You're all set!** The project should now open and build cleanly in Qt Creator. 🎉
