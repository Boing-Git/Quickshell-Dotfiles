import QtQuick
import QtQuick.Layouts
import Quickshell
// 1. THE HIGH-LEVEL WRAPPER: Exposes properties like title, icon, and activate()
import Quickshell.Services.SystemTray

import "./Variables/colors.js" as Colors
import "./Variables/variables.js" as Vars

// Container layout that holds the collection of tray pills side-by-side
RowLayout {
    id: systemTrayContainer
    spacing: 8

    // 2. THE REPEATER: Since multiple apps run in the background (Discord, Steam, etc.),
    // we use a Repeater to dynamically build your custom pill layout for every running app.
    Repeater {
        model: SystemTray.items

        delegate: Rectangle {
            id: controlCenterPill
            Layout.preferredWidth: 39
            Layout.preferredHeight: 40
            color: Colors.primary.base
            radius: Math.min(width, height) * Vars.radiusAmount

            // Explicitly aliasing modelData to make the code highly readable
            property var trayItem: modelData 

            // ==========================================
            // DBUSMENU ENGINE (The Connection Point)
            // ==========================================
            // This is how Quickshell bridges the gap between your UI and the DBusMenu protocol.
            // It reads the 'DBusMenuHandle' layer and prepares the desktop dropdown menu window.
            QsMenuAnchor {
                id: contextMenu
                
                // CRUCIAL: Maps the tray item's internal menu handle directly to the popup controller
                menu: trayItem.menu 
            }

            // ==========================================
            // MOUSE INTERACTIVITY & ROUTING
            // ==========================================
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton

                onClicked: (mouse) => {
                    if (!trayItem) return;

                    // Right Click: Opens the application's actual DBus Context Menu
                    if (mouse.button === Qt.RightButton && trayItem.hasMenu) {
                        
                        // Tells Quickshell to coordinate with your Wayland/X11 window manager 
                        // to smoothly draw the DBus menu popup relative to this specific pill.
                        contextMenu.open();
                        
                    } else {
                        // Left Click: Executes the application's primary system instruction
                        // (e.g., maximizing the Discord/Steam client window).
                        trayItem.activate();
                    }
                }
            }

            // ==========================================
            // VISUAL DESIGN
            // ==========================================
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 6

                // System Tray Icon
                Image {
                    id: itemIcon
                    Layout.preferredWidth: 20
                    Layout.preferredHeight: 20
                    Layout.alignment: Qt.AlignVCenter
                    
                    // In Quickshell, 'trayItem.icon' resolves directly into a usable 
                    // image path string—no theme lookup hacks or font files needed.
                    source: trayItem.icon ? trayItem.icon : "" 
                    fillMode: Image.PreserveAspectFit
                }
            }
        }
    }
}