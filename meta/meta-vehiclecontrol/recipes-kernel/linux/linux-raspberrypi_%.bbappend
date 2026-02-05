FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += "file://bluetooth.cfg"
SRC_URI += "file://spi-can.cfg"
SRC_URI += "file://camera.cfg"

# Force CAN and Camera configuration directly in do_configure
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

    # Add Camera drivers for OV5647 (RPi Camera v1.3)
    echo "" >> ${B}/.config
    echo "# Camera drivers for OV5647" >> ${B}/.config
    echo "CONFIG_MEDIA_SUPPORT=y" >> ${B}/.config
    echo "CONFIG_MEDIA_CAMERA_SUPPORT=y" >> ${B}/.config
    echo "CONFIG_VIDEO_DEV=y" >> ${B}/.config
    echo "CONFIG_VIDEO_V4L2=y" >> ${B}/.config
    echo "CONFIG_VIDEO_V4L2_SUBDEV_API=y" >> ${B}/.config
    echo "CONFIG_VIDEO_OV5647=m" >> ${B}/.config
    echo "CONFIG_VIDEO_BCM2835_UNICAM=m" >> ${B}/.config
    echo "CONFIG_MEDIA_CONTROLLER=y" >> ${B}/.config

    # Reprocess config
    oe_runmake -C ${S} O=${B} olddefconfig
}

