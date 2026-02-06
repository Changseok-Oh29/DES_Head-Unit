# DES_Head-Unit

A distributed automotive infotainment system built on SOME/IP middleware with multi-ECU architecture, featuring instrument cluster, head unit, and PDC(Parking Distance Control) features.

## Table of Contents

- [Introduction](#introduction)
- [Features](#features)
- [System Architecture](#system-architecture)
- [Applications](#applications)
- [Technology Stack](#technology-stack)
- [Hardware Requirements](#hardware-requirements)
- [Repository Structure](#repository-structure)
- [Build Instructions](#build-instructions)
- [Network Configuration](#network-configuration)
- [SOME/IP Service Definitions](#someip-service-definitions)
- [References](#references)

## Introduction

<!--
TODO: Add logo table here
<table>
  <tr>
    <td align="center"><img src="docs/images/yocto-logo.png" width="120"/><br/><b>Yocto</b></td>
    <td align="center"><img src="docs/images/qt-logo.png" width="120"/><br/><b>Qt5</b></td>
    <td align="center"><img src="docs/images/covesa-logo.png" width="120"/><br/><b>COVESA</b></td>
    <td align="center"><img src="docs/images/gstreamer-logo.png" width="120"/><br/><b>GStreamer</b></td>
  </tr>
</table>
-->

DES_Head-Unit is a service-oriented automotive infotainment system developed as part of the SEAME (Software Engineering for Automotive and Mobility Engineers) program. The system implements a dual-ECU architecture where a Raspberry Pi 4 and an NVIDIA Jetson Orin Nano communicate over Ethernet, providing a head unit display, instrument cluster, and reverse camera streaming.

The project demonstrates key automotive software concepts including:

- Service-Oriented Architecture (SOA) with SOME/IP middleware
- Multi-process Qt5/QML applications with Wayland composition
- Real-time camera streaming via GStreamer RTP/UDP pipeline
- CAN bus communication for vehicle control
- Custom Yocto Linux distributions for embedded targets

## Features

### Head Unit (HDMI-1: 1028x600)

- **Media Player** — USB auto-detection, playback controls, supports MP3/WAV/FLAC/M4A/AAC/OGG/WMA
- **Gear Selection** — PRND gear control with real-time visual feedback via SOME/IP
- **Ambient Lighting** — RGB color picker with manual, auto, and music sync modes
- **Home Screen** — Application launcher and navigation

### Instrument Cluster (HDMI-2: 1028x600)

- **Speed Display** — Real-time speed gauge from vehicle sensors
- **Battery Monitor** — Battery voltage and level from INA219 sensor
- **Gear Indicator** — Current gear status synchronized via SOME/IP

### Vehicle Control (ECU1)

- **Motor & Servo Control** — PiRacer actuator management via PCA9685 PWM
- **Sensor Monitoring** — Battery (INA219), ultrasonic distance sensor
- **Gamepad Input** — Shanwan controller for manual driving
- **CAN Communication** — MCP251xFD CAN interface for vehicle bus

### Reverse Camera (PDC)

- **Live Streaming** — OV5647 camera → H.264 encoding → RTP/UDP → Ethernet → ECU2 (Jetson Orin Nano)
- **Hardware Decoding** — NVIDIA nvv4l2decoder for low-latency video on ECU2
- **Auto-start** — Camera streaming service starts automatically on boot via systemd

## System Architecture

<!-- TODO: Replace this ASCII diagram with an architecture diagram image (PNG/SVG) -->
<!-- Example: ![System Architecture](docs/images/system-architecture.png) -->

```
┌─────────────────────────────────────────────────────────┐
│                    Ethernet (192.168.1.0/24)            │
│                                                         │
│  ┌─────────────────────┐      ┌──────────────────────┐  │
│  │  ECU1 - VehicleCtrl │      │  ECU2 - Head Unit    │  │
│  │  (RPi4)             │      │  (Jetson Orin Nano)  │  │
│  │  192.168.1.100      │      │  192.168.1.101       │  │
│  │                     │      │                      │  │
│  │  ┌───────────────┐  │      │  ┌────────────────┐  │  │
│  │  │ VehicleControl│  │ SOME │  │  HU_MainApp    │  │  │
│  │  │ ECU Service   │◄─┼──/IP─┼─►│  (Compositor)  │  │  │
│  │  │  (Provider)   │  │      │  │  GearApp       │  │  │
│  │  └───────────────┘  │      │  │  MediaApp      │  │  │
│  │                     │      │  │  AmbientApp    │  │  │
│  │  ┌───────────────┐  │      │  └────────────────┘  │  │
│  │  │ OV5647 Camera │  │      │                      │  │
│  │  │ → GStreamer   │──┼─UDP──┼─►┌────────────────┐  │  │
│  │  │ → RTP/H.264   │  │ 5000 │  │  PDCApp        │  │  │
│  │  └───────────────┘  │      │  │  (nvv4l2decoder│  │  │
│  │                     │      │  │   + nv3dsink)  │  │  │
│  │  ┌───────────────┐  │      │  └────────────────┘  │  │
│  │  │ PiRacer HW    │  │      │                      │  │
│  │  │ Motor/Servo   │  │      │  ┌────────────────┐  │  │
│  │  │ INA219/CAN    │  │      │  │  IC_app        │  │  │
│  │  │ Gamepad       │  │      │  │  SpeedApp      │  │  │
│  │  └───────────────┘  │      │  │  BatteryApp    │  │  │
│  │                     │      │  │  ICGearApp     │  │  │
│  └─────────────────────┘      │  └────────────────┘  │  │
│                               │                      │  │
│                               │  HDMI-1  │  HDMI-2   │  │
│                               │(1028x600) (1280x600) │  │
│                               └──────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

### Communication Flow

| Source | Destination | Protocol | Purpose |
|--------|-------------|----------|---------|
| ECU1 → ECU2 | SOME/IP (vsomeip) | vehicleStateChanged broadcast (gear, speed, battery) |
| ECU2 → ECU1 | SOME/IP (vsomeip) | setGearPosition RPC method |
| ECU1 → ECU2 | SOME/IP (vsomeip) | gearDistanceChanged broadcast (gear, distance) |
| ECU1 → ECU2 | RTP/UDP (port 5000) | H.264 camera stream |
| ECU1 internal | CAN (MCP251xFD) | Vehicle bus communication |

## Applications

| Application | Target | Display | Description |
|-------------|--------|---------|-------------|
| **HU_MainApp** | ECU2 | HDMI-1 | Wayland compositor, manages head unit windows |
| **GearApp** | ECU2 | HDMI-1 | PRND gear selection, sends setGearPosition via SOME/IP |
| **MediaApp** | ECU2 | HDMI-1 | USB media player with SOME/IP media control service |
| **AmbientApp** | ECU2 | HDMI-1 | RGB ambient lighting with manual/auto/music sync modes |
| **HomeScreenApp** | ECU2 | HDMI-1 | Application launcher and home screen |
| **PDCApp** | ECU2 | HDMI-1 | Park Distance Control camera display |
| **IC_MainApp** | ECU2 | HDMI-2 | Wayland compositor for instrument cluster |
| **SpeedApp** | ECU2 | HDMI-2 | Real-time speed gauge display |
| **BatteryApp** | ECU2 | HDMI-2 | Battery level monitoring display |
| **ICGearApp** | ECU2 | HDMI-2 | Instrument cluster gear indicator |
| **VehicleControlECU** | ECU1 | — | SOME/IP service provider, hardware control |
| **RemoteSpeakerApp** | ECU2 | — | Remote audio control |
| **VehicleControlMock** | Dev | — | Mock SOME/IP service for testing |

## Technology Stack

| Category | Technology |
|----------|-----------|
| **Language** | C++17, QML |
| **UI Framework** | Qt5 (QtQuick, QtMultimedia, QtWaylandCompositor) |
| **Display** | Wayland compositor |
| **Middleware** | vsomeip 3.5.8, CommonAPI 3.2.4 (Core + SomeIP binding) |
| **Video Streaming** | GStreamer (libcamerasrc, x264enc, rtph264pay, nvv4l2decoder) |
| **Build System** | CMake (native), Yocto/BitBake (cross-compilation) |
| **OS** | Yocto Linux (Kirkstone LTS) |
| **Init System** | systemd |
| **Audio** | PulseAudio |
| **CAN** | SocketCAN (MCP251xFD driver) |
| **Camera** | libcamera with Raspberry Pi IPA module |
| **CI/CD** | GitHub Actions |

## Hardware Requirements

### ECU1 — VehicleControl ECU

| Component | Specification |
|-----------|--------------|
| Board | Raspberry Pi 4 Model B (4GB) |
| Camera | OV5647 (RPi Camera Module v1.3) on CSI |
| Motor/Servo | PCA9685 PWM controller (I2C: 0x40, 0x60) |
| Battery Sensor | INA219 current/voltage (I2C: 0x41) |
| CAN | MCP251xFD via SPI (Waveshare 2-CH CAN FD HAT) |
| Gamepad | Shanwan USB controller |
| Network | Ethernet (static: 192.168.1.100/24) |

### ECU2 — Head Unit + Camera Receiver

| Component | Specification |
|-----------|--------------|
| Board | NVIDIA Jetson Orin Nano |
| Display 1 | 1024x600 HDMI touchscreen (Head Unit) |
| Display 2 | 800x480 HDMI display (Instrument Cluster) |
| Video Decoder | nvv4l2decoder (hardware H.264) |
| Video Sink | nv3dsink |
| Network | Ethernet (static: 192.168.1.101/24) |

## Repository Structure

```
DES_Head-Unit/
├── app/                              # Application source code
│   ├── HU_MainApp/                   # Head Unit Wayland compositor
│   ├── GearApp/                      # Gear selection UI
│   ├── MediaApp/                     # Media player
│   ├── AmbientApp/                   # Ambient lighting control
│   ├── HomeScreenApp/                # Home screen launcher
│   ├── PDCApp/                       # Park Distance Control camera
│   ├── IC_MainApp/                   # Instrument Cluster compositor
│   ├── IC_app/                       # Standalone IC application
│   ├── SpeedApp/                     # Speed gauge widget
│   ├── BatteryApp/                   # Battery status widget
│   ├── ICGearApp/                    # IC gear indicator widget
│   ├── VehicleControlECU/            # ECU1 service provider
│   ├── VehicleControlMock/           # Mock service for testing
│   └── RemoteSpeakerApp/            # Remote audio control
├── commonapi/                        # CommonAPI interface definitions
│   ├── fidl/                         # FIDL service definitions
│   ├── generated/                    # Generated proxy/stub code
│   └── generate_code.sh             # Code generation script
├── meta/                             # Yocto build layers
│   ├── meta-headunit/                # ECU2 head unit layer
│   ├── meta-instrumentcluster/       # Instrument cluster layer
│   ├── meta-middleware/              # vsomeip/CommonAPI layer
│   └── meta-vehiclecontrol/          # ECU1 vehicle control layer
├── deps/                             # External dependencies
│   └── commonapi-generators/         # CommonAPI code generators
├── scripts/                          # Deployment scripts
├── Arduino/                          # Arduino firmware
├── .github/                          # CI/CD workflows
└── CMakeLists.txt                    # Top-level build configuration
```

## Build Instructions

### Yocto Build (Production)

#### ECU1 — VehicleControl Image

```bash
cd /path/to/yocto-build
source sources/poky/oe-init-build-env build
bitbake vehiclecontrol-image
```

#### ECU2 — Head Unit Image

```bash
cd /path/to/yocto-build
source sources/poky/oe-init-build-env build
bitbake headunit-image
```

#### Flash to SD Card

```bash
sudo dd if=tmp/deploy/images/raspberrypi4-64/<image-name>.wic of=/dev/sdX bs=4M status=progress
sync
```

### Local Development (x86_64)

#### Prerequisites

```bash
# Ubuntu/Debian
sudo apt-get install cmake build-essential \
    qtbase5-dev qtdeclarative5-dev qtquickcontrols2-5-dev \
    qtmultimedia5-dev qtwayland5-dev-tools \
    libboost-system-dev libboost-thread-dev libboost-filesystem-dev
```

#### Build Applications

```bash
cmake -B build -DCMAKE_BUILD_TYPE=Debug
cmake --build build -j$(nproc)
```

Individual applications can be toggled via CMake options:

```bash
cmake -B build -DBUILD_MEDIA_APP=ON -DBUILD_GEAR_APP=ON -DBUILD_AMBIENT_APP=OFF
```

## Network Configuration

| Device | Interface | IP Address | Role |
|--------|-----------|-----------|------|
| ECU1 (Raspberry Pi 4) | eth0 | 192.168.1.100/24 | SOME/IP Provider + Camera Sender |
| ECU2 (Jetson Orin Nano) | eth0 | 192.168.1.101/24 | SOME/IP Consumer + Display Host + Camera Receiver |

### SOME/IP Network

- **Service Discovery:** Multicast 224.244.224.245:30490
- **Unicast Ports:** UDP 30501 (unreliable), TCP 30502 (reliable)
- **Service ID:** 0x1234, **Instance ID:** 0x5678

### Camera Streaming Pipeline

**Sender (ECU1 → ECU2):**
```
libcamerasrc → video/x-raw,1280x720@30fps → x264enc → rtph264pay → udpsink:5000
```

**Receiver (ECU2):**
```
udpsrc:5000 → rtph264depay → h264parse → nvv4l2decoder → nv3dsink
```

## SOME/IP Service Definitions

### VehicleControl Service (0x1234)

```
interface VehicleControl {
    method setGearPosition {
        in  { String gear }
        out { Boolean success }
    }

    broadcast vehicleStateChanged {
        out { String gear, UInt16 speed, UInt8 batteryLevel, UInt64 timestamp }
    }

    broadcast gearDistanceChanged {
        out { String newGear, String oldGear, UInt16 distance, UInt64 timestamp }
    }
}
```

### AmbientControl Service

```
interface AmbientControl {
    method getAmbientColor { out { String color } }
    method getBrightness   { out { Float brightness } }

    broadcast ambientColorChanged { out { String newColor } }
    broadcast brightnessChanged   { out { Float newBrightness } }
}
```

## References

- [vsomeip](https://github.com/COVESA/vsomeip) — SOME/IP implementation by COVESA
- [CommonAPI](https://github.com/COVESA/capicxx-core-runtime) — Language binding for automotive middleware
- [Yocto Project](https://www.yoctoproject.org/) — Embedded Linux build system
- [Qt5](https://www.qt.io/) — Cross-platform UI framework
- [GStreamer](https://gstreamer.freedesktop.org/) — Multimedia framework
- [libcamera](https://libcamera.org/) — Camera stack for Linux

<!--
## License

TODO: Add license information
[![License: CC BY-NC-SA 4.0](https://img.shields.io/badge/License-CC%20BY--NC--SA%204.0-lightgrey.svg)](https://creativecommons.org/licenses/by-nc-sa/4.0/)
-->
