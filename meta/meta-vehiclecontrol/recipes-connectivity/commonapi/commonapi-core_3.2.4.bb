SUMMARY = "CommonAPI C++ Core Runtime"
DESCRIPTION = "CommonAPI C++ runtime library providing language bindings for Franca IDL"
HOMEPAGE = "https://github.com/COVESA/capicxx-core-runtime"
SECTION = "libs"
LICENSE = "MPL-2.0"
LIC_FILES_CHKSUM = "file://LICENSE;md5=815ca599c9df247a0c7f619bab123dad"

SRC_URI = "git://github.com/COVESA/capicxx-core-runtime.git;protocol=https;branch=master;tag=3.2.4"
SRCREV = "${AUTOREV}"
PV = "3.2.4"

S = "${WORKDIR}/git"

inherit cmake pkgconfig

EXTRA_OECMAKE = " \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
"

FILES_${PN} = "${libdir}/libCommonAPI.so.*"

FILES_${PN}-dev = " \
    ${includedir} \
    ${libdir}/libCommonAPI.so \
    ${libdir}/pkgconfig \
    ${libdir}/cmake \
"

BBCLASSEXTEND = "native nativesdk"
