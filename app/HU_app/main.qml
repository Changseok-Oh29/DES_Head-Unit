import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.12
import HeadUnit 1.0

ApplicationWindow {
    id: window
    width: 1024
    height: 600
    visible: true
    title: qsTr("Head Unit - SEA-ME Project")
    
    property int currentPage: 0  // 0: Main, 1: Media, 2: Ambient
    
    // Connection status indicator
    property bool isConnected: ipcManager.isConnected
    
    // Main Content Area - 전체 화면 사용
    Rectangle {
        anchors.fill: parent
        
        // Ambient light 색상을 전체 배경에 적용
        gradient: Gradient {
            GradientStop { 
                position: 0.0
                color: ipcManager.ambientLightEnabled ? 
                       Qt.lighter(ipcManager.ambientColor, 1.8) : "#34495e"
            }
            GradientStop { 
                position: 1.0
                color: "#34495e"
            }
        }
        
        Behavior on gradient {
            PropertyAnimation { duration: 1500 }
        }
        
        // Main Menu
        MainMenu {
            id: mainMenu
            visible: window.currentPage === 0
            anchors.fill: parent
            
            onMediaSelected: window.currentPage = 1
            onAmbientSelected: window.currentPage = 2
        }
        
        // Media App Page
        MediaApp {
            id: mediaPage
            visible: window.currentPage === 1
            anchors.fill: parent
            
            onBackClicked: window.currentPage = 0
        }
        
        // Ambient Lighting Page
        AmbientLighting {
            id: ambientPage
            visible: window.currentPage === 2
            anchors.fill: parent
            
            onBackClicked: window.currentPage = 0
        }
    }
}
