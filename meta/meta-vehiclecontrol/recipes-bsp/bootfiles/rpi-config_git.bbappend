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
    # MCP2518FD CAN Controller (Team2 방식)
    # ========================================
    # 중요: ENABLE_CAN=1은 MCP2515용이므로 사용하지 않음
    # 대신 meta-raspberrypi의 built-in mcp251xfd overlay 사용
    echo "" >> ${DEPLOYDIR}/${BOOTFILES_DIR_NAME}/config.txt
    echo "# MCP2518FD CAN Controller" >> ${DEPLOYDIR}/${BOOTFILES_DIR_NAME}/config.txt
    echo "dtoverlay=mcp251xfd,spi0-0,interrupt=25,oscillator=40000000" >> ${DEPLOYDIR}/${BOOTFILES_DIR_NAME}/config.txt
}
