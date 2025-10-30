SUMMARY = "VehicleControl ECU Service for PiRacer"
DESCRIPTION = "vsomeip-based vehicle control service with PiRacer hardware integration"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

DEPENDS = " \
    qtbase \
    qtdeclarative \
    qtquickcontrols2 \
    vsomeip \
    commonapi-core \
    commonapi-someip \
    boost \
    pigpio \
    i2c-tools \
"

RDEPENDS:${PN} = " \
    qtbase \
    qtdeclarative \
    qtquickcontrols2 \
    vsomeip \
    commonapi-core \
    commonapi-someip \
    boost-system \
    boost-thread \
    boost-filesystem \
    boost-log \
    pigpio \
    i2c-tools \
"

SRC_URI = " \
    file://src \
    file://CMakeLists.txt \
    file://config/vsomeip_ecu1.json \
    file://config/commonapi_ecu1.ini \
"

S = "${WORKDIR}"

inherit cmake qt5

# CMake configuration
EXTRA_OECMAKE = " \
    -DCMAKE_BUILD_TYPE=Release \
    -DCOMMONAPI_GEN_DIR=${STAGING_DIR_HOST}/usr/share/commonapi/generated \
"

# Install paths
FILES:${PN} += " \
    ${bindir}/VehicleControlECU \
    ${sysconfdir}/vsomeip/vsomeip_ecu1.json \
    ${sysconfdir}/commonapi/commonapi_ecu1.ini \
    ${datadir}/commonapi/generated \
"

do_install:append() {
    # Install binary
    install -d ${D}${bindir}
    install -m 0755 ${B}/VehicleControlECU ${D}${bindir}/
    
    # Install configuration files
    install -d ${D}${sysconfdir}/vsomeip
    install -m 0644 ${S}/config/vsomeip_ecu1.json ${D}${sysconfdir}/vsomeip/
    
    install -d ${D}${sysconfdir}/commonapi
    install -m 0644 ${S}/config/commonapi_ecu1.ini ${D}${sysconfdir}/commonapi/
    
    # Create log directory
    install -d ${D}${localstatedir}/log
}

# Enable I2C device tree overlay
KERNEL_DEVICETREE:append = " overlays/i2c1.dtbo"

# Package configuration
PACKAGE_ARCH = "${MACHINE_ARCH}"
