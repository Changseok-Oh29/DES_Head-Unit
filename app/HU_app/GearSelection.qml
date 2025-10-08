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
    
    // Gear Selection Buttons
    Grid {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: currentGearDisplay.bottom
        anchors.topMargin: 50
        columns: 4
        spacing: 30
        
        // Park (P)
        Rectangle {
            width: 100
            height: 80
            color: root.currentGear === "P" ? "#e74c3c" : "#7f8c8d"
            radius: 10
            border.color: root.currentGear === "P" ? "#c0392b" : "#95a5a6"
            border.width: 2
            
            Text {
                anchors.centerIn: parent
                text: "P"
                font.pixelSize: 32
                font.bold: true
                color: "#ecf0f1"
            }
            
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    ipcManager.setGearPosition("P")
                    console.log("Gear changed to Park")
                }
            }
        }
        
        // Reverse (R)
        Rectangle {
            width: 100
            height: 80
            color: root.currentGear === "R" ? "#e74c3c" : "#7f8c8d"
            radius: 10
            border.color: root.currentGear === "R" ? "#c0392b" : "#95a5a6"
            border.width: 2
            
            Text {
                anchors.centerIn: parent
                text: "R"
                font.pixelSize: 32
                font.bold: true
                color: "#ecf0f1"
            }
            
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    ipcManager.setGearPosition("R")
                    console.log("Gear changed to Reverse")
                }
            }
        }
        
        // Neutral (N)
        Rectangle {
            width: 100
            height: 80
            color: root.currentGear === "N" ? "#f39c12" : "#7f8c8d"
            radius: 10
            border.color: root.currentGear === "N" ? "#e67e22" : "#95a5a6"
            border.width: 2
            
            Text {
                anchors.centerIn: parent
                text: "N"
                font.pixelSize: 32
                font.bold: true
                color: "#ecf0f1"
            }
            
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    ipcManager.setGearPosition("N")
                    console.log("Gear changed to Neutral")
                }
            }
        }
        
        // Drive (D)
        Rectangle {
            width: 100
            height: 80
            color: root.currentGear === "D" ? "#27ae60" : "#7f8c8d"
            radius: 10
            border.color: root.currentGear === "D" ? "#229954" : "#95a5a6"
            border.width: 2
            
            Text {
                anchors.centerIn: parent
                text: "D"
                font.pixelSize: 32
                font.bold: true
                color: "#ecf0f1"
            }
            
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    ipcManager.setGearPosition("D")
                    console.log("Gear changed to Drive")
                }
            }
        }
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
