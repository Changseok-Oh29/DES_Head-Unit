SUMMARY = "CAN Interface Setup for MCP2518FD"
DESCRIPTION = "Systemd service to configure CAN interface at boot"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = " \
    file://can-setup.sh \
    file://can-setup.service \
"

S = "${WORKDIR}"

inherit systemd

SYSTEMD_SERVICE:${PN} = "can-setup.service"
SYSTEMD_AUTO_ENABLE:${PN} = "enable"

do_install() {
    # Install setup script
    install -d ${D}${sbindir}
    install -m 0755 ${WORKDIR}/can-setup.sh ${D}${sbindir}/can-setup.sh
    
    # Install systemd service
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/can-setup.service ${D}${systemd_system_unitdir}/
}

FILES:${PN} = " \
    ${sbindir}/can-setup.sh \
    ${systemd_system_unitdir}/can-setup.service \
"

RDEPENDS:${PN} = "bash iproute2"
