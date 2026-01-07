#!/bin/bash

echo "════════════════════════════════════════════════════════"
echo "Generating CommonAPI Code from FIDL files"
echo "════════════════════════════════════════════════════════"

cd "$(dirname "$0")"

FIDL_DIR="fidl"
FDEPL_DIR="fidl"
OUTPUT_CORE="generated/core"
OUTPUT_SOMEIP="generated/someip"

# Generator paths
CORE_GEN="/home/seame/PDC/headunit/DES_Head-Unit/deps/commonapi-generators/commonapi_core/commonapi-core-generator-linux-x86_64"
SOMEIP_GEN="/home/seame/PDC/headunit/DES_Head-Unit/deps/commonapi-generators/commonapi_someip/commonapi-someip-generator-linux-x86_64"

# List of interfaces to generate
INTERFACES=("MediaControl" "AmbientControl" "VehicleControl")

# Create output directories
mkdir -p $OUTPUT_CORE
mkdir -p $OUTPUT_SOMEIP

for INTERFACE in "${INTERFACES[@]}"; do
    echo ""
    echo "────────────────────────────────────────────────────────"
    echo "Generating code for: $INTERFACE"
    echo "────────────────────────────────────────────────────────"

    FIDL_FILE="$FIDL_DIR/$INTERFACE.fidl"
    FDEPL_FILE="$FDEPL_DIR/$INTERFACE.fdepl"

    # Check if FIDL file exists
    if [ ! -f "$FIDL_FILE" ]; then
        echo "⚠️  Skipping $INTERFACE - FIDL file not found: $FIDL_FILE"
        continue
    fi

    # Generate Core code
    echo "Generating Core code..."
    $CORE_GEN -sk -d $OUTPUT_CORE $FIDL_FILE

    if [ $? -ne 0 ]; then
        echo "❌ Core code generation failed for $INTERFACE!"
        exit 1
    fi
    echo "✅ Core code generated"

    # Generate SomeIP code (only if fdepl exists)
    if [ -f "$FDEPL_FILE" ]; then
        echo "Generating SomeIP code..."
        $SOMEIP_GEN -d $OUTPUT_SOMEIP $FDEPL_FILE

        if [ $? -ne 0 ]; then
            echo "❌ SomeIP code generation failed for $INTERFACE!"
            exit 1
        fi
        echo "✅ SomeIP code generated"
    else
        echo "⚠️  No fdepl file found, skipping SomeIP generation"
    fi
done

echo ""
echo "════════════════════════════════════════════════════════"
echo "Code generation completed successfully!"
echo "════════════════════════════════════════════════════════"
echo ""
echo "Generated Core files:"
ls -la $OUTPUT_CORE/v1/*/
echo ""
echo "Generated SomeIP files:"
ls -la $OUTPUT_SOMEIP/v1/*/
