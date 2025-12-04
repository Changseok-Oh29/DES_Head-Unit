SUMMARY = "vsomeip - SOME/IP implementation"
DESCRIPTION = "Implementation of Scalable service-Oriented MiddlewarE over IP (SOME/IP)"
HOMEPAGE = "https://github.com/COVESA/vsomeip"
SECTION = "libs/network"
LICENSE = "MPL-2.0"
LIC_FILES_CHKSUM = "file://LICENSE;md5=9741c346eef56131163e13b9db1241b3"

DEPENDS = "boost"

# Use specific commit for stable 3.5.8 release
SRC_URI = "git://github.com/COVESA/vsomeip.git;protocol=https;branch=master"
SRCREV = "e89240c7d5d506505326987b6a2f848658230641"
PV = "3.5.8+git${SRCPV}"

S = "${WORKDIR}/git"

inherit cmake pkgconfig

EXTRA_OECMAKE = " \
    -DENABLE_SIGNAL_HANDLING=ON \
    -DDIAGNOSIS_ADDRESS=0x10 \
"

do_install:append() {
    # Move config files from /usr/etc to /etc
    if [ -d ${D}${prefix}/etc ]; then
        install -d ${D}${sysconfdir}
        mv ${D}${prefix}/etc/* ${D}${sysconfdir}/
        rm -rf ${D}${prefix}/etc
    fi
    
    # Remove empty bin directory if exists
    if [ -d ${D}${bindir} ] && [ -z "$(ls -A ${D}${bindir})" ]; then
        rmdir ${D}${bindir}
    fi
}

# Package split for better modularity
PACKAGES =+ "${PN}-tools ${PN}-examples"

FILES:${PN} = " \
    ${libdir}/libvsomeip3*.so.* \
    ${sysconfdir}/vsomeip \
    ${sysconfdir}/vsomeip/*.json \
"

FILES:${PN}-dev = " \
    ${includedir} \
    ${libdir}/libvsomeip3*.so \
    ${libdir}/pkgconfig \
    ${libdir}/cmake \
"

FILES:${PN}-tools = " \
    ${bindir}/* \
"

FILES:${PN}-examples = " \
    ${datadir}/vsomeip \
"

RDEPENDS:${PN} = "boost-system boost-thread boost-filesystem boost-log"

BBCLASSEXTEND = "native nativesdk"
