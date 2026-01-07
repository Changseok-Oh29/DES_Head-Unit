import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    id: root
    width: 280
    height: 400
    color: "transparent"

    property int batteryLevel: vehicleClient.batteryLevel

    // Outer ring
    Image {
        id: gaugeSpeedometer_Ticks4_battery
        x: 0
        y: 60
        width: 280
        height: 280
        source: "qrc:/images/GaugeSpeedometer_Ticks2.png"
        fillMode: Image.PreserveAspectFit
    }

    // Inner ring with label
    Image {
        id: gaugeSpeedometer_Ticks5_battery
        anchors.centerIn: gaugeSpeedometer_Ticks4_battery
        source: "qrc:/images/GaugeSpeedometer_Ticks1.png"
        fillMode: Image.PreserveAspectFit

        Text {
            x: 134
            y: 265
            width: 195
            height: 49
            color: "#730000"
            text: qsTr("Battery")
            font.pixelSize: 20
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    // Battery fill indicator
    Rectangle {
        id: battery_fill
        width: 68
        height: 110 * batteryLevel / 100
        x: 103
        y: 258 - height
        z: 1

        color: batteryLevel <= 20 ? "#ff4444"
             : batteryLevel <= 60 ? "#ffaa33"
                                  : "#57e389"

        Behavior on height {
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutQuad
            }
        }

        Behavior on color {
            ColorAnimation {
                duration: 300
            }
        }
    }

    // Battery outline icon
    Image {
        id: battery_outline_icon
        x: 80
        y: 80
        width: 120
        source: "qrc:/images/battery_outline_icon.png"
        fillMode: Image.PreserveAspectFit
        z: 2
    }

    // Battery percentage text
    Text {
        id: battery_text
        anchors.centerIn: battery_outline_icon
        font.pixelSize: 25
        font.bold: true
        color: "white"
        text: batteryLevel + "%"
        z: 3
    }

    Component.onCompleted: {
        console.log("BatteryWidget initialized - Battery:", batteryLevel, "%")
    }

    Connections {
        target: vehicleClient
        function onBatteryLevelChanged() {
            console.log("Battery changed:", vehicleClient.batteryLevel, "%")
        }
    }
}
