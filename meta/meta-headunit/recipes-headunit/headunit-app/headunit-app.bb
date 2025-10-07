SUMMARY = "Head Unit Application"
DESCRIPTION = "Qt5-based Head Unit application for automotive infotainment system"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

DEPENDS = "qtbase qtdeclarative qtquickcontrols2"

# Source from local directory - in production this would be a git repository
SRC_URI = "file://../../../app/HU_app"
S = "${WORKDIR}/HU_app"

# Inherit cmake class for building
inherit cmake_qt5

# Qt5 specific settings
EXTRA_OECMAKE += "-DQT_QMAKE_EXECUTABLE=${STAGING_BINDIR_NATIVE}/qmake"

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${B}/HU_app ${D}${bindir}/
    
    # Install desktop file for autostart
    install -d ${D}${sysconfdir}/xdg/autostart
    install -m 0644 ${WORKDIR}/headunit.desktop ${D}${sysconfdir}/xdg/autostart/
}

# Desktop file for autostart
SRC_URI += "file://headunit.desktop"

FILES:${PN} += "${bindir}/HU_app ${sysconfdir}/xdg/autostart/headunit.desktop"

RDEPENDS:${PN} = "qtbase qtdeclarative qtquickcontrols2"
