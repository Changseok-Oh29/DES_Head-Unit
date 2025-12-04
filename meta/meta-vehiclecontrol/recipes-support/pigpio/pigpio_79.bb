SUMMARY = "pigpio library - Raspberry Pi GPIO control"
DESCRIPTION = "C library for Raspberry Pi GPIO control with PWM, Servo, and I2C support"
HOMEPAGE = "http://abyz.me.uk/rpi/pigpio/"
SECTION = "libs"
LICENSE = "Unlicense"
LIC_FILES_CHKSUM = "file://UNLICENCE;md5=61287f92700ec1bdf13bc86d8228cd13"

SRC_URI = " \
    https://github.com/joan2937/pigpio/archive/v${PV}.tar.gz;downloadfilename=pigpio-${PV}.tar.gz \
"
SRC_URI[sha256sum] = "c5337c0b7ae888caf0262a6f476af0e2ab67065f7650148a0b21900b8d1eaed7"

S = "${WORKDIR}/pigpio-${PV}"

inherit pkgconfig

# Ensure cross-compilation with correct compiler and flags
EXTRA_OEMAKE = " \
    'CC=${CC}' \
    'AR=${AR}' \
    'RANLIB=${RANLIB}' \
    'STRIP=${STRIP}' \
    'CFLAGS=${CFLAGS} -fPIC' \
    'LDFLAGS=${LDFLAGS}' \
    'PREFIX=${prefix}' \
"

# pigpio uses plain Makefile
do_compile() {
    oe_runmake ${EXTRA_OEMAKE}
}

do_install() {
    oe_runmake DESTDIR=${D} PREFIX=${prefix} install ${EXTRA_OEMAKE}
    
    # pigpio ignores PREFIX and installs to /usr/local
    # Move everything from /usr/local to /usr
    if [ -d "${D}${prefix}/local/include" ]; then
        install -d ${D}${includedir}
        cp -r ${D}${prefix}/local/include/* ${D}${includedir}/
    fi
    
    if [ -d "${D}${prefix}/local/lib" ]; then
        install -d ${D}${libdir}
        cp -r ${D}${prefix}/local/lib/* ${D}${libdir}/
    fi
    
    if [ -d "${D}${prefix}/local/bin" ]; then
        install -d ${D}${bindir}
        cp -r ${D}${prefix}/local/bin/* ${D}${bindir}/
    fi
    
    # Remove unwanted directories
    rm -rf ${D}/opt
    rm -rf ${D}${prefix}/local
    rm -rf ${D}${prefix}/man
}

# Package split
PACKAGES =+ "${PN}-daemon ${PN}-utils ${PN}-python"

FILES:${PN} = "${libdir}/libpigpio.so.* ${libdir}/libpigpiod_if*.so.*"
FILES:${PN}-dev = "${includedir} ${libdir}/*.so"
FILES:${PN}-daemon = "${bindir}/pigpiod"
FILES:${PN}-utils = "${bindir}/pig2vcd ${bindir}/pigs"
FILES:${PN}-python = "${libdir}/python*"

# pigpio requires GPIO access
RDEPENDS:${PN} = ""
RRECOMMENDS:${PN} = "kernel-module-i2c-dev"

# Skip QA checks for already-stripped binaries and ldflags
INSANE_SKIP:${PN} += "already-stripped ldflags"
INSANE_SKIP:${PN}-daemon += "already-stripped ldflags"
INSANE_SKIP:${PN}-utils += "already-stripped ldflags"
