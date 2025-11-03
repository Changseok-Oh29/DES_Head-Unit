import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.12
// HeadUnit 모듈 제거: C++ backend는 contextProperty로 노출됨

// GearApp 독립 실행용 메인 윈도우
Window {
    id: window
    width: 400
    height: 600
    visible: true
    title: "GearApp - Gear Selection"
    
    Rectangle {
        anchors.fill: parent
        
        // Ambient lighting 효과를 위한 그라데이션 배경
        gradient: Gradient {
            GradientStop { 
                position: 0.0
                color: {
                    // 기어에 따른 ambient 색상 (버튼과 매칭)
                    switch(root.currentGear) {
                        case "P": return Qt.lighter("#3498db", 1.3)  // Blue (Park)
                        case "R": return Qt.lighter("#e67e22", 1.3)  // Orange (Reverse)
                        case "N": return Qt.lighter("#f39c12", 1.3)  // Yellow (Neutral)
                        case "D": return Qt.lighter("#27ae60", 1.3)  // Green (Drive)
                        default: return "#34495e"
                    }
                }
                
                Behavior on color {
                    ColorAnimation { duration: 300 }
                }
            }
            GradientStop { 
                position: 1.0
                color: "#34495e"
            }
        }
        
        Column {
            anchors.centerIn: parent
            spacing: 30
            
            // Title
            Text {
                text: "GearApp Test"
                font.pixelSize: 24
                font.bold: true
                color: "#ecf0f1"
                anchors.horizontalCenter: parent.horizontalCenter
            }
            
            // Current Gear Display
            Rectangle {
                width: 120
                height: 120
                radius: 60
                color: "#2c3e50"
                border.color: "#1abc9c"
                border.width: 3
                anchors.horizontalCenter: parent.horizontalCenter
                
                Column {
                    anchors.centerIn: parent
                    spacing: 5
                    
                    Text {
                        text: "Current"
                        font.pixelSize: 12
                        color: "#95a5a6"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    
                    Text {
                        text: root.currentGear
                        font.pixelSize: 40
                        font.bold: true
                        color: "#1abc9c"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }
            
            // 재사용 가능한 기어 선택 위젯 컴포넌트
            Column {
                id: root
                anchors.horizontalCenter: parent.horizontalCenter
                
                property string currentGear: gearManager.gearPosition
                property bool compactMode: false  // 독립 실행 시 큰 모드
                
                spacing: compactMode ? 8 : 12
                
                // GearManager의 gearPositionChanged 시그널을 감지하여 UI 업데이트
                Connections {
                    target: gearManager
                    function onGearPositionChanged(gear) {
                        root.currentGear = gear
                        console.log("GearApp QML: Gear position updated to:", gear)
                    }
                }
    
    // 기어 선택 버튼들
    Repeater {
        model: ["P", "R", "N", "D"]
        
        Rectangle {
            width: root.compactMode ? 50 : 80
            height: root.compactMode ? 50 : 70
            color: {
                if (root.currentGear === modelData) {
                    switch(modelData) {
                        case "P": return "#3498db"  // 파란색 (Park)
                        case "R": return "#e67e22"  // 주황색 (Reverse)
                        case "N": return "#f39c12"  // 노란색 (Neutral)
                        case "D": return "#27ae60"  // 녹색 (Drive)
                    }
                }
                return "#7f8c8d"  // 비활성 회색
            }
            radius: root.compactMode ? 25 : 10
            border.color: {
                if (root.currentGear === modelData) {
                    switch(modelData) {
                        case "P": return "#2980b9"  // 진한 파란색 (Park)
                        case "R": return "#ca6f1e"
                        case "N": return "#e67e22"
                        case "D": return "#229954"
                    }
                }
                return "#95a5a6"
            }
            border.width: 2
            
            // 글로우 효과 (선택된 기어용)
            Rectangle {
                anchors.centerIn: parent
                width: parent.width + 4
                height: parent.height + 4
                color: "transparent"
                radius: parent.radius + 2
                border.color: parent.color
                border.width: 1
                opacity: root.currentGear === modelData ? 0.6 : 0
                visible: root.currentGear === modelData
                
                Behavior on opacity {
                    NumberAnimation { duration: 200 }
                }
            }
            
            Text {
                anchors.centerIn: parent
                text: modelData
                font.pixelSize: root.compactMode ? 20 : 32
                font.bold: true
                color: "#ecf0f1"
            }
            
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    gearManager.gearPosition = modelData
                    console.log("Gear changed to:", modelData)
                }
                
                // 터치 피드백 효과
                onPressed: {
                    parent.scale = 0.95
                    parent.opacity = 0.8
                }
                onReleased: {
                    parent.scale = 1.0
                    parent.opacity = 1.0
                }
            }
            
            // 애니메이션 효과
            Behavior on color {
                ColorAnimation { duration: 200 }
            }
            
            Behavior on scale {
                NumberAnimation { duration: 100 }
            }
            
            Behavior on opacity {
                NumberAnimation { duration: 100 }
            }
        }
    }
    
    // 현재 기어 라벨 (컴팩트 모드가 아닐 때만 표시)
    Text {
        visible: !root.compactMode
        anchors.horizontalCenter: parent.horizontalCenter
        text: {
            switch(root.currentGear) {
                case "P": return "PARK"
                case "R": return "REVERSE"
                case "N": return "NEUTRAL"
                case "D": return "DRIVE"
                default: return ""
            }
        }
        font.pixelSize: 12
        font.bold: true
        color: "#bdc3c7"
        horizontalAlignment: Text.AlignHCenter
    }
            } // Column (root)
            
            // Gear Description
            Text {
                text: {
                    switch(root.currentGear) {
                        case "P": return "Park - Vehicle locked"
                        case "R": return "Reverse - Backward"
                        case "N": return "Neutral - Free roll"
                        case "D": return "Drive - Forward"
                        default: return ""
                    }
                }
                font.pixelSize: 14
                color: "#bdc3c7"
                anchors.horizontalCenter: parent.horizontalCenter
            }
            
            // IC Connection Status
            Rectangle {
                width: 180
                height: 28
                radius: 14
                color: ipcManager.isConnected ? "#27ae60" : "#e74c3c"
                anchors.horizontalCenter: parent.horizontalCenter
                
                Text {
                    anchors.centerIn: parent
                    text: ipcManager.isConnected ? "✓ IC Connected" : "✗ IC Disconnected"
                    font.pixelSize: 11
                    color: "white"
                }
            }
        } // Column (main layout)
    } // Rectangle
} // Window
