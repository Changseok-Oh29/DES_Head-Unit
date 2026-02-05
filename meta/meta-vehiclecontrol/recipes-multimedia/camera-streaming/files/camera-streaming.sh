#!/bin/bash
# Camera streaming script for VehicleControl ECU
# Streams OV5647 camera via GStreamer RTP/H264/UDP to Jetson Orin Nano
#
# RPi (192.168.1.100) -> UDP port 5000 -> Jetson (192.168.1.101)

set -euo pipefail

JETSON_IP="192.168.1.101"
UDP_PORT="5000"
WIDTH="1280"
HEIGHT="720"
FRAMERATE="30"
BITRATE="4000"
MAX_WAIT_SECS=15

# --- Wait for camera device to become available ---
echo "Waiting for camera device..."
waited=0
while [ "$waited" -lt "$MAX_WAIT_SECS" ]; do
    if [ -e /dev/video0 ]; then
        echo "Found /dev/video0 after ${waited}s"
        break
    fi
    sleep 1
    waited=$((waited + 1))
    echo "Waiting for camera... (${waited}/${MAX_WAIT_SECS}s)"
done

if [ ! -e /dev/video0 ]; then
    echo "ERROR: Camera device /dev/video0 not found after ${MAX_WAIT_SECS}s"
    echo "Check:"
    echo "  1. OV5647 camera module is connected to CSI port"
    echo "  2. dtoverlay=ov5647 is in config.txt"
    echo "  3. Kernel modules: lsmod | grep ov5647"
    echo "  4. Kernel modules: lsmod | grep bcm2835_unicam"
    exit 1
fi

# Brief additional delay to let libcamera IPA fully initialize
sleep 2

echo "Starting camera stream to ${JETSON_IP}:${UDP_PORT}..."
echo "  Resolution: ${WIDTH}x${HEIGHT}@${FRAMERATE}fps"
echo "  Codec: H.264 (x264enc, bitrate=${BITRATE}kbps)"
echo "  Transport: RTP/UDP"

exec gst-launch-1.0 -e \
    libcamerasrc \
    ! "video/x-raw,width=${WIDTH},height=${HEIGHT},framerate=${FRAMERATE}/1" \
    ! videoconvert \
    ! x264enc tune=zerolatency bitrate="${BITRATE}" speed-preset=ultrafast \
    ! h264parse config-interval=1 \
    ! rtph264pay pt=96 \
    ! udpsink host="${JETSON_IP}" port="${UDP_PORT}" sync=false async=false
