SUMMARY = "CAN interface setup service"
DESCRIPTION = "Systemd service to configure CAN interface on boot"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = " \
    file://can-setup.service \
    file://setup-can.sh \
"

S = "${WORKDIR}"

inherit systemd

SYSTEMD_SERVICE:${PN} = "can-setup.service"
SYSTEMD_AUTO_ENABLE:${PN} = "enable"

# CAN support is built into kernel, not as modules
RDEPENDS:${PN} = "bash iproute2"

do_install() {
    # Install systemd service
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/can-setup.service ${D}${systemd_system_unitdir}/
    
    # Install setup script
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/setup-can.sh ${D}${bindir}/
}

FILES:${PN} = " \
    ${systemd_system_unitdir}/can-setup.service \
    ${bindir}/setup-can.sh \
"
