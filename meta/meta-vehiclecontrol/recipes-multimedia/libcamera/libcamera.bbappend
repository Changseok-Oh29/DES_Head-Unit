# Fix libcamera for Raspberry Pi Camera Module v1.3 (OV5647)
#
# Root cause: The base libcamera recipe uses -Dipas=vimc which only builds
# a virtual camera IPA module for testing. This causes the error:
#   "No IPA found in '/usr/lib/libcamera'"
#   "Failed to load a suitable IPA library"
#
# Solution:
# 1. Build Raspberry Pi IPA module (raspberrypi) instead of vimc
# 2. Package IPA .so files into /usr/lib/libcamera/

# Enable Raspberry Pi pipeline (meta-raspberrypi already does this, but be explicit)
PACKAGECONFIG[raspberrypi] = "-Dpipelines=raspberrypi,-Dpipelines=uvcvideo,,"
PACKAGECONFIG:append:rpi = " raspberrypi"

# CRITICAL FIX: Build Raspberry Pi IPA instead of vimc
# Remove vimc IPA and add Raspberry Pi IPA for OV5647 camera support
# Valid IPA options: ipu3, raspberrypi, rkisp1, vimc
EXTRA_OEMESON:remove:rpi = "-Dipas=vimc"
EXTRA_OEMESON:append:rpi = " -Dipas=raspberrypi"

# CRITICAL FIX: Package IPA modules into the final image
# The base recipe builds IPA modules but doesn't include them in FILES
# IPA modules must be in /usr/lib/libcamera/ for libcamera to find them
FILES:${PN} += "${libdir}/libcamera/*.so"
FILES:${PN} += "${libdir}/libcamera/*.so.sign"
FILES:${PN} += "${libexecdir}/libcamera/*"
