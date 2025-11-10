SUMMARY = "vSomeIP Configuration Files"
DESCRIPTION = "CommonAPI and vSomeIP configuration files for Head Unit applications"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

# Use external source directory
EXTERNALSRC = "/home/seame/HU/chang_new/DES_Head-Unit/app"

inherit externalsrc

do_install() {
    # Create configuration directories
    install -d ${D}${sysconfdir}/vsomeip
    install -d ${D}${sysconfdir}/commonapi
    install -d ${D}${bindir}

    # Install routing manager configuration (shared)
    install -m 0644 ${EXTERNALSRC}/config/routing_manager_ecu2.json ${D}${sysconfdir}/vsomeip/

    # Install startup scripts
    install -m 0755 ${EXTERNALSRC}/config/start_all_ecu2.sh ${D}${bindir}/
    install -m 0755 ${EXTERNALSRC}/config/start_all_ecu2_simple.sh ${D}${bindir}/
    install -m 0755 ${EXTERNALSRC}/config/start_ecu1.sh ${D}${bindir}/
    install -m 0755 ${EXTERNALSRC}/config/start_routing_manager_ecu2.sh ${D}${bindir}/

    # Install per-application vsomeip JSON files
    install -m 0644 ${EXTERNALSRC}/AmbientApp/vsomeip_ambient.json ${D}${sysconfdir}/vsomeip/
    install -m 0644 ${EXTERNALSRC}/GearApp/config/vsomeip_ecu2.json ${D}${sysconfdir}/vsomeip/
    install -m 0644 ${EXTERNALSRC}/MediaApp/vsomeip.json ${D}${sysconfdir}/vsomeip/vsomeip_media.json
    install -m 0644 ${EXTERNALSRC}/IC_app/vsomeip_ic.json ${D}${sysconfdir}/vsomeip/
    install -m 0644 ${EXTERNALSRC}/HU_MainApp/vsomeip.json ${D}${sysconfdir}/vsomeip/vsomeip_mainapp.json

    # Install per-application CommonAPI ini files
    install -m 0644 ${EXTERNALSRC}/AmbientApp/commonapi.ini ${D}${sysconfdir}/commonapi/commonapi_ambient.ini
    install -m 0644 ${EXTERNALSRC}/GearApp/config/commonapi_ecu2.ini ${D}${sysconfdir}/commonapi/
    install -m 0644 ${EXTERNALSRC}/MediaApp/commonapi.ini ${D}${sysconfdir}/commonapi/commonapi_media.ini
    install -m 0644 ${EXTERNALSRC}/IC_app/commonapi.ini ${D}${sysconfdir}/commonapi/commonapi_ic.ini
    install -m 0644 ${EXTERNALSRC}/HU_MainApp/commonapi.ini ${D}${sysconfdir}/commonapi/commonapi_mainapp.ini
}

FILES:${PN} = " \
    ${sysconfdir}/vsomeip/* \
    ${sysconfdir}/commonapi/* \
    ${bindir}/start_all_ecu2.sh \
    ${bindir}/start_all_ecu2_simple.sh \
    ${bindir}/start_ecu1.sh \
    ${bindir}/start_routing_manager_ecu2.sh \
"

RDEPENDS:${PN} = "vsomeip commonapi-core commonapi-someip-runtime bash"
