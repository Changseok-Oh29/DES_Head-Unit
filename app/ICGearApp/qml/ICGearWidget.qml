import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    id: root
    width: 280
    height: 400
    color: "transparent"

    property string gear: vehicleClient.currentGear

    // Outer ring
    Image {
        id: gaugeSpeedometer_Ticks3_gear
        x: 0
        y: 60
        width: 280
        height: 280
        source: "qrc:/images/GaugeSpeedometer_Ticks2.png"
        fillMode: Image.PreserveAspectFit
    }

    // Inner ring with label
    Image {
        id: gaugeSpeedometer_Ticks1_gear
        anchors.centerIn: gaugeSpeedometer_Ticks3_gear
        source: "qrc:/images/GaugeSpeedometer_Ticks1.png"
        fillMode: Image.PreserveAspectFit

        Text {
            x: 134
            y: 265
            width: 195
            height: 49
            color: "#730000"
            text: qsTr("Gear")
            font.pixelSize: 20
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    // Gear text display
    Text {
        id: gearText
        x: 65
        y: 125
        width: 150
        height: 150
        color: "#ffffff"
        text: gear
        font.pixelSize: 100
        font.bold: true
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter

        Behavior on text {
            SequentialAnimation {
                NumberAnimation {
                    target: gearText
                    property: "scale"
                    to: 1.1
                    duration: 100
                }
                NumberAnimation {
                    target: gearText
                    property: "scale"
                    to: 1.0
                    duration: 100
                }
            }
        }
    }

    Component.onCompleted: {
        console.log("ICGearWidget initialized - Gear:", gear)
    }

    Connections {
        target: vehicleClient
        function onCurrentGearChanged() {
            console.log("Gear changed:", vehicleClient.currentGear)
        }
    }
}
