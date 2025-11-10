#!/bin/bash
# ECU1 (VehicleControl ECU) Yocto 빌드 환경 자동 설정 스크립트
# 
# 이 스크립트는 다음을 수행합니다:
# 1. Yocto Kirkstone 레이어 클론
# 2. 빌드 환경 초기화
# 3. 레이어 추가
# 4. local.conf 및 bblayers.conf 설정

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 경로 설정
YOCTO_BASE="${HOME}/yocto"
BUILD_DIR="build-ecu1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
META_VEHICLECONTROL="$(dirname "$SCRIPT_DIR")"

echo -e "${BLUE}=========================================="
echo "ECU1 Yocto Build Environment Setup"
echo -e "==========================================${NC}"
echo ""
echo "Yocto Base: ${YOCTO_BASE}"
echo "Build Dir:  ${BUILD_DIR}"
echo "Layer:      ${META_VEHICLECONTROL}"
echo ""

# Step 1: Yocto 레이어 클론 확인
echo -e "${YELLOW}[1/6] Checking Yocto layers...${NC}"

if [ ! -d "${YOCTO_BASE}" ]; then
    echo "Creating Yocto directory..."
    mkdir -p "${YOCTO_BASE}"
    cd "${YOCTO_BASE}"
    
    echo "Cloning Yocto Kirkstone layers (this may take 10-30 minutes)..."
    
    if [ ! -d "poky" ]; then
        echo "  → Cloning poky (Kirkstone)..."
        git clone -b kirkstone git://git.yoctoproject.org/poky
    fi
    
    if [ ! -d "meta-raspberrypi" ]; then
        echo "  → Cloning meta-raspberrypi (Kirkstone)..."
        git clone -b kirkstone https://github.com/agherzan/meta-raspberrypi.git
    fi
    
    if [ ! -d "meta-openembedded" ]; then
        echo "  → Cloning meta-openembedded (Kirkstone)..."
        git clone -b kirkstone https://github.com/openembedded/meta-openembedded.git
    fi
    
    echo -e "${GREEN}✓ Yocto layers cloned${NC}"
else
    echo -e "${GREEN}✓ Yocto layers already exist${NC}"
fi

# Step 2: 빌드 환경 초기화
echo ""
echo -e "${YELLOW}[2/6] Initializing build environment...${NC}"
cd "${YOCTO_BASE}"

if [ ! -d "${BUILD_DIR}" ]; then
    source poky/oe-init-build-env ${BUILD_DIR}
    echo -e "${GREEN}✓ Build environment initialized${NC}"
else
    source poky/oe-init-build-env ${BUILD_DIR}
    echo -e "${GREEN}✓ Build environment loaded${NC}"
fi

# Step 3: 레이어 추가
echo ""
echo -e "${YELLOW}[3/6] Adding layers...${NC}"

# 레이어가 이미 추가되어 있는지 확인
if ! bitbake-layers show-layers | grep -q "meta-raspberrypi"; then
    bitbake-layers add-layer ../meta-raspberrypi
    echo "  → Added meta-raspberrypi"
fi

if ! bitbake-layers show-layers | grep -q "meta-oe"; then
    bitbake-layers add-layer ../meta-openembedded/meta-oe
    echo "  → Added meta-oe"
fi

if ! bitbake-layers show-layers | grep -q "meta-vehiclecontrol"; then
    bitbake-layers add-layer ${META_VEHICLECONTROL}
    echo "  → Added meta-vehiclecontrol"
fi

echo -e "${GREEN}✓ All layers added${NC}"

# Step 4: local.conf 설정
echo ""
echo -e "${YELLOW}[4/6] Configuring local.conf...${NC}"

CONF_FILE="conf/local.conf"
BACKUP_FILE="conf/local.conf.bak"

# 백업 생성
if [ ! -f "${BACKUP_FILE}" ]; then
    cp "${CONF_FILE}" "${BACKUP_FILE}"
    echo "  → Backup created: ${BACKUP_FILE}"
fi

# MACHINE 설정
if ! grep -q "^MACHINE = \"raspberrypi4-64\"" "${CONF_FILE}"; then
    sed -i 's/^MACHINE ??= .*/MACHINE = "raspberrypi4-64"/' "${CONF_FILE}"
    echo "  → Set MACHINE = raspberrypi4-64"
fi

# systemd 설정 추가
if ! grep -q "DISTRO_FEATURES:append.*systemd" "${CONF_FILE}"; then
    cat >> "${CONF_FILE}" << 'EOF'

# ========================================
# ECU1 VehicleControl Configuration
# ========================================

# Use systemd as init manager (Kirkstone syntax)
DISTRO_FEATURES:append = " systemd"
VIRTUAL-RUNTIME_init_manager = "systemd"
VIRTUAL-RUNTIME_initscripts = "systemd-compat-units"

# Build performance (adjust based on your CPU cores)
BB_NUMBER_THREADS = "8"
PARALLEL_MAKE = "-j 8"

# Disk space monitoring
BB_DISKMON_DIRS = "\
    STOPTASKS,${TMPDIR},1G,100K \
    STOPTASKS,${DL_DIR},1G,100K \
    STOPTASKS,${SSTATE_DIR},1G,100K"

# Package management
PACKAGE_CLASSES = "package_rpm"

# Image configuration
IMAGE_FSTYPES = "tar.bz2 ext4 rpi-sdimg"

# Development features (remove for production)
EXTRA_IMAGE_FEATURES += "debug-tweaks"

# License flags (accept all for development)
LICENSE_FLAGS_ACCEPTED = "commercial"

# Enable serial console
ENABLE_UART = "1"

EOF
    echo "  → Added ECU1 configuration"
fi

echo -e "${GREEN}✓ local.conf configured${NC}"

# Step 5: 레이어 확인
echo ""
echo -e "${YELLOW}[5/6] Verifying layer configuration...${NC}"
bitbake-layers show-layers

# Step 6: 빌드 준비 완료 메시지
echo ""
echo -e "${GREEN}=========================================="
echo "✅ Build environment setup complete!"
echo -e "==========================================${NC}"
echo ""
echo -e "${BLUE}You are now in the build environment.${NC}"
echo ""
echo "Available commands:"
echo ""
echo "  ${GREEN}# Build the complete image${NC}"
echo "  bitbake vehiclecontrol-image"
echo ""
echo "  ${GREEN}# Build individual packages${NC}"
echo "  bitbake vehiclecontrol-ecu"
echo "  bitbake vsomeip"
echo "  bitbake commonapi-core"
echo ""
echo "  ${GREEN}# Check dependencies${NC}"
echo "  bitbake-layers show-recipes vehiclecontrol-ecu"
echo ""
echo "  ${GREEN}# Clean builds${NC}"
echo "  bitbake -c cleanall vehiclecontrol-ecu"
echo ""
echo -e "${YELLOW}Note: First build will take 2-4 hours (includes downloads)${NC}"
echo ""
echo "Output location:"
echo "  ${YOCTO_BASE}/${BUILD_DIR}/tmp/deploy/images/raspberrypi4-64/"
echo ""
