import QtQuick 2.12
import QtQuick.Window 2.12
import QtWayland.Compositor 1.3

/*
 * DES Head Unit - Wayland Compositor (Modular Version)
 *
 * This is the WAYLAND SERVER (not a client!)
 * - Creates wayland-1 socket for clients to connect
 * - Manages and composites multiple client windows
 * - Runs on EGLFS (direct framebuffer rendering)
 *
 * Architecture:
 * - compositor_modular.qml (this file): Wayland server setup
 * - CompositorLayout.qml: UI layout and containers
 * - SurfaceRouter.qml: Logic for routing app windows
 */

WaylandCompositor {
    id: compositor

    // Create Wayland server socket
    socketName: "wayland-1"

    // ═══════════════════════════════════════════════════════════
    // Single Output - Spans both HDMI and DSI displays
    // EGLFS only supports ONE Window, positioned across both screens
    // ═══════════════════════════════════════════════════════════
    WaylandOutput {
        id: output
        compositor: compositor
        sizeFollowsWindow: true

        window: Window {
            id: mainWindow
            width: 1424  // 1024 (HDMI) + 400 (DSI)
            height: 1280 // Max height
            visible: true
            title: "DES Head Unit - Dual Display Compositor"
            color: "#000000"

            // ═══════════════════════════════════════════════════════
            // HDMI Area (Left side: x=0 to x=1024)
            // ═══════════════════════════════════════════════════════
            Item {
                id: hdmiArea
                x: 0
                y: 0
                width: 1024
                height: 600

                // Load the layout component for HU apps
                CompositorLayout {
                    id: layout
                    anchors.fill: parent

                    // Update surface count when surfaces change
                    onSurfaceCountChanged: {
                        var count = surfacesList.count
                        layout.surfaceCount = count + " apps"
                    }
                }
            }

            // ═══════════════════════════════════════════════════════
            // DSI Area (Right side: x=1024 to x=1424)
            // ═══════════════════════════════════════════════════════
            Item {
                id: dsiArea
                x: 1024
                y: 0
                width: 400
                height: 1280

                Rectangle {
                    anchors.fill: parent
                    color: "#000000"
                }

                Text {
                    anchors.centerIn: parent
                    text: "Waiting for IC_app..."
                    color: "white"
                    font.pixelSize: 24
                    visible: icSurfaceItem.surface === null
                }

                // IC app surface will be placed here
                ShellSurfaceItem {
                    id: icSurfaceItem
                    anchors.fill: parent
                    autoCreatePopupItems: true
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════════════
    // Surface Management
    // ═══════════════════════════════════════════════════════════

    // List to track all surfaces
    ListModel {
        id: surfacesList
    }

    property alias surfaces: surfacesList

    // Surface router (handles routing logic)
    SurfaceRouter {
        id: surfaceRouter
        gearAppContainer: layout.gearAppContainer
        homeScreenAppContainer: layout.homeScreenAppContainer
        mediaAppContainer: layout.mediaAppContainer
        ambientAppContainer: layout.ambientAppContainer
    }

    // Component to wrap each wayland surface
    Component {
        id: chromeComponent

        ShellSurfaceItem {
            id: chrome
            autoCreatePopupItems: true

            onSurfaceDestroyed: {
                console.log("🗑️  Surface destroyed")
                for (var i = 0; i < surfacesList.count; i++) {
                    if (surfacesList.get(i).surface === chrome) {
                        surfacesList.remove(i)
                        break
                    }
                }

                // Update surface count
                layout.surfaceCount = surfacesList.count + " apps"

                chrome.destroy()
            }
        }
    }

    // ═══════════════════════════════════════════════════════════
    // XDG Shell Extension (Modern Wayland Protocol)
    // ═══════════════════════════════════════════════════════════
    XdgShell {
        onToplevelCreated: {
            var appId = toplevel.appId || ""
            var title = toplevel.title || ""

            console.log("═══════════════════════════════════════")
            console.log("🪟 New XDG Toplevel created")
            console.log("   App ID:", appId)
            console.log("   Window Title:", title)

            // Helper function to check if this is IC app
            function isInstrumentCluster(id, windowTitle) {
                var checkStr = (id + " " + windowTitle).toLowerCase()
                return checkStr.indexOf("ic") !== -1 ||
                       checkStr.indexOf("instrument") !== -1 ||
                       checkStr.indexOf("cluster") !== -1
            }

            // Determine which area this app should go to
            var isICApp = isInstrumentCluster(appId, title)

            var targetContainer = isICApp ? dsiArea : hdmiArea

            console.log("   Target area:", isICApp ? "DSI (Instrument Cluster)" : "HDMI (Head Unit)")

            var chrome = chromeComponent.createObject(targetContainer, {
                "shellSurface": xdgSurface
            })

            // Store whether this was initially identified as IC app
            var initialICDetection = isICApp

            // Add to surface list
            surfacesList.append({"surface": chrome, "appId": appId, "title": title, "isIC": isICApp})

            // Monitor title changes to detect IC app if not initially detected
            toplevel.titleChanged.connect(function() {
                var newTitle = toplevel.title || ""
                console.log("═══════════════════════════════════════")
                console.log("📝 Title changed to:", newTitle)

                // Check if this is actually IC app based on new title
                if (!initialICDetection && isInstrumentCluster(appId, newTitle)) {
                    console.log("   🔄 DETECTED as IC app! Re-assigning to DSI area...")

                    // Move surface to DSI area
                    chrome.parent = dsiArea
                    icSurfaceItem.surface = chrome.surface
                    chrome.visible = true
                    chrome.opacity = 1.0

                    // Update tracking
                    initialICDetection = true
                    console.log("   ✅ IC_app NOW assigned to DSI area")
                    console.log("      Surface size:", chrome.width, "x", chrome.height)
                    console.log("      DSI area position:", dsiArea.x, ",", dsiArea.y)
                    console.log("      icSurfaceItem surface:", icSurfaceItem.surface)

                } else if (initialICDetection) {
                    console.log("   IC app title update (already on DSI)")
                } else {
                    // Regular HU app title change - route normally
                    if (newTitle !== "") {
                        console.log("   Re-routing HU app based on new title...")
                        surfaceRouter.routeSurface(chrome, newTitle)
                    }
                }
                console.log("═══════════════════════════════════════")
            })

            // Initial assignment
            if (isICApp) {
                icSurfaceItem.surface = chrome.surface
                chrome.visible = true
                chrome.opacity = 1.0
                console.log("   ✅ IC_app assigned to DSI area")
                console.log("      Surface size:", chrome.width, "x", chrome.height)
                console.log("      DSI area position:", dsiArea.x, dsiArea.y)
            } else {
                // Update surface count for HU apps
                layout.surfaceCount = surfacesList.count + " apps"

                // Initial routing for HU apps
                var identifier = appId || title
                surfaceRouter.routeSurface(chrome, identifier)
            }

            console.log("✅ Surface routed successfully")
            console.log("═══════════════════════════════════════")
        }
    }


    // ═══════════════════════════════════════════════════════════
    // Initialization
    // ═══════════════════════════════════════════════════════════
    Component.onCompleted: {
        console.log("════════════════════════════════════════════════════════")
        console.log("🚀 DES Head Unit - Dual Display Wayland Compositor")
        console.log("════════════════════════════════════════════════════════")
        console.log("📊 Single Window Spans Both Displays:")
        console.log("   Window size:", mainWindow.width, "x", mainWindow.height)
        console.log("   HDMI area: x=0-1024, y=0-600")
        console.log("   DSI area:  x=1024-1424, y=0-1280")
        console.log("")
        console.log("🖥️  HDMI Area (1024x600) - Head Unit")
        console.log("   • Left Panel (130px): GearApp")
        console.log("   • Main Area Pages:")
        console.log("       [0] HOME - HomeScreenApp window")
        console.log("       [1] MEDIA - MediaApp window")
        console.log("       [2] AMBIENT - AmbientApp window")
        console.log("   • Bottom Bar (80px): [Home] [Media] [Ambient]")
        console.log("")
        console.log("🖥️  Output 2: DSI-1 (400x1280) - Instrument Cluster")
        console.log("   • Full screen: IC_app")
        console.log("")
        console.log("⏳ Waiting for client apps to connect...")
        console.log("   HU Apps (→ HDMI):")
        console.log("     - 'GearApp' → Left panel")
        console.log("     - 'HomeScreenApp' → Home page")
        console.log("     - 'MediaApp' → Media page")
        console.log("     - 'AmbientApp' → Ambient page")
        console.log("   IC App (→ DSI):")
        console.log("     - 'IC_app' → Full screen")
        console.log("")
        console.log("🔌 Wayland socket: $XDG_RUNTIME_DIR/wayland-1")
        console.log("   Compositor renders on: EGLFS (dual framebuffer)")
        console.log("   Client apps connect via: QT_QPA_PLATFORM=wayland")
        console.log("════════════════════════════════════════════════════════")
    }
}
