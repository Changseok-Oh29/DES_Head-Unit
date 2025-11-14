FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += "file://bluetooth.cfg"
SRC_URI += "file://spi-can.cfg"

# Force CAN configuration directly in do_configure
do_configure:append() {
    # Add CAN drivers to .config
    echo "" >> ${B}/.config
    echo "# CAN drivers for MCP2518FD" >> ${B}/.config
    echo "CONFIG_CAN=y" >> ${B}/.config
    echo "CONFIG_CAN_DEV=y" >> ${B}/.config
    echo "CONFIG_CAN_RAW=y" >> ${B}/.config
    echo "CONFIG_CAN_MCP251X=m" >> ${B}/.config
    echo "CONFIG_CAN_MCP251XFD=m" >> ${B}/.config
    echo "CONFIG_CAN_MCP251XFD_SANITY=y" >> ${B}/.config
    
    # Reprocess config
    oe_runmake -C ${S} O=${B} olddefconfig
}

# Compile MCP2518FD Device Tree Overlay using kernel's DTC
do_compile:append() {
    if [ -f ${WORKDIR}/mcp2518fd-overlay.dts ]; then
        bbnote "Compiling MCP2518FD device tree overlay"
        ${B}/scripts/dtc/dtc -@ -I dts -O dtb -o ${WORKDIR}/mcp2518fd.dtbo ${WORKDIR}/mcp2518fd-overlay.dts || bbwarn "Failed to compile mcp2518fd overlay"
    fi
}

do_deploy:append() {
    if [ -f ${WORKDIR}/mcp2518fd.dtbo ]; then
        install -d ${DEPLOYDIR}/overlays
        install -m 0644 ${WORKDIR}/mcp2518fd.dtbo ${DEPLOYDIR}/overlays/
        bbnote "Installed mcp2518fd.dtbo to ${DEPLOYDIR}/overlays/"
    fi
}
