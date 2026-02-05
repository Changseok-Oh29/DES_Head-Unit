# Deploy device tree overlays from rpi-bootfiles firmware
# Deploy to DEPLOYDIR root so IMAGE_BOOT_FILES can find them

FILESEXTRAPATHS:prepend := "${THISDIR}:"

do_deploy:append() {
    # Deploy mcp251xfd.dtbo for CAN
    if [ -f ${S}/overlays/mcp251xfd.dtbo ]; then
        install -m 0644 ${S}/overlays/mcp251xfd.dtbo ${DEPLOYDIR}/
        bbnote "✅ Deployed mcp251xfd.dtbo"
    else
        bbwarn "❌ mcp251xfd.dtbo not found in ${S}/overlays/"
    fi

    # Deploy ov5647.dtbo for Camera Module v1.3
    if [ -f ${S}/overlays/ov5647.dtbo ]; then
        install -m 0644 ${S}/overlays/ov5647.dtbo ${DEPLOYDIR}/
        bbnote "✅ Deployed ov5647.dtbo"
    else
        bbwarn "❌ ov5647.dtbo not found in ${S}/overlays/"
    fi
}
