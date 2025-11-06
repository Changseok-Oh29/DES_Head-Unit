import QtQuick 2.12
import QtQuick.Controls 2.12
import QtGraphicalEffects 1.0
import "components"

// Ambient lighting control page
Rectangle {
    id: root
    color: "transparent"

    property color selectedColor: ambientManager.ambientColor

    // Update ambient manager when color changes
    onSelectedColorChanged: {
        if (ambientManager.ambientLightEnabled) {
            ambientManager.ambientColor = selectedColor
        }
    }

    // Center content
    Item {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -60
        width: 700
        height: 420

        // Color wheel
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            width: 350
            height: 350
            color: "transparent"

            Control {
                id: colorWheel
                anchors.centerIn: parent
                property real ringWidth: 35
                property real hsvValue: 1.0
                property real hsvSaturation: 1.0

                readonly property color color: Qt.hsva(mousearea.angle, 1.0, 1.0, 1.0)

                onColorChanged: {
                    root.selectedColor = color
                }

                contentItem: Item {
                    implicitWidth: 350
                    implicitHeight: width

                    ShaderEffect {
                        id: shadereffect
                        width: parent.width
                        height: parent.height
                        readonly property real ringWidth: colorWheel.ringWidth / width / 2
                        readonly property real s: colorWheel.hsvSaturation
                        readonly property real v: colorWheel.hsvValue

                        vertexShader: "
                            attribute vec4 qt_Vertex;
                            attribute vec2 qt_MultiTexCoord0;
                            varying vec2 qt_TexCoord0;
                            uniform mat4 qt_Matrix;

                            void main() {
                                gl_Position = qt_Matrix * qt_Vertex;
                                qt_TexCoord0 = qt_MultiTexCoord0;
                            }"

                        fragmentShader: "
                            varying vec2 qt_TexCoord0;
                            uniform float qt_Opacity;
                            uniform float ringWidth;
                            uniform float s;
                            uniform float v;

                            vec3 hsv2rgb(vec3 c) {
                                vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
                                vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
                                return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
                            }

                            void main() {
                                vec2 coord = qt_TexCoord0 - vec2(0.5);
                                float ring = smoothstep(0.0, 0.01, -abs(length(coord) - 0.5 + ringWidth) + ringWidth);
                                gl_FragColor = vec4(hsv2rgb(vec3((atan(coord.y, coord.x) + 3.1415 + 3.1415 / 2.0) / 6.2831 + 0.5, s, v)), 1.0);
                                gl_FragColor *= ring;
                            }"
                    }

                    // Indicator on the wheel
                    Rectangle {
                        id: indicator
                        x: (parent.width - width)/2
                        y: colorWheel.ringWidth * 0.15

                        width: colorWheel.ringWidth * 0.7
                        height: width
                        radius: width/2

                        color: 'white'
                        border {
                            width: mousearea.containsPress ? 3 : 2
                            color: Qt.lighter(colorWheel.color)
                            Behavior on width { NumberAnimation { duration: 50 } }
                        }

                        transform: Rotation {
                            angle: mousearea.angle * 360
                            origin.x: indicator.width/2
                            origin.y: colorWheel.availableHeight/2 - indicator.y
                        }
                    }

                    MouseArea {
                        id: mousearea
                        anchors.fill: parent
                        property real angle: Math.atan2(width/2 - mouseX, mouseY - height/2) / 3.14 / 2 + 0.5
                    }
                }
            }

            // Center vehicle preview
            Item {
                anchors.centerIn: parent
                width: 140
                height: 100

                Image {
                    id: carImageAmbient
                    anchors.centerIn: parent
                    width: parent.width
                    height: parent.height
                    source: "qrc:/images/car.svg"
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                }

                ColorOverlay {
                    anchors.fill: carImageAmbient
                    source: carImageAmbient
                    color: "#ecf0f1"
                    opacity: 0.9
                }
            }
        }

        // Control panel below color wheel
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            width: 500
            height: 120
            radius: 15
            color: "#2c3e50"
            opacity: 0.95

            Row {
                anchors.centerIn: parent
                spacing: 40

                // Enable/Disable toggle
                Column {
                    spacing: 10
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        text: "Ambient Lighting"
                        font.pixelSize: 14
                        font.bold: true
                        color: "#95a5a6"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Switch {
                        id: ambientSwitch
                        checked: ambientManager.ambientLightEnabled
                        anchors.horizontalCenter: parent.horizontalCenter

                        onCheckedChanged: {
                            ambientManager.ambientLightEnabled = checked
                        }

                        indicator: Rectangle {
                            implicitWidth: 60
                            implicitHeight: 30
                            x: ambientSwitch.leftPadding
                            y: parent.height / 2 - height / 2
                            radius: 15
                            color: ambientSwitch.checked ? "#27ae60" : "#7f8c8d"
                            border.color: ambientSwitch.checked ? "#229954" : "#95a5a6"

                            Rectangle {
                                x: ambientSwitch.checked ? parent.width - width - 3 : 3
                                y: 3
                                width: 24
                                height: 24
                                radius: 12
                                color: "#ecf0f1"
                                border.color: "#bdc3c7"

                                Behavior on x {
                                    NumberAnimation { duration: 200 }
                                }
                            }

                            Behavior on color {
                                ColorAnimation { duration: 200 }
                            }
                        }
                    }

                    Text {
                        text: ambientSwitch.checked ? "ON" : "OFF"
                        font.pixelSize: 16
                        font.bold: true
                        color: ambientSwitch.checked ? "#27ae60" : "#7f8c8d"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }

                // Brightness control
                Column {
                    width: 280
                    spacing: 10
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        text: "Brightness: " + Math.round(brightnessSlider.value) + "%"
                        font.pixelSize: 14
                        font.bold: true
                        color: "#95a5a6"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    // Brightness slider maps UI 0%-100% to actual brightness 50%-100%
                    Slider {
                        id: brightnessSlider
                        width: parent.width
                        from: 0
                        to: 100
                        // Initialize from backend (reverse mapping: 0.5-1.0 → 0-100)
                        value: (ambientManager.brightness - 0.5) * 200
                        stepSize: 1
                        enabled: ambientSwitch.checked

                        onMoved: {
                            // Map slider value (0-100) to brightness (0.5-1.0)
                            var mappedBrightness = 0.5 + (value / 200.0)
                            ambientManager.brightness = mappedBrightness
                        }

                        background: Rectangle {
                            x: parent.leftPadding
                            y: parent.topPadding + parent.availableHeight / 2 - height / 2
                            implicitWidth: 200
                            implicitHeight: 6
                            width: parent.availableWidth
                            height: implicitHeight
                            radius: 3
                            color: "#34495e"

                            Rectangle {
                                // Use slider value (0-100) for visual fill, not backend brightness
                                width: parent.width * (brightnessSlider.value / 100.0)
                                height: parent.height
                                radius: parent.radius
                                color: enabled ? "#3498db" : "#7f8c8d"
                            }
                        }

                        handle: Rectangle {
                            x: parent.leftPadding + parent.visualPosition * (parent.availableWidth - width)
                            y: parent.topPadding + parent.availableHeight / 2 - height / 2
                            implicitWidth: 20
                            implicitHeight: 20
                            radius: 10
                            color: enabled ? "#3498db" : "#7f8c8d"
                            border.color: enabled ? "#2980b9" : "#95a5a6"
                            border.width: 2
                        }
                    }
                }
            }
        }
    }

    // Color preview panel
    Row {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 15
        spacing: 20

        // Current color preview
        Rectangle {
            width: 250
            height: 80
            radius: 10
            color: "#2c3e50"
            opacity: 0.95

            Row {
                anchors.centerIn: parent
                spacing: 15

                Rectangle {
                    width: 50
                    height: 50
                    radius: 25
                    color: root.selectedColor
                    border.color: Qt.darker(root.selectedColor, 1.3)
                    border.width: 3
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 5

                    Text {
                        text: "Selected Color"
                        font.pixelSize: 11
                        color: "#95a5a6"
                    }

                    Text {
                        text: root.selectedColor.toString().toUpperCase()
                        font.pixelSize: 14
                        font.bold: true
                        font.family: "monospace"
                        color: "#ecf0f1"
                    }
                }
            }
        }

        // Gear sync indicator
        Rectangle {
            width: 200
            height: 80
            radius: 10
            color: "#2c3e50"
            opacity: 0.95

            Column {
                anchors.centerIn: parent
                spacing: 8

                Text {
                    text: "Gear Sync"
                    font.pixelSize: 11
                    color: "#95a5a6"
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: "Color changes with gear"
                    font.pixelSize: 12
                    font.bold: true
                    color: "#ecf0f1"
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: "Current: " + gearManager.gearPosition
                    font.pixelSize: 13
                    font.bold: true
                    color: {
                        switch(gearManager.gearPosition) {
                            case "P": return "#e74c3c"
                            case "R": return "#e67e22"
                            case "N": return "#f39c12"
                            case "D": return "#27ae60"
                            default: return "#7f8c8d"
                        }
                    }
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }
    }
}
