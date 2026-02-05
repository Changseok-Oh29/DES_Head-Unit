SUMMARY = "VehicleControl ECU package group"
DESCRIPTION = "Package group for VehicleControl ECU system dependencies"

inherit packagegroup

# This packagegroup has architecture-specific dependencies
# Do not use allarch
PACKAGE_ARCH = "${MACHINE_ARCH}"

PACKAGES = "\
    ${PN} \
    ${PN}-connectivity \
    ${PN}-hardware \
    ${PN}-system \
    ${PN}-camera \
"

RDEPENDS:${PN} = " \
    ${PN}-connectivity \
    ${PN}-hardware \
    ${PN}-system \
    ${PN}-camera \
"

# Note: vsomeip, commonapi, and boost packages are already RDEPENDS of vehiclecontrol-ecu
# Only list additional connectivity tools here to avoid dynamic rename conflicts
RDEPENDS:${PN}-connectivity = " \
"

RDEPENDS:${PN}-hardware = " \
    pigpio \
    i2c-tools \
    kernel-module-i2c-dev \
    can-utils \
"

RRECOMMENDS:${PN}-hardware = " \
    kernel-module-i2c-bcm2835 \
    kernel-module-can \
    kernel-module-can-raw \
    kernel-module-can-bcm \
    kernel-module-can-gw \
    kernel-module-vcan \
    kernel-module-slcan \
    kernel-module-mcp251x \
"

RDEPENDS:${PN}-system = " \
    systemd \
    openssh \
    bash \
    coreutils \
    iproute2 \
    iputils \
    udev-rules-vehiclecontrol \
"

# Camera streaming for reverse camera (RPi to Jetson via GStreamer RTP/UDP)
# Requires: meta-openembedded/meta-multimedia layer for libcamera
# Note: x264enc is in gstreamer1.0-plugins-ugly
# Note: IPA modules are included in the libcamera package itself
# Note: libcamera-apps (libcamera-hello, etc.) are not available in this Yocto version
#       Use GStreamer with libcamerasrc instead for camera access
RDEPENDS:${PN}-camera = " \
    gstreamer1.0 \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-ugly \
    libcamera \
    libcamera-gst \
"

RRECOMMENDS:${PN}-camera = " \
    v4l-utils \
"
