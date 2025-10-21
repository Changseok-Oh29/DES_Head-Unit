import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.3
import QtGraphicalEffects 1.0
// HeadUnit 모듈 제거: C++ backend는 contextProperty로 노출됨

// AmbientApp 독립 실행용 메인 윈도우
Window {
    id: window
    width: 800
    height: 600
    visible: true
    title: "AmbientApp - Ambient Lighting Control"

    Rectangle {
        id: root
        anchors.fill: parent
        color: "#1a1a1a"  // Very dark background (to see brightness effect)

        signal backClicked()

        // Background color from color wheel
        property color displayColor: colorWheel.color

        // Background gradient layer with brightness control
        Rectangle {
            id: backgroundGradient
            anchors.fill: parent

            // Calculate brightness-adjusted colors
            property real brightnessValue: ambientManager.brightness
            property color brightColor: Qt.rgba(
                root.displayColor.r * brightnessValue,
                root.displayColor.g * brightnessValue,
                root.displayColor.b * brightnessValue,
                1.0
            )

            // Ambient light 색상을 배경 그라데이션으로 표시
            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: Qt.lighter(backgroundGradient.brightColor, 1.3)
                }
                GradientStop {
                    position: 0.5
                    color: backgroundGradient.brightColor
                }
                GradientStop {
                    position: 1.0
                    color: Qt.darker(backgroundGradient.brightColor, 1.5)
                }
            }

            // Brightness animation
            Behavior on brightnessValue {
                NumberAnimation { duration: 200; easing.type: Easing.OutQuad }
            }
        }

        // Color animation
        Behavior on displayColor {
            ColorAnimation { duration: 300; easing.type: Easing.OutQuad }
        }

        // Listen to ambientManager color changes (from external sources like gear changes)
        Connections {
            target: ambientManager
            function onAmbientColorChanged() {
                if (ambientManager.ambientColor !== "" &&
                    ambientManager.ambientColor !== root.displayColor.toString()) {
                    console.log("Backend color changed to:", ambientManager.ambientColor)
                    root.displayColor = ambientManager.ambientColor
                }
            }
        }

        // Update backend when color wheel changes
        onDisplayColorChanged: {
            var colorString = displayColor.toString()
            if (ambientManager.ambientColor !== colorString) {
                console.log("Display color changed to:", colorString)
                ambientManager.ambientColor = colorString
            }
        }
    
    // Title text (standalone mode - no back button needed)
    Text {
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 20
        text: "Ambient Lighting Control"
        font.pixelSize: 24
        font.bold: true
        color: "#ecf0f1"
        z: 100
    }
    
    // 중앙 색상 휠 컨트롤
    Rectangle {
        anchors.centerIn: parent
        width: 350
        height: 350
        color: "transparent"
            
        Control {
            id: colorWheel
            anchors.centerIn: parent
            property real ringWidth: 30
            property real hsvValue: 1.0
            property real hsvSaturation: 1.0

            readonly property color color: Qt.hsva(mousearea.angle, 1.0, 1.0, 1.0)

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

                Rectangle {
                    id: indicator
                    x: (parent.width - width)/2
                    y: colorWheel.ringWidth * 0.1

                    width: colorWheel.ringWidth * 0.8; height: width
                    radius: width/2

                    color: 'white'
                    border {
                        width: mousearea.containsPress ? 3 : 1
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

        // 중앙 텍스트 표시 (색상 원 안)
        Text {
            anchors.centerIn: parent
            text: "Ambient\nLighting"
            font.pixelSize: 32
            font.bold: true
            color: "#ecf0f1"
            horizontalAlignment: Text.AlignHCenter
            style: Text.Outline
            styleColor: "#2c3e50"
        }
    }

    // Brightness control slider (bottom of screen)
    // Maps UI range 0%-100% to actual brightness 50%-100%
    Slider {
        id: brightnessSlider
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 30
        width: 300
        from: 0.0
        to: 1.0
        // Initialize slider position from backend brightness (reverse mapping: 0.5-1.0 → 0.0-1.0)
        value: (ambientManager.brightness - 0.5) / 0.5
        z: 10  // Above background

        onMoved: {
            // Map slider value (0.0-1.0) to brightness (0.5-1.0)
            var mappedBrightness = 0.5 + (value * 0.5)
            console.log("Brightness slider UI:", Math.round(value * 100) + "% → Actual:", Math.round(mappedBrightness * 100) + "%")
            ambientManager.brightness = mappedBrightness
        }

        Text {
            anchors.bottom: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottomMargin: 10
            text: "Brightness: " + Math.round(brightnessSlider.value * 100) + "%"
            color: "#ecf0f1"
            font.pixelSize: 16
            font.bold: true
        }
    }

    } // Rectangle root
} // Window
