import QtQuick 2.15
import QtQuick.Window 2.15

Window {
    id: root
    visible: true
    width: 874   // Match HU_MainApp PDC container: 1024 - 130 (gear panel) - 20 (margins)
    height: 500  // Match HU_MainApp PDC container: 600 - 80 (nav bar) - 20 (margins)
    color: "#000000"
    title: "PDC - Park Distance Control"

    // Distance thresholds (in cm)
    readonly property int greenThreshold: 50   // 30-50cm: Green zone
    readonly property int yellowThreshold: 30  // 15-30cm: Yellow zone
    readonly property int redThreshold: 15     // <15cm: Red zone (danger)

    // Current distance from vsomeip
    property int currentDistance: vehicleControlClient.currentDistance
    property string currentGear: vehicleControlClient.currentGear

    // Determine which zone we're in
    property string distanceZone: {
        if (currentDistance > greenThreshold) return "safe"
        else if (currentDistance > yellowThreshold) return "green"
        else if (currentDistance > redThreshold) return "yellow"
        else return "red"
    }

    // Main container
    Rectangle {
        anchors.fill: parent
        color: "#000000"

        // Distance display - on the left side of the car
        Text {
            id: distanceText
            anchors.left: parent.left
            anchors.leftMargin: 40
            anchors.verticalCenter: parent.verticalCenter
            text: currentDistance + " cm"
            font.pixelSize: 32
            font.bold: true
            color: {
                if (distanceZone === "red") return "#FF0000"
                else if (distanceZone === "yellow") return "#FFBB00"
                else if (distanceZone === "green") return "#00FF00"
                else return "#888888"
            }
        }

        // Car and distance indicator container
        Item {
            id: carContainer
            anchors.top: parent.top
            anchors.topMargin: 20
            anchors.horizontalCenter: parent.horizontalCenter

            width: parent.width * 0.9
            height: parent.height * 0.8

            // Car image (rear view - positioned at center) - Made even larger
            Image {
                id: carImage
                source: "qrc:/asset/car.png"
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width * 0.95
                fillMode: Image.PreserveAspectFit
                height: Math.min(implicitHeight * (width / implicitWidth), parent.height * 0.7)
            }

            // Distance indicator arcs (positioned below car)
            Item {
                id: arcContainer
                anchors.top: carImage.bottom
                anchors.topMargin: -30
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width * 0.85
                height: 120

                // Green arc (outermost - 30-50cm zone)
                // Only visible when distance is exactly in green zone (30-50cm)
                Image {
                    id: greenArc
                    source: "qrc:/asset/green.svg"
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: -180
                    fillMode: Image.PreserveAspectFit
                    visible: distanceZone === "green"
                }

                // Yellow arc (middle - 15-30cm zone)
                // Only visible when distance is exactly in yellow zone (15-30cm)
                Image {
                    id: yellowArc
                    source: "qrc:/asset/yellow.svg"
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: -105
                    fillMode: Image.PreserveAspectFit
                    visible: distanceZone === "yellow"
                }

                // Red arc (innermost - <15cm danger zone)
                // Only visible when distance is exactly in red zone (<15cm)
                Image {
                    id: redArc
                    source: "qrc:/asset/red.svg"
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: 20
                    fillMode: Image.PreserveAspectFit
                    visible: distanceZone === "red"
                }
            }
        }

        // Service status indicator
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.margins: 10
            width: 15
            height: 15
            radius: 7.5
            color: vehicleControlClient.serviceAvailable ? "#00ff00" : "#ff0000"

            Text {
                anchors.right: parent.left
                anchors.rightMargin: 5
                anchors.verticalCenter: parent.verticalCenter
                text: vehicleControlClient.serviceAvailable ? "Connected" : "Disconnected"
                font.pixelSize: 12
                color: "#888888"
            }
        }
    }
}
