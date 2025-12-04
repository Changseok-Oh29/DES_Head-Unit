#!/bin/bash
# ECU1 빌드 시작 헬퍼 스크립트
# 빌드 시작 전 시스템 체크 및 가이드 제공

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

clear

echo -e "${CYAN}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════════════╗
║                                                                   ║
║   ECU1 VehicleControl Yocto Image Build                          ║
║   Raspberry Pi 4 - PiRacer Vehicle Control System                ║
║                                                                   ║
╚═══════════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo ""
echo -e "${BLUE}📋 시스템 요구사항 확인${NC}"
echo ""

# Check disk space
AVAILABLE_SPACE=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')
if [ "$AVAILABLE_SPACE" -lt 100 ]; then
    echo -e "${RED}⚠️  경고: 디스크 여유 공간이 부족합니다 (${AVAILABLE_SPACE}GB)${NC}"
    echo -e "${YELLOW}   최소 100GB 이상 필요${NC}"
else
    echo -e "${GREEN}✓ 디스크 공간: ${AVAILABLE_SPACE}GB 사용 가능${NC}"
fi

# Check RAM
TOTAL_RAM=$(free -g | awk 'NR==2 {print $2}')
if [ "$TOTAL_RAM" -lt 8 ]; then
    echo -e "${YELLOW}⚠️  RAM이 8GB 미만입니다 (${TOTAL_RAM}GB)${NC}"
    echo -e "${YELLOW}   빌드가 느릴 수 있습니다. 16GB 권장${NC}"
else
    echo -e "${GREEN}✓ RAM: ${TOTAL_RAM}GB${NC}"
fi

# Check CPU cores
CPU_CORES=$(nproc)
echo -e "${GREEN}✓ CPU 코어: ${CPU_CORES}개${NC}"

# Check if required packages are installed
echo ""
echo -e "${BLUE}📦 필수 패키지 확인${NC}"
echo ""

REQUIRED_PACKAGES=("git" "wget" "python3" "gcc" "make")
MISSING_PACKAGES=()

for pkg in "${REQUIRED_PACKAGES[@]}"; do
    if ! command -v "$pkg" &> /dev/null; then
        MISSING_PACKAGES+=("$pkg")
    fi
done

if [ ${#MISSING_PACKAGES[@]} -eq 0 ]; then
    echo -e "${GREEN}✓ 모든 필수 패키지가 설치되어 있습니다${NC}"
else
    echo -e "${RED}✗ 다음 패키지가 설치되지 않았습니다: ${MISSING_PACKAGES[*]}${NC}"
    echo ""
    echo -e "${YELLOW}다음 명령으로 설치하세요:${NC}"
    echo "sudo apt-get install -y gawk wget git diffstat unzip texinfo gcc build-essential \\"
    echo "    chrpath socat cpio python3 python3-pip python3-pexpect xz-utils \\"
    echo "    debianutils iputils-ping python3-git python3-jinja2 libegl1-mesa \\"
    echo "    libsdl1.2-dev pylint3 xterm python3-subunit mesa-common-dev zstd liblz4-tool"
    echo ""
    read -p "지금 설치하시겠습니까? (y/N) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo apt-get update
        sudo apt-get install -y \
            gawk wget git diffstat unzip texinfo gcc build-essential \
            chrpath socat cpio python3 python3-pip python3-pexpect \
            xz-utils debianutils iputils-ping python3-git python3-jinja2 \
            libegl1-mesa libsdl1.2-dev pylint3 xterm python3-subunit \
            mesa-common-dev zstd liblz4-tool
    else
        echo "설치를 건너뜁니다. 빌드가 실패할 수 있습니다."
    fi
fi

echo ""
echo -e "${MAGENTA}═══════════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${CYAN}🚀 빌드 옵션${NC}"
echo ""
echo "1. 전체 자동 빌드 (권장) - 소스 준비 + 환경 설정 + 가이드"
echo "2. 소스 준비만 실행"
echo "3. 빌드 환경 설정만 실행"
echo "4. 문서 보기"
echo "5. 종료"
echo ""
read -p "선택 (1-5): " -n 1 -r CHOICE
echo ""
echo ""

case $CHOICE in
    1)
        echo -e "${GREEN}전체 자동 빌드를 시작합니다...${NC}"
        echo ""
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        META_DIR="$(dirname "$SCRIPT_DIR")"
        cd "$META_DIR"
        exec ./tools/build-all.sh
        ;;
    2)
        echo -e "${GREEN}소스 준비를 시작합니다...${NC}"
        echo ""
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        META_DIR="$(dirname "$SCRIPT_DIR")"
        cd "$META_DIR"
        exec ./tools/prepare-sources.sh
        ;;
    3)
        echo -e "${GREEN}빌드 환경 설정을 시작합니다...${NC}"
        echo ""
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        META_DIR="$(dirname "$SCRIPT_DIR")"
        cd "$META_DIR"
        exec ./tools/setup-build-env.sh
        ;;
    4)
        echo -e "${CYAN}사용 가능한 문서:${NC}"
        echo ""
        echo "  - QUICKSTART.md         : 빠른 시작 가이드 (초보자 권장)"
        echo "  - BUILD_CHECKLIST.md    : 상세 체크리스트"
        echo "  - 빌드가이드.md         : 전체 빌드 가이드"
        echo "  - 문제해결.md           : 문제 해결 가이드"
        echo "  - README.md             : 레이어 개요"
        echo ""
        echo "다음 명령으로 문서를 확인하세요:"
        echo "  cat meta/meta-vehiclecontrol/QUICKSTART.md | less"
        echo ""
        ;;
    5)
        echo "종료합니다."
        exit 0
        ;;
    *)
        echo -e "${RED}잘못된 선택입니다.${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${MAGENTA}═══════════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${CYAN}📊 예상 빌드 시간${NC}"
echo ""
echo "  • 레이어 클론: 10-30분 (처음 한 번만)"
echo "  • 첫 빌드:     2-4시간 (패키지 다운로드 포함)"
echo "  • 재빌드:      10-30분 (변경사항만)"
echo ""
echo -e "${YELLOW}⚠️  주의: 빌드 중 인터넷 연결이 안정적이어야 합니다.${NC}"
echo ""
echo -e "${MAGENTA}═══════════════════════════════════════════════════════════════════${NC}"
echo ""
