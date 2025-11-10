SUMMARY = "VehicleControl ECU Minimal Image"
DESCRIPTION = "Lightweight Linux image for Raspberry Pi with VehicleControl ECU application"
LICENSE = "MIT"

inherit core-image

# Image file system types
IMAGE_FSTYPES = "tar.bz2 ext4 rpi-sdimg"

# Image size configuration (512MB root filesystem)
IMAGE_ROOTFS_SIZE ?= "524288"
IMAGE_ROOTFS_EXTRA_SPACE = "102400"

# Core packages
IMAGE_INSTALL = " \
    packagegroup-core-boot \
    packagegroup-vehiclecontrol \
    vehiclecontrol-ecu \
    ${CORE_IMAGE_EXTRA_INSTALL} \
"

# Development and debugging tools (optional, can be removed for production)
IMAGE_INSTALL_append = " \
    gdbserver \
    strace \
    tcpdump \
    vim \
    htop \
"

# Image features
IMAGE_FEATURES += " \
    ssh-server-openssh \
    debug-tweaks \
"

# Use systemd as init manager
DISTRO_FEATURES_append = " systemd"
VIRTUAL-RUNTIME_init_manager = "systemd"
VIRTUAL-RUNTIME_initscripts = "systemd-compat-units"

# Set hostname
hostname_pn-base-files = "vehiclecontrol-ecu"

# Root password (development only)
EXTRA_IMAGE_FEATURES += "debug-tweaks"

# User configuration
inherit extrausers
EXTRA_USERS_PARAMS = " \
    usermod -P raspberry root; \
"
