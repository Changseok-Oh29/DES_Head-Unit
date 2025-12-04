#!/bin/bash
# ECU1 Yocto 빌드 전체 프로세스 자동화 스크립트
#
# 이 스크립트는 소스 준비부터 빌드 환경 설정까지 모두 수행합니다.

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
META_DIR="$(dirname "$SCRIPT_DIR")"

echo -e "${CYAN}"
echo "╔════════════════════════════════════════════════════╗"
echo "║                                                    ║"
echo "║   ECU1 VehicleControl Yocto Build Setup           ║"
echo "║   Complete Automation Script                      ║"
echo "║                                                    ║"
echo "╚════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

# Step 1: 소스 준비
echo -e "${YELLOW}[Step 1/2] Preparing source files...${NC}"
echo ""
cd "${META_DIR}"
./tools/prepare-sources.sh

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✓ Source preparation completed${NC}"
else
    echo ""
    echo -e "${RED}✗ Source preparation failed${NC}"
    exit 1
fi

# Step 2: 빌드 환경 설정
echo ""
echo -e "${YELLOW}[Step 2/2] Setting up build environment...${NC}"
echo ""
echo -e "${BLUE}This will:"
echo "  - Clone Yocto Kirkstone layers (if not exists)"
echo "  - Create build directory: ~/yocto/build-ecu1"
echo "  - Configure all necessary layers"
echo "  - Set up local.conf for Raspberry Pi 4"
echo -e "${NC}"
echo ""
read -p "Continue? (y/N) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

./tools/setup-build-env.sh

echo ""
echo -e "${GREEN}"
echo "╔════════════════════════════════════════════════════╗"
echo "║                                                    ║"
echo "║   ✓ Setup Complete!                               ║"
echo "║                                                    ║"
echo "╚════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""
echo -e "${CYAN}Next Steps:${NC}"
echo ""
echo -e "${YELLOW}To start building:${NC}"
echo ""
echo "  cd ~/yocto/build-ecu1"
echo "  source ../poky/oe-init-build-env ."
echo "  bitbake vehiclecontrol-image"
echo ""
echo -e "${BLUE}Note: First build takes 2-4 hours${NC}"
echo ""
echo -e "${CYAN}For more information:${NC}"
echo "  - Quick Start: QUICKSTART.md"
echo "  - Detailed Guide: 빌드가이드.md"
echo ""
