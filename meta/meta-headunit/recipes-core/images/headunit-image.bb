SUMMARY = "Head Unit Linux Image"
DESCRIPTION = "Custom Linux image for Raspberry Pi with Head Unit applications"

# Inherit all common headunit image configuration from custom class
inherit headunit-image

# Application-specific packages (built by this project)
IMAGE_INSTALL:append = " \
    hu-mainapp \
    ic-app \
    ambientapp \
    gearapp \
    mediaapp \
    vsomeip-config \
"
