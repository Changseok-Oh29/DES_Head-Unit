import QtQuick 2.12

/*
 * IC Compositor Layout - UI Structure for Instrument Cluster
 *
 * Portrait display (400x1280) with content rendered landscape (1280x400)
 * and rotated -90 degrees for proper viewing
 *
 * Landscape layout (1280x400):
 * ┌────────────┬────────────────┬────────────┐
 * │  GearApp   │   SpeedApp     │ BatteryApp │
 * │  (280px)   │   (400px)      │  (280px)   │
 * └────────────┴────────────────┴────────────┘
 */

Item {
    id: root

    // Expose containers for surface routing
    property alias gearAppContainer: gearAppContainer
    property alias speedAppContainer: speedAppContainer
    property alias batteryAppContainer: batteryAppContainer

    // Rotated container: Render landscape (1280x400) inside portrait canvas (400x1280)
    Item {
        id: rotatedContent
        width: 1280   // Landscape width
        height: 400   // Landscape height
        anchors.centerIn: parent
        rotation: -90  // Rotate -90 so landscape content appears upright when screen is portrait

        // ===== LEFT: GEAR SECTION (x: 60-340) =====
        Rectangle {
            id: gearSection
            x: 60
            y: 0
            width: 280
            height: 400
            color: "#1a1a2e"  // Dark blue background for debugging
            border.color: "#444"
            border.width: 1

            // Container for ICGearApp window
            Item {
                id: gearAppContainer
                anchors.fill: parent
            }
        }

        // ===== CENTER: SPEEDOMETER SECTION (x: 440-840) =====
        Rectangle {
            id: speedometerSection
            x: 440
            y: 0
            width: 400
            height: 400
            color: "#2e1a1a"  // Dark red background for debugging
            border.color: "#444"
            border.width: 1

            // Container for SpeedApp window
            Item {
                id: speedAppContainer
                anchors.fill: parent
            }
        }

        // ===== RIGHT: BATTERY SECTION (x: 940-1220) =====
        Rectangle {
            id: batterySection
            x: 940
            y: 0
            width: 280
            height: 400
            color: "#1a2e1a"  // Dark green background for debugging
            border.color: "#444"
            border.width: 1

            // Container for BatteryApp window
            Item {
                id: batteryAppContainer
                anchors.fill: parent
            }
        }
    }
}
