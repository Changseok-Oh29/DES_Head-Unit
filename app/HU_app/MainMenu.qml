import QtQuick 2.12
import QtQuick.Controls 2.12
import QtGraphicalEffects 1.0

Rectangle {
    id: root
    
    signal mediaSelected()
    signal ambientSelected()
    
    // 현재 ambient 색상을 추적하는 속성들
    property color currentAmbientColor: ipcManager.ambientLightEnabled ? ipcManager.ambientColor : "#34495e"
    property color gradientTopColor: Qt.lighter(currentAmbientColor, 1.3)
    property color gradientMiddleColor: currentAmbientColor
    property color gradientBottomColor: Qt.darker(currentAmbientColor, 2.0)
    
    // 색상 변경 애니메이션
    Behavior on currentAmbientColor {
        ColorAnimation { duration: 800; easing.type: Easing.OutQuad }
    }
    
    Behavior on gradientTopColor {
        ColorAnimation { duration: 800; easing.type: Easing.OutQuad }
    }
    
    Behavior on gradientMiddleColor {
        ColorAnimation { duration: 800; easing.type: Easing.OutQuad }
    }
    
    Behavior on gradientBottomColor {
        ColorAnimation { duration: 800; easing.type: Easing.OutQuad }
    }
    
    // Ambient light 색상을 배경 그라데이션으로 표시
    gradient: Gradient {
        GradientStop { 
            position: 0.0
            color: gradientTopColor
        }
        GradientStop { 
            position: 0.5
            color: gradientMiddleColor
        }
        GradientStop { 
            position: 1.0
            color: gradientBottomColor
        }
    }
    
    // 왼쪽 기어 선택 영역
    Rectangle {
        id: leftGearPanel
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 120
        color: "transparent"  // 투명하게 만들어 배경 그라데이션이 보이도록
        
        GearSelectionWidget {
            id: gearWidget
            compactMode: true
            anchors.centerIn: parent
        }
    }
    
    // 중앙 차량 이미지
    Rectangle {
        anchors.centerIn: parent
        width: 400
        height: 280
        color: "transparent"
        
        Image {
            id: carImage
            anchors.centerIn: parent
            width: 350
            height: 230
            source: "qrc:/images/car.svg"
            fillMode: Image.PreserveAspectFit
            opacity: 0.7
            
            // Ambient light에 따른 글로우 효과
            ColorOverlay {
                anchors.fill: carImage
                source: carImage
                color: {
                    if (ipcManager.ambientLightEnabled && ipcManager.ambientColor) {
                        return Qt.lighter(ipcManager.ambientColor, 1.5)
                    }
                    return "#ecf0f1"
                }
                opacity: 0.3
            }
        }
    }
    
    // 오른쪽 상단 버튼 영역
    Row {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 20
        anchors.rightMargin: 20
        spacing: 15
        
        // Media App Button (SVG 아이콘만)
        Rectangle {
            width: 60
            height: 60
            color: "transparent"
            
            Image {
                id: mediaIcon
                anchors.centerIn: parent
                source: "qrc:/images/mp3.svg"
                sourceSize.width: 60
                sourceSize.height: 60
                fillMode: Image.PreserveAspectFit
            }
            
            ColorOverlay {
                anchors.fill: mediaIcon
                source: mediaIcon
                color: "#ecf0f1"
            }
            
            MouseArea {
                anchors.fill: parent
                onClicked: root.mediaSelected()
                
                onPressed: {
                    parent.scale = 0.9
                }
                onReleased: {
                    parent.scale = 1.0
                }
            }
            
            Behavior on scale {
                NumberAnimation { duration: 100 }
            }
        }
        
        // Ambient Lighting Button (SVG 아이콘만)
        Rectangle {
            width: 60
            height: 60
            color: "transparent"
            
            Image {
                id: ambientIcon
                anchors.centerIn: parent
                source: "qrc:/images/ambient_light.svg"
                sourceSize.width: 60
                sourceSize.height: 60
                fillMode: Image.PreserveAspectFit
            }
            
            ColorOverlay {
                anchors.fill: ambientIcon
                source: ambientIcon
                color: "#ecf0f1"
            }
            
            MouseArea {
                anchors.fill: parent
                onClicked: root.ambientSelected()
                
                onPressed: {
                    parent.scale = 0.9
                }
                onReleased: {
                    parent.scale = 1.0
                }
            }
            
            Behavior on scale {
                NumberAnimation { duration: 100 }
            }
        }
    }
    

}
