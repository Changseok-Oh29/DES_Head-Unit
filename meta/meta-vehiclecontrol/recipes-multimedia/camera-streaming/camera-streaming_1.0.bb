SUMMARY = "Camera streaming service"
DESCRIPTION = "Systemd service to stream OV5647 camera via GStreamer RTP/UDP to Jetson Orin Nano"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = " \
    file://camera-streaming.service \
    file://camera-streaming.sh \
"

S = "${WORKDIR}"

inherit systemd

SYSTEMD_SERVICE:${PN} = "camera-streaming.service"
SYSTEMD_AUTO_ENABLE:${PN} = "enable"

RDEPENDS:${PN} = " \
    bash \
    gstreamer1.0 \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-ugly \
    libcamera \
    libcamera-gst \
"

do_install() {
    # Install systemd service
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/camera-streaming.service ${D}${systemd_system_unitdir}/

    # Install streaming script
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/camera-streaming.sh ${D}${bindir}/
}

FILES:${PN} = " \
    ${systemd_system_unitdir}/camera-streaming.service \
    ${bindir}/camera-streaming.sh \
"
