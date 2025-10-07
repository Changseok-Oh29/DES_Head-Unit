import QtQuick 2.12
import QtQuick.Controls 2.12

Rectangle {
    id: root
    color: "#34495e"
    
    signal gearSelected()
    signal mediaSelected()
    signal ambientSelected()
    
    Text {
        id: titleText
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 50
        text: "Select Function"
        font.pixelSize: 32
        font.bold: true
        color: "#ecf0f1"
    }
    
    Grid {
        anchors.centerIn: parent
        columns: 3
        spacing: 40
        
        // Gear Selection Button
        Rectangle {
            width: 200
            height: 150
            color: "#e74c3c"
            radius: 10
            border.color: "#c0392b"
            border.width: 2
            
            Column {
                anchors.centerIn: parent
                spacing: 10
                
                Rectangle {
                    width: 60
                    height: 60
                    color: "#c0392b"
                    radius: 30
                    anchors.horizontalCenter: parent.horizontalCenter
                    
                    Text {
                        anchors.centerIn: parent
                        text: "⚙"
                        font.pixelSize: 32
                        color: "#ecf0f1"
                    }
                }
                
                Text {
                    text: "GEAR\nSELECTION"
                    font.pixelSize: 16
                    font.bold: true
                    color: "#ecf0f1"
                    horizontalAlignment: Text.AlignHCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
            
            MouseArea {
                anchors.fill: parent
                onClicked: root.gearSelected()
                
                onPressed: parent.color = "#c0392b"
                onReleased: parent.color = "#e74c3c"
            }
        }
        
        // Media App Button
        Rectangle {
            width: 200
            height: 150
            color: "#3498db"
            radius: 10
            border.color: "#2980b9"
            border.width: 2
            
            Column {
                anchors.centerIn: parent
                spacing: 10
                
                Rectangle {
                    width: 60
                    height: 60
                    color: "#2980b9"
                    radius: 30
                    anchors.horizontalCenter: parent.horizontalCenter
                    
                    Text {
                        anchors.centerIn: parent
                        text: "♪"
                        font.pixelSize: 32
                        color: "#ecf0f1"
                    }
                }
                
                Text {
                    text: "MEDIA\nAPP"
                    font.pixelSize: 16
                    font.bold: true
                    color: "#ecf0f1"
                    horizontalAlignment: Text.AlignHCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
            
            MouseArea {
                anchors.fill: parent
                onClicked: root.mediaSelected()
                
                onPressed: parent.color = "#2980b9"
                onReleased: parent.color = "#3498db"
            }
        }
        
        // Ambient Lighting Button
        Rectangle {
            width: 200
            height: 150
            color: "#f39c12"
            radius: 10
            border.color: "#e67e22"
            border.width: 2
            
            Column {
                anchors.centerIn: parent
                spacing: 10
                
                Rectangle {
                    width: 60
                    height: 60
                    color: "#e67e22"
                    radius: 30
                    anchors.horizontalCenter: parent.horizontalCenter
                    
                    Text {
                        anchors.centerIn: parent
                        text: "💡"
                        font.pixelSize: 32
                        color: "#ecf0f1"
                    }
                }
                
                Text {
                    text: "AMBIENT\nLIGHTING"
                    font.pixelSize: 16
                    font.bold: true
                    color: "#ecf0f1"
                    horizontalAlignment: Text.AlignHCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
            
            MouseArea {
                anchors.fill: parent
                onClicked: root.ambientSelected()
                
                onPressed: parent.color = "#e67e22"
                onReleased: parent.color = "#f39c12"
            }
        }
    }
}
