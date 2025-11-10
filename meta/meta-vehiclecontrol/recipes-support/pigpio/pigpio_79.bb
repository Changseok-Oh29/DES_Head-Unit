SUMMARY = "pigpio library - Raspberry Pi GPIO control"
DESCRIPTION = "C library for Raspberry Pi GPIO control with PWM, Servo, and I2C support"
HOMEPAGE = "http://abyz.me.uk/rpi/pigpio/"
SECTION = "libs"
LICENSE = "Unlicense"
LIC_FILES_CHKSUM = "file://UNLICENCE;md5=8891796b47eb8786038b3164db03111a"

SRC_URI = " \
    https://github.com/joan2937/pigpio/archive/v${PV}.tar.gz;downloadfilename=pigpio-${PV}.tar.gz \
"
SRC_URI[sha256sum] = "cb9b8df9f32a9697a7b4b0c39e4c0e03aa5f467d63846a46359b1c348dbdfb99"

S = "${WORKDIR}/pigpio-${PV}"

# pigpio uses plain Makefile
do_compile() {
    oe_runmake
}

do_install() {
    oe_runmake DESTDIR=${D} prefix=${prefix} install
}

# Package split
PACKAGES =+ "${PN}-daemon ${PN}-utils"

FILES_${PN} = "${libdir}/libpigpio.so.* ${libdir}/libpigpiod_if*.so.*"
FILES_${PN}-dev = "${includedir} ${libdir}/*.so"
FILES_${PN}-daemon = "${bindir}/pigpiod"
FILES_${PN}-utils = "${bindir}/pig2vcd ${bindir}/pigs"

# pigpio requires GPIO access
RDEPENDS_${PN} = "kernel-module-i2c-dev"
