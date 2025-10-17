# DES_Head-Unit
Head Unit project repository for automotive infotainment system with **CommonAPI + SOME/IP communication**

[![CI/CD Pipeline](https://github.com/Changseok-Oh29/DES_Head-Unit/actions/workflows/ci-cd.yml/badge.svg)](https://github.com/Changseok-Oh29/DES_Head-Unit/actions)
[![CommonAPI](https://img.shields.io/badge/CommonAPI-3.2.4-blue)](https://github.com/GENIVI/capicxx-core-runtime)
[![vsomeip](https://img.shields.io/badge/vsomeip-3.5.8-green)](https://github.com/COVESA/vsomeip)
[![Qt5](https://img.shields.io/badge/Qt5-5.15.2-brightgreen)](https://www.qt.io/)
[![SOME/IP](https://img.shields.io/badge/AUTOSAR-SOME%2FIP-orange)](https://www.autosar.org/)
[![Phase](https://img.shields.io/badge/Development-Phase%201%20Complete-success)](commonapi/PHASE1_COMPLETE_GUIDE.md)

## 🚗 Project Overview

This project implements a professional-grade Head Unit (HU) application for automotive systems, featuring **automotive-standard communication protocols**. Built with industry-standard middleware used in real vehicles by BMW, Audi, and other OEMs.

### Key Features:
- **Gear Selection**: P, R, N, D gear control interface
- **Media Player**: USB media scanning and playback
- **Ambient Lighting**: Customizable cabin lighting control
- **SOME/IP Communication**: AUTOSAR-compliant ECU-to-ECU communication
- **CommonAPI Integration**: Service-oriented architecture with automatic code generation
- **2-ECU System**: Vehicle Control ECU + Infotainment ECU simulation

### 🌟 What Makes This Special:
- Uses the **same communication stack as real automotive systems**
- **AUTOSAR SOME/IP** protocol for network communication  
- **Service Discovery** for automatic ECU detection
- **Type-safe interfaces** generated from FIDL specifications
- **Production-ready middleware** (vsomeip + CommonAPI)

## 🏗️ System Architecture

### High-Level Overview
```
    ┌─────────────────────┐                 ┌─────────────────────┐
    │     ECU 1           │   SOME/IP       │     ECU 2           │
    │  Vehicle Control    │◄─────────────── ▷│  Infotainment       │
    │                     │   Network       │                     │  
    │ • Battery Info      │                 │ • Head Unit App     │
    │ • Speed Control     │                 │ • Media Player      │
    │ • Gear Selection    │                 │ • Ambient Light     │
    └─────────────────────┘                 │ • Instrument Cluster│
                                            └─────────────────────┘
```

### Communication Stack
```
┌─────────────────────────────────────────────────────────────┐
│                    Application Layer                        │
│           (Qt5 QML UI + C++ Business Logic)                 │
├─────────────────────────────────────────────────────────────┤
│                    CommonAPI Layer                          │
│        (Auto-generated Proxy/Stub from FIDL)               │
├─────────────────────────────────────────────────────────────┤
│                   SOME/IP Protocol                          │
│           (vsomeip - Service Discovery + RPC)               │
├─────────────────────────────────────────────────────────────┤
│                 Network Transport                           │
│                (TCP/UDP + Multicast)                        │
└─────────────────────────────────────────────────────────────┘
```

## 🚀 Quick Start

### Option 1: Use Pre-built Environment (Recommended)
If you've completed Phase 1 setup:
```bash
# Clone the repository
git clone https://github.com/Changseok-Oh29/DES_Head-Unit.git
cd DES_Head-Unit

# Test CommonAPI environment
cd commonapi/simple/build
./integration_test

# Build Head Unit application
cd ../../../app/HU_app
mkdir build && cd build
cmake .. -DCMAKE_PREFIX_PATH="/usr/local"
make
./HU_app
```

### Option 2: Complete Setup from Scratch  
Follow the complete setup guide:
```bash
# See detailed instructions
cat commonapi/PHASE1_COMPLETE_GUIDE.md
```

### Option 3: Docker Environment (Coming Soon)
```bash
# TODO: Docker setup for easy deployment
docker-compose up --build
```
│ • Media Player  │    │ • Status Info   │
│ • Ambient Light │    │ • Gear Status   │
└─────────────────┘    └─────────────────┘
         │                       │
         └───────────────────────┘
              vSOME/IP IPC
```

## 🛠️ Technology Stack

- **Framework**: Qt5 with QML
- **Build System**: CMake
- **Target Platform**: Raspberry Pi 4 (ARM64)
- **OS**: Yocto-based Linux
- **CI/CD**: GitHub Actions
- **IPC**: vSOME/IP (planned)

## 📁 Project Structure

```
├── app/                    # Application source code
│   └── HU_app/            # Qt5 Head Unit application
│       ├── main.cpp       # Application entry point
│       ├── mediamanager.cpp/.h    # USB media scanning & playback
│       ├── ipcmanager.cpp/.h      # IPC communication with IC
│       ├── main.qml       # Main UI interface
│       ├── MainMenu.qml   # Main navigation menu
│       ├── GearSelection.qml      # Gear control interface
│       ├── MediaApp.qml   # Media player interface
│       ├── AmbientLighting.qml    # Ambient lighting control
│       └── CMakeLists.txt # Build configuration
├── meta/                  # Yocto build system
│   └── meta-headunit/     # Custom Yocto layer
│       ├── conf/layer.conf        # Layer configuration
│       ├── recipes-headunit/      # Application recipes
│       └── recipes-images/        # Image recipes
├── .github/workflows/     # CI/CD pipeline
├── test_headunit.sh       # Local testing script
│   └── meta-headunit/     # Custom Yocto layer
│       ├── conf/          # Layer configuration
│       ├── recipes-headunit/    # Application recipes
│       └── recipes-images/      # Custom image recipes
└── .github/workflows/     # CI/CD automation
    └── ci-cd.yml         # GitHub Actions workflow
```

## 🚀 Quick Start

### Local Development (x86_64)

1. **Prerequisites**:
   ```bash
   # Ubuntu/Debian
   sudo apt-get install qt5-qmake qtbase5-dev qtdeclarative5-dev qtquickcontrols2-5-dev cmake build-essential

   # Fedora/RHEL
   sudo dnf install qt5-qtbase-devel qt5-qtdeclarative-devel qt5-qtquickcontrols2-devel cmake gcc-c++
   ```

2. **Build and Run**:
   ```bash
   cd app/HU_app
   cmake -B build -DCMAKE_BUILD_TYPE=Debug
   cmake --build build
   ./build/HU_app
   ```

### Raspberry Pi Deployment (Yocto)

1. **Setup Yocto Environment**:
   ```bash
   git clone git://git.yoctoproject.org/poky
   cd poky
   git checkout kirkstone
   git clone git://git.yoctoproject.org/meta-raspberrypi
   cd meta-raspberrypi && git checkout kirkstone && cd ..
   git clone git://git.yoctoproject.org/meta-openembedded
   cd meta-openembedded && git checkout kirkstone && cd ..
   ```

2. **Configure Build**:
   ```bash
   source oe-init-build-env
   cp -r /path/to/this/repo/meta/meta-headunit .
   bitbake-layers add-layer ../meta-raspberrypi
   bitbake-layers add-layer ../meta-openembedded/meta-oe
   bitbake-layers add-layer ../meta-openembedded/meta-python
   bitbake-layers add-layer ../meta-openembedded/meta-multimedia
   bitbake-layers add-layer ./meta-headunit
   
   # Configure for RPi4
   echo 'MACHINE = "raspberrypi4-64"' >> conf/local.conf
   ```

3. **Build Image**:
   ```bash
   bitbake headunit-image
   ```

4. **Flash to SD Card**:
   ```bash
   sudo dd if=tmp/deploy/images/raspberrypi4-64/headunit-image-raspberrypi4-64.wic of=/dev/sdX bs=4M status=progress
   ```

## ✨ Features

### 🎵 Media Player
- **USB Auto-Detection**: Automatically scans USB devices for media files
- **Supported Formats**: MP3, WAV, FLAC, M4A, AAC, OGG, WMA
- **Playback Controls**: Play, Pause, Next, Previous, Volume control
- **Real-time Scanning**: Updates media list when USB devices are connected/disconnected

### ⚙️ Gear Selection
- **PRND Control**: Park, Reverse, Neutral, Drive gear selection
- **Visual Feedback**: Real-time gear status display
- **IPC Communication**: Sends gear changes to Instrument Cluster via UDP

### 💡 Ambient Lighting
- **Color Control**: RGB color picker with real-time preview
- **Multiple Modes**: Manual, Auto, Music Sync modes
- **IPC Integration**: Syncs lighting state with Instrument Cluster
- **Brightness Control**: Adjustable lighting intensity

### 🔗 IPC Communication
- **UDP Protocol**: Real-time communication with Instrument Cluster
- **Heartbeat Monitoring**: Connection status monitoring
- **Data Synchronization**: Gear, ambient lighting, and status sync
- **Error Handling**: Robust connection management

## 🔧 Testing

### Local Testing Script
```bash
# Build the application
./test_headunit.sh build

# Run with test media files
./test_headunit.sh run

# Clean build artifacts
./test_headunit.sh clean

# Check code quality
./test_headunit.sh check
```

### Manual Testing
1. **Media Player Testing**:
   - Create test directory: `/tmp/test_media/`
   - Copy MP3 files to test USB detection
   - Test playback controls

2. **IPC Testing**:
   - Run mock Instrument Cluster on port 12345
   - Monitor UDP traffic: `sudo tcpdump -i lo port 12345`

3. **Gear Selection Testing**:
   - Click gear buttons (P, R, N, D)
   - Verify IPC messages sent to IC

## 🏗️ Development Workflow

### 1. Local Development
```bash
# Qt5 development environment
export QT_SELECT=qt5

# Configure build
cd app/HU_app
cmake -B build -DCMAKE_BUILD_TYPE=Debug -DCMAKE_PREFIX_PATH=/usr/lib/qt5

# Build with verbose output
cmake --build build --verbose

# Run with debugging
QT_LOGGING_RULES="*.debug=true" ./build/HU_app
```

### 2. Yocto Integration
```bash
# Add layer to build
bitbake-layers add-layer /path/to/meta-headunit

# Build image
bitbake headunit-image

# Deploy to SD card
dd if=tmp/deploy/images/raspberrypi4-64/headunit-image-raspberrypi4-64.wic of=/dev/sdX bs=4M status=progress
```

### 3. CI/CD Pipeline
The project includes GitHub Actions workflows for:
- **Build Verification**: Compiles application on every push
- **Yocto Cross-compilation**: Builds RPi image for main branch
- **Security Scanning**: CodeQL analysis for vulnerabilities
- **Artifact Management**: Stores build outputs and images
