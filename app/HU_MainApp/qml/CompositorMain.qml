import QtQuick 2.15
import QtQuick.Window 2.15
import QtWayland.Compositor 1.15

WaylandCompositor {
    id: compositor
    socketName: "wayland-hu"  // 명시적으로 소켓 이름 지정
    
    // Compositor window
    WaylandOutput {
        compositor: compositor
        
        window: Window {
            id: mainWindow
            width: 1280
            height: 480
            visible: true
            title: "HU MainApp - Wayland Compositor"
            color: "#000000"
            
            Rectangle {
                id: root
                anchors.fill: parent
                color: "#000000"
                
                // ══════════════════════════════════════════════════
                // Layout Areas
                // ══════════════════════════════════════════════════
                
                // Left panel: GearApp (300px width)
                Rectangle {
                    id: gearArea
                    width: 300
                    height: parent.height
                    x: 0
                    y: 0
                    color: "#1a1a1a"
                    border.color: "#333333"
                    border.width: 1
                    
                    Text {
                        anchors.centerIn: parent
                        text: "GearApp\n(Wayland Client)"
                        color: "#888888"
                        font.pixelSize: 18
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
                
                // Right panel: MediaApp / AmbientApp (980px width)
                Rectangle {
                    id: contentArea
                    width: 980
                    height: parent.height
                    x: 300
                    y: 0
                    color: "#0d0d0d"
                    
                    // Tab bar
                    Rectangle {
                        id: tabBar
                        width: parent.width
                        height: 60
                        color: "#1a1a1a"
                        
                        Row {
                            anchors.centerIn: parent
                            spacing: 20
                            
                            Rectangle {
                                id: mediaTab
                                width: 150
                                height: 40
                                color: tabState.currentTab === "media" ? "#4a4a4a" : "#2a2a2a"
                                radius: 5
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: "Media"
                                    color: "#ffffff"
                                    font.pixelSize: 16
                                }
                                
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: tabState.currentTab = "media"
                                }
                            }
                            
                            Rectangle {
                                id: ambientTab
                                width: 150
                                height: 40
                                color: tabState.currentTab === "ambient" ? "#4a4a4a" : "#2a2a2a"
                                radius: 5
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: "Ambient"
                                    color: "#ffffff"
                                    font.pixelSize: 16
                                }
                                
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: tabState.currentTab = "ambient"
                                }
                            }
                        }
                    }
                    
                    // Content area for apps
                    Rectangle {
                        id: appContentArea
                        width: parent.width
                        height: parent.height - 60
                        y: 60
                        color: "#0d0d0d"
                        
                        Text {
                            anchors.centerIn: parent
                            text: tabState.currentTab === "media" 
                                  ? "MediaApp\n(Wayland Client)" 
                                  : "AmbientApp\n(Wayland Client)"
                            color: "#888888"
                            font.pixelSize: 18
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }
            }
        }
    }
    
    // ══════════════════════════════════════════════════════
    // Tab state management
    // ══════════════════════════════════════════════════════
    QtObject {
        id: tabState
        property string currentTab: "media"
    }
    
    // ══════════════════════════════════════════════════════
    // Wayland client surfaces
    // ══════════════════════════════════════════════════════
    
    // Handle new Wayland surfaces (clients)
    onSurfaceRequested: {
        var surface = surfaceComponent.createObject(compositor, {});
        surface.initialize(compositor, client, id, version);
    }
    
    Component {
        id: surfaceComponent
        WaylandSurface {
            onSurfaceDestroyed: {
                console.log("Client disconnected");
            }
        }
    }
    
    // XdgShell for modern window management
    XdgShell {
        onToplevelCreated: {
            var title = toplevel.windowTitle || "";
            var appId = toplevel.appId || "";
            console.log("New XDG toplevel - Title:", title, "AppId:", appId);
            
            // Create shell surface item
            var item = surfaceItem.createObject(root, {
                "shellSurface": toplevel,
                "autoCreatePopupItems": true,
                "sizeFollowsSurface": false  // Compositor가 크기 제어
            });
            
            // Position based on window title (Gear, Media, Ambient)
            var isGear = title.indexOf("Gear") >= 0 || appId.indexOf("Gear") >= 0;
            var isMedia = title.indexOf("Media") >= 0 || appId.indexOf("Media") >= 0;
            var isAmbient = title.indexOf("Ambient") >= 0 || appId.indexOf("Ambient") >= 0;
            
            if (isGear) {
                item.x = 0;
                item.y = 0;
                item.width = 300;
                item.height = 480;
                console.log("→ GearApp positioned: Left panel (300x480)");
            } 
            else if (isMedia) {
                item.x = 300;
                item.y = 60;
                item.width = 980;
                item.height = 420;
                console.log("→ MediaApp positioned: Right panel (980x420)");
            }
            else if (isAmbient) {
                item.x = 300;
                item.y = 60;
                item.width = 980;
                item.height = 420;
                console.log("→ AmbientApp positioned: Right panel (980x420)");
            }
            else {
                // Default positioning
                item.x = 300;
                item.y = 60;
                item.width = 980;
                item.height = 420;
                console.log("→ Unknown app (Title:" + title + ") positioned: default");
            }
        }
    }
    
    Component {
        id: surfaceItem
        ShellSurfaceItem {
            onSurfaceDestroyed: destroy()
        }
    }
}
