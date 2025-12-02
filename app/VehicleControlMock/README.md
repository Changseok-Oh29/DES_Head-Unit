# VehicleControlMock - Ubuntu Test Service

## Overview
This is a lightweight mock VehicleControl service for testing GearApp ↔ AmbientApp communication on Ubuntu **without Raspberry Pi hardware**.

Unlike the real `VehicleControlECU` which requires:
- Raspberry Pi GPIO (pigpio)
- PCA9685 PWM controllers
- INA219 battery monitor
- Physical gamepad

This mock service has **NO hardware dependencies** and runs purely in software.

## Features

### ✅ What it does:
- Provides VehicleControl vSOME/IP service (0x1234:0x5678)
- Accepts `setGearPosition(gear)` RPC calls from GearApp
- Fires `gearChanged` events when gear changes
- Broadcasts `vehicleStateChanged` events at 10Hz
- Simulates vehicle speed based on gear (P/N=0, D=25, R=10)
- Simulates battery drain (starts at 85%)

### ❌ What it doesn't do:
- No actual GPIO/motor control
- No physical hardware interaction
- Not suitable for Raspberry Pi deployment

## Building

```bash
cd /home/seame/HU/chang_new/DES_Head-Unit/app/VehicleControlMock
mkdir build && cd build
cmake ..
make
```

## Running

**Terminal 1 - VehicleControlMock Service:**
```bash
cd /home/seame/HU/chang_new/DES_Head-Unit/app/VehicleControlMock/build
export VSOMEIP_CONFIGURATION=../config/vsomeip_mock.json
export COMMONAPI_CONFIG=/home/seame/HU/chang_new/DES_Head-Unit/app/GearApp/commonapi.ini
./VehicleControlMock
```

**Terminal 2 - Compositor:**
```bash
cd /home/seame/HU/chang_new/DES_Head-Unit/app/HU_MainApp/build_compositor
./HU_MainApp_Compositor
```

**Terminal 3 - GearApp:**
```bash
cd /home/seame/HU/chang_new/DES_Head-Unit/app/GearApp/build
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export WAYLAND_DISPLAY=wayland-1
export VSOMEIP_CONFIGURATION=/home/seame/HU/chang_new/DES_Head-Unit/app/GearApp/vsomeip_gear.json
export COMMONAPI_CONFIG=/home/seame/HU/chang_new/DES_Head-Unit/app/GearApp/commonapi.ini
./GearApp
```

**Terminal 4 - AmbientApp:**
```bash
cd /home/seame/HU/chang_new/DES_Head-Unit/app/AmbientApp/build
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export WAYLAND_DISPLAY=wayland-1
export VSOMEIP_CONFIGURATION=/home/seame/HU/chang_new/DES_Head-Unit/app/AmbientApp/vsomeip_ambient.json
export COMMONAPI_CONFIG=/home/seame/HU/chang_new/DES_Head-Unit/app/AmbientApp/commonapi_ambient.ini
./AmbientApp
```

**Terminal 5 - MediaApp:**
```bash
cd /home/seame/HU/chang_new/DES_Head-Unit/app/MediaApp/build
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export WAYLAND_DISPLAY=wayland-1
export VSOMEIP_CONFIGURATION=/home/seame/HU/chang_new/DES_Head-Unit/app/MediaApp/vsomeip_media.json
export COMMONAPI_CONFIG=/home/seame/HU/chang_new/DES_Head-Unit/app/MediaApp/commonapi_media.ini
./MediaApp
```

## Testing

1. Start VehicleControlMock service
2. Start Compositor
3. Start GearApp, MediaApp, AmbientApp
4. Click different gears in GearApp (P, R, N, D)
5. Watch AmbientApp background color change based on gear!

## Expected Behavior

When you change gears in GearApp:
- **P (Park)** → AmbientApp shows **Blue**
- **R (Reverse)** → AmbientApp shows **Red/Orange**
- **N (Neutral)** → AmbientApp shows **Yellow**
- **D (Drive)** → AmbientApp shows **Green**

The mock service logs will show:
```
VehicleControlStubImpl: setGearPosition() called
  Requested gear: D
  Gear changed: P -> D
  Speed: 25 km/h
  gearChanged event fired
```

## Troubleshooting

### Service registration failed
**Problem:** `Failed to register VehicleControl service!`

**Solution:** Check that no other VehicleControl service is running:
```bash
killall -9 VehicleControlMock VehicleControlECU
sudo rm -rf /tmp/vsomeip-*
```

### GearApp can't connect
**Problem:** GearApp shows "VehicleControl service unavailable"

**Solution:**
1. Make sure VehicleControlMock is running first
2. Check vsomeip config paths are correct
3. Verify both use same multicast address (224.0.0.1)

## Differences from Real VehicleControlECU

| Feature | VehicleControlMock | VehicleControlECU |
|---------|-------------------|-------------------|
| Platform | Ubuntu (any PC) | Raspberry Pi only |
| Dependencies | Qt5 + vSOME/IP | pigpio, I2C hardware |
| Purpose | Testing | Real vehicle control |
| Motor control | ❌ Simulated | ✅ Real PCA9685 |
| Battery | ❌ Mock 85% | ✅ Real INA219 |
| Gamepad | ❌ Not supported | ✅ ShanWan USB |

## License
SEA-ME DES Project
