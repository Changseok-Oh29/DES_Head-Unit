# PDCApp Docker Containerization Guide

## Overview

This guide explains how to containerize the PDCApp for use in a hypervisor environment.

## Prerequisites

- Docker installed on the host system
- Docker Compose (optional, but recommended)
- Access to display (framebuffer or X11)
- vsomeip network configuration

## Architecture

```
┌─────────────────────────────────────┐
│  Docker Container (PDCApp)          │
│  ┌───────────────────────────────┐  │
│  │ Qt5 Application (QML UI)      │  │
│  │ ├─ VehicleControlClient       │  │
│  │ └─ CommonAPI Proxy            │  │
│  └───────────────────────────────┘  │
│             ↓                        │
│  ┌───────────────────────────────┐  │
│  │ vsomeip3 (IPC/Network)        │  │
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘
           ↓ (shared memory, network)
┌─────────────────────────────────────┐
│  Host System / Other Containers     │
│  └─ VehicleControl ECU (vsomeip)   │
└─────────────────────────────────────┘
```

## Building the Container

### Option 1: Using docker-compose (Recommended)

```bash
cd /home/seame/PDC/headunit/DES_Head-Unit/app/PDCApp
docker-compose build
```

### Option 2: Using docker directly

```bash
cd /home/seame/PDC/headunit/DES_Head-Unit
docker build -t pdcapp:latest -f app/PDCApp/Dockerfile .
```

## Running the Container

### With docker-compose:

```bash
docker-compose up -d
```

### With docker directly:

```bash
docker run -d \
  --name pdcapp \
  --privileged \
  --network host \
  --ipc host \
  -v /dev/shm:/dev/shm \
  -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
  --device /dev/dri \
  --device /dev/fb0 \
  -e DISPLAY=$DISPLAY \
  -e QT_QPA_PLATFORM=eglfs \
  pdcapp:latest
```

## Display Options

### Option 1: Direct Framebuffer (eglfs)
Best for embedded systems without X11:
```bash
-e QT_QPA_PLATFORM=eglfs
-e QT_QPA_EGLFS_INTEGRATION=eglfs_kms
--device /dev/dri
--device /dev/fb0
```

### Option 2: X11 Forwarding
If running on a system with X11:
```bash
-e DISPLAY=$DISPLAY
-e QT_QPA_PLATFORM=xcb
-v /tmp/.X11-unix:/tmp/.X11-unix:rw
```

### Option 3: Wayland
For Wayland compositors:
```bash
-e QT_QPA_PLATFORM=wayland
-e XDG_RUNTIME_DIR=/run/user/1000
-v $XDG_RUNTIME_DIR:$XDG_RUNTIME_DIR
```

## vsomeip Configuration

### Network Mode
The container uses `network_mode: host` to share the network namespace with the host. This is necessary for vsomeip service discovery.

### Shared Memory
vsomeip uses shared memory for local IPC:
```yaml
volumes:
  - /dev/shm:/dev/shm
ipc: host
```

### Configuration File
Mount your vsomeip configuration:
```yamllocal IPC
volumes:
  - ./config:/app/config:ro
environment:
  - VSOMEIP_CONFIGURATION=/app/config/vsomeip.json
```

## Hypervisor Integration

For use with hypervisors (KVM/Xen/Docker):

### 1. Container as VM Equivalent
Run PDCApp in a container instead of a full VM:
- Lower overhead than VM
- Faster startup
- Shared kernel with host

### 2. Multi-Container Setup
```yaml
version: '3.8'
services:
  ecu-vehiclecontrol:
    image: vehiclecontrol-ecu:latest
    network_mode: host

  ecu-instrumentcluster:
    image: instrumentcluster:latest
    network_mode: host

  headunit-pdcapp:
    image: pdcapp:latest
    network_mode: host
    depends_on:
      - ecu-vehiclecontrol
```

### 3. Resource Limits
For hypervisor-like resource isolation:
```yaml
services:
  pdcapp:
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 512M
        reservations:
          cpus: '1.0'
          memory: 256M
```

## Troubleshooting

### Display Issues
```bash
# Check if framebuffer is accessible
ls -la /dev/fb0

# Check DRI devices
ls -la /dev/dri/

# Test X11 connection
xhost +local:docker
```

### vsomeip Connection Issues
```bash
# Check if vsomeip service is running
docker exec -it pdcapp ps aux | grep vsomeip

# Check network connectivity
docker exec -it pdcapp netstat -tulpn | grep 30490

# Check shared memory
docker exec -it pdcapp ls -la /dev/shm
```

### CommonAPI Issues
```bash
# Verify CommonAPI libraries are loaded
docker exec -it pdcapp ldd /app/PDCApp | grep CommonAPI
```

## Advanced: Building for ARM64

For Raspberry Pi deployment:

```dockerfile
FROM arm64v8/ubuntu:22.04 AS builder
# ... rest of Dockerfile
```

Build on x86_64 with buildx:
```bash
docker buildx build \
  --platform linux/arm64 \
  -t pdcapp:arm64 \
  -f app/PDCApp/Dockerfile .
```

## Security Considerations

### Reduce Privileges
Remove `--privileged` and add specific capabilities:
```yaml
cap_add:
  - SYS_ADMIN  # For device access
  - NET_ADMIN  # For network configuration
security_opt:
  - seccomp:unconfined
```

### Read-only Root Filesystem
```yaml
read_only: true
tmpfs:
  - /tmp
  - /var/run
```

## Performance Tuning

### GPU Acceleration
Ensure GPU passthrough is working:
```bash
docker exec -it pdcapp glxinfo | grep renderer
```

### vsomeip Performance
Tune vsomeip buffer sizes in configuration:
```json
{
  "unicast": "127.0.0.1",
  "netmask": "255.255.255.0",
  "buffer-shrink-threshold": 5,
  "max-payload-size-local": 32768
}
```

## Logs and Monitoring

View logs:
```bash
docker logs -f pdcapp
```

Monitor resources:
```bash
docker stats pdcapp
```

## References

- Qt in Docker: https://doc.qt.io/qt-5/embedded-linux.html
- vsomeip: https://github.com/COVESA/vsomeip
- Docker networking: https://docs.docker.com/network/
