# Enable UART globally for bluetooth (선배 기수 방식 참고)
ENABLE_UART = "1"

do_deploy:append:raspberrypi4-64() {
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
    
    # Enable Bluetooth UART (mini UART for BT on RPi4)
    echo "" >> ${DEPLOYDIR}/${BOOTFILES_DIR_NAME}/config.txt
    echo "# Bluetooth configuration" >> ${DEPLOYDIR}/${BOOTFILES_DIR_NAME}/config.txt
    echo "dtoverlay=pi3-miniuart-bt" >> ${DEPLOYDIR}/${BOOTFILES_DIR_NAME}/config.txt
    echo "enable_uart=1" >> ${DEPLOYDIR}/${BOOTFILES_DIR_NAME}/config.txt
    
    # ========================================
    # Waveshare 2-CH CAN FD HAT (MCP2518FD)
    # ========================================
    echo "" >> ${DEPLOYDIR}/${BOOTFILES_DIR_NAME}/config.txt
    echo "# VehicleControl ECU CAN Configuration" >> ${DEPLOYDIR}/${BOOTFILES_DIR_NAME}/config.txt
    echo "# Waveshare 2-CH CAN FD HAT (MCP2518FD)" >> ${DEPLOYDIR}/${BOOTFILES_DIR_NAME}/config.txt
    echo "dtparam=spi=on" >> ${DEPLOYDIR}/${BOOTFILES_DIR_NAME}/config.txt
    echo "dtoverlay=spi1-3cs" >> ${DEPLOYDIR}/${BOOTFILES_DIR_NAME}/config.txt
    echo "dtoverlay=mcp251xfd,spi0-0,interrupt=25" >> ${DEPLOYDIR}/${BOOTFILES_DIR_NAME}/config.txt
    echo "dtoverlay=mcp251xfd,spi1-0,interrupt=24" >> ${DEPLOYDIR}/${BOOTFILES_DIR_NAME}/config.txt

    # ========================================
    # Camera Configuration (Reverse Camera)
    # Camera Module v1.3 (OV5647)
    # ========================================
    echo "" >> ${DEPLOYDIR}/${BOOTFILES_DIR_NAME}/config.txt
    echo "# Reverse Camera Configuration - Camera Module v1.3 (OV5647)" >> ${DEPLOYDIR}/${BOOTFILES_DIR_NAME}/config.txt
    echo "# Enable camera with libcamera stack" >> ${DEPLOYDIR}/${BOOTFILES_DIR_NAME}/config.txt
    echo "camera_auto_detect=1" >> ${DEPLOYDIR}/${BOOTFILES_DIR_NAME}/config.txt
    echo "dtoverlay=ov5647" >> ${DEPLOYDIR}/${BOOTFILES_DIR_NAME}/config.txt
    echo "start_x=1" >> ${DEPLOYDIR}/${BOOTFILES_DIR_NAME}/config.txt
    echo "gpu_mem=128" >> ${DEPLOYDIR}/${BOOTFILES_DIR_NAME}/config.txt
}
