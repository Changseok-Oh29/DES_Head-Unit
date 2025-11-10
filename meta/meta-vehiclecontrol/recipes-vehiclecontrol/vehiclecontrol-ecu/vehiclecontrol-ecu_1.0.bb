SUMMARY = "VehicleControl ECU Application"
DESCRIPTION = "PiRacer vehicle control service using vsomeip and CommonAPI for inter-ECU communication"
HOMEPAGE = "https://github.com/Changseok-Oh29/DES_Head-Unit"
SECTION = "apps"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

DEPENDS = " \
    qtbase \
    commonapi-core \
    commonapi-someip \
    vsomeip \
    boost \
    pigpio \
"

# Source files are included in the recipe
SRC_URI = " \
    file://src \
    file://lib \
    file://commonapi-generated \
    file://CMakeLists.txt \
    file://config/vsomeip_ecu1.json \
    file://config/commonapi_ecu1.ini \
    file://vehiclecontrol-ecu.service \
"

S = "${WORKDIR}"

inherit cmake_qt5 systemd

# CMake configuration
EXTRA_OECMAKE = " \
    -DCOMMONAPI_GEN_DIR=${S}/commonapi-generated \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_FLAGS=-Wno-psabi \
"

# Systemd service configuration
SYSTEMD_SERVICE_${PN} = "vehiclecontrol-ecu.service"
SYSTEMD_AUTO_ENABLE_${PN} = "enable"

do_install_append() {
    # Install configuration files
    install -d ${D}${sysconfdir}/vsomeip
    install -d ${D}${sysconfdir}/commonapi
    
    install -m 0644 ${S}/config/vsomeip_ecu1.json ${D}${sysconfdir}/vsomeip/
    install -m 0644 ${S}/config/commonapi_ecu1.ini ${D}${sysconfdir}/commonapi/
    
    # Install systemd service
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/vehiclecontrol-ecu.service ${D}${systemd_system_unitdir}/
}

FILES_${PN} = " \
    ${bindir}/VehicleControlECU \
    ${sysconfdir}/vsomeip/vsomeip_ecu1.json \
    ${sysconfdir}/commonapi/commonapi_ecu1.ini \
    ${systemd_system_unitdir}/vehiclecontrol-ecu.service \
"

RDEPENDS_${PN} = " \
    qtbase \
    commonapi-core \
    commonapi-someip \
    vsomeip \
    boost-system \
    boost-thread \
    boost-filesystem \
    boost-log \
    pigpio \
    bash \
"

# The application needs root access for GPIO
INSANE_SKIP_${PN} += "ldflags"
