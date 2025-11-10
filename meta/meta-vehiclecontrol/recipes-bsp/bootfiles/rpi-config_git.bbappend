do_deploy_append_raspberrypi4-64() {
    # Enable I2C for VehicleControl ECU hardware
    echo "" >> ${DEPLOYDIR}/${BOOTFILES_DIR_NAME}/config.txt
    echo "# VehicleControl ECU - Enable I2C" >> ${DEPLOYDIR}/${BOOTFILES_DIR_NAME}/config.txt
    echo "dtparam=i2c_arm=on" >> ${DEPLOYDIR}/${BOOTFILES_DIR_NAME}/config.txt
    echo "dtparam=i2c1=on" >> ${DEPLOYDIR}/${BOOTFILES_DIR_NAME}/config.txt
    echo "dtparam=i2c_arm_baudrate=400000" >> ${DEPLOYDIR}/${BOOTFILES_DIR_NAME}/config.txt
    
    # Enable GPIO access
    echo "" >> ${DEPLOYDIR}/${BOOTFILES_DIR_NAME}/config.txt
    echo "# GPIO configuration" >> ${DEPLOYDIR}/${BOOTFILES_DIR_NAME}/config.txt
    echo "gpio=2-27=a0" >> ${DEPLOYDIR}/${BOOTFILES_DIR_NAME}/config.txt
}
