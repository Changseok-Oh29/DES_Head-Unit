import QtQuick 2.12
import QtQuick.Controls 2.12

Rectangle {
    id: root
    color: "#34495e"
    
    property bool isPlaying: false
    property string currentSong: "No song selected"
    property int currentIndex: -1
    
    // Mock USB media files (in real implementation, this would come from USB scan)
    property var mediaFiles: [
        "Song 1 - Artist A.mp3",
        "Song 2 - Artist B.mp3", 
        "Song 3 - Artist C.mp3",
        "Song 4 - Artist D.mp3",
        "Song 5 - Artist E.mp3"
    ]
    
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
                            text: modelData
                            color: "#ecf0f1"
                            font.pixelSize: 14
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                root.currentIndex = index
                                root.currentSong = modelData
                                console.log("Selected: " + modelData)
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
                        text: root.currentSong
                        color: "#ecf0f1"
                        font.pixelSize: 12
                        wrapMode: Text.WordWrap
                        horizontalAlignment: Text.AlignHCenter
                        anchors.margins: 10
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
                                if (root.currentIndex > 0) {
                                    root.currentIndex--
                                    root.currentSong = root.mediaFiles[root.currentIndex]
                                }
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
                                root.isPlaying = !root.isPlaying
                                if (root.currentIndex === -1 && root.mediaFiles.length > 0) {
                                    root.currentIndex = 0
                                    root.currentSong = root.mediaFiles[0]
                                }
                                console.log("Playback: " + (root.isPlaying ? "Playing" : "Paused"))
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
                                if (root.currentIndex < root.mediaFiles.length - 1) {
                                    root.currentIndex++
                                    root.currentSong = root.mediaFiles[root.currentIndex]
                                }
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
