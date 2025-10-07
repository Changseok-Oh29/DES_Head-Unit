SUMMARY = "Head Unit Linux Image"
DESCRIPTION = "Custom Linux image for Raspberry Pi with Head Unit application"

IMAGE_INSTALL = "packagegroup-core-boot ${CORE_IMAGE_EXTRA_INSTALL}"

IMAGE_INSTALL += " \
    packagegroup-core-x11 \
    packagegroup-qt5-toolchain-target \
    qtbase \
    qtdeclarative \
    qtquickcontrols2 \
    headunit-app \
    usbutils \
    alsa-utils \
    pulseaudio \
    pulseaudio-server \
    kernel-modules \
    openssh \
    bash \
    coreutils \
"

# Set a rootfs password for development
set_root_passwd() {
    usermod -P raspberry root
}
ROOTFS_POSTPROCESS_COMMAND += "set_root_passwd; "

# Image features
IMAGE_FEATURES += "debug-tweaks ssh-server-openssh x11-base"

# Inherit from core-image
inherit core-image

# Set image size (in KB)
IMAGE_ROOTFS_SIZE ?= "1048576"
