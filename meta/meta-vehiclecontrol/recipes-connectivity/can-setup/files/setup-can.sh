#!/bin/bash
# CAN interface setup script for VehicleControl ECU

# CAN modules are built-in to kernel, no need to modprobe

# Wait for CAN interface to appear (up to 5 seconds)
for i in {1..10}; do
    if ip link show can0 &>/dev/null; then
        echo "Found CAN interface can0"
        break
    fi
    echo "Waiting for can0... ($i/10)"
    sleep 0.5
done

# Check if can0 exists (physical CAN interface)
if ip link show can0 &>/dev/null; then
    echo "Setting up physical CAN interface can0..."
    # CRITICAL: Use 1000kbps to match Arduino MCP2515 setting (CAN_1000KBPS)
    ip link set can0 type can bitrate 1000000
    ip link set can0 up
    echo "✅ can0 is up at 1000kbps (matches Arduino CAN_1000KBPS)"
else
    echo "❌ Physical CAN interface can0 not found!"
    echo "Please check:"
    echo "  1. MCP2518FD module is connected to SPI"
    echo "  2. Device tree overlay is enabled in /boot/config.txt"
    echo "  3. Kernel modules: lsmod | grep can"
    exit 1
fi

exit 0
