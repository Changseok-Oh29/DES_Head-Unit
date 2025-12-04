#!/bin/bash
# Quick verification script for meta-vehiclecontrol layer

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
META_DIR="$(dirname "$SCRIPT_DIR")"

echo "=========================================="
echo "meta-vehiclecontrol Layer Verification"
echo "=========================================="
echo ""

# Check directory structure
echo "[1/5] Checking directory structure..."
REQUIRED_DIRS=(
    "conf"
    "recipes-connectivity/vsomeip"
    "recipes-connectivity/commonapi"
    "recipes-support/pigpio"
    "recipes-bsp/bootfiles"
    "recipes-core/images"
    "recipes-core/packagegroups"
    "recipes-core/systemd"
    "recipes-vehiclecontrol/vehiclecontrol-ecu"
    "tools"
)

ALL_DIRS_OK=true
for dir in "${REQUIRED_DIRS[@]}"; do
    if [ ! -d "$META_DIR/$dir" ]; then
        echo "❌ Missing directory: $dir"
        ALL_DIRS_OK=false
    fi
done

if [ "$ALL_DIRS_OK" = true ]; then
    echo "✓ All directories present"
else
    exit 1
fi

# Check recipe files
echo "[2/5] Checking recipe files..."
REQUIRED_RECIPES=(
    "conf/layer.conf"
    "recipes-connectivity/vsomeip/vsomeip_3.5.8.bb"
    "recipes-connectivity/commonapi/commonapi-core_3.2.4.bb"
    "recipes-connectivity/commonapi/commonapi-someip_3.2.4.bb"
    "recipes-support/pigpio/pigpio_79.bb"
    "recipes-core/images/vehiclecontrol-image.bb"
    "recipes-core/packagegroups/packagegroup-vehiclecontrol.bb"
    "recipes-vehiclecontrol/vehiclecontrol-ecu/vehiclecontrol-ecu_1.0.bb"
)

ALL_RECIPES_OK=true
for recipe in "${REQUIRED_RECIPES[@]}"; do
    if [ ! -f "$META_DIR/$recipe" ]; then
        echo "❌ Missing recipe: $recipe"
        ALL_RECIPES_OK=false
    fi
done

if [ "$ALL_RECIPES_OK" = true ]; then
    echo "✓ All recipes present"
else
    exit 1
fi

# Check for syntax errors in layer.conf
echo "[3/5] Validating layer configuration..."
if grep -q "BBFILE_COLLECTIONS" "$META_DIR/conf/layer.conf"; then
    echo "✓ layer.conf looks valid"
else
    echo "❌ layer.conf may be invalid"
    exit 1
fi

# Check documentation
echo "[4/5] Checking documentation..."
if [ -f "$META_DIR/README.md" ] && [ -f "$META_DIR/BUILD_GUIDE.md" ]; then
    echo "✓ Documentation present"
else
    echo "⚠ Warning: Documentation may be incomplete"
fi

# Check if sources need to be prepared
echo "[5/5] Checking source preparation..."
if [ -f "$META_DIR/recipes-vehiclecontrol/vehiclecontrol-ecu/files/src/main.cpp" ]; then
    echo "✓ Sources already prepared"
    SOURCES_READY=true
else
    echo "⚠ Sources not yet prepared - run ./tools/prepare-sources.sh"
    SOURCES_READY=false
fi

echo ""
echo "=========================================="
echo "✅ Layer structure verification complete!"
echo "=========================================="
echo ""

if [ "$SOURCES_READY" = true ]; then
    echo "Your meta-vehiclecontrol layer is ready to use!"
    echo ""
    echo "Next steps:"
    echo "1. cd ~/yocto"
    echo "2. source poky/oe-init-build-env build-ecu1"
    echo "3. bitbake-layers add-layer $META_DIR"
    echo "4. bitbake vehiclecontrol-image"
else
    echo "Before building, prepare the sources:"
    echo "1. cd $META_DIR"
    echo "2. ./tools/prepare-sources.sh"
    echo "3. cd ~/yocto"
    echo "4. source poky/oe-init-build-env build-ecu1"
    echo "5. bitbake-layers add-layer $META_DIR"
    echo "6. bitbake vehiclecontrol-image"
fi

echo ""
