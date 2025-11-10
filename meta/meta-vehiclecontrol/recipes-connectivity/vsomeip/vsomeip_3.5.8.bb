SUMMARY = "vsomeip - SOME/IP implementation"
DESCRIPTION = "Implementation of Scalable service-Oriented MiddlewarE over IP (SOME/IP)"
HOMEPAGE = "https://github.com/COVESA/vsomeip"
SECTION = "libs/network"
LICENSE = "MPL-2.0"
LIC_FILES_CHKSUM = "file://LICENSE;md5=9741c346eef56131163e13b9db1241b3"

DEPENDS = "boost"

# Use release tag for stable builds
SRC_URI = "git://github.com/COVESA/vsomeip.git;protocol=https;branch=master;tag=3.5.8"
SRCREV = "${AUTOREV}"
PV = "3.5.8"

S = "${WORKDIR}/git"

inherit cmake pkgconfig

EXTRA_OECMAKE = " \
    -DENABLE_SIGNAL_HANDLING=ON \
    -DDIAGNOSIS_ADDRESS=0x10 \
"

# Package split for better modularity
PACKAGES =+ "${PN}-tools ${PN}-examples"

FILES_${PN} = " \
    ${libdir}/libvsomeip3*.so.* \
"

FILES_${PN}-dev = " \
    ${includedir} \
    ${libdir}/libvsomeip3*.so \
    ${libdir}/pkgconfig \
    ${libdir}/cmake \
"

FILES_${PN}-tools = " \
    ${bindir}/routingmanagerd \
"

FILES_${PN}-examples = " \
    ${datadir}/vsomeip \
"

RDEPENDS_${PN} = "boost-system boost-thread boost-filesystem boost-log"

BBCLASSEXTEND = "native nativesdk"
