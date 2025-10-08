import QtQuick 2.12
import QtQuick.Controls 2.12
import QtMultimedia 5.12
import HeadUnit 1.0

Page {
    id: root
    title: "USB Media Player"

    Column {
        anchors.fill: parent
        spacing: 8
        padding: 16

        Text {
            text: "USB Media Player"
            font.pixelSize: 24
            font.bold: true
            color: "#ecf0f1"
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Row {
            spacing: 10
            anchors.horizontalCenter: parent.horizontalCenter

            ComboBox {
                id: mountBox
                width: 300
                model: mediaManager.usbMounts
                textRole: ""
                background: Rectangle {
                    color: "#3498db"
                    radius: 5
                }
                contentItem: Text {
                    text: mountBox.displayText
                    color: "white"
                    leftPadding: 10
                    rightPadding: 10
                    verticalAlignment: Text.AlignVCenter
                }
            }
            
            Button {
                text: "Scan USB"
                background: Rectangle {
                    color: "#e74c3c"
                    radius: 5
                }
                contentItem: Text {
                    text: parent.text
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: {
                    var files = mediaManager.scanUsbAt(mountBox.currentText);
                    console.log("Found", files.length, "media files");
                }
            }

            Button {
                text: "Refresh USB"
                background: Rectangle {
                    color: "#27ae60" 
                    radius: 5
                }
                contentItem: Text {
                    text: parent.text
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: {
                    mediaManager.refreshUsbMounts();
                }
            }
        }

        Rectangle {
            width: parent.width - 32
            height: parent.height * 0.4
            color: "#2c3e50"
            radius: 10
            anchors.horizontalCenter: parent.horizontalCenter

            ListView {
                id: view
                anchors.fill: parent
                anchors.margins: 10
                model: mediaManager.mediaFiles
                delegate: ItemDelegate {
                    width: ListView.view.width - 20
                    height: 40
                    
                    Rectangle {
                        anchors.fill: parent
                        color: parent.hovered ? "#34495e" : "transparent"
                        radius: 5
                        
                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            text: {
                                var fileName = modelData.split("/").pop();
                                return fileName;
                            }
                            color: "#ecf0f1"
                            elide: Text.ElideRight
                            width: parent.width - 20
                        }
                    }
                    
                    onClicked: {
                        currentSongText.text = "Now Playing: " + modelData.split("/").pop();
                        mediaManager.playFile(index);
                    }
                }
            }
        }

        // Current Song Display
        Text {
            id: currentSongText
            text: mediaManager.currentFile ? "Now Playing: " + mediaManager.currentFile.split("/").pop() : "No media selected"
            color: "#ecf0f1"
            font.pixelSize: 16
            anchors.horizontalCenter: parent.horizontalCenter
            elide: Text.ElideRight
            width: parent.width - 32
        }

        // Control Buttons
        Row {
            spacing: 15
            anchors.horizontalCenter: parent.horizontalCenter
            
            Button {
                text: "⏮"
                width: 50
                height: 50
                background: Rectangle {
                    color: "#9b59b6"
                    radius: 25
                }
                contentItem: Text {
                    text: parent.text
                    color: "white"
                    font.pixelSize: 20
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: {
                    mediaManager.previous();
                }
            }
            
            Button {
                text: mediaManager.isPlaying ? "⏸" : "▶"
                width: 60
                height: 60
                background: Rectangle {
                    color: "#e74c3c"
                    radius: 30
                }
                contentItem: Text {
                    text: parent.text
                    color: "white"
                    font.pixelSize: 24
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: {
                    if (mediaManager.isPlaying) {
                        mediaManager.pause();
                    } else {
                        mediaManager.play();
                    }
                }
            }
            
            Button {
                text: "⏹"
                width: 50
                height: 50
                background: Rectangle {
                    color: "#34495e"
                    radius: 25
                }
                contentItem: Text {
                    text: parent.text
                    color: "white"
                    font.pixelSize: 20
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: {
                    mediaManager.stop();
                }
            }
            
            Button {
                text: "⏭"
                width: 50
                height: 50
                background: Rectangle {
                    color: "#9b59b6"
                    radius: 25
                }
                contentItem: Text {
                    text: parent.text
                    color: "white"
                    font.pixelSize: 20
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: {
                    mediaManager.next();
                }
            }
        }

        // USB Status
        Rectangle {
            width: parent.width - 32
            height: 40
            color: "#27ae60"
            radius: 5
            anchors.horizontalCenter: parent.horizontalCenter
            
            Text {
                anchors.centerIn: parent
                text: "USB Devices: " + mediaManager.usbMounts.length + " | Media Files: " + mediaManager.mediaFiles.length
                color: "#ecf0f1"
                font.pixelSize: 12
            }
        }
    }
}
