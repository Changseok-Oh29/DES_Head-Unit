import QtQuick 2.15
import QtQuick.Controls 2.15
import Design 1.0

Rectangle {
    id: rectangle
    width: Constants.width   // 400 (portrait)
    height: Constants.height // 1280 (portrait)
    color: "#000000"

    property int speed: 0
    property string gear: "P"

    Component.onCompleted: {
        gear = vehicleClient.currentGear
        console.log("🎬 IC_app initialized - Gear:", gear, "Battery:", vehicleClient.batteryLevel)
    }

    Connections {
        target: vehicleClient
        function onCurrentGearChanged() {
            console.log("📡 Gear changed:", vehicleClient.currentGear)
            gear = vehicleClient.currentGear
        }
        function onBatteryLevelChanged() {
            console.log("📡 Battery changed:", vehicleClient.batteryLevel)
        }
        function onCurrentSpeedChanged() {
            console.log("📡 Speed changed:", vehicleClient.currentSpeed, "km/h")
            speed = vehicleClient.currentSpeed
        }
    }

    Connections {
        target: canInterface
        onSpeedDataReceived: {
            console.log("🏎️  CAN Speed:", speedCms, "cm/s")
            speed = Math.round(speedCms);
        }
    }

    onSpeedChanged: {
        var angle = -45 + (speed * 1.125)
        console.log("📊 Needle angle:", angle, "for speed:", speed)
        needleRotation.angle = angle
    }

    // Rotated container: Render landscape (1280x400) inside portrait canvas (400x1280)
    Item {
        id: rotatedContent
        width: 1280   // Landscape width
        height: 400   // Landscape height
        anchors.centerIn: parent
        rotation: -90  // Rotate -90° so landscape content appears upright when screen is portrait

        // ===== LEFT: GEAR SECTION (x: 0-400) =====
        Rectangle {
            id: gearSection
            x: 60
            y: 0
            width: 280
            height: 400
            color: "transparent"

            Image {
                id: gaugeSpeedometer_Ticks3_gear
                x: 0
                y: 60
                width: 280
                height: 280
                source: "images/GaugeSpeedometer_Ticks2.png"
                fillMode: Image.PreserveAspectFit
            }

            Image {
                id: gaugeSpeedometer_Ticks1_gear
                anchors.centerIn: gaugeSpeedometer_Ticks3_gear
                source: "images/GaugeSpeedometer_Ticks1.png"
                fillMode: Image.PreserveAspectFit

                TextInput {
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
                    readOnly: true
                }
            }

            TextInput {
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
                readOnly: true
            }
        }

        // ===== CENTER: SPEEDOMETER SECTION (x: 440-840) =====
        Rectangle {
            id: speedometerSection
            x: 440
            y: 0
            width: 400
            height: 400
            color: "transparent"

            Image {
                id: gauge_Speed
                anchors.centerIn: parent
                width: 400
                height: 400
                source: "images/Gauge_Speed.png"
                rotation: 45
                fillMode: Image.PreserveAspectFit
            }

            Image {
                id: gaugeSpeedometer_Ticks2
                anchors.centerIn: parent
                width: 259
                height: 278
                source: "images/GaugeSpeedometer_Ticks2.png"
                fillMode: Image.PreserveAspectFit
            }

            Image {
                id: gaugeNeedleBig
                anchors.centerIn: gauge_Speed
                anchors.horizontalCenterOffset: -49
                width: 160
                height: 66
                source: "images/gaugeNeedleBig.png"
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

            Image {
                id: bottomPanel
                anchors.horizontalCenter: parent.horizontalCenter
                y: 209
                width: 697
                height: 298
                source: "images/BottomPanel.png"
                fillMode: Image.PreserveAspectFit
            }

            TextInput {
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
                readOnly: true
            }
        }

        // ===== RIGHT: BATTERY SECTION (x: 940-1280) =====
        Rectangle {
            id: batterySection
            x: 940
            y: 0
            width: 280
            height: 400
            color: "transparent"

            Image {
                id: gaugeSpeedometer_Ticks4_battery
                x: 0
                y: 60
                width: 280
                height: 280
                source: "images/GaugeSpeedometer_Ticks2.png"
                fillMode: Image.PreserveAspectFit
            }

            Image {
                id: gaugeSpeedometer_Ticks5_battery
                anchors.centerIn: gaugeSpeedometer_Ticks4_battery
                source: "images/GaugeSpeedometer_Ticks1.png"
                fillMode: Image.PreserveAspectFit

                TextInput {
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
                    readOnly: true
                }
            }

            Rectangle {
                id: battery_fill
                width: 68
                height: 110 * vehicleClient.batteryLevel / 100
                x: 103
                y: 258 - height
                z: 1

                color: vehicleClient.batteryLevel <= 20 ? "#ff4444"
                     : vehicleClient.batteryLevel <= 60 ? "#ffaa33"
                                                        : "#57e389"
            }

            Image {
                id: battery_outline_icon
                x: 80
                y: 80
                width: 120
                source: "images/battery_outline_icon.png"
                fillMode: Image.PreserveAspectFit
                z: 2
            }

            Text {
                id: battery_text
                anchors.centerIn: battery_outline_icon
                font.pixelSize: 25
                font.bold: true
                color: "white"
                text: vehicleClient.batteryLevel + "%"
                z: 3
            }
        }
    }
}
