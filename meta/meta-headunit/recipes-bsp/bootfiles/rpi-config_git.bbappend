# Enable Raspberry Pi 4 audio jack (3.5mm headphone output)

do_deploy:append:raspberrypi4-64() {
    # Enable the PWM audio (3.5mm jack) for Raspberry Pi 4
    echo "# Enable audio (loads snd_bcm2835)" >> ${DEPLOYDIR}/${BOOTFILES_DIR_NAME}/config.txt
    echo "dtparam=audio=on" >> ${DEPLOYDIR}/${BOOTFILES_DIR_NAME}/config.txt
}
