# OV5647 Camera Fix for Yocto Build

## Problem Summary

The Raspberry Pi Camera Module v1.3 (OV5647) was not working with the Yocto-built image due to missing IPA (Image Processing Algorithm) modules.

### Error Messages
```
[0:05:38.557587792] [470]  WARN IPAManager ipa_manager.cpp:149 No IPA found in '/usr/lib/libcamera'
[0:05:38.576924365] [476] ERROR RPI raspberrypi.cpp:1085 Failed to load a suitable IPA library
[0:05:38.577020549] [476] ERROR RPI raspberrypi.cpp:1019 Failed to register camera: -22
ERROR: Could not find any supported camera on this system.
```

## Root Cause

The libcamera recipe was configured with `-Dipas=vimc` which only builds a virtual camera IPA for testing, not the Raspberry Pi IPA needed for the OV5647 camera.

**What was built:**
- ✓ libcamera core libraries
- ✓ GStreamer libcamera plugin
- ✓ Raspberry Pi IPA proxy binary
- ✗ **Raspberry Pi IPA module (ipa_rpi.so) - MISSING**

## Solution Applied

Created `meta-vehiclecontrol/recipes-multimedia/libcamera/libcamera.bbappend` to:

1. **Build the Raspberry Pi IPA module:**
   - Changed from `-Dipas=vimc` to `-Dipas=rpi/vc4`

2. **Package the IPA files:**
   - Added FILES variables to include `/usr/lib/libcamera/*.so` and `*.so.sign`

## Files Modified

```
meta-vehiclecontrol/recipes-multimedia/libcamera/libcamera.bbappend (NEW)
```

## Rebuild Instructions

### 1. Clean libcamera package
```bash
cd /home/seame/PDC/headunit/yocto-build/build
source ../poky/oe-init-build-env

# Clean libcamera to force rebuild with new configuration
bitbake -c cleansstate libcamera
```

### 2. Rebuild the image
```bash
# Rebuild libcamera with Raspberry Pi IPA
bitbake libcamera

# Rebuild the complete image
bitbake vehiclecontrol-image
```

### 3. Flash the new image
```bash
# The new image will be in:
# build/tmp-glibc/deploy/images/raspberrypi4-64/vehiclecontrol-image-raspberrypi4-64.rootfs.rpi-sdimg

# Flash to SD card (adjust /dev/sdX to your SD card device)
sudo dd if=tmp-glibc/deploy/images/raspberrypi4-64/vehiclecontrol-image-raspberrypi4-64.rootfs.rpi-sdimg of=/dev/sdX bs=4M status=progress && sync
```

## Verification After Rebuild

After flashing and booting the new image, verify the fix:

### 1. Check IPA modules are installed
```bash
ls -la /usr/lib/libcamera/
# Should show: ipa_rpi.so and ipa_rpi.so.sign
```

### 2. Test libcamera
```bash
# This should work without errors
gst-launch-1.0 libcamerasrc ! fakesink
```

### 3. Test camera streaming
```bash
# Test the full streaming pipeline
gst-launch-1.0 libcamerasrc ! video/x-raw,width=1280,height=720,framerate=30/1 ! \
  x264enc tune=zerolatency bitrate=4000 speed-preset=ultrafast ! \
  h264parse config-interval=1 ! \
  rtph264pay pt=96 ! \
  udpsink host=192.168.1.101 port=5000 sync=false async=false
```

## Expected Results

After the fix, you should see:
- ✓ No "No IPA found" warnings
- ✓ Camera detected and registered successfully
- ✓ GStreamer pipeline works with libcamerasrc
- ✓ Video streaming to Jetson Orin Nano works

## Technical Details

### What is IPA?
IPA (Image Processing Algorithm) modules are crucial components in libcamera that handle:
- Auto exposure (AE)
- Auto white balance (AWB)
- Auto focus (AF)
- Lens shading correction
- Black level correction
- Other image processing algorithms

Each camera sensor requires a specific IPA module. For the Raspberry Pi Camera Module v1.3 (OV5647), the `rpi/vc4` IPA is required.

### I2C Detection Note
The camera appearing on bus 10 (not bus 1) is **correct**:
- Bus 10 is the CSI-2 dedicated I2C bus
- Bus 1 is the GPIO header I2C bus
- Camera modules connect via CSI connector, not GPIO header

The dmesg message `ov5647 10-0036` confirms the camera is detected on the correct bus.

## Current Configuration Status

### ✓ Already Configured
- Kernel modules (ov5647, bcm2835_unicam)
- Device tree overlays (ov5647.dtbo)
- GStreamer plugins (libcamerasrc, x264enc, rtph264pay, udpsink)
- Raspberry Pi config (start_x=1, gpu_mem=128)

### ✓ Fixed by This Change
- Raspberry Pi IPA module build and packaging

## Streaming Architecture

```
┌─────────────┐      ┌──────────────┐      ┌─────────────┐
│  OV5647     │──────▶│ libcamera    │──────▶│ GStreamer   │
│  Camera     │ CSI-2 │ + IPA (rpi)  │ v4l2 │ libcamerasrc│
└─────────────┘      └──────────────┘      └─────────────┘
                                                    │
                                                    ▼
                                            ┌──────────────┐
                                            │ x264enc      │
                                            │ (H.264)      │
                                            └──────────────┘
                                                    │
                                                    ▼
                                            ┌──────────────┐
                                            │ rtph264pay   │
                                            │ (RTP)        │
                                            └──────────────┘
                                                    │
                                                    ▼
                                            ┌──────────────┐
                                            │ udpsink      │────▶ Ethernet
                                            └──────────────┘
```

## References

- libcamera: https://libcamera.org/
- Raspberry Pi Camera: https://www.raspberrypi.com/documentation/accessories/camera.html
- GStreamer: https://gstreamer.freedesktop.org/
