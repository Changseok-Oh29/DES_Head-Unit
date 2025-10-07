# DES_Head-Unit
Head Unit project repository for automotive infotainment system

## 🚗 Project Overview

This project implements a Head Unit (HU) application for automotive systems, designed to work with Raspberry Pi hardware. The Head Unit provides an intuitive interface for:

- **Gear Selection**: P, R, N, D gear control interface
- **Media Player**: USB media scanning and playback
- **Ambient Lighting**: Customizable cabin lighting control
- **System Integration**: IPC communication with Instrument Cluster (IC)

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐
│   Head Unit     │◄──►│ Instrument      │
│   (This Repo)   │    │ Cluster (IC)    │
│                 │    │                 │
│ • Gear Control  │    │ • Speed Display │
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
│       ├── main.qml       # Main UI interface
│       ├── MainMenu.qml   # Main navigation menu
│       ├── GearSelection.qml    # Gear control interface
│       ├── MediaApp.qml   # Media player interface
│       ├── AmbientLighting.qml  # Ambient lighting control
│       └── CMakeLists.txt # Build configuration
├── meta/                  # Yocto build system
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

### 🎛️ Gear Selection
- Visual P/R/N/D gear selection interface
- Real-time gear status display
- Integration with vehicle systems (planned)

### 🎵 Media Player
- USB device auto-detection
- MP3 file scanning and playlist generation
- Playback controls (play/pause/next/previous)
- Volume control

### 💡 Ambient Lighting
- RGB color selection
- Brightness control
- Multiple modes: Manual, Auto, Music Sync
- Quick color presets

### 🔄 System Integration
- IPC communication with Instrument Cluster
- Real-time data synchronization
- Status monitoring and reporting

## 🔧 Development

### Code Style
- Follow Qt/QML best practices
- Use meaningful component names
- Maintain consistent indentation (4 spaces)
- Comment complex logic

### Testing
```bash
# Run local tests
cd app/HU_app/build
# Unit tests would go here
```

### CI/CD Pipeline
The project includes automated CI/CD with GitHub Actions:
- **Build**: Compiles the application for x86_64
- **Test**: Runs basic validation tests
- **Yocto Build**: Creates Raspberry Pi image (on main branch)
- **Artifacts**: Stores build outputs for download

## 📋 Roadmap

- [ ] **Phase 1**: Core UI Implementation ✅
- [ ] **Phase 2**: USB Media Integration
- [ ] **Phase 3**: vSOME/IP Communication
- [ ] **Phase 4**: Hardware Abstraction Layer
- [ ] **Phase 5**: Advanced Features (CAN bus, OTA updates)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For support and questions:
- Create an issue on GitHub
- Check the documentation in `/docs`
- Review existing discussions

## 🙏 Acknowledgments

- Qt Framework for the excellent UI toolkit
- Yocto Project for embedded Linux build system
- Raspberry Pi Foundation for the hardware platform
- Open source automotive community
