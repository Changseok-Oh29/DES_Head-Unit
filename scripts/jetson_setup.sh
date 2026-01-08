#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# Jetson Orin Nano Setup Script for DES_Head-Unit
# This script installs all dependencies and builds the Head Unit applications
# ═══════════════════════════════════════════════════════════════════════════════

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"
INSTALL_PREFIX="$BASE_DIR/install_folder"
DEPS_DIR="$BASE_DIR/deps"

echo ""
echo "═══════════════════════════════════════════════════════════════════════════════"
echo "Jetson Orin Nano - DES_Head-Unit Setup"
echo "═══════════════════════════════════════════════════════════════════════════════"
echo ""
echo "Base directory: $BASE_DIR"
echo "Install prefix: $INSTALL_PREFIX"
echo ""

# ───────────────────────────────────────────────────────────────────────────────
# Step 1: Install system dependencies
# ───────────────────────────────────────────────────────────────────────────────
install_system_deps() {
    echo "═══════════════════════════════════════════════════════════════════════════════"
    echo "Step 1: Installing system dependencies..."
    echo "═══════════════════════════════════════════════════════════════════════════════"
    echo ""

    sudo apt-get update
    sudo apt-get install -y \
        build-essential \
        cmake \
        git \
        pkg-config \
        qtbase5-dev \
        qtdeclarative5-dev \
        qtquickcontrols2-5-dev \
        qtwayland5 \
        qml-module-qtquick2 \
        qml-module-qtquick-controls2 \
        qml-module-qtquick-layouts \
        qml-module-qtquick-window2 \
        qml-module-qtgraphicaleffects \
        qml-module-qt-labs-platform \
        libqt5waylandcompositor5-dev \
        libboost-all-dev \
        libdbus-1-dev \
        weston \
        libpulse-dev \
        libasound2-dev \
        gnome-terminal

    echo ""
    echo "System dependencies installed!"
    echo ""
}

# ───────────────────────────────────────────────────────────────────────────────
# Step 2: Build and install vsomeip
# ───────────────────────────────────────────────────────────────────────────────
build_vsomeip() {
    echo "═══════════════════════════════════════════════════════════════════════════════"
    echo "Step 2: Building vsomeip..."
    echo "═══════════════════════════════════════════════════════════════════════════════"
    echo ""

    mkdir -p "$DEPS_DIR"
    cd "$DEPS_DIR"

    # Clone vsomeip if not exists
    if [ ! -d "vsomeip" ] || [ -z "$(ls -A vsomeip 2>/dev/null)" ]; then
        rm -rf vsomeip
        git clone https://github.com/COVESA/vsomeip.git
        cd vsomeip
        git checkout 3.5.8
    else
        cd vsomeip
    fi

    mkdir -p build && cd build
    cmake .. \
        -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" \
        -DENABLE_SIGNAL_HANDLING=1 \
        -DDIAGNOSIS_ADDRESS=0x10
    make -j$(nproc)
    make install

    echo ""
    echo "vsomeip installed to $INSTALL_PREFIX"
    echo ""
}

# ───────────────────────────────────────────────────────────────────────────────
# Step 3: Build and install CommonAPI Core Runtime
# ───────────────────────────────────────────────────────────────────────────────
build_commonapi_core() {
    echo "═══════════════════════════════════════════════════════════════════════════════"
    echo "Step 3: Building CommonAPI Core Runtime..."
    echo "═══════════════════════════════════════════════════════════════════════════════"
    echo ""

    cd "$DEPS_DIR"

    # Clone if not exists
    if [ ! -d "capicxx-core-runtime" ] || [ -z "$(ls -A capicxx-core-runtime 2>/dev/null)" ]; then
        rm -rf capicxx-core-runtime
        git clone https://github.com/COVESA/capicxx-core-runtime.git
        cd capicxx-core-runtime
        git checkout 3.2.4
    else
        cd capicxx-core-runtime
    fi

    mkdir -p build && cd build
    cmake .. \
        -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX"
    make -j$(nproc)
    make install

    echo ""
    echo "CommonAPI Core Runtime installed to $INSTALL_PREFIX"
    echo ""
}

