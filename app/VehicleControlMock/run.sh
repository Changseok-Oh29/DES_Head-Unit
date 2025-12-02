#!/bin/bash

# VehicleControlMock run script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

echo "=========================================="
echo "Starting VehicleControlMock Service"
echo "=========================================="

# Set library path
export LD_LIBRARY_PATH="${PROJECT_ROOT}/install_folder/lib:$LD_LIBRARY_PATH"

# Set vSOME/IP configuration
export VSOMEIP_CONFIGURATION="${SCRIPT_DIR}/config/vsomeip_mock.json"

# Set CommonAPI configuration
export COMMONAPI_CONFIG="${PROJECT_ROOT}/app/GearApp/commonapi.ini"

echo "Library Path: ${LD_LIBRARY_PATH}"
echo "vSOME/IP Config: ${VSOMEIP_CONFIGURATION}"
echo "CommonAPI Config: ${COMMONAPI_CONFIG}"
echo ""

# Run the service
cd "${SCRIPT_DIR}/build"
./VehicleControlMock
