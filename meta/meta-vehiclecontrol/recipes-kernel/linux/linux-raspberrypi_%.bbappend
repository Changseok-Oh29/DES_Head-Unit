FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += "file://bluetooth.cfg"

# Enable bluetooth features
KERNEL_FEATURES:append = " features/bluetooth/bluetooth.scc"
