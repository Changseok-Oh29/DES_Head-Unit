import QtQuick 2.12
import QtQuick.Controls 2.12
import HeadUnit 1.0

Rectangle {
    id: root
    color: "#34495e"
    
    // Use actual media manager properties
    property bool isPlaying: mediaManager.isPlaying
    property string currentSong: mediaManager.currentFile
    property int currentIndex: mediaManager.currentIndex
    property var mediaFiles: mediaManager.mediaFiles
    
    // Function to get just the filename from full path
    function getFileName(filePath) {
        if (!filePath) return "No song selected"
        var parts = filePath.split('/')
        return parts[parts.length - 1]
    }
    
    Text {
        id: titleText
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 20
        text: "Media Player"
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
        spacing: 20
        height: parent.height - titleText.height - 50
        
        // Media List
        Rectangle {
            width: parent.width * 0.6
            height: parent.height
            color: "#2c3e50"
            radius: 10
            
            Column {
                anchors.fill: parent
                anchors.margins: 10
                
                Text {
                    text: "USB Media Files"
                    font.pixelSize: 18
                    font.bold: true
                    color: "#ecf0f1"
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                
                Rectangle {
                    width: parent.width
                    height: 2
                    color: "#3498db"
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                
                ListView {
                    width: parent.width
                    height: parent.height - 40
                    model: root.mediaFiles
                    
                    delegate: Rectangle {
                        width: parent.width
                        height: 50
                        color: root.currentIndex === index ? "#3498db" : "transparent"
                        radius: 5
                        
                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.getFileName(modelData)
                            color: "#ecf0f1"
                            font.pixelSize: 14
                            elide: Text.ElideRight
                            width: parent.width - 20
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                mediaManager.playFile(index)
                                console.log("Playing: " + modelData)
                            }
                        }
                    }
                }
            }
        }
        
        // Player Controls
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
                    text: "Now Playing"
                    font.pixelSize: 18
                    font.bold: true
                    color: "#ecf0f1"
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                
                Rectangle {
                    width: parent.width
                    height: 60
                    color: "#34495e"
                    radius: 5
                    border.color: "#3498db"
                    border.width: 1
                    
                    Text {
                        anchors.centerIn: parent
                        text: root.getFileName(root.currentSong)
                        color: "#ecf0f1"
                        font.pixelSize: 12
                        wrapMode: Text.WordWrap
                        horizontalAlignment: Text.AlignHCenter
                        anchors.margins: 10
                        width: parent.width - 20
                    }
                }
                
                // Control Buttons
                Row {
                    spacing: 15
                    anchors.horizontalCenter: parent.horizontalCenter
                    
                    // Previous Button
                    Rectangle {
                        width: 50
                        height: 50
                        color: "#7f8c8d"
                        radius: 25
                        
                        Text {
                            anchors.centerIn: parent
                            text: "⏮"
                            font.pixelSize: 20
                            color: "#ecf0f1"
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                mediaManager.previous()
                            }
                        }
                    }
                    
                    // Play/Pause Button
                    Rectangle {
                        width: 60
                        height: 60
                        color: root.isPlaying ? "#e74c3c" : "#27ae60"
                        radius: 30
                        
                        Text {
                            anchors.centerIn: parent
                            text: root.isPlaying ? "⏸" : "▶"
                            font.pixelSize: 24
                            color: "#ecf0f1"
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (root.isPlaying) {
                                    mediaManager.pause()
                                } else {
                                    mediaManager.play()
                                }
                                console.log("Playback: " + (root.isPlaying ? "Paused" : "Playing"))
                            }
                        }
                    }
                    
                    // Next Button
                    Rectangle {
                        width: 50
                        height: 50
                        color: "#7f8c8d"
                        radius: 25
                        
                        Text {
                            anchors.centerIn: parent
                            text: "⏭"
                            font.pixelSize: 20
                            color: "#ecf0f1"
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                mediaManager.next()
                            }
                        }
                    }
                }
                
                // Volume Control
                Column {
                    width: parent.width
                    spacing: 10
                    
                    Text {
                        text: "Volume"
                        font.pixelSize: 16
                        color: "#ecf0f1"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    
                    Slider {
                        width: parent.width
                        from: 0
                        to: 100
                        value: 50
                        anchors.horizontalCenter: parent.horizontalCenter
                        
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
                }
                
                // USB Status
                Rectangle {
                    width: parent.width
                    height: 40
                    color: "#27ae60"
                    radius: 5
                    
                    Text {
                        anchors.centerIn: parent
                        text: "USB Connected - " + root.mediaFiles.length + " files found"
                        color: "#ecf0f1"
                        font.pixelSize: 12
                    }
                }
            }
        }
    }
}
