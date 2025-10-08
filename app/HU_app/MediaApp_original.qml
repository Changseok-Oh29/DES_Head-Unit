import QtQuick 2.12
import QtQuick.Controls 2.12
import QtMultimedia 5.12

Page {
    id: root
    title: "Media Player"

    ListModel { id: fileList }

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
                model: UsbMedia.listMounts()
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
                    fileList.clear();
                    var files = UsbMedia.scanAt(mountBox.currentText);
                    for (var i=0; i<files.length; ++i) {
                        var fileName = files[i].split("/").pop();
                        fileList.append({ name: fileName, path: files[i] });
                    }
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
                    mountBox.model = UsbMedia.listMounts();
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
                model: fileList
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
                            text: name
                            color: "#ecf0f1"
                            elide: Text.ElideRight
                            width: parent.width - 20
                        }
                    }
                    
                    onClicked: {
                        currentSongText.text = "Now Playing: " + name;
                        player.source = "file://" + path;
                        player.play();
                    }
                }
            }
        }

        // Video Output (for video files)
        VideoOutput {
            id: video
            width: parent.width - 32
            height: parent.height * 0.25
            source: player
            visible: player.hasVideo
            anchors.horizontalCenter: parent.horizontalCenter
            
            Rectangle {
                anchors.fill: parent
                color: "#1a1a1a"
                radius: 10
                visible: !player.hasVideo
                
                Text {
                    anchors.centerIn: parent
                    text: "Audio Only"
                    color: "#7f8c8d"
                    font.pixelSize: 16
                }
            }
        }

        // Current Song Display
        Text {
            id: currentSongText
            text: "No media selected"
            color: "#ecf0f1"
            font.pixelSize: 16
            anchors.horizontalCenter: parent.horizontalCenter
            elide: Text.ElideRight
            width: parent.width - 32
        }

        // Media Player
        MediaPlayer {
            id: player
            autoPlay: false
            volume: 0.8
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
                    if (view.currentIndex > 0) {
                        view.currentIndex--;
                        var item = fileList.get(view.currentIndex);
                        currentSongText.text = "Now Playing: " + item.name;
                        player.source = "file://" + item.path;
                        player.play();
                    }
                }
            }
            
            Button {
                text: player.playbackState === MediaPlayer.PlayingState ? "⏸" : "▶"
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
                    if (player.playbackState === MediaPlayer.PlayingState) {
                        player.pause();
                    } else {
                        player.play();
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
                    player.stop();
                    currentSongText.text = "Stopped";
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
                    if (view.currentIndex < fileList.count - 1) {
                        view.currentIndex++;
                        var item = fileList.get(view.currentIndex);
                        currentSongText.text = "Now Playing: " + item.name;
                        player.source = "file://" + item.path;
                        player.play();
                    }
                }
            }
        }

        // Volume Control
        Row {
            spacing: 10
            anchors.horizontalCenter: parent.horizontalCenter
            
            Text {
                text: "Volume:"
                color: "#ecf0f1"
                anchors.verticalCenter: parent.verticalCenter
            }
            
            Slider {
                id: volumeSlider
                from: 0
                to: 1
                value: 0.8
                width: 200
                onValueChanged: player.volume = value
                
                background: Rectangle {
                    x: volumeSlider.leftPadding
                    y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                    implicitWidth: 200
                    implicitHeight: 4
                    width: volumeSlider.availableWidth
                    height: implicitHeight
                    radius: 2
                    color: "#bdc3c7"
                }
                
                handle: Rectangle {
                    x: volumeSlider.leftPadding + volumeSlider.visualPosition * (volumeSlider.availableWidth - width)
                    y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                    implicitWidth: 20
                    implicitHeight: 20
                    radius: 10
                    color: "#3498db"
                }
            }
        }
    }
}
