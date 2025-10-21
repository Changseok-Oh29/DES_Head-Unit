import QtQuick 2.12
import QtQuick.Controls 2.12
import QtGraphicalEffects 1.0
import "components"

// Home page - Dashboard view
Rectangle {
    id: root
    color: "transparent"

    // Center vehicle visualization
    Item {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -30
        width: 500
        height: 330

        // Vehicle image
        Image {
            id: carImage
            anchors.centerIn: parent
            width: 400
            height: 280
            source: "qrc:/images/car.svg"
            fillMode: Image.PreserveAspectFit
            smooth: true
        }

        ColorOverlay {
            anchors.fill: carImage
            source: carImage
            color: "#ecf0f1"
            opacity: 0.9
        }

        // Gear indicator overlay on vehicle
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 40
            width: 100
            height: 100
            radius: 50
            color: "#2c3e50"
            opacity: 0.95
            border.color: {
                switch(gearManager.gearPosition) {
                    case "P": return "#e74c3c"
                    case "R": return "#e67e22"
                    case "N": return "#f39c12"
                    case "D": return "#27ae60"
                    default: return "#7f8c8d"
                }
            }
            border.width: 4

            Column {
                anchors.centerIn: parent
                spacing: 5

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: gearManager.gearPosition
                    font.pixelSize: 36
                    font.bold: true
                    color: "#ecf0f1"
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: {
                        switch(gearManager.gearPosition) {
                            case "P": return "PARK"
                            case "R": return "REVERSE"
                            case "N": return "NEUTRAL"
                            case "D": return "DRIVE"
                            default: return ""
                        }
                    }
                    font.pixelSize: 11
                    font.bold: true
                    color: "#bdc3c7"
                }
            }

            Behavior on border.color {
                ColorAnimation { duration: 300 }
            }
        }
    }

    // Quick stats grid
    Grid {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 15
        columns: 3
        spacing: 20

        // Media status card
        QuickInfoCard {
            icon: "qrc:/images/mp3.svg"
            title: "Now Playing"
            value: getFileName(mediaManager.currentFile)
            subtitle: mediaManager.isPlaying ? "Playing" : "Paused"
        }

        // Connection status card
        QuickInfoCard {
            icon: "qrc:/images/car.svg"
            title: "IC Connection"
            value: ipcManager.isConnected ? "Connected" : "Disconnected"
            subtitle: ipcManager.isConnected ? "Active" : "No Signal"
        }

        // Ambient status card
        QuickInfoCard {
            icon: "qrc:/images/ambient_light.svg"
            title: "Ambient Light"
            value: ambientManager.ambientLightEnabled ? "ON" : "OFF"
            subtitle: "Mode: Auto"
        }
    }

    // Helper function to extract filename
    function getFileName(filePath) {
        if (!filePath || filePath === "") return "No Media"
        var parts = filePath.split('/')
        var filename = parts[parts.length - 1]
        // Truncate if too long
        if (filename.length > 20) {
            return filename.substring(0, 17) + "..."
        }
        return filename
    }
}
