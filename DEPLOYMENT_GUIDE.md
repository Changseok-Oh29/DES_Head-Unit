# Deployment Guide - Raspberry Pi & Jetson Orin Nano

## Overview

This guide explains how to deploy your applications to the target devices via SSH:

- **Raspberry Pi** (ECU1 - 192.168.1.100): VehicleControlECU
- **Jetson Orin Nano** (ECU2 - 192.168.1.101): HU_MainApp, AmbientApp, GearApp, HomeScreenApp, MediaApp, PDCApp, RemoteSpeakerApp

---

## Prerequisites

### 1. Network Configuration

Both devices must be on the same network with static IP addresses:

```bash
# Raspberry Pi (ECU1)
IP: 192.168.1.100/24

# Jetson Orin Nano (ECU2)
IP: 192.168.1.101/24
```

### 2. SSH Access Setup

**Test SSH connections from your development PC:**

```bash
# Test connection to Raspberry Pi
ssh team06@greywolf1
# or: ssh team06@192.168.1.100

# Test connection to Jetson Orin Nano
ssh <your_jetson_user>@192.168.1.101
```

**Set up SSH key authentication (recommended):**

```bash
# Generate SSH key if you don't have one
ssh-keygen -t rsa -b 4096

# Copy key to Raspberry Pi
ssh-copy-id team06@greywolf1

# Copy key to Jetson Orin Nano
ssh-copy-id <your_jetson_user>@192.168.1.101
```

### 3. Required Dependencies

#### On Raspberry Pi:
- Qt5 (qtbase5-dev, qtdeclarative5-dev)
- pigpio library (for hardware control)
- vsomeip3 (3.5.8)
- CommonAPI Core (3.2.4)
- CommonAPI-SomeIP (3.2.4)
- I2C tools and libraries

#### On Jetson Orin Nano:
- Qt5 with Wayland support
- vsomeip3 (3.5.8)
- CommonAPI Core (3.2.4)
- CommonAPI-SomeIP (3.2.4)
- Boost libraries

---

## Deployment Strategy

### Option A: Quick Deployment (Recommended for Testing)

This approach deploys pre-built binaries from your local build directory.

#### Step 1: Deploy to Raspberry Pi (VehicleControlECU)

**Using the existing deployment script:**

```bash
cd /home/seame/PDC/headunit/DES_Head-Unit/app/VehicleControlECU

# Edit deploy_to_rpi.sh to set correct IP/hostname if needed
# Default is: RPI_IP="greywolf1" and RPI_USER="team06"

./deploy_to_rpi.sh
```

This script will:
1. Test SSH connection
2. Create necessary directories
3. Transfer VehicleControlECU source code
4. Transfer CommonAPI generated code
5. Transfer vsomeip and CommonAPI libraries

**Then on the Raspberry Pi (via SSH):**

```bash
ssh team06@greywolf1

cd ~/VehicleControlECU

# Install dependencies
sudo ./install_dependencies.sh

# Build vsomeip and CommonAPI if not already installed
sudo ./build_vsomeip_rpi.sh

# Build VehicleControlECU
mkdir -p build && cd build
cmake .. -DCOMMONAPI_GEN_DIR=~/commonapi/generated
make -j4

# Run the application
cd ..
./run.sh
```

#### Step 2: Deploy to Jetson Orin Nano (HU Apps)

**Create a deployment script for Jetson:**

```bash
cd /home/seame/PDC/headunit/DES_Head-Unit/app
```

Create `deploy_to_jetson.sh`:

