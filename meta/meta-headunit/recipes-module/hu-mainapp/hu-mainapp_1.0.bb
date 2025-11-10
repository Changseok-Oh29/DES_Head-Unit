SUMMARY = "Head Unit Main Application - Wayland Compositor"
DESCRIPTION = "Qt5-based Wayland compositor for Head Unit automotive infotainment system"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

DEPENDS = "qtbase qtdeclarative qtquickcontrols2"

# Use external source directory for local development
SRC_URI = "file://hu-mainapp-compositor.service"
EXTERNALSRC = "/home/seame/HU/chang_new/DES_Head-Unit/app/HU_MainApp"
EXTERNALSRC_BUILD = "${EXTERNALSRC}/build"

inherit cmake_qt5 systemd externalsrc

# Qt5 specific settings
EXTRA_OECMAKE += "-DQT_QMAKE_EXECUTABLE=${STAGING_BINDIR_NATIVE}/qmake"

# Systemd service configuration
SYSTEMD_SERVICE:${PN} = "hu-mainapp-compositor.service"
SYSTEMD_AUTO_ENABLE = "enable"

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${B}/HU_MainApp_Compositor ${D}${bindir}/HU_MainApp_Compositor

    # Install systemd service file
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/hu-mainapp-compositor.service ${D}${systemd_system_unitdir}/
}

FILES:${PN} = "${bindir}/HU_MainApp_Compositor ${systemd_system_unitdir}/hu-mainapp-compositor.service"

RDEPENDS:${PN} = "qtbase qtdeclarative qtquickcontrols2 qtwayland systemd"
