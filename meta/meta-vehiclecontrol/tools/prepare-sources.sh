#!/bin/bash
# VehicleControlECU 소스를 Yocto recipe files 디렉토리로 복사하는 스크립트

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
META_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(dirname "$(dirname "$META_DIR")")"

SRC_APP_DIR="$PROJECT_ROOT/app/VehicleControlECU"
SRC_COMMONAPI_DIR="$PROJECT_ROOT/commonapi/generated"

DEST_DIR="$META_DIR/recipes-vehiclecontrol/vehiclecontrol-ecu/files"

echo "=========================================="
echo "VehicleControl ECU - Source Preparation"
echo "=========================================="
echo ""
echo "Project Root: $PROJECT_ROOT"
echo "Source App:   $SRC_APP_DIR"
echo "CommonAPI:    $SRC_COMMONAPI_DIR"
echo "Destination:  $DEST_DIR"
echo ""

# Check if source directories exist
if [ ! -d "$SRC_APP_DIR" ]; then
    echo "❌ Error: VehicleControlECU source not found at $SRC_APP_DIR"
    exit 1
fi

if [ ! -d "$SRC_COMMONAPI_DIR" ]; then
    echo "❌ Error: CommonAPI generated code not found at $SRC_COMMONAPI_DIR"
    exit 1
fi

# Create destination directory
mkdir -p "$DEST_DIR"

echo "[1/5] Copying source code..."
# Copy source files
rsync -av --delete \
    --exclude='build*' \
    --exclude='*.user' \
    --exclude='*.autosave' \
    --exclude='.vscode' \
    "$SRC_APP_DIR/src/" "$DEST_DIR/src/"

rsync -av --delete \
    --exclude='build*' \
    "$SRC_APP_DIR/lib/" "$DEST_DIR/lib/"

echo "✓ Source code copied"

echo "[2/5] Copying CMakeLists.txt..."
cp "$SRC_APP_DIR/CMakeLists.txt" "$DEST_DIR/"
echo "✓ CMakeLists.txt copied"

echo "[3/5] Copying configuration files..."
mkdir -p "$DEST_DIR/config"
cp "$SRC_APP_DIR/config/vsomeip_ecu1.json" "$DEST_DIR/config/"
cp "$SRC_APP_DIR/config/commonapi_ecu1.ini" "$DEST_DIR/config/"
echo "✓ Configuration files copied"

echo "[4/5] Copying CommonAPI generated code..."
mkdir -p "$DEST_DIR/commonapi-generated"
rsync -av --delete "$SRC_COMMONAPI_DIR/" "$DEST_DIR/commonapi-generated/"
echo "✓ CommonAPI generated code copied"

echo "[5/5] Verifying file structure..."
# Verify essential files
REQUIRED_FILES=(
    "src/main.cpp"
    "src/VehicleControlStubImpl.cpp"
    "CMakeLists.txt"
    "config/vsomeip_ecu1.json"
    "config/commonapi_ecu1.ini"
)

ALL_OK=true
for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$DEST_DIR/$file" ]; then
        echo "❌ Missing: $file"
        ALL_OK=false
    fi
done

if [ "$ALL_OK" = true ]; then
    echo "✓ All required files present"
    echo ""
    echo "=========================================="
    echo "✅ Source preparation complete!"
    echo "=========================================="
    echo ""
    echo "Next steps:"
    echo "1. cd ~/yocto"
    echo "2. source poky/oe-init-build-env build-ecu1"
    echo "3. bitbake-layers add-layer $META_DIR"
    echo "4. bitbake vehiclecontrol-image"
    echo ""
else
    echo ""
    echo "❌ Source preparation failed - missing required files"
    exit 1
fi
