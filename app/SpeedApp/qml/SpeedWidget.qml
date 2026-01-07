import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    id: root
    width: 400
    height: 400
    color: "transparent"

    property int speed: vehicleClient.currentSpeed

    onSpeedChanged: {
        var angle = -45 + (speed * 1.125)
        needleRotation.angle = angle
    }

    // Speedometer background
    Image {
        id: gauge_Speed
        anchors.centerIn: parent
        width: 400
        height: 400
        source: "qrc:/images/Gauge_Speed.png"
        rotation: 45
        fillMode: Image.PreserveAspectFit
    }

    // Ticks overlay
    Image {
        id: gaugeSpeedometer_Ticks2
        anchors.centerIn: parent
        width: 259
        height: 278
        source: "qrc:/images/GaugeSpeedometer_Ticks2.png"
        fillMode: Image.PreserveAspectFit
    }

    // Needle
    Image {
        id: gaugeNeedleBig
        anchors.centerIn: gauge_Speed
        anchors.horizontalCenterOffset: -49
        width: 160
        height: 66
        source: "qrc:/images/gaugeNeedleBig.png"
        fillMode: Image.PreserveAspectFit

        transform: Rotation {
            id: needleRotation
            origin.x: 130
            origin.y: 33
            angle: -45

            Behavior on angle {
                NumberAnimation {
                    duration: 100
                    easing.type: Easing.OutQuad
                }
            }
        }
    }

    // Bottom panel
    Image {
        id: bottomPanel
        anchors.horizontalCenter: parent.horizontalCenter
        y: 209
        width: 697
        height: 298
        source: "qrc:/images/BottomPanel.png"
        fillMode: Image.PreserveAspectFit
    }

    // Speed text display
    Text {
        id: speedText
        anchors.horizontalCenter: parent.horizontalCenter
        y: 332
        width: 188
        height: 81
        color: "#ffffff"
        text: speed.toString()
        font.pixelSize: 30
        font.bold: true
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    Component.onCompleted: {
        console.log("SpeedWidget initialized - Speed:", speed)
    }

    Connections {
        target: vehicleClient
        function onCurrentSpeedChanged() {
            console.log("Speed changed:", vehicleClient.currentSpeed, "km/h")
        }
    }
}
