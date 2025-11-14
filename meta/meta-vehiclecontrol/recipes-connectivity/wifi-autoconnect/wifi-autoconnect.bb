SUMMARY = "WiFi Auto Connect Service"
DESCRIPTION = "Automatically connect to WiFi on boot"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://wifi-autoconnect.service"

S = "${WORKDIR}"

inherit systemd

SYSTEMD_SERVICE:${PN} = "wifi-autoconnect.service"
SYSTEMD_AUTO_ENABLE = "enable"

do_install() {
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/wifi-autoconnect.service ${D}${systemd_system_unitdir}/
}

FILES:${PN} += "${systemd_system_unitdir}/wifi-autoconnect.service"

RDEPENDS:${PN} = "wpa-supplicant dhcpcd"
