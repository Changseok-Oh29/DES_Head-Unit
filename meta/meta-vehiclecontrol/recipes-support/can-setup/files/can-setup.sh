#!/bin/bash
# CAN interface setup script for MCP2518FD

set -e

INTERFACE="can0"
BITRATE="1000000"

# Check if interface exists
if ! ip link show "$INTERFACE" &> /dev/null; then
    echo "⚠️  CAN interface $INTERFACE not found!"
    echo "   Check device tree overlay and kernel module"
    exit 1
fi

# Configure CAN interface
echo "🔧 Setting up $INTERFACE (bitrate: ${BITRATE}bps)..."

ip link set "$INTERFACE" down 2>/dev/null || true
ip link set "$INTERFACE" type can bitrate "$BITRATE"
ip link set "$INTERFACE" up

echo "✅ $INTERFACE is up and running"
ip -details link show "$INTERFACE"
