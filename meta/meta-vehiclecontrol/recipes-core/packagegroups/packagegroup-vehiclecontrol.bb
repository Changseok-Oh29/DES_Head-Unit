SUMMARY = "VehicleControl ECU package group"
DESCRIPTION = "Package group for VehicleControl ECU system dependencies"

inherit packagegroup

# Allow architecture-specific dependencies in allarch packagegroup
INSANE_SKIP:${PN}-connectivity = "allarch-pkg-requires"

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
"

RRECOMMENDS:${PN}-hardware = " \
    kernel-module-i2c-bcm2835 \
"

RDEPENDS:${PN}-system = " \
    systemd \
    openssh \
    bash \
    coreutils \
    iproute2 \
    iputils \
"
