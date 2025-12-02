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

