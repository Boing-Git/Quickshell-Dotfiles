import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray

import "./Variables/variables.js" as Vars

// Blanket Style: A single unified unibody pill to hold all tray icons
Rectangle {
    id: systemTrayContainer
    color: Theme.primary
    radius: Math.min(width, height) * Vars.radiusAmount
    
    // THE FIX: Only show this pill if there is actually an app in the tray!
    visible: SystemTray.items.length > 0
    
    // Auto-size based on the number of tray items
    implicitWidth: trayLayout.implicitWidth + 24
    implicitHeight: 40

    RowLayout {
        id: trayLayout
        anchors.centerIn: parent
        spacing: 6

        Repeater {
            model: SystemTray.items

            delegate: Rectangle {
                id: controlCenterPill
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                
                // Blanket Style: Transparent normally, soft accent circle on hover
                color: itemMouseArea.containsMouse ? Theme.primary_container : "transparent"
                radius: Math.min(width, height) * Vars.radiusAmount

                Behavior on color {
                    ColorAnimation { duration: 250; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Expressive }
                }

                property var trayItem: modelData 

                QsMenuAnchor {
                    id: contextMenu
                    menu: trayItem.menu 
                }

                MouseArea {
                    id: itemMouseArea
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onClicked: (mouse) => {
                        if (!trayItem) return;
                        if (mouse.button === Qt.RightButton && trayItem.hasMenu) {
                            contextMenu.open();
                        } else {
                            trayItem.activate();
                        }
                    }
                }

                Image {
                    id: itemIcon
                    width: 20
                    height: 20
                    anchors.centerIn: parent
                    source: trayItem.icon ? trayItem.icon : "" 
                    fillMode: Image.PreserveAspectFit
                    
                    // Dim inactive tray icons slightly to match the aesthetic
                    opacity: itemMouseArea.containsMouse ? 1.0 : 0.7
                    Behavior on opacity { NumberAnimation { duration: 250 } }
                }
            }
        }
    }
}