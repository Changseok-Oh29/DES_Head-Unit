SUMMARY = "Raspberry Pi config.txt modifications for VehicleControl ECU"
DESCRIPTION = "Enables MCP2515 SPI CAN controller via device tree overlay"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

COMPATIBLE_MACHINE = "^rpi$"

# This modifies the bootloader configuration
inherit deploy

SRC_URI = "file://config.txt.append"

S = "${WORKDIR}"

do_deploy() {
    # Install config.txt fragment
    install -d ${DEPLOYDIR}/bcm2835-bootfiles
    install -m 0644 ${WORKDIR}/config.txt.append ${DEPLOYDIR}/bcm2835-bootfiles/
}

addtask deploy before do_build after do_install
