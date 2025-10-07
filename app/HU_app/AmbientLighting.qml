import QtQuick 2.12
import QtQuick.Controls 2.12

Rectangle {
    id: root
    color: "#34495e"
    
    property real redValue: 128
    property real greenValue: 128  
    property real blueValue: 255
    property real brightness: 80
    property string currentMode: "Manual"
    
    Text {
        id: titleText
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 20
        text: "Ambient Lighting Control"
        font.pixelSize: 28
        font.bold: true
        color: "#ecf0f1"
    }
    
    Row {
        anchors.top: titleText.bottom
        anchors.topMargin: 30
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        spacing: 30
        height: parent.height - titleText.height - 50
        
        // Left Panel - Controls
        Rectangle {
            width: parent.width * 0.6
            height: parent.height
            color: "#2c3e50"
            radius: 10
            
            Column {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 20
                
                // Mode Selection
                Text {
                    text: "Lighting Mode"
                    font.pixelSize: 18
                    font.bold: true
                    color: "#ecf0f1"
                }
                
                Row {
                    spacing: 15
                    
                    Rectangle {
                        width: 100
                        height: 40
                        color: root.currentMode === "Manual" ? "#3498db" : "#7f8c8d"
                        radius: 5
                        
                        Text {
                            anchors.centerIn: parent
                            text: "Manual"
                            color: "#ecf0f1"
                            font.pixelSize: 14
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.currentMode = "Manual"
                        }
                    }
                    
                    Rectangle {
                        width: 100
                        height: 40
                        color: root.currentMode === "Auto" ? "#3498db" : "#7f8c8d"
                        radius: 5
                        
                        Text {
                            anchors.centerIn: parent
                            text: "Auto"
                            color: "#ecf0f1"
                            font.pixelSize: 14
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.currentMode = "Auto"
                        }
                    }
                    
                    Rectangle {
                        width: 100
                        height: 40
                        color: root.currentMode === "Music Sync" ? "#3498db" : "#7f8c8d"
                        radius: 5
                        
                        Text {
                            anchors.centerIn: parent
                            text: "Music Sync"
                            color: "#ecf0f1"
                            font.pixelSize: 14
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.currentMode = "Music Sync"
                        }
                    }
                }
                
                Rectangle {
                    width: parent.width
                    height: 2
                    color: "#3498db"
                }
                
                // Color Controls (visible in Manual mode)
                Column {
                    visible: root.currentMode === "Manual"
                    width: parent.width
                    spacing: 15
                    
                    Text {
                        text: "Color Control"
                        font.pixelSize: 16
                        font.bold: true
                        color: "#ecf0f1"
                    }
                    
                    // Red Control
                    Row {
                        width: parent.width
                        spacing: 10
                        
                        Text {
                            text: "Red:"
                            width: 50
                            color: "#ecf0f1"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        
                        Slider {
                            width: parent.width - 100
                            from: 0
                            to: 255
                            value: root.redValue
                            onValueChanged: root.redValue = value
                            
                            background: Rectangle {
                                x: parent.leftPadding
                                y: parent.topPadding + parent.availableHeight / 2 - height / 2
                                implicitWidth: 200
                                implicitHeight: 4
                                width: parent.availableWidth
                                height: implicitHeight
                                radius: 2
                                color: "#7f8c8d"
                            }
                            
                            handle: Rectangle {
                                x: parent.leftPadding + parent.visualPosition * (parent.availableWidth - width)
                                y: parent.topPadding + parent.availableHeight / 2 - height / 2
                                implicitWidth: 20
                                implicitHeight: 20
                                radius: 10
                                color: "#e74c3c"
                            }
                        }
                        
                        Text {
                            text: Math.round(root.redValue)
                            width: 40
                            color: "#ecf0f1"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    
                    // Green Control
                    Row {
                        width: parent.width
                        spacing: 10
                        
                        Text {
                            text: "Green:"
                            width: 50
                            color: "#ecf0f1"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        
                        Slider {
                            width: parent.width - 100
                            from: 0
                            to: 255
                            value: root.greenValue
                            onValueChanged: root.greenValue = value
                            
                            background: Rectangle {
                                x: parent.leftPadding
                                y: parent.topPadding + parent.availableHeight / 2 - height / 2
                                implicitWidth: 200
                                implicitHeight: 4
                                width: parent.availableWidth
                                height: implicitHeight
                                radius: 2
                                color: "#7f8c8d"
                            }
                            
                            handle: Rectangle {
                                x: parent.leftPadding + parent.visualPosition * (parent.availableWidth - width)
                                y: parent.topPadding + parent.availableHeight / 2 - height / 2
                                implicitWidth: 20
                                implicitHeight: 20
                                radius: 10
                                color: "#27ae60"
                            }
                        }
                        
                        Text {
                            text: Math.round(root.greenValue)
                            width: 40
                            color: "#ecf0f1"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    
                    // Blue Control
                    Row {
                        width: parent.width
                        spacing: 10
                        
                        Text {
                            text: "Blue:"
                            width: 50
                            color: "#ecf0f1"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        
                        Slider {
                            width: parent.width - 100
                            from: 0
                            to: 255
                            value: root.blueValue
                            onValueChanged: root.blueValue = value
                            
                            background: Rectangle {
                                x: parent.leftPadding
                                y: parent.topPadding + parent.availableHeight / 2 - height / 2
                                implicitWidth: 200
                                implicitHeight: 4
                                width: parent.availableWidth
                                height: implicitHeight
                                radius: 2
                                color: "#7f8c8d"
                            }
                            
                            handle: Rectangle {
                                x: parent.leftPadding + parent.visualPosition * (parent.availableWidth - width)
                                y: parent.topPadding + parent.availableHeight / 2 - height / 2
                                implicitWidth: 20
                                implicitHeight: 20
                                radius: 10
                                color: "#3498db"
                            }
                        }
                        
                        Text {
                            text: Math.round(root.blueValue)
                            width: 40
                            color: "#ecf0f1"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
                
                Rectangle {
                    width: parent.width
                    height: 2
                    color: "#3498db"
                }
                
                // Brightness Control
                Row {
                    width: parent.width
                    spacing: 10
                    
                    Text {
                        text: "Brightness:"
                        width: 80
                        color: "#ecf0f1"
                        font.pixelSize: 16
                        font.bold: true
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    
                    Slider {
                        width: parent.width - 130
                        from: 0
                        to: 100
                        value: root.brightness
                        onValueChanged: root.brightness = value
                        
                        background: Rectangle {
                            x: parent.leftPadding
                            y: parent.topPadding + parent.availableHeight / 2 - height / 2
                            implicitWidth: 200
                            implicitHeight: 4
                            width: parent.availableWidth
                            height: implicitHeight
                            radius: 2
                            color: "#7f8c8d"
                        }
                        
                        handle: Rectangle {
                            x: parent.leftPadding + parent.visualPosition * (parent.availableWidth - width)
                            y: parent.topPadding + parent.availableHeight / 2 - height / 2
                            implicitWidth: 20
                            implicitHeight: 20
                            radius: 10
                            color: "#f39c12"
                        }
                    }
                    
                    Text {
                        text: Math.round(root.brightness) + "%"
                        width: 40
                        color: "#ecf0f1"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }
        
        // Right Panel - Preview
        Rectangle {
            width: parent.width * 0.35
            height: parent.height
            color: "#2c3e50"
            radius: 10
            
            Column {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 20
                
                Text {
                    text: "Preview"
                    font.pixelSize: 18
                    font.bold: true
                    color: "#ecf0f1"
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                
                // Color Preview
                Rectangle {
                    width: parent.width
                    height: 100
                    color: Qt.rgba(root.redValue/255, root.greenValue/255, root.blueValue/255, root.brightness/100)
                    radius: 10
                    border.color: "#7f8c8d"
                    border.width: 2
                    
                    Text {
                        anchors.centerIn: parent
                        text: "Ambient Light Preview"
                        color: "#2c3e50"
                        font.pixelSize: 14
                        font.bold: true
                    }
                }
                
                // Status Info
                Rectangle {
                    width: parent.width
                    height: 120
                    color: "#34495e"
                    radius: 5
                    
                    Column {
                        anchors.centerIn: parent
                        spacing: 8
                        
                        Text {
                            text: "Status"
                            font.pixelSize: 16
                            font.bold: true
                            color: "#3498db"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        
                        Text {
                            text: "Mode: " + root.currentMode
                            color: "#ecf0f1"
                            font.pixelSize: 12
                        }
                        
                        Text {
                            text: "RGB: (" + Math.round(root.redValue) + ", " + Math.round(root.greenValue) + ", " + Math.round(root.blueValue) + ")"
                            color: "#ecf0f1"
                            font.pixelSize: 12
                        }
                        
                        Text {
                            text: "Brightness: " + Math.round(root.brightness) + "%"
                            color: "#ecf0f1"
                            font.pixelSize: 12
                        }
                    }
                }
                
                // Quick Preset Colors
                Text {
                    text: "Quick Presets"
                    font.pixelSize: 16
                    font.bold: true
                    color: "#ecf0f1"
                }
                
                Grid {
                    columns: 3
                    spacing: 10
                    anchors.horizontalCenter: parent.horizontalCenter
                    
                    // Red preset
                    Rectangle {
                        width: 40
                        height: 40
                        color: "#e74c3c"
                        radius: 20
                        
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                root.redValue = 231
                                root.greenValue = 76
                                root.blueValue = 60
                            }
                        }
                    }
                    
                    // Green preset
                    Rectangle {
                        width: 40
                        height: 40
                        color: "#27ae60"
                        radius: 20
                        
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                root.redValue = 39
                                root.greenValue = 174
                                root.blueValue = 96
                            }
                        }
                    }
                    
                    // Blue preset
                    Rectangle {
                        width: 40
                        height: 40
                        color: "#3498db"
                        radius: 20
                        
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                root.redValue = 52
                                root.greenValue = 152
                                root.blueValue = 219
                            }
                        }
                    }
                    
                    // Yellow preset
                    Rectangle {
                        width: 40
                        height: 40
                        color: "#f1c40f"
                        radius: 20
                        
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                root.redValue = 241
                                root.greenValue = 196
                                root.blueValue = 15
                            }
                        }
                    }
                    
                    // Purple preset
                    Rectangle {
                        width: 40
                        height: 40
                        color: "#9b59b6"
                        radius: 20
                        
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                root.redValue = 155
                                root.greenValue = 89
                                root.blueValue = 182
                            }
                        }
                    }
                    
                    // White preset
                    Rectangle {
                        width: 40
                        height: 40
                        color: "#ecf0f1"
                        radius: 20
                        
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                root.redValue = 236
                                root.greenValue = 240
                                root.blueValue = 241
                            }
                        }
                    }
                }
            }
        }
    }
}
