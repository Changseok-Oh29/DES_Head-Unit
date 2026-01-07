import QtQuick 2.12

/*
 * IC Surface Router - Logic for routing IC client app windows to containers
 * Routes based on app_id or window title
 */

QtObject {
    id: router

    // Container references (set by compositor)
    property var gearAppContainer: null
    property var speedAppContainer: null
    property var batteryAppContainer: null

    // Helper function to clear container and add new surface
    function assignToContainer(chrome, container, containerName) {
        // Clear any existing children in the container (prevent duplicates)
        for (var i = container.children.length - 1; i >= 0; i--) {
            var child = container.children[i]
            if (child !== chrome) {
                console.log("   Removing existing surface from", containerName)
                child.visible = false
                child.parent = null
            }
        }

        // Assign new surface
        chrome.parent = container
        chrome.anchors.fill = chrome.parent
        chrome.visible = true
        console.log("   ->", containerName, "assigned")
    }

    // Route surface to appropriate container
    function routeSurface(chrome, identifier) {
        if (!chrome) {
            console.error("Cannot route: chrome is null")
            return
        }

        var idLower = identifier.toLowerCase()

        console.log("Routing IC surface...")
        console.log("   Identifier:", identifier)

        // Route by app_id or window title
        if (identifier === "ICGearApp" || idLower.includes("icgear") || idLower.includes("ic_gear")) {
            if (gearAppContainer) {
                assignToContainer(chrome, gearAppContainer, "Gear Section")
            } else {
                console.error("   gearAppContainer is null!")
            }
            return

        } else if (identifier === "SpeedApp" || idLower.includes("speed")) {
            if (speedAppContainer) {
                assignToContainer(chrome, speedAppContainer, "Speed Section")
            } else {
                console.error("   speedAppContainer is null!")
            }
            return

        } else if (identifier === "BatteryApp" || idLower.includes("battery")) {
            if (batteryAppContainer) {
                assignToContainer(chrome, batteryAppContainer, "Battery Section")
            } else {
                console.error("   batteryAppContainer is null!")
            }
            return
        }

        // Default: Don't route unknown surfaces
        console.error("Unknown IC app_id - NOT ROUTING:", identifier)
        console.error("   Surface will be hidden. Check app's QGuiApplication::setApplicationName()")

        // Hide the chrome so it doesn't appear anywhere
        chrome.visible = false
    }
}
