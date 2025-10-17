import QtQuick 2.15
import Design 1.0
import QtQuick.Window 2.15

Window {
    id: mainWindow
    width: mainScreen.width
    height: mainScreen.height
    visible: true
    visibility: "FullScreen"      // fullscreen
    flags: Qt.FramelessWindowHint // fullscreen
    title: "Design"

    Component.onCompleted: Qt.inputMethod.hide()

    Screen01Form {
        id: mainScreen
    }
}
