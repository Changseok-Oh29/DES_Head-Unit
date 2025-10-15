import QtQuick 2.12
import QtQuick.Controls 2.12
import HeadUnit 1.0

Rectangle {
    id: root
    color: "#34495e"
    
    // Use IPC manager for actual gear position
    property string currentGear: ipcManager.gearPosition
    
    Text {
        id: titleText
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 30
        text: "Gear Selection"
        font.pixelSize: 28
        font.bold: true
        color: "#ecf0f1"
    }
    
    // Current Gear Display
    Rectangle {
        id: currentGearDisplay
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: titleText.bottom
        anchors.topMargin: 30
        width: 200
        height: 100
        color: "#2c3e50"
        radius: 15
        border.color: "#1abc9c"
        border.width: 3
        
        Column {
            anchors.centerIn: parent
            spacing: 5
            
            Text {
                text: "CURRENT GEAR"
                font.pixelSize: 14
                color: "#95a5a6"
                anchors.horizontalCenter: parent.horizontalCenter
            }
            
            Text {
                text: root.currentGear
                font.pixelSize: 48
                font.bold: true
                color: "#1abc9c"
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }
    
    // Gear Selection Buttons (새로운 위젯 사용)
    GearSelectionWidget {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: currentGearDisplay.bottom
        anchors.topMargin: 50
        compactMode: false
    }
    
    // Gear Description
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 50
        text: {
            switch(root.currentGear) {
                case "P": return "Park - Vehicle locked in position"
                case "R": return "Reverse - Vehicle moves backward"
                case "N": return "Neutral - Vehicle can roll freely"
                case "D": return "Drive - Vehicle moves forward"
                default: return ""
            }
        }
        font.pixelSize: 16
        color: "#bdc3c7"
        horizontalAlignment: Text.AlignHCenter
    }
}
