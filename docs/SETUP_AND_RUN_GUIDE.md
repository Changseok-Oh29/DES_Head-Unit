# DES Head Unit - Setup and Run Guide

Complete guide for building, deploying, and running the distributed Head Unit system with PDC (Park Distance Control) feature.

---

## 📋 Table of Contents

- [System Overview](#system-overview)
- [Hardware Requirements](#hardware-requirements)
- [Network Configuration](#network-configuration)
- [ECU1: Raspberry Pi Setup](#ecu1-raspberry-pi-setup)
- [ECU2: Jetson Orin Nano Setup](#ecu2-jetson-orin-nano-setup)
- [Running the System](#running-the-system)
- [Troubleshooting](#troubleshooting)

---

## 🎯 System Overview

The Head Unit system consists of two ECUs communicating via SOME/IP over Ethernet:

```
┌─────────────────────────────────────────────────────────────────┐
│                         System Architecture                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  Arduino Uno                                                      │
│  └─ HC-SR04 (Ultrasonic Sensor)                                  │
│       │                                                           │
│       │ CAN (MCP2518FD)                                          │
│       ▼                                                           │
│  ┌──────────────────────┐          ┌─────────────────────────┐  │
│  │  ECU1: Raspberry Pi  │◄────────►│  ECU2: Jetson Orin Nano │  │
│  │  (VehicleControlECU) │ Ethernet │  (Head Unit Apps)       │  │
│  │                      │          │                         │  │
│  │  • Service Provider  │          │  • HU_MainApp          │  │
│  │  • Routing Manager   │          │    (Wayland Compositor) │  │
│  │  • CAN Interface     │          │  • GearApp             │  │
│  │  • Speed/Distance    │          │  • PDCApp              │  │
│  │  • Gear Control      │          │  • HomeScreenApp       │  │
│  │                      │          │  • MediaApp            │  │
│  │  IP: 192.168.1.100   │          │  • AmbientApp          │  │
│  └──────────────────────┘          │  • IC_app              │  │
│                                     │                         │  │
│                                     │  IP: 192.168.1.101     │  │
│                                     └─────────────────────────┘  │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

**Communication Protocol:**
- SOME/IP (Service-Oriented Middleware over IP)
- CommonAPI C++ bindings
- vsomeip3 implementation

---

## 🔧 Hardware Requirements

### ECU1 (Raspberry Pi 4)
- Raspberry Pi 4 Model B (4GB+ RAM recommended)
- MicroSD card (16GB+ recommended)
- Waveshare 2-CH CAN FD HAT (MCP2518FD)
- PiRacer HAT (for motor control and sensors)
- Ethernet cable
- Power supply (5V/3A USB-C)

### ECU2 (Jetson Orin Nano)
- NVIDIA Jetson Orin Nano Developer Kit
- MicroSD card or NVMe SSD
- Monitor with HDMI connection
- Ethernet cable
- Power supply (appropriate for Jetson model)

### Additional Hardware
- Arduino Uno
- HC-SR04 Ultrasonic Distance Sensor
- CAN transceiver module (for Arduino to CAN HAT connection)
- Jumper wires and breadboard

---

## 🌐 Network Configuration

Both ECUs must be on the same Ethernet network with static IPs:

| Device | Interface | IP Address | Netmask |
|--------|-----------|------------|---------|
| Raspberry Pi (ECU1) | eth0 | 192.168.1.100 | 255.255.255.0 |
| Jetson Orin Nano (ECU2) | enP8p1s0 | 192.168.1.101 | 255.255.255.0 |

**Important:** Use a direct Ethernet cable connection between ECU1 and ECU2 for best performance.

---

## 🍓 ECU1: Raspberry Pi Setup

### Prerequisites

**Development Machine Requirements:**
- Ubuntu 20.04 or 22.04 (64-bit)
- 50GB+ free disk space
- 8GB+ RAM
- Yocto build dependencies installed

### Step 1: Clone the Repository

```bash
git clone <repository-url> PDC
cd PDC/headunit/DES_Head-Unit
git checkout PDC  # Switch to PDC branch
```

### Step 2: Build Yocto Image

Navigate to the Yocto build directory:

```bash
cd /home/seame/PDC/headunit/yocto-build
```

Initialize the build environment:

```bash
source sources/poky/oe-init-build-env build
```

Build the VehicleControl ECU image:

```bash
# (Optional) Clean previous builds to ensure all changes are applied
bitbake -c clean vehiclecontrol-ecu
bitbake -c clean rpi-cmdline

# Build the complete image
bitbake vehiclecontrol-image
```

**Build Time:** Expect 2-4 hours for the first build (depending on your machine).

The build output will be located at:
```
build/tmp-glibc/deploy/images/raspberrypi4-64/vehiclecontrol-image-raspberrypi4-64.rpi-sdimg
```

### Step 3: Flash SD Card

**On Linux:**

1. Insert SD card and identify the device:
```bash
lsblk
# Look for your SD card (e.g., /dev/sda)
```

2. Unmount any mounted partitions:
```bash
sudo umount /dev/sda*
```

3. Flash the image:
```bash
sudo dd if=build/tmp-glibc/deploy/images/raspberrypi4-64/vehiclecontrol-image-raspberrypi4-64.rpi-sdimg \
    of=/dev/sda \
    bs=4M \
    status=progress \
    conv=fsync
```

4. Safely eject:
```bash
sync
sudo eject /dev/sda
```

### Step 4: Hardware Setup

1. **Insert SD card** into Raspberry Pi
2. **Connect CAN HAT** to GPIO pins
3. **Connect PiRacer HAT** (if using motor control)
4. **Connect Ethernet cable** to Jetson
5. **Connect Arduino** to CAN HAT via CAN transceiver
6. **Power on** Raspberry Pi

### Step 5: Verify Boot

The VehicleControlECU service starts automatically on boot. To verify:

```bash
# SSH into Raspberry Pi (if network is configured)
ssh root@192.168.1.100

# Check service status
systemctl status vehiclecontrol-ecu

# View logs
journalctl -u vehiclecontrol-ecu -f
```

**Expected log output:**
```
✅ VehicleControlStubImpl initialized
✅ Routing Manager started [Host]
🚀 VehicleControlECU is running...
✅ CAN interface can0 connected successfully
✅ CAN interface can1 connected successfully
```

---

## 🤖 ECU2: Jetson Orin Nano Setup

### Prerequisites

- Jetson Orin Nano with Ubuntu 20.04/22.04
- Display connected via HDMI
- Internet connection for initial setup
- Git installed

### Step 1: Clone the Repository

```bash
cd ~
git clone <repository-url> Chang/DES_Head-Unit
cd Chang/DES_Head-Unit
git checkout PDC  # Switch to PDC branch
```

### Step 2: Install Dependencies

#### Install vsomeip3

```bash
cd ~/Chang/DES_Head-Unit/deps/vsomeip
mkdir -p build && cd build

cmake .. \
    -DCMAKE_INSTALL_PREFIX=/usr/local \
    -DENABLE_SIGNAL_HANDLING=1 \
    -DVSOMEIP_INSTALL_ROUTINGMANAGERD=ON

make -j$(nproc)
sudo make install
sudo ldconfig
```

Verify installation:
```bash
which routingmanagerd
# Should output: /usr/local/bin/routingmanagerd

ldconfig -p | grep vsomeip
# Should show vsomeip3 libraries
```

#### Install CommonAPI Runtime

Follow the CommonAPI installation guide for building CommonAPI Core and CommonAPI SOME/IP runtime libraries.

#### Install Qt5 (for GUI apps)

```bash
sudo apt-get update
sudo apt-get install -y \
    qt5-default \
    qtwayland5 \
    qtdeclarative5-dev \
    qml-module-qtquick2 \
    qml-module-qtquick-controls2 \
    qml-module-qtquick-window2
```

### Step 3: Build All Applications

Build each application in the correct order:

```bash
cd ~/Chang/DES_Head-Unit/app
```

#### 1. Build HU_MainApp Compositor (REQUIRED - Must build first)

```bash
cd HU_MainApp
mkdir -p build && cd build
cmake ..
make -j$(nproc)
cd ../..
```

#### 2. Build GearApp

```bash
cd GearApp
mkdir -p build && cd build
cmake ..
make -j$(nproc)
cd ../..
```

#### 3. Build AmbientApp

```bash
cd AmbientApp
mkdir -p build && cd build
cmake ..
make -j$(nproc)
cd ../..
```

#### 4. Build IC_app

```bash
cd IC_app
mkdir -p build && cd build
cmake ..
make -j$(nproc)
cd ../..
```

#### 5. Build MediaApp

```bash
cd MediaApp
mkdir -p build && cd build
cmake ..
make -j$(nproc)
cd ../..
```

#### 6. Build PDCApp

```bash
cd PDCApp
mkdir -p build && cd build
cmake ..
make -j$(nproc)
cd ../..
```

#### 7. Build HomeScreenApp

```bash
cd HomeScreenApp
mkdir -p build && cd build
cmake ..
make -j$(nproc)
cd ../..
```

#### 8. Build RemoteSpeakerApp (Optional)

```bash
cd RemoteSpeakerApp
mkdir -p build && cd build
cmake ..
make -j$(nproc)
cd ../..
```

### Build All at Once (Alternative)

```bash
cd ~/Chang/DES_Head-Unit/app

for app in HU_MainApp GearApp AmbientApp IC_app MediaApp PDCApp HomeScreenApp RemoteSpeakerApp; do
    echo "Building $app..."
    cd $app
    mkdir -p build && cd build
    cmake .. && make -j$(nproc)
    cd ../..
done
```

**Build Time:** Approximately 10-30 minutes depending on the machine.

### Step 4: Configure Network

The `start_all_ecu2.sh` script will configure the network automatically, but you can set it up manually:

```bash
sudo ip link set enP8p1s0 up
sudo ip addr add 192.168.1.101/24 dev enP8p1s0
sudo ip route add 224.0.0.0/4 dev enP8p1s0
```

Verify connectivity to ECU1:
```bash
ping -c 3 192.168.1.100
```

---

## 🚀 Running the System

### Start Order

**IMPORTANT:** Always start ECU1 (Raspberry Pi) BEFORE ECU2 (Jetson).

### ECU1: Raspberry Pi

The VehicleControlECU service starts automatically on boot.

**Manual start (if needed):**
```bash
sudo systemctl start vehiclecontrol-ecu
```

**Check status:**
```bash
sudo systemctl status vehiclecontrol-ecu
journalctl -u vehiclecontrol-ecu -f
```

### ECU2: Jetson Orin Nano

#### Automated Startup (Recommended)

Use the provided startup script:

```bash
cd ~/Chang/DES_Head-Unit/app/config
./start_all_ecu2.sh
```

The script will:
1. ✅ Clean up previous processes
2. ✅ Configure network (192.168.1.101)
3. ✅ Verify connection to ECU1
4. ✅ Start vsomeip routing manager
5. ✅ Start HU_MainApp Wayland Compositor
6. ✅ Wait for Wayland display socket
7. ✅ Start all GUI applications in order

**Expected output:**
```
==========================================
ECU2 전체 시스템 시작
==========================================
Project Root: /home/jetson/Chang/DES_Head-Unit/app

[1/10] Cleaning up all processes...
✓ Cleanup complete

[2/10] Checking network configuration...
✓ IP Address: 192.168.1.101
✓ Multicast route: OK
⏳ Checking connection to ECU1 (192.168.1.100)... ✓ Connected

[3/10] Starting Routing Manager...
✓ Routing Manager started (PID: 1234)
✓ Routing Manager ready (/tmp/vsomeip-0)

[4/10] Starting HU_MainApp Compositor...
✓ Compositor started (PID: 1235)
  Waiting for wayland-1 socket...
  ✓ Wayland socket ready

[5/10] Starting GearApp...
✓ GearApp started (PID: 1236)

[6/10] Starting AmbientApp...
✓ AmbientApp started (PID: 1237)

[7/10] Starting IC_app...
✓ IC_app started (PID: 1238)

[8/10] Starting MediaApp...
✓ MediaApp started (PID: 1239)

[9/10] Starting PDCApp...
✓ PDCApp started (PID: 1240)

[10/10] Starting HomeScreenApp...
✓ HomeScreenApp started (PID: 1241)

==========================================
✅ ECU2 시스템 시작 완료!
==========================================
```

#### Manual Startup (Advanced)

If you need to start apps individually for debugging:

```bash
# 1. Start routing manager
cd ~/Chang/DES_Head-Unit/app/config
export VSOMEIP_CONFIGURATION=routing_manager_ecu2.json
export VSOMEIP_APPLICATION_NAME=routingmanagerd
routingmanagerd > /tmp/routingmanagerd.log 2>&1 &

# 2. Start HU_MainApp Compositor
cd ~/Chang/DES_Head-Unit/app/HU_MainApp/build
export QT_QPA_PLATFORM=xcb
export QML2_IMPORT_PATH=/usr/lib/aarch64-linux-gnu/qt5/qml:/usr/lib/qt5/qml
./HU_MainApp_Compositor > /tmp/HU_MainApp_Compositor.log 2>&1 &

# Wait for Wayland socket
sleep 5

# 3. Start GearApp
cd ~/Chang/DES_Head-Unit/app/GearApp/build
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export WAYLAND_DISPLAY=wayland-1
export VSOMEIP_APPLICATION_NAME=GearApp
export VSOMEIP_CONFIGURATION=~/Chang/DES_Head-Unit/app/GearApp/config/vsomeip_ecu2.json
export COMMONAPI_CONFIG=~/Chang/DES_Head-Unit/app/GearApp/config/commonapi_ecu2.ini
./GearApp > /tmp/gearapp.log 2>&1 &

# Repeat for other apps...
```

### Running RemoteSpeakerApp (Optional)

The RemoteSpeakerApp runs separately and can be started on the Jetson or from a laptop via SSH.

**On Jetson:**
```bash
cd ~/Chang/DES_Head-Unit/app/RemoteSpeakerApp/build
export VSOMEIP_APPLICATION_NAME=RemoteSpeakerApp
export VSOMEIP_CONFIGURATION=~/Chang/DES_Head-Unit/app/RemoteSpeakerApp/config/vsomeip_speaker.json
export COMMONAPI_CONFIG=~/Chang/DES_Head-Unit/app/RemoteSpeakerApp/config/commonapi_speaker.ini
./RemoteSpeakerApp
```

**From Laptop (via SSH with X11 forwarding):**
```bash
ssh -X jetson@192.168.1.101
cd ~/Chang/DES_Head-Unit/app/RemoteSpeakerApp/build
export VSOMEIP_APPLICATION_NAME=RemoteSpeakerApp
export VSOMEIP_CONFIGURATION=~/Chang/DES_Head-Unit/app/RemoteSpeakerApp/config/vsomeip_speaker.json
export COMMONAPI_CONFIG=~/Chang/DES_Head-Unit/app/RemoteSpeakerApp/config/commonapi_speaker.ini
./RemoteSpeakerApp
```

---

## 🔍 Verification and Testing

### Verify vsomeip Communication

**On ECU1 (Raspberry Pi):**
```bash
journalctl -u vehiclecontrol-ecu -n 50
```

Look for:
```
OFFER [1234.5678:0.0] (192.168.1.100)  # Service is being offered
```

**On ECU2 (Jetson):**
```bash
tail -f /tmp/gearapp.log
```

Look for:
```
SUBSCRIBE ACK [1234.5678.8001]  # Subscribed to events
Service [1234.5678] is available  # Service discovered
```

### Test PDC Feature

1. **Change gear to Reverse:**
   - Use GearApp UI on the Head Unit display
   - Select "R" (Reverse) gear

2. **Move object near ultrasonic sensor:**
   - Place an object within 2-400cm of the HC-SR04 sensor
   - The distance should update on PDCApp display

3. **Monitor distance data:**
```bash
# On ECU1 (RPi)
journalctl -u vehiclecontrol-ecu -f | grep -i distance

# On ECU2 (Jetson)
tail -f /tmp/pdcapp.log
```

### Test GUI Applications

All GUI apps should appear on the HU_MainApp compositor display:

- **HomeScreen**: Default home page with navigation buttons
- **GearApp**: Gear selection (P/R/N/D)
- **MediaApp**: Media playback controls
- **PDCApp**: Park distance visualization (overlay in Reverse)
- **IC_app**: Instrument cluster display
- **AmbientApp**: Ambient lighting control

---

## 🛑 Stopping the System

### ECU2 (Jetson)

**Stop all apps:**
```bash
killall -9 GearApp AmbientApp IC_app MediaApp PDCApp HomeScreenApp routingmanagerd HU_MainApp_Compositor
sudo rm -rf /tmp/vsomeip-*
```

**Or use the cleanup from the script:**
```bash
cd ~/Chang/DES_Head-Unit/app/config
# The script has a cleanup section at the beginning
```

### ECU1 (Raspberry Pi)

**Stop VehicleControlECU service:**
```bash
sudo systemctl stop vehiclecontrol-ecu
```

**Power off:**
```bash
sudo poweroff
```

---

## 🐛 Troubleshooting

### ECU1 Issues

#### Problem: VehicleControlECU service fails to start

**Check logs:**
```bash
sudo journalctl -u vehiclecontrol-ecu -n 100
```

**Common causes:**
- CAN interfaces not available → Check HAT connection
- vsomeip routing manager failed → Check network configuration
- Permissions issues → Service runs as root

#### Problem: CAN interfaces not appearing

**Check device tree overlays:**
```bash
cat /boot/config.txt | grep mcp251xfd
```

Should show:
```
dtoverlay=mcp251xfd,spi0-0,interrupt=25
dtoverlay=mcp251xfd,spi1-0,interrupt=24
```

**Manually bring up CAN interfaces:**
```bash
sudo ip link set can0 up type can bitrate 1000000
sudo ip link set can1 up type can bitrate 1000000
ip link show can0
```

#### Problem: Distance data not updating

**Check Arduino CAN output:**
- Verify Arduino is sending CAN messages
- Check CAN ID is 0x123 for distance data
- Verify data format (bytes 3-6 contain float distance)

**Monitor CAN traffic:**
```bash
candump can0
```

### ECU2 Issues

#### Problem: Apps not appearing on display

**Check Wayland compositor:**
```bash
ps aux | grep HU_MainApp_Compositor
ls -la $XDG_RUNTIME_DIR/wayland-1
```

**Check app logs:**
```bash
tail -f /tmp/HU_MainApp_Compositor.log
tail -f /tmp/gearapp.log
```

**Common causes:**
- Compositor not started → Build and start HU_MainApp first
- Wrong QT_QPA_PLATFORM → Should be "wayland" for apps, "xcb" for compositor
- Wayland socket not accessible → Check $XDG_RUNTIME_DIR

#### Problem: vsomeip connection failed

**Check routing manager:**
```bash
ps aux | grep routingmanagerd
ls -la /tmp/vsomeip-0
```

**Check network connectivity:**
```bash
ping 192.168.1.100
ip route | grep 224.0.0.0
```

**Check vsomeip logs:**
```bash
tail -f /tmp/routing_manager.log
tail -f /tmp/gearapp.log | grep -i vsomeip
```

**Common causes:**
- Routing manager not running → Start it first
- Network not configured → Run start_all_ecu2.sh
- Firewall blocking multicast → Disable firewall or add rules
- ECU1 not reachable → Check Ethernet cable and ECU1 status

#### Problem: Specific app crashes

**Check individual app logs:**
```bash
tail -f /tmp/gearapp.log
tail -f /tmp/pdcapp.log
tail -f /tmp/homescreenapp.log
```

**Common causes:**
- Missing config files → Check vsomeip and commonapi config paths
- Library version mismatch → Rebuild dependencies
- CommonAPI interface mismatch → Regenerate CommonAPI code

### Network Issues

#### Problem: ECU1 and ECU2 cannot ping each other

**Check physical connection:**
- Verify Ethernet cable is properly connected
- Check link status: `ip link show enP8p1s0` (Jetson) or `ip link show eth0` (RPi)

**Check IP configuration:**
```bash
# On ECU1
ip addr show eth0

# On ECU2
ip addr show enP8p1s0
```

**Verify routing:**
```bash
ip route
# Should include: 224.0.0.0/4 dev <interface>
```

**Test multicast:**
```bash
# On ECU1
ping -I eth0 224.244.224.245

# On ECU2
ping -I enP8p1s0 224.244.224.245
```

---

## 📝 Log Files Reference

### ECU1 (Raspberry Pi)

| Component | Log Location | Command |
|-----------|--------------|---------|
| VehicleControlECU Service | systemd journal | `journalctl -u vehiclecontrol-ecu -f` |
| Boot logs | systemd journal | `journalctl -b` |
| Kernel messages | dmesg | `dmesg \| tail -100` |

### ECU2 (Jetson)

| Component | Log Location | Command |
|-----------|--------------|---------|
| Routing Manager | /tmp/routing_manager.log | `tail -f /tmp/routing_manager.log` |
| HU_MainApp Compositor | /tmp/HU_MainApp_Compositor.log | `tail -f /tmp/HU_MainApp_Compositor.log` |
| GearApp | /tmp/gearapp.log | `tail -f /tmp/gearapp.log` |
| AmbientApp | /tmp/ambientapp.log | `tail -f /tmp/ambientapp.log` |
| IC_app | /tmp/ic_app.log | `tail -f /tmp/ic_app.log` |
| MediaApp | /tmp/mediaapp.log | `tail -f /tmp/mediaapp.log` |
| PDCApp | /tmp/pdcapp.log | `tail -f /tmp/pdcapp.log` |
| HomeScreenApp | /tmp/homescreenapp.log | `tail -f /tmp/homescreenapp.log` |
| RemoteSpeakerApp | /tmp/remotespeakerapp.log | `tail -f /tmp/remotespeakerapp.log` |

---

## 🔧 Development Tips

### Rebuilding After Code Changes

**ECU1 (Raspberry Pi):**
```bash
cd /home/seame/PDC/headunit/yocto-build
source sources/poky/oe-init-build-env build
bitbake -c clean vehiclecontrol-ecu
bitbake vehiclecontrol-image
# Flash new image to SD card
```

**ECU2 (Jetson) - Rebuild specific app:**
```bash
cd ~/Chang/DES_Head-Unit/app/GearApp/build
make clean
cmake ..
make -j$(nproc)
```

### Quick Testing Without Full Rebuild

**ECU1:** Copy modified binary directly to running system:
```bash
scp build/VehicleControlECU root@192.168.1.100:/usr/bin/
ssh root@192.168.1.100 'systemctl restart vehiclecontrol-ecu'
```

**ECU2:** Rebuild and restart specific app:
```bash
cd ~/Chang/DES_Head-Unit/app/PDCApp/build
make -j$(nproc)
killall PDCApp
./PDCApp > /tmp/pdcapp.log 2>&1 &
```

### Debugging vsomeip Communication

**Enable verbose logging:**

Edit vsomeip config files and set log level to "trace":
```json
"logging": {
    "level": "trace",
    "console": "true"
}
```

**Monitor SOME/IP messages:**
```bash
# On ECU1
journalctl -u vehiclecontrol-ecu -f | grep -E "OFFER|REQUEST|SUBSCRIBE"

# On ECU2
tail -f /tmp/gearapp.log | grep -E "OFFER|REQUEST|SUBSCRIBE|available"
```

---

## 📚 Additional Resources

- [vsomeip Documentation](https://github.com/COVESA/vsomeip)
- [CommonAPI C++ Documentation](https://covesa.github.io/capicxx-core-tools/)
- [Yocto Project Documentation](https://docs.yoctoproject.org/)
- [Raspberry Pi Documentation](https://www.raspberrypi.com/documentation/)
- [NVIDIA Jetson Documentation](https://developer.nvidia.com/embedded/jetson-orin)

---

## 📄 License

[Your License Here]

---

## 👥 Contributors

[Your Team/Contributors Here]

---

**Last Updated:** January 10, 2026
