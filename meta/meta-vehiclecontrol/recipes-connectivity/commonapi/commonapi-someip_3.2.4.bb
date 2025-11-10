SUMMARY = "CommonAPI C++ SomeIP Runtime"
DESCRIPTION = "CommonAPI C++ SOME/IP binding runtime library"
HOMEPAGE = "https://github.com/COVESA/capicxx-someip-runtime"
SECTION = "libs"
LICENSE = "MPL-2.0"
LIC_FILES_CHKSUM = "file://LICENSE;md5=815ca599c9df247a0c7f619bab123dad"

DEPENDS = "commonapi-core vsomeip boost"

SRC_URI = "git://github.com/COVESA/capicxx-someip-runtime.git;protocol=https;branch=master;tag=3.2.4"
SRCREV = "${AUTOREV}"
PV = "3.2.4"

S = "${WORKDIR}/git"

inherit cmake pkgconfig

EXTRA_OECMAKE = " \
    -DUSE_INSTALLED_COMMONAPI=ON \
    -DUSE_INSTALLED_VSOMEIP=ON \
"

FILES_${PN} = "${libdir}/libCommonAPI-SomeIP.so.*"

FILES_${PN}-dev = " \
    ${includedir} \
    ${libdir}/libCommonAPI-SomeIP.so \
    ${libdir}/pkgconfig \
    ${libdir}/cmake \
"

RDEPENDS_${PN} = "commonapi-core vsomeip"

BBCLASSEXTEND = "native nativesdk"
