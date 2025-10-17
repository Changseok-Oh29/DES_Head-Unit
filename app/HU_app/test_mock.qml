import QtQuick 2.15
import QtQuick.Controls 2.15
import HeadUnit 1.0

ApplicationWindow {
    id: window
    width: 800
    height: 600
    visible: true
    title: "Head Unit - Mock Data Test"

    MockVehicleService {
        id: mockService
    }

    Column {
        anchors.centerIn: parent
        spacing: 20

        Text {
            text: "🚗 Vehicle Status (Mock Data)"
            font.pixelSize: 24
            font.bold: true
        }

        Rectangle {
            width: 400
            height: 200
            color: "#f0f0f0"
            border.color: "#ccc"
            radius: 10

            Column {
                anchors.centerIn: parent
                spacing: 10

                Text {
                    text: "⚙️ Gear: " + getGearText(mockService.currentGear)
                    font.pixelSize: 18
                }
                
                Text {
                    text: "🔋 Battery: " + mockService.batteryLevel + "%"
                    font.pixelSize: 18
                    color: mockService.batteryLevel < 20 ? "red" : "black"
                }
                
                Text {
                    text: "🏃 Speed: " + mockService.currentSpeed.toFixed(1) + " km/h"
                    font.pixelSize: 18
                }
                
                Text {
                    text: "🔧 Engine: " + (mockService.engineStatus ? "ON" : "OFF")
                    font.pixelSize: 18
                    color: mockService.engineStatus ? "green" : "red"
                }
            }
        }

        Row {
            spacing: 10
            
            Button {
                text: "🔧 Toggle Engine"
                onClicked: mockService.setEngineStatus(!mockService.engineStatus)
            }
            
            Button {
                text: "⚙️ Set Drive (D)"
                onClicked: mockService.setGear(3)
            }
            
            Button {
                text: "⚙️ Set Park (P)"
                onClicked: mockService.setGear(0)
            }
            
            Button {
                text: "🚨 Emergency Stop"
                onClicked: mockService.emergencyStop()
                background: Rectangle {
                    color: "red"
                    radius: 5
                }
            }
        }
    }

    function getGearText(gear) {
        switch(gear) {
            case 0: return "P (Park)"
            case 1: return "R (Reverse)"
            case 2: return "N (Neutral)"
            case 3: return "D (Drive)"
            default: return "Unknown"
        }
    }
}
