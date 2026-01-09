# ============================================================================
# USB XHCI Fix for Raspberry Pi 4
# ============================================================================
# Fix USB XHCI boot hang issue by disabling USB autosuspend
# This prevents "BUG at drivers/usb/host/xhci-ring.c" errors during boot
# when USB devices (CAN adapter, keyboard, mouse) are connected

# Add USB autosuspend disable parameter to kernel command line
CMDLINE:append:raspberrypi4-64 = " usbcore.autosuspend=-1"
