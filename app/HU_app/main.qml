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
    
    property int currentPage: 0  // 0: Main, 1: Gear, 2: Media, 3: Ambient
    
    // Connection status indicator
    property bool isConnected: ipcManager.isConnected
    
    // Main Header
    Rectangle {
        id: header
        anchors.top: parent.top
        width: parent.width
        height: 80
        color: "#2c3e50"
        
        Text {
            anchors.centerIn: parent
            text: "HEAD UNIT SYSTEM"
            font.pixelSize: 24
            font.bold: true
            color: "#ecf0f1"
        }
        
        // Back button (visible when not on main page)
        Rectangle {
            id: backButton
            visible: window.currentPage !== 0
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 20
            width: 60
            height: 40
            color: "#34495e"
            radius: 5
            
            Text {
                anchors.centerIn: parent
                text: "← Back"
                color: "#ecf0f1"
                font.pixelSize: 14
            }
            
            MouseArea {
                anchors.fill: parent
                onClicked: window.currentPage = 0
            }
        }
    }
    
    // Main Content Area
    Rectangle {
        anchors.top: header.bottom
        anchors.bottom: parent.bottom
        width: parent.width
        color: "#34495e"
        
        // Main Menu
        MainMenu {
            id: mainMenu
            visible: window.currentPage === 0
            anchors.fill: parent
            
            onGearSelected: window.currentPage = 1
            onMediaSelected: window.currentPage = 2
            onAmbientSelected: window.currentPage = 3
        }
        
        // Gear Selection Page
        GearSelection {
            id: gearPage
            visible: window.currentPage === 1
            anchors.fill: parent
        }
        
        // Media App Page
        MediaApp {
            id: mediaPage
            visible: window.currentPage === 2
            anchors.fill: parent
        }
        
        // Ambient Lighting Page
        AmbientLighting {
            id: ambientPage
            visible: window.currentPage === 3
            anchors.fill: parent
        }
    }
}
