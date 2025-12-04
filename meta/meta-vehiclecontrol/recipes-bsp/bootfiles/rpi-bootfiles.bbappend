# Deploy mcp251xfd.dtbo from rpi-bootfiles firmware
# The file already exists in raspberrypi-firmware, we just need to deploy it

FILESEXTRAPATHS:prepend := "${THISDIR}:"

# Copy mcp251xfd.dtbo from firmware to deployment directory
do_deploy:append() {
    # The dtbo is in rpi-bootfiles source
    if [ -f ${S}/overlays/mcp251xfd.dtbo ]; then
        install -m 0644 ${S}/overlays/mcp251xfd.dtbo ${DEPLOYDIR}/
        bbnote "✅ Deployed mcp251xfd.dtbo from rpi-bootfiles firmware"
    else
        bbwarn "❌ mcp251xfd.dtbo not found in ${S}/overlays/"
    fi
}
