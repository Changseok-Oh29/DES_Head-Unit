SUMMARY = "CommonAPI C++ SomeIP Runtime"
DESCRIPTION = "CommonAPI C++ SOME/IP binding runtime library"
HOMEPAGE = "https://github.com/COVESA/capicxx-someip-runtime"
SECTION = "libs"
LICENSE = "MPL-2.0"
LIC_FILES_CHKSUM = "file://LICENSE;md5=815ca599c9df247a0c7f619bab123dad"

DEPENDS = "commonapi-core vsomeip boost"

SRC_URI = "git://github.com/COVESA/capicxx-someip-runtime.git;protocol=https;branch=master"
SRCREV = "86dfd69802e673d00aed0062f41eddea4670b571"
PV = "3.2.4+git${SRCPV}"

S = "${WORKDIR}/git"

inherit cmake pkgconfig

EXTRA_OECMAKE = " \
    -DUSE_INSTALLED_COMMONAPI=ON \
    -DUSE_INSTALLED_VSOMEIP=ON \
"

FILES:${PN} = "${libdir}/libCommonAPI-SomeIP.so.*"

FILES:${PN}-dev = " \
    ${includedir} \
    ${libdir}/libCommonAPI-SomeIP.so \
    ${libdir}/pkgconfig \
    ${libdir}/cmake \
"

RDEPENDS:${PN} = "commonapi-core vsomeip"

BBCLASSEXTEND = "native nativesdk"
