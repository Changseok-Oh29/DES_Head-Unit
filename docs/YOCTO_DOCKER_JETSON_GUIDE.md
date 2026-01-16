# Yocto Docker Container Build Guide for Jetson Orin Nano

This guide explains how to build and deploy Docker containerized headunit applications on Jetson Orin Nano using Yocto.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [System Architecture](#system-architecture)
3. [Prerequisites](#prerequisites)
4. [Yocto Layer Structure](#yocto-layer-structure)
5. [Docker Configuration for Jetson](#docker-configuration-for-jetson)
6. [Dockerfile Modifications for Jetson](#dockerfile-modifications-for-jetson)
7. [Yocto Recipes](#yocto-recipes)
8. [Network Configuration for vsomeip](#network-configuration-for-vsomeip)
9. [Boot Sequence](#boot-sequence)
10. [Troubleshooting](#troubleshooting)

---

## Architecture Overview

### Current Local Testing Setup

```
┌─────────────────────────────────────────────────────────┐
│  Development Laptop (x86_64)                            │
│                                                         │
│  X11 Display Server                                     │
│       │                                                 │
│       ▼                                                 │
│  HU_MainApp (Docker) ─── QT_QPA_PLATFORM=xcb           │
│       │ creates wayland-1                               │
│       ▼                                                 │
│  Client Apps (Docker) ─── QT_QPA_PLATFORM=wayland      │
│  (GearApp, PDCApp, HomeScreenApp, MediaApp, AmbientApp)│
│       │                                                 │
│       ▼                                                 │
│  VehicleControlMock (Native) ─── vsomeip routing mgr   │
└─────────────────────────────────────────────────────────┘
```

### Target Jetson Deployment Setup

```
┌─────────────────────────────────────────────────────────────────────────┐
│  Jetson Orin Nano (ARM64) - Yocto Linux                                 │
│                                                                         │
│  Weston Compositor (Native) ─── wayland-0 ─── Dual Screen Output        │
│       │                                                                 │
│       ├──► Screen 1 ─────────────────────────────────────────────────┐ │
│       │    HU_MainApp (Docker) ─── QT_QPA_PLATFORM=wayland            │ │
│       │         │ connects to wayland-0, creates wayland-1            │ │
│       │         │                                                     │ │
│       │         ├── GearApp (Docker) ────────┐                        │ │
│       │         ├── PDCApp (Docker) ─────────┤ Connect to wayland-1   │ │
│       │         ├── HomeScreenApp (Docker) ──┤                        │ │
│       │         ├── MediaApp (Docker) ───────┤                        │ │
│       │         └── AmbientApp (Docker) ─────┘                        │ │
│       │    └──────────────────────────────────────────────────────────┘ │
│       │                                                                 │
│       └──► Screen 2 ─────────────────────────────────────────────────┐ │
│            IC_app (Docker or Native) ─── connects to wayland-0        │ │
│            └──────────────────────────────────────────────────────────┘ │
│                                                                         │
│  routing_manager_ecu2 (Native) ─── vsomeip routing manager for HU      │
└─────────────────────────────────────────────────────────────────────────┘
                              │
                              │ Ethernet (vsomeip UDP multicast)
                              │ 224.244.224.245:30490
                              ▼
┌─────────────────────────────────────────────────────────────────────────┐
│  Raspberry Pi (ARM64)                                                   │
│                                                                         │
│  VehicleControlECU (Native) ─── vsomeip routing manager for ECU1       │
│       │                                                                 │
│       └── Provides: VehicleControl service (0x1234.0x5678)             │
│           - Gear position                                               │
│           - PDC distance                                                │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## System Architecture

### Wayland Socket Structure

| Socket | Creator | Consumers | Purpose |
|--------|---------|-----------|---------|
| `wayland-0` | Weston | HU_MainApp, IC_app | Main compositor for physical displays |
| `wayland-1` | HU_MainApp | GearApp, PDCApp, HomeScreenApp, MediaApp, AmbientApp | Nested compositor for headunit apps |

### vsomeip Communication

| Component | IP Address | Role | Config File |
|-----------|------------|------|-------------|
| Jetson (ECU2) | 192.168.1.101 | Routing Manager (HU side) | `routing_manager_ecu2.json` |
| Raspberry Pi (ECU1) | 192.168.1.100 | Routing Manager (Vehicle side) | `vsomeip_ecu1.json` |

### Service Discovery

- **Multicast Address**: 224.244.224.245
- **Port**: 30490
- **Protocol**: UDP

---

## Prerequisites

### Required Yocto Layers

```
poky/                          # Yocto base
├── meta                       # Core metadata
├── meta-poky                  # Poky reference distro
├── meta-yocto-bsp             # Yocto BSP
meta-openembedded/
├── meta-oe                    # OpenEmbedded core
├── meta-python                # Python support
├── meta-networking            # Network utilities
meta-tegra/                    # NVIDIA Jetson BSP (L4T)
meta-virtualization/           # Docker support
meta-pdc-headunit/             # Your custom layer (create this)
```

### Jetson-Specific Requirements

- **L4T Version**: R35.4.1 or compatible
- **NVIDIA Container Runtime**: For GPU access in containers
- **Docker Engine**: docker-ce or docker-moby

---

## Yocto Layer Structure

Create a custom Yocto layer for your PDC headunit:

```
meta-pdc-headunit/
├── conf/
│   └── layer.conf
├── recipes-containers/
│   └── pdc-apps/
│       ├── pdc-apps.bb
│       └── files/
│           ├── docker-compose.jetson.yml
│           ├── pdc-containers.service
│           └── build-containers.sh
├── recipes-core/
│   └── images/
│       └── pdc-headunit-image.bb
├── recipes-connectivity/
│   └── vsomeip-routing/
│       ├── vsomeip-routing.bb
│       └── files/
│           ├── routing_manager_ecu2.json
│           └── vsomeip-routing.service
└── README.md
```

### layer.conf

```bitbake
# meta-pdc-headunit/conf/layer.conf

BBPATH .= ":${LAYERDIR}"

BBFILES += "${LAYERDIR}/recipes-*/*/*.bb \
            ${LAYERDIR}/recipes-*/*/*.bbappend"

BBFILE_COLLECTIONS += "pdc-headunit"
BBFILE_PATTERN_pdc-headunit = "^${LAYERDIR}/"
BBFILE_PRIORITY_pdc-headunit = "10"

LAYERDEPENDS_pdc-headunit = "core tegra virtualization-layer"
LAYERSERIES_COMPAT_pdc-headunit = "kirkstone langdale mickledore"
```

---

## Docker Configuration for Jetson

### docker-compose.jetson.yml

This file configures containers for Jetson with NVIDIA runtime:

```yaml
version: '3.8'

services:
  # ═══════════════════════════════════════════════════════════════════
  # HU_MainApp - Nested Wayland Compositor
  # Connects to Weston (wayland-0), creates wayland-1 for client apps
  # ═══════════════════════════════════════════════════════════════════
  humainapp:
    image: humainapp:latest
    container_name: humainapp
    user: "1000:1000"
    runtime: nvidia
    network_mode: host
    privileged: true
    ipc: host
    pid: host
    environment:
      - NVIDIA_VISIBLE_DEVICES=all
      - NVIDIA_DRIVER_CAPABILITIES=all
      - XDG_RUNTIME_DIR=/run/user/1000
      - QT_QPA_PLATFORM=wayland
      - WAYLAND_DISPLAY=wayland-0
      - QT_XKB_CONFIG_ROOT=/usr/share/X11/xkb
    volumes:
      - /tmp:/tmp
      - /run/user/1000:/run/user/1000
      - /dev/dri:/dev/dri
      - /dev/shm:/dev/shm
      - /usr/share/X11/xkb:/usr/share/X11/xkb:ro
    restart: unless-stopped

  # ═══════════════════════════════════════════════════════════════════
  # Client Apps - Connect to HU_MainApp's wayland-1 socket
  # ═══════════════════════════════════════════════════════════════════

  gearapp:
    image: gearapp:latest
    container_name: gearapp
    user: "1000:1000"
    runtime: nvidia
    network_mode: host
    ipc: host
    pid: host
    depends_on:
      - humainapp
    environment:
      - NVIDIA_VISIBLE_DEVICES=all
      - NVIDIA_DRIVER_CAPABILITIES=all
      - XDG_RUNTIME_DIR=/run/user/1000
      - QT_QPA_PLATFORM=wayland
      - WAYLAND_DISPLAY=wayland-1
      - QT_WAYLAND_DISABLE_WINDOWDECORATION=1
      - QT_XKB_CONFIG_ROOT=/usr/share/X11/xkb
    volumes:
      - /tmp:/tmp
      - /run/user/1000:/run/user/1000
      - /dev/dri:/dev/dri
      - /dev/shm:/dev/shm
      - /usr/share/X11/xkb:/usr/share/X11/xkb:ro
    restart: unless-stopped

  pdcapp:
    image: pdcapp:latest
    container_name: pdcapp
    user: "1000:1000"
    runtime: nvidia
    network_mode: host
    ipc: host
    pid: host
    depends_on:
      - humainapp
    environment:
      - NVIDIA_VISIBLE_DEVICES=all
      - NVIDIA_DRIVER_CAPABILITIES=all
      - XDG_RUNTIME_DIR=/run/user/1000
      - QT_QPA_PLATFORM=wayland
      - WAYLAND_DISPLAY=wayland-1
      - QT_WAYLAND_DISABLE_WINDOWDECORATION=1
      - QT_XKB_CONFIG_ROOT=/usr/share/X11/xkb
    volumes:
      - /tmp:/tmp
      - /run/user/1000:/run/user/1000
      - /dev/dri:/dev/dri
      - /dev/shm:/dev/shm
      - /usr/share/X11/xkb:/usr/share/X11/xkb:ro
    restart: unless-stopped

  homescreenapp:
    image: homescreenapp:latest
    container_name: homescreenapp
    user: "1000:1000"
    runtime: nvidia
    network_mode: host
    ipc: host
    pid: host
    depends_on:
      - humainapp
    environment:
      - NVIDIA_VISIBLE_DEVICES=all
      - NVIDIA_DRIVER_CAPABILITIES=all
      - XDG_RUNTIME_DIR=/run/user/1000
      - QT_QPA_PLATFORM=wayland
      - WAYLAND_DISPLAY=wayland-1
      - QT_WAYLAND_DISABLE_WINDOWDECORATION=1
      - QT_XKB_CONFIG_ROOT=/usr/share/X11/xkb
    volumes:
      - /tmp:/tmp
      - /run/user/1000:/run/user/1000
      - /dev/dri:/dev/dri
      - /dev/shm:/dev/shm
      - /usr/share/X11/xkb:/usr/share/X11/xkb:ro
    restart: unless-stopped

  mediaapp:
    image: mediaapp:latest
    container_name: mediaapp
    user: "1000:1000"
    runtime: nvidia
    network_mode: host
    ipc: host
    pid: host
    depends_on:
      - humainapp
    environment:
      - NVIDIA_VISIBLE_DEVICES=all
      - NVIDIA_DRIVER_CAPABILITIES=all
      - XDG_RUNTIME_DIR=/run/user/1000
      - QT_QPA_PLATFORM=wayland
      - WAYLAND_DISPLAY=wayland-1
      - QT_WAYLAND_DISABLE_WINDOWDECORATION=1
      - QT_XKB_CONFIG_ROOT=/usr/share/X11/xkb
    volumes:
      - /tmp:/tmp
      - /run/user/1000:/run/user/1000
      - /dev/dri:/dev/dri
      - /dev/shm:/dev/shm
      - /usr/share/X11/xkb:/usr/share/X11/xkb:ro
    restart: unless-stopped

  ambientapp:
    image: ambientapp:latest
    container_name: ambientapp
    user: "1000:1000"
    runtime: nvidia
    network_mode: host
    ipc: host
    pid: host
    depends_on:
      - humainapp
    environment:
      - NVIDIA_VISIBLE_DEVICES=all
      - NVIDIA_DRIVER_CAPABILITIES=all
      - XDG_RUNTIME_DIR=/run/user/1000
      - QT_QPA_PLATFORM=wayland
      - WAYLAND_DISPLAY=wayland-1
      - QT_WAYLAND_DISABLE_WINDOWDECORATION=1
      - QT_XKB_CONFIG_ROOT=/usr/share/X11/xkb
    volumes:
      - /tmp:/tmp
      - /run/user/1000:/run/user/1000
      - /dev/dri:/dev/dri
      - /dev/shm:/dev/shm
      - /usr/share/X11/xkb:/usr/share/X11/xkb:ro
    restart: unless-stopped
```

### Key Differences: Local vs Jetson

| Setting | Local (x86_64) | Jetson (ARM64) |
|---------|----------------|----------------|
| `runtime` | (none) | `nvidia` |
| HU_MainApp `QT_QPA_PLATFORM` | `xcb` | `wayland` |
| HU_MainApp `WAYLAND_DISPLAY` | `wayland-1` (creates) | `wayland-0` (connects to Weston) |
| `XDG_RUNTIME_DIR` | `/tmp/runtime-root` | `/run/user/1000` |
| `NVIDIA_VISIBLE_DEVICES` | (none) | `all` |
| `NVIDIA_DRIVER_CAPABILITIES` | (none) | `all` |

---

## Dockerfile Modifications for Jetson

### Option A: Use L4T Base Image (Recommended for GPU apps)

For apps requiring GPU acceleration, use NVIDIA's L4T base image:

```dockerfile
# Stage 2: Runtime environment (Jetson version)
FROM nvcr.io/nvidia/l4t-base:r35.4.1

ENV DEBIAN_FRONTEND=noninteractive

# L4T base includes CUDA, cuDNN, TensorRT
# Install additional Qt dependencies
RUN apt-get update && apt-get install -y \
    qtbase5-dev \
    qtdeclarative5-dev \
    qtquickcontrols2-5-dev \
    qtwayland5 \
    libqt5waylandclient5 \
    # ... rest of packages
    && rm -rf /var/lib/apt/lists/*
```

### Option B: Use Ubuntu ARM64 (For non-GPU apps)

For apps that don't need GPU, standard Ubuntu ARM64 works:

```dockerfile
# Stage 2: Runtime environment
FROM ubuntu:22.04

# Same as current Dockerfiles, will be built for ARM64
```

### Build Stage Considerations

The builder stage uses `ubuntu:22.04` which works for both x86_64 and ARM64:

```dockerfile
# Stage 1: Build environment (works for both architectures)
FROM ubuntu:22.04 AS builder
# ... build steps remain the same
```

---

## Yocto Recipes

### pdc-apps.bb (Main Container Recipe)

```bitbake
# meta-pdc-headunit/recipes-containers/pdc-apps/pdc-apps.bb

SUMMARY = "PDC Headunit Docker Applications"
DESCRIPTION = "Docker containers for PDC headunit infotainment system"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = " \
    git://github.com/AIM-AI-Co/DES_Head-Unit.git;branch=main;protocol=https;name=headunit \
    file://docker-compose.jetson.yml \
    file://pdc-containers.service \
    file://build-containers.sh \
"
SRCREV_headunit = "${AUTOREV}"

S = "${WORKDIR}/git"

RDEPENDS:${PN} = " \
    docker-ce \
    docker-compose \
    nvidia-container-runtime \
    bash \
"

inherit systemd

SYSTEMD_SERVICE:${PN} = "pdc-containers.service"
SYSTEMD_AUTO_ENABLE = "enable"

do_install() {
    # Install source code for Docker build
    install -d ${D}/opt/pdc/src
    cp -r ${S}/app ${D}/opt/pdc/src/
    cp -r ${S}/deps ${D}/opt/pdc/src/
    cp -r ${S}/commonapi ${D}/opt/pdc/src/

    # Install docker-compose configuration
    install -d ${D}/opt/pdc
    install -m 0644 ${WORKDIR}/docker-compose.jetson.yml ${D}/opt/pdc/docker-compose.yml

    # Install build script
    install -m 0755 ${WORKDIR}/build-containers.sh ${D}/opt/pdc/

    # Install systemd service
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/pdc-containers.service ${D}${systemd_system_unitdir}/
}

FILES:${PN} = " \
    /opt/pdc \
"
```

### build-containers.sh

```bash
#!/bin/bash
# Build Docker containers on Jetson (run once after first boot)

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC_DIR="$SCRIPT_DIR/src"
LOG_FILE="/var/log/pdc-container-build.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Check if images already exist
check_images_exist() {
    local images=("humainapp" "gearapp" "pdcapp" "homescreenapp" "mediaapp" "ambientapp")
    for img in "${images[@]}"; do
        if ! docker images | grep -q "$img"; then
            return 1
        fi
    done
    return 0
}

if check_images_exist; then
    log "Docker images already built, skipping build"
    exit 0
fi

log "Starting PDC Docker container build..."

cd "$SRC_DIR"

# Build each app
log "Building HU_MainApp..."
docker build -f app/HU_MainApp/Dockerfile -t humainapp:latest . 2>&1 | tee -a "$LOG_FILE"

log "Building GearApp..."
docker build -f app/GearApp/Dockerfile -t gearapp:latest . 2>&1 | tee -a "$LOG_FILE"

log "Building PDCApp..."
docker build -f app/PDCApp/Dockerfile -t pdcapp:latest . 2>&1 | tee -a "$LOG_FILE"

log "Building HomeScreenApp..."
docker build -f app/HomeScreenApp/Dockerfile -t homescreenapp:latest . 2>&1 | tee -a "$LOG_FILE"

log "Building MediaApp..."
docker build -f app/MediaApp/Dockerfile -t mediaapp:latest . 2>&1 | tee -a "$LOG_FILE"

log "Building AmbientApp..."
docker build -f app/AmbientApp/Dockerfile -t ambientapp:latest . 2>&1 | tee -a "$LOG_FILE"

log "All Docker containers built successfully!"
```

### pdc-containers.service

```ini
[Unit]
Description=PDC Headunit Docker Containers
After=docker.service weston.service network-online.target vsomeip-routing.service
Requires=docker.service
Wants=network-online.target vsomeip-routing.service

[Service]
Type=oneshot
RemainAfterExit=yes

# Build containers if not already built (first boot only)
ExecStartPre=/opt/pdc/build-containers.sh

# Start all containers
ExecStart=/usr/bin/docker-compose -f /opt/pdc/docker-compose.yml up -d

# Stop all containers
ExecStop=/usr/bin/docker-compose -f /opt/pdc/docker-compose.yml down

# Allow time for Docker builds on first boot
TimeoutStartSec=1800

[Install]
WantedBy=multi-user.target
```

### vsomeip-routing.bb (vsomeip Routing Manager)

```bitbake
# meta-pdc-headunit/recipes-connectivity/vsomeip-routing/vsomeip-routing.bb

SUMMARY = "vsomeip Routing Manager for PDC Headunit"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = " \
    file://routing_manager_ecu2.json \
    file://vsomeip-routing.service \
"

RDEPENDS:${PN} = "vsomeip"

inherit systemd

SYSTEMD_SERVICE:${PN} = "vsomeip-routing.service"
SYSTEMD_AUTO_ENABLE = "enable"

do_install() {
    # Install vsomeip configuration
    install -d ${D}/etc/vsomeip
    install -m 0644 ${WORKDIR}/routing_manager_ecu2.json ${D}/etc/vsomeip/

    # Install systemd service
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/vsomeip-routing.service ${D}${systemd_system_unitdir}/
}

FILES:${PN} = " \
    /etc/vsomeip \
"
```

### vsomeip-routing.service

```ini
[Unit]
Description=vsomeip Routing Manager for PDC Headunit
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
Environment=VSOMEIP_CONFIGURATION=/etc/vsomeip/routing_manager_ecu2.json
ExecStart=/usr/bin/routingmanagerd
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

### pdc-headunit-image.bb (Yocto Image Recipe)

```bitbake
# meta-pdc-headunit/recipes-core/images/pdc-headunit-image.bb

SUMMARY = "PDC Headunit Image for Jetson Orin Nano"

require recipes-core/images/core-image-weston.bb

IMAGE_FEATURES += " \
    ssh-server-openssh \
    tools-debug \
"

IMAGE_INSTALL:append = " \
    docker-ce \
    docker-compose \
    nvidia-container-runtime \
    pdc-apps \
    vsomeip-routing \
    weston \
    weston-init \
    weston-examples \
    wayland-utils \
    qt5-wayland \
"

# Ensure enough space for Docker images and builds
IMAGE_ROOTFS_EXTRA_SPACE = "4194304"

# Enable systemd
DISTRO_FEATURES:append = " systemd"
VIRTUAL-RUNTIME_init_manager = "systemd"
```

---

## Network Configuration for vsomeip

### routing_manager_ecu2.json (Jetson)

```json
{
    "unicast": "192.168.1.101",
    "netmask": "255.255.255.0",
    "logging": {
        "level": "info",
        "console": "true",
        "file": {
            "enable": "false"
        },
        "dlt": "false"
    },
    "applications": [
        {
            "name": "routingmanagerd",
            "id": "0xFFFF"
        }
    ],
    "routing": "routingmanagerd",
    "service-discovery": {
        "enable": "true",
        "multicast": "224.244.224.245",
        "port": "30490",
        "protocol": "udp",
        "initial_delay_min": "10",
        "initial_delay_max": "100",
        "repetitions_base_delay": "200",
        "repetitions_max": "3",
        "ttl": "3",
        "cyclic_offer_delay": "2000",
        "request_response_delay": "1500"
    }
}
```

### Static IP Configuration

On Jetson, configure static IP via systemd-networkd or NetworkManager:

```ini
# /etc/systemd/network/10-eth0.network
[Match]
Name=eth0

[Network]
Address=192.168.1.101/24
Gateway=192.168.1.1
```

---

## Boot Sequence

```
┌─────────────────────────────────────────────────────────────────────────┐
│  Jetson Boot Sequence                                                   │
│                                                                         │
│  1. systemd starts                                                      │
│       │                                                                 │
│       ▼                                                                 │
│  2. network-online.target (wait for network)                           │
│       │                                                                 │
│       ▼                                                                 │
│  3. docker.service (start Docker daemon)                               │
│       │                                                                 │
│       ▼                                                                 │
│  4. weston.service (start Weston compositor)                           │
│       │ creates wayland-0                                              │
│       ▼                                                                 │
│  5. vsomeip-routing.service (start routing manager)                    │
│       │ creates /tmp/vsomeip-0                                         │
│       ▼                                                                 │
│  6. pdc-containers.service                                             │
│       │                                                                 │
│       ├── ExecStartPre: build-containers.sh                           │
│       │   (builds Docker images on first boot, ~20-30 min)            │
│       │                                                                 │
│       └── ExecStart: docker-compose up -d                              │
│           │                                                             │
│           ├── humainapp (connects to wayland-0, creates wayland-1)    │
│           ├── gearapp (connects to wayland-1)                          │
│           ├── pdcapp (connects to wayland-1)                           │
│           ├── homescreenapp (connects to wayland-1)                    │
│           ├── mediaapp (connects to wayland-1)                         │
│           └── ambientapp (connects to wayland-1)                       │
│                                                                         │
│  7. Apps discover VehicleControlECU via vsomeip multicast              │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Troubleshooting

### Check Container Status

```bash
# View running containers
docker ps

# View all containers (including stopped)
docker ps -a

# View container logs
docker logs humainapp
docker logs gearapp

# Follow logs in real-time
docker-compose -f /opt/pdc/docker-compose.yml logs -f
```

### Check vsomeip Communication

```bash
# Check routing manager is running
systemctl status vsomeip-routing

# Check vsomeip sockets
ls -la /tmp/vsomeip*

# Check if apps connect to routing manager
docker logs gearapp 2>&1 | grep -i "routing\|available"
```

### Check Wayland Sockets

```bash
# Check Weston socket
ls -la /run/user/1000/wayland-0

# Check HU_MainApp socket
ls -la /tmp/runtime-root/wayland-1  # or /run/user/1000/wayland-1
```

### Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| Apps can't connect to wayland-1 | HU_MainApp not running | Check `docker logs humainapp` |
| vsomeip service not available | Routing manager not running | Check `systemctl status vsomeip-routing` |
| GPU not accessible | nvidia-container-runtime missing | Ensure `runtime: nvidia` in compose |
| First boot very slow | Building Docker images | Wait ~20-30 minutes for first boot |
| Network issues | Static IP not set | Check `/etc/systemd/network/` config |

### Manual Testing

```bash
# Manually start containers
cd /opt/pdc
docker-compose up -d

# Manually rebuild a single container
docker build -f /opt/pdc/src/app/GearApp/Dockerfile -t gearapp:latest /opt/pdc/src

# Restart a single container
docker-compose restart gearapp
```

---

## Summary

| Component | Location | Purpose |
|-----------|----------|---------|
| Source code | `/opt/pdc/src/` | Docker build context |
| docker-compose.yml | `/opt/pdc/docker-compose.yml` | Container configuration |
| Build script | `/opt/pdc/build-containers.sh` | First-boot image builder |
| vsomeip config | `/etc/vsomeip/routing_manager_ecu2.json` | Routing manager config |
| Container service | `pdc-containers.service` | Starts containers on boot |
| Routing service | `vsomeip-routing.service` | Starts vsomeip routing manager |

This setup provides:
- Automatic Docker image building on first boot
- Proper GPU acceleration via nvidia-container-runtime
- Wayland compositor integration (Weston → HU_MainApp → client apps)
- vsomeip communication with external ECUs via Ethernet
- Systemd-managed services for reliability
