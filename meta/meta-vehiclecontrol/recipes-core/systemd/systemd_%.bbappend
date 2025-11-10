FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += "file://10-eth0.network"

do_install_append() {
    install -d ${D}${sysconfdir}/systemd/network
    install -m 0644 ${WORKDIR}/10-eth0.network ${D}${sysconfdir}/systemd/network/
}

FILES_${PN} += "${sysconfdir}/systemd/network/"
