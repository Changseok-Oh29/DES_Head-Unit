import QtQuick 2.15
import Design 1.0
import QtQuick.Window 2.15

Window {
    id: mainWindow
    width: Constants.width   // DSI display width (400)
    height: Constants.height // DSI display height (1280)
    visible: true
    visibility: "FullScreen"      // fullscreen
    flags: Qt.FramelessWindowHint // fullscreen
    title: "Design"
    color: "#000000"  // Black background for unused space

    Component.onCompleted: Qt.inputMethod.hide()

    // Native 1:1 scaling for DSI display (400x1280 portrait)
    Screen01Form {
        id: mainScreen
        anchors.fill: parent
    }
}
