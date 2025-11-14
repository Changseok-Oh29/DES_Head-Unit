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
    can-setup \
    ${CORE_IMAGE_EXTRA_INSTALL} \
"

# Essential tools only (CAN + Bluetooth + WiFi)
IMAGE_INSTALL:append = " \
    vim \
    kmod \
    linux-firmware \
    linux-firmware-rpidistro-bcm43430 \
    linux-firmware-rpidistro-bcm43455 \
    pi-bluetooth \
    bluez5 \
    wpa-supplicant \
    dhcpcd \
    wifi-autoconnect \
    iw \
    wireless-regdb-static \
    kernel-module-joydev \
    kernel-module-hci-uart \
    kernel-module-btbcm \
    kernel-modules \
    can-utils \
    openssh \
    openssh-sftp-server \
"

# Image features
IMAGE_FEATURES += " \
    ssh-server-openssh \
    debug-tweaks \
    splash \
"

# Kernel features for Wi-Fi
KERNEL_FEATURES:append = " cfg/wifi.scc"

# Enable bluetooth hardware support
MACHINE_FEATURES:append = " bluetooth wifi"

# Use systemd as init manager
DISTRO_FEATURES:append = " systemd bluetooth wifi"
VIRTUAL-RUNTIME_init_manager = "systemd"
VIRTUAL-RUNTIME_initscripts = "systemd-compat-units"

# Set hostname
hostname_pn-base-files = "vehiclecontrol-ecu"

# Root password (development only)
EXTRA_IMAGE_FEATURES += "debug-tweaks"

# Note: debug-tweaks allows root login without password
# For production, remove debug-tweaks and set proper password using:
# inherit extrausers
# EXTRA_USERS_PARAMS = "usermod -p '\$6\$...' root;"