# ───────────────────────────────────────────────────────────────────────────────
# Step 4: Build and install CommonAPI SomeIP Runtime
# ───────────────────────────────────────────────────────────────────────────────
build_commonapi_someip() {
    echo "═══════════════════════════════════════════════════════════════════════════════"
    echo "Step 4: Building CommonAPI SomeIP Runtime..."
    echo "═══════════════════════════════════════════════════════════════════════════════"
    echo ""

    cd "$DEPS_DIR"

    # Clone if not exists
    if [ ! -d "capicxx-someip-runtime" ] || [ -z "$(ls -A capicxx-someip-runtime 2>/dev/null)" ]; then
        rm -rf capicxx-someip-runtime
        git clone https://github.com/COVESA/capicxx-someip-runtime.git
        cd capicxx-someip-runtime
        git checkout 3.2.4
    else
        cd capicxx-someip-runtime
    fi

    mkdir -p build && cd build
    cmake .. \
        -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" \
        -DCMAKE_PREFIX_PATH="$INSTALL_PREFIX"
    make -j$(nproc)
    make install

    echo ""
    echo "CommonAPI SomeIP Runtime installed to $INSTALL_PREFIX"
    echo ""
}

# ───────────────────────────────────────────────────────────────────────────────
# Step 5: Set up environment variables
# ───────────────────────────────────────────────────────────────────────────────
setup_environment() {
    echo "═══════════════════════════════════════════════════════════════════════════════"
    echo "Step 5: Setting up environment..."
    echo "═══════════════════════════════════════════════════════════════════════════════"
    echo ""

    # Create environment setup script
    cat > "$BASE_DIR/scripts/env_setup.sh" << EOF
#!/bin/bash
# DES_Head-Unit Environment Setup for Jetson

export INSTALL_PREFIX="$INSTALL_PREFIX"
export LD_LIBRARY_PATH="\$INSTALL_PREFIX/lib:\$LD_LIBRARY_PATH"
export PKG_CONFIG_PATH="\$INSTALL_PREFIX/lib/pkgconfig:\$PKG_CONFIG_PATH"
export CMAKE_PREFIX_PATH="\$INSTALL_PREFIX:\$CMAKE_PREFIX_PATH"
export PATH="\$INSTALL_PREFIX/bin:\$PATH"

# CommonAPI configuration
export COMMONAPI_CONFIG="$BASE_DIR/commonapi/commonapi.ini"
export COMMONAPI_GEN_DIR="$BASE_DIR/commonapi/generated"

# XDG Runtime (for Wayland)
export XDG_RUNTIME_DIR="/run/user/\$(id -u)"

echo "Environment configured for DES_Head-Unit"
echo "  INSTALL_PREFIX: \$INSTALL_PREFIX"
echo "  LD_LIBRARY_PATH includes: \$INSTALL_PREFIX/lib"
EOF

    chmod +x "$BASE_DIR/scripts/env_setup.sh"

    echo "Environment setup script created: $BASE_DIR/scripts/env_setup.sh"
    echo ""
    echo "To use, run: source $BASE_DIR/scripts/env_setup.sh"
    echo ""
}

# ───────────────────────────────────────────────────────────────────────────────
# Step 6: Build Head Unit Applications
# ───────────────────────────────────────────────────────────────────────────────
build_apps() {
    echo "═══════════════════════════════════════════════════════════════════════════════"
    echo "Step 6: Building Head Unit Applications..."
    echo "═══════════════════════════════════════════════════════════════════════════════"
    echo ""

    # Source environment
    source "$BASE_DIR/scripts/env_setup.sh"

    # Use the existing run_pdc_test.sh build functionality
    cd "$BASE_DIR/app"
    ./run_pdc_test.sh build

    echo ""
    echo "Applications built successfully!"
    echo ""
}

# ───────────────────────────────────────────────────────────────────────────────
# Main
# ───────────────────────────────────────────────────────────────────────────────
print_usage() {
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  all         - Run complete setup (default)"
    echo "  deps        - Install system dependencies only"
    echo "  vsomeip     - Build vsomeip only"
    echo "  commonapi   - Build CommonAPI (core + someip) only"
    echo "  env         - Setup environment only"
    echo "  build       - Build applications only"
    echo "  help        - Show this help"
    echo ""
}

case "${1:-all}" in
    all)
        install_system_deps
        build_vsomeip
        build_commonapi_core
        build_commonapi_someip
        setup_environment
        build_apps
        echo ""
        echo "═══════════════════════════════════════════════════════════════════════════════"
        echo "Setup Complete!"
        echo "═══════════════════════════════════════════════════════════════════════════════"
        echo ""
        echo "To run the PDC test:"
        echo "  1. source $BASE_DIR/scripts/env_setup.sh"
        echo "  2. cd $BASE_DIR/app"
        echo "  3. ./run_pdc_test.sh run"
        echo ""
        ;;
    deps)
        install_system_deps
        ;;
    vsomeip)
        build_vsomeip
        ;;
    commonapi)
        build_commonapi_core
        build_commonapi_someip
        ;;
    env)
        setup_environment
        ;;
    build)
        setup_environment
        build_apps
        ;;
    help|--help|-h)
        print_usage
        ;;
    *)
        echo "Unknown command: $1"
        print_usage
        exit 1
        ;;
esac