```bash
#!/bin/bash
set -e

# Jetson Orin Nano configuration
JETSON_IP="192.168.1.101"
JETSON_USER="<your_username>"  # Change this

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║   HU Apps Deployment to Jetson Orin Nano                      ║"
echo "║   Development PC → Jetson Orin Nano                           ║"
echo "╚═══════════════════════════════════════════════════════════════╝"

# Test connection
echo "🔌 Testing Jetson connection..."
if ! ssh -o ConnectTimeout=5 $JETSON_USER@$JETSON_IP "echo '✅ Connection successful'" 2>/dev/null; then
    echo "❌ Cannot connect to Jetson!"
    echo "   Please check IP address and SSH access"
    exit 1
fi

# Create directories on Jetson
echo "📁 Creating directories on Jetson..."
ssh $JETSON_USER@$JETSON_IP "mkdir -p HU_Apps/{HU_MainApp,AmbientApp,GearApp,HomeScreenApp,MediaApp,PDCApp,RemoteSpeakerApp} commonapi/generated install_folder"

# Transfer CommonAPI generated code
echo "📦 Transferring CommonAPI generated code..."
rsync -avz --progress ../../commonapi/generated/ \
    $JETSON_USER@$JETSON_IP:commonapi/generated/

# Transfer vsomeip/CommonAPI libraries
echo "📦 Transferring libraries..."
rsync -avz --progress ../../install_folder/ \
    $JETSON_USER@$JETSON_IP:install_folder/

# Transfer each application
APPS="HU_MainApp AmbientApp GearApp HomeScreenApp MediaApp PDCApp RemoteSpeakerApp"

for APP in $APPS; do
    echo ""
    echo "📦 Transferring $APP..."
    rsync -avz --progress --exclude='build*' \
        $APP/ \
        $JETSON_USER@$JETSON_IP:HU_Apps/$APP/
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Deployment complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🎯 Next steps on Jetson Orin Nano:"
echo ""
echo "1. SSH to Jetson:"
echo "   ssh $JETSON_USER@$JETSON_IP"
echo ""
echo "2. Install dependencies (see JETSON_SETUP.md)"
echo ""
echo "3. Build and run applications"
echo ""
```

Make it executable:

```bash
chmod +x deploy_to_jetson.sh
```

Run the deployment:

```bash
./deploy_to_jetson.sh
```

**Then on the Jetson Orin Nano (via SSH):**

```bash
ssh <your_username>@192.168.1.101

# Build each application
cd ~/HU_Apps

# Build order (compositor first, then apps)
for APP in HU_MainApp AmbientApp GearApp HomeScreenApp MediaApp PDCApp RemoteSpeakerApp; do
    echo "Building $APP..."
    cd $APP
    mkdir -p build && cd build
    cmake .. -DCOMMONAPI_GEN_DIR=~/commonapi/generated
    make -j$(nproc)
    cd ../..
done
```

---

### Option B: Cross-Compilation (Advanced)

For faster deployment, you can set up cross-compilation on your development PC. However, this requires:

1. ARM64 cross-compilation toolchain
2. Cross-compiled versions of all dependencies (Qt, vsomeip, CommonAPI, etc.)
3. Proper sysroot configuration

This is more complex but results in faster builds. The Yocto build system in your workspace is designed for this approach.

---

## Running the Applications

### On Raspberry Pi (VehicleControlECU)

```bash
ssh team06@greywolf1
cd ~/VehicleControlECU

# Set up network (if not configured permanently)
sudo ip addr add 192.168.1.100/24 dev eth0
sudo ip route add 224.0.0.0/4 dev eth0

# Run VehicleControlECU
./run.sh
```

### On Jetson Orin Nano (HU Apps)

**Start the Wayland Compositor first:**

```bash
ssh <your_username>@192.168.1.101

# Set up network (if not configured permanently)
sudo ip addr add 192.168.1.101/24 dev eth0
sudo ip route add 224.0.0.0/4 dev eth0

# Set environment variables
export XDG_RUNTIME_DIR=/tmp
export VSOMEIP_CONFIGURATION=~/HU_Apps/HU_MainApp/vsomeip_compositor.json

# Start compositor
cd ~/HU_Apps/HU_MainApp/build
./HU_MainApp_Compositor &

# Wait a few seconds for compositor to start
sleep 3

# Start applications in separate terminals or screen sessions
cd ~/HU_Apps/HomeScreenApp/build
WAYLAND_DISPLAY=wayland-0 ./HomeScreenApp &

cd ~/HU_Apps/GearApp/build
WAYLAND_DISPLAY=wayland-0 ./GearApp &

cd ~/HU_Apps/MediaApp/build
WAYLAND_DISPLAY=wayland-0 ./MediaApp &

cd ~/HU_Apps/PDCApp/build
WAYLAND_DISPLAY=wayland-0 ./PDCApp &

cd ~/HU_Apps/AmbientApp/build
WAYLAND_DISPLAY=wayland-0 ./AmbientApp &

cd ~/HU_Apps/RemoteSpeakerApp/build
WAYLAND_DISPLAY=wayland-0 ./RemoteSpeakerApp &
```

**Tip:** Use `screen` or `tmux` for better session management:

