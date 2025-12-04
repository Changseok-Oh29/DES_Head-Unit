SUMMARY = "CommonAPI C++ Core Runtime"
DESCRIPTION = "CommonAPI C++ runtime library providing language bindings for Franca IDL"
HOMEPAGE = "https://github.com/COVESA/capicxx-core-runtime"
SECTION = "libs"
LICENSE = "MPL-2.0"
LIC_FILES_CHKSUM = "file://LICENSE;md5=815ca599c9df247a0c7f619bab123dad"

SRC_URI = "git://github.com/COVESA/capicxx-core-runtime.git;protocol=https;branch=master"
SRCREV = "0e1d97ef0264622194a42f20be1d6b4489b310b5"
PV = "3.2.4+git${SRCPV}"

S = "${WORKDIR}/git"

inherit cmake pkgconfig

EXTRA_OECMAKE = " \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
"

FILES:${PN} = "${libdir}/libCommonAPI.so.*"

FILES:${PN}-dev = " \
    ${includedir} \
    ${libdir}/libCommonAPI.so \
    ${libdir}/pkgconfig \
    ${libdir}/cmake \
"

BBCLASSEXTEND = "native nativesdk"
