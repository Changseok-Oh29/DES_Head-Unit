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
"

RDEPENDS:${PN} = " \
    ${PN}-connectivity \
    ${PN}-hardware \
    ${PN}-system \
"

RDEPENDS:${PN}-connectivity = " \
    vsomeip \
    commonapi-core \
    commonapi-someip \
    boost-system \
    boost-thread \
    boost-filesystem \
    boost-log \
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