```bash
# Install screen
sudo apt install screen

# Create a startup script
cat > ~/start_all_apps.sh << 'EOF'
#!/bin/bash

# Start compositor
screen -dmS compositor bash -c 'cd ~/HU_Apps/HU_MainApp/build && ./HU_MainApp_Compositor'
sleep 3

# Start apps
APPS="HomeScreenApp GearApp MediaApp PDCApp AmbientApp RemoteSpeakerApp"
for APP in $APPS; do
    screen -dmS $APP bash -c "cd ~/HU_Apps/$APP/build && WAYLAND_DISPLAY=wayland-0 ./$APP"
    sleep 1
done

echo "✅ All applications started"
screen -ls
EOF

chmod +x ~/start_all_apps.sh
./start_all_apps.sh

# View running sessions
screen -ls

# Attach to a session
screen -r compositor
screen -r GearApp
```

---

## Verification

### Check vsomeip Communication

**On Raspberry Pi:**

```bash
# Check if service is offering
tail -f /tmp/vsomeip.log
# Look for: "OFFER(1234): [1234.5678:0.0]"
```

**On Jetson:**

```bash
# Check if service is available
tail -f /tmp/vsomeip.log
# Look for: "AVAILABLE(1234): [1234.5678:0.0]"
```

### Test Network Connectivity

```bash
# From Raspberry Pi to Jetson
ping 192.168.1.101

# From Jetson to Raspberry Pi
ping 192.168.1.100

# Check multicast route
ip route | grep 224
# Should show: 224.0.0.0/4 dev eth0 scope link
```

---

## Troubleshooting

### SSH Connection Issues

```bash
# Check if SSH service is running on target
ssh <user>@<ip> systemctl status sshd

# Check firewall
ssh <user>@<ip> sudo ufw status

# Verbose SSH connection for debugging
ssh -vvv <user>@<ip>
```

### Build Errors on Target Device

```bash
# Check dependencies
ldconfig -p | grep vsomeip
ldconfig -p | grep CommonAPI
ldconfig -p | grep Qt5

# Check library paths
echo $LD_LIBRARY_PATH

# Add library path if needed
export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
```

### vsomeip Communication Issues

1. **Check network configuration:**
   - Both devices on same subnet (192.168.1.x/24)
   - Multicast routing enabled
   
2. **Check vsomeip configuration:**
   - Correct unicast IPs in JSON files
   - Matching service IDs between client and server
   - Service Discovery enabled

3. **Check logs:**
   ```bash
   # Enable debug logging
   export VSOMEIP_CONFIGURATION=<path_to_config_with_debug_level>
   ```

---

## Architecture Summary

```
┌─────────────────────────────────────────────────────────────────┐
│                     Development PC (x86_64)                      │
│  • Build applications locally                                    │
│  • Deploy via rsync over SSH                                     │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ SSH/rsync
                              │
                ┌─────────────┴─────────────┐
                │                           │
                ▼                           ▼
┌──────────────────────────┐    ┌──────────────────────────┐
│   Raspberry Pi (ARM64)   │    │ Jetson Orin Nano (ARM64) │
│   ECU1: 192.168.1.100    │◄──►│   ECU2: 192.168.1.101    │
│                          │    │                          │
│  • VehicleControlECU     │    │  • HU_MainApp (Comp)     │
│  • Routing Manager       │    │  • AmbientApp            │
│  • Service Provider      │    │  • GearApp               │
│  • Hardware control      │    │  • HomeScreenApp         │
│                          │    │  • MediaApp              │
│                          │    │  • PDCApp                │
│                          │    │  • RemoteSpeakerApp      │
└──────────────────────────┘    └──────────────────────────┘
         vsomeip/SOME-IP network communication
```

---

## Summary

**Yes, deployment via SSH is feasible!** You have:

1. ✅ Existing deployment script for Raspberry Pi (`deploy_to_rpi.sh`)
2. ✅ CMake build system configured for target devices
3. ✅ Network architecture already defined (192.168.1.100 & .101)
4. ✅ Dependencies documented for both platforms
5. ✅ vsomeip configuration files for both ECUs

**Key Requirements:**

- Ensure both devices have dependencies installed (Qt5, vsomeip, CommonAPI)
- Set up static IP addresses on both devices
- Configure SSH access from development PC
- Transfer source code and build on target (or cross-compile)
- Set up environment variables for vsomeip configuration

**Recommended Workflow:**

1. Use deployment scripts to transfer code via SSH
2. Build on target devices (simpler than cross-compilation)
3. Run applications with proper vsomeip configuration
4. Test communication between ECU1 and ECU2

The infrastructure is already in place - you just need to configure the Jetson Orin Nano following the same pattern as the Raspberry Pi!
