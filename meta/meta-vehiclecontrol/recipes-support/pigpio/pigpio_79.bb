SUMMARY = "pigpio library - Raspberry Pi GPIO control"
DESCRIPTION = "C library for Raspberry Pi GPIO control with PWM, Servo, and I2C support"
HOMEPAGE = "http://abyz.me.uk/rpi/pigpio/"
SECTION = "libs"
LICENSE = "Unlicense"
LIC_FILES_CHKSUM = "file://UNLICENCE;md5=8891796b47eb8786038b3164db03111a"

SRC_URI = " \
    https://github.com/joan2937/pigpio/archive/v${PV}.tar.gz;downloadfilename=pigpio-${PV}.tar.gz \
"
SRC_URI[sha256sum] = "c5337c0b7ae888caf0262a6f476af0e2ab67065f7650148a0b21900b8d1eaed7"

S = "${WORKDIR}/pigpio-${PV}"

# pigpio uses plain Makefile
do_compile() {
    oe_runmake
}

do_install() {
    oe_runmake DESTDIR=${D} prefix=${prefix} install
    
    # Remove unwanted files
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
RDEPENDS:${PN} = "kernel-module-i2c-dev"

# Skip QA checks for already-stripped binaries
INSANE_SKIP:${PN} += "already-stripped"
INSANE_SKIP:${PN}-daemon += "already-stripped"
INSANE_SKIP:${PN}-utils += "already-stripped"
