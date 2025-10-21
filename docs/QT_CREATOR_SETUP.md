# Qt Creator Setup Guide for DES Head-Unit

This guide explains how to open and run the DES Head-Unit project in Qt Creator.

## Method 1: Open CMake Project (Recommended)

### Step 1: Open Project in Qt Creator

1. Launch Qt Creator
2. Click **File → Open File or Project**
3. Navigate to `/home/seam/DES_Head-Unit/`
4. Select `CMakeLists.txt` (the root CMakeLists.txt file)
5. Click **Open**

### Step 2: Configure Build

Qt Creator will show the "Configure Project" screen:

1. **Select Kit:**
   - Choose **Desktop Qt 5.x.x GCC 64bit** (or your installed Qt5 kit)
   - If no kit is available, you need to set up Qt5 first

2. **Build Settings:**
   - Keep the default build directory (usually `../build-DES_Head-Unit-Desktop-Debug`)
   - Or change to `/home/seam/DES_Head-Unit/build` if you prefer

3. **CMake Configuration:**
   - Add these CMake arguments to configure which apps to build:
   ```
   -DCMAKE_BUILD_TYPE=Debug
   -DBUILD_MAIN_APP=ON
   -DBUILD_MEDIA_APP=OFF
   -DBUILD_GEAR_APP=OFF
   -DBUILD_AMBIENT_APP=OFF
   -DBUILD_LEGACY_APP=OFF
   ```

4. Click **Configure Project**

### Step 3: Select Run Target

1. In the bottom-left corner, click the **computer icon** (Build/Run selector)
2. From the **Run** dropdown, select **HU_MainApp**
3. The full path should show: `build/app/HU_MainApp/HU_MainApp`

### Step 4: Configure Run Environment (Important!)

1. Click **Projects** tab on the left sidebar
2. Select **Run** (under the Desktop kit)
3. In the **Run** section, find **Environment**
4. Click **Details** to expand environment variables
5. Click **Add** and add these variables:

   ```
   QT_QPA_PLATFORM = wayland
   QT_WAYLAND_DISABLE_WINDOWDECORATION = 1
   ```

   **OR** for X11 instead of Wayland:
   ```
   QT_QPA_PLATFORM = xcb
   ```

### Step 5: Build and Run

1. Click the **Build** button (hammer icon) or press `Ctrl+B`
2. Once built, click the **Run** button (green play icon) or press `Ctrl+R`
3. The Head Unit application window should appear!

---

## Method 2: Open as Qt Quick Application (Alternative)

If you want to work primarily on QML files:

### Step 1: Create .pro File (Optional)

While the project uses CMake, you can create a `.pro` file for Qt Creator:

Create `HU_MainApp.pro` in `/home/seam/DES_Head-Unit/app/HU_MainApp/`:

```qmake
QT += quick qml multimedia network core
CONFIG += c++17

# Source files
SOURCES += \
    src/main.cpp \
    ../MediaApp/src/mediamanager.cpp \
    ../GearApp/src/gearmanager.cpp \
    ../AmbientApp/src/ambientmanager.cpp \
    ../GearApp/src/ipcmanager.cpp

HEADERS += \
    ../MediaApp/src/mediamanager.h \
    ../GearApp/src/gearmanager.h \
    ../AmbientApp/src/ambientmanager.h \
    ../GearApp/src/ipcmanager.h

# QML files
RESOURCES += qml.qrc

# Default rules for deployment
qnx: target.path = /tmp/$${TARGET}/bin
else: unix:!android: target.path = /opt/$${TARGET}/bin
!isEmpty(target.path): INSTALLS += target
```

Then open `HU_MainApp.pro` in Qt Creator instead of CMakeLists.txt.

---

## Troubleshooting

### Issue: "No valid kits found"

**Solution:**
1. Go to **Tools → Options → Kits**
2. Click **Qt Versions** tab
3. Click **Add** and browse to your Qt5 qmake binary (e.g., `/usr/bin/qmake` or `/usr/lib/qt5/bin/qmake`)
4. Go back to **Kits** tab
5. Click **Add** and configure a new kit with your Qt5 version

### Issue: "Cannot find Qt5Quick" or similar CMake errors

**Solution:**
Install Qt5 development packages:
```bash
# Ubuntu/Debian
sudo apt-get install qtbase5-dev qtdeclarative5-dev qtmultimedia5-dev \
                     libqt5multimedia5-plugins qtquickcontrols2-5-dev

# Fedora
sudo dnf install qt5-qtbase-devel qt5-qtdeclarative-devel \
                 qt5-qtmultimedia-devel qt5-qtquickcontrols2-devel
```

### Issue: Application window doesn't appear

**Solution:**
1. Check the **Application Output** pane in Qt Creator for error messages
2. Verify environment variables are set (Step 4 above)
3. Try changing `QT_QPA_PLATFORM` from `wayland` to `xcb` or remove it entirely

### Issue: "Failed to bind to port 12346"

**Solution:**
This is normal if another instance is running. The IpcManager will continue to work but won't receive IC data until the port is available.

---

## Qt Creator Features to Use

### QML Live Preview

1. Open any `.qml` file (e.g., `main.qml`)
2. Click **Design** mode (bottom-left tabs)
3. You can see a live preview and edit properties visually

**Note:** Complex QML with C++ backends may not preview perfectly, but simple components will work.

### QML Profiler

1. Run the application
2. Click **Analyze → QML Profiler**
3. This helps identify performance issues in QML code

### Debugger

1. Set breakpoints in C++ code by clicking left margin
2. Press `F5` or click **Debug** (bug icon)
3. You can step through C++ manager code and inspect variables

### Quick Access to Files

- Press `Ctrl+K` to open the **Locator**
- Type filename to quickly jump to any file
- Type `:line_number` to jump to a specific line

---

## Recommended Qt Creator Settings

### Enable QML Syntax Highlighting

1. **Tools → Options → Text Editor → Generic Highlighter**
2. Ensure QML is enabled

### Auto-format QML on Save

1. **Tools → Options → Qt Quick → QML/JS Editing**
2. Check **Enable auto-formatting on file save**

### Show Line Numbers

1. **Tools → Options → Text Editor → Display**
2. Check **Display line numbers**

---

## Quick Reference: Qt Creator Shortcuts

| Action | Shortcut |
|--------|----------|
| Build | `Ctrl+B` |
| Run | `Ctrl+R` |
| Debug | `F5` |
| Stop | `Ctrl+Shift+R` |
| Switch Header/Source | `F4` |
| Locator (Quick Open) | `Ctrl+K` |
| Find in Files | `Ctrl+Shift+F` |
| Format Code | `Ctrl+I` |

---

## Running Individual App Processes (Advanced)

If you want to run MediaApp, GearApp, or AmbientApp separately:

1. In CMake configuration, enable the app you want:
   ```
   -DBUILD_MEDIA_APP=ON
   -DBUILD_GEAR_APP=ON
   -DBUILD_AMBIENT_APP=ON
   ```

2. After building, select the desired target from the Run dropdown:
   - MediaApp
   - GearApp
   - AmbientApp

**Note:** These individual apps have their own UIs and are designed to run as separate processes in the future vsomeip architecture.

---

## Next Steps

- **Explore the Code:** Browse through the QML files to customize the UI
- **Modify Layouts:** Edit `HomePage.qml`, `MediaPage.qml`, etc. and see changes on rebuild
- **Add Features:** Extend manager classes in the `src/` folders
- **Debug:** Set breakpoints and step through the signal/slot connections

Happy coding! 🚀
