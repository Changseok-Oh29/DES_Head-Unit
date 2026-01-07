import QtQuick 2.12
import QtQuick.Window 2.12
import QtWayland.Compositor 1.3

/*
 * IC_MainApp - Nested Wayland Compositor for Instrument Cluster
 *
 * This is a NESTED WAYLAND COMPOSITOR for the DSI display
 * - Connects to Weston (wayland-0) as a client
 * - Shows fullscreen on DSI output (400x1280 portrait) via Weston
 * - Creates wayland-2 socket for IC app clients
 * - Manages and composites IC app windows (SpeedApp, BatteryApp, ICGearApp)
 *
 * Layout (landscape 1280x400, rotated -90 for portrait display):
 * - Left (0-400): ICGearApp
 * - Center (400-880): SpeedApp
 * - Right (880-1280): BatteryApp
 */

WaylandCompositor {
    id: compositor

    // Create Wayland server socket for IC apps
    // Weston uses wayland-0, HU_MainApp uses wayland-1, we use wayland-2
    socketName: "wayland-2"

    // Nested Compositor Output - Shows on DSI via Weston
    WaylandOutput {
        id: output
        compositor: compositor
        sizeFollowsWindow: true

        window: Window {
            id: mainWindow
            // For local testing: use smaller window; for deployment: fullscreen
            property bool localTest: (Qt.platform.pluginName === "xcb")
            width: localTest ? 400 : 400    // DSI portrait width
            height: localTest ? 800 : 1280  // Shorter for local testing
            visible: true
            visibility: localTest ? "Windowed" : "FullScreen"
            flags: localTest ? Qt.Window : Qt.FramelessWindowHint
            title: "IC-Compositor (Press ESC or Q to quit)"
            color: "#000000"

            // Keyboard handler for quitting (ESC or Q)
            Item {
                anchors.fill: parent
                focus: true
                Keys.onPressed: {
                    if (event.key === Qt.Key_Escape || event.key === Qt.Key_Q) {
                        console.log("Quit requested - closing IC_MainApp")
                        Qt.quit()
                    }
                }
            }

            // Load the layout component for IC apps
            ICCompositorLayout {
                id: layout
                anchors.fill: parent
            }

            // Close button for local testing
            Rectangle {
                visible: mainWindow.localTest
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: 10
                width: 40
                height: 40
                color: "#ff4444"
                radius: 5
                z: 100

                Text {
                    anchors.centerIn: parent
                    text: "X"
                    color: "white"
                    font.bold: true
                    font.pixelSize: 20
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: Qt.quit()
                }
            }
        }
    }

    // List to track all surfaces
    ListModel {
        id: surfacesList
    }

    property alias surfaces: surfacesList

    // Surface router (handles routing logic)
    ICSurfaceRouter {
        id: surfaceRouter
        gearAppContainer: layout.gearAppContainer
        speedAppContainer: layout.speedAppContainer
        batteryAppContainer: layout.batteryAppContainer
    }

    // Component to wrap each wayland surface
    Component {
        id: chromeComponent

        ShellSurfaceItem {
            id: chrome
            autoCreatePopupItems: true

            onSurfaceDestroyed: {
                console.log("Surface destroyed")
                for (var i = 0; i < surfacesList.count; i++) {
                    if (surfacesList.get(i).surface === chrome) {
                        surfacesList.remove(i)
                        break
                    }
                }
                chrome.destroy()
            }
        }
    }

    // XDG Shell Extension (Modern Wayland Protocol)
    XdgShell {
        onToplevelCreated: {
            var appId = toplevel.appId || ""
            var title = toplevel.title || ""

            console.log("═══════════════════════════════════════")
            console.log("New XDG Toplevel created (IC)")
            console.log("   App ID:", appId)
            console.log("   Window Title:", title)
            console.log("   Target area: DSI (Instrument Cluster)")

            var chrome = chromeComponent.createObject(layout, {
                "shellSurface": xdgSurface
            })

            // Add to surface list
            surfacesList.append({"surface": chrome, "appId": appId, "title": title})

            // Monitor title changes for routing
            toplevel.titleChanged.connect(function() {
                var newTitle = toplevel.title || ""
                console.log("Title changed to:", newTitle)
                surfaceRouter.routeSurface(chrome, newTitle)
            })

            // Initial routing
            var identifier = appId || title
            surfaceRouter.routeSurface(chrome, identifier)

            console.log("Surface routed successfully")
            console.log("═══════════════════════════════════════")
        }
    }

    // Initialization
    Component.onCompleted: {
        console.log("════════════════════════════════════════════════════════")
        console.log("IC_MainApp - Nested Wayland Compositor")
        console.log("════════════════════════════════════════════════════════")
        console.log("Window (400x1280 portrait) - Shows on DSI via Weston")
        console.log("   Layout (rotated -90 for landscape content):")
        console.log("   - Left Section: ICGearApp")
        console.log("   - Center Section: SpeedApp")
        console.log("   - Right Section: BatteryApp")
        console.log("")
        console.log("Waiting for IC apps to connect...")
        console.log("   - 'ICGearApp' -> Gear display")
        console.log("   - 'SpeedApp' -> Speedometer")
        console.log("   - 'BatteryApp' -> Battery status")
        console.log("")
        console.log("Sub-compositor socket: $XDG_RUNTIME_DIR/wayland-2")
        console.log("Parent compositor: Weston (wayland-0)")
        console.log("Client apps connect via: WAYLAND_DISPLAY=wayland-2")
        console.log("════════════════════════════════════════════════════════")
    }
}
