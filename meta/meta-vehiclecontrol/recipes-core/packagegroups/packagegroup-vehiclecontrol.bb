SUMMARY = "VehicleControl ECU package group"
DESCRIPTION = "Package group for VehicleControl ECU system dependencies"

inherit packagegroup

RDEPENDS_${PN} = " \
    ${PN}-connectivity \
    ${PN}-hardware \
    ${PN}-system \
"

RDEPENDS_${PN}-connectivity = " \
    vsomeip \
    commonapi-core \
    commonapi-someip \
    boost-system \
    boost-thread \
    boost-filesystem \
    boost-log \
"

RDEPENDS_${PN}-hardware = " \
    pigpio \
    i2c-tools \
    kernel-module-i2c-dev \
    kernel-module-i2c-bcm2835 \
"

RDEPENDS_${PN}-system = " \
    systemd \
    openssh \
    bash \
    coreutils \
    iproute2 \
    iputils \
"
