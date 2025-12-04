SYSTEMD_AUTO_ENABLE:${PN}-sshd = "enable"

do_install:append() {
    # Root 로그인 허용
    sed -i 's/^#*PermitRootLogin.*/PermitRootLogin yes/' ${D}${sysconfdir}/ssh/sshd_config
    sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' ${D}${sysconfdir}/ssh/sshd_config
    sed -i 's/^#*PermitEmptyPasswords.*/PermitEmptyPasswords yes/' ${D}${sysconfdir}/ssh/sshd_config
}
