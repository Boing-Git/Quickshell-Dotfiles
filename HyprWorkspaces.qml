import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "./Variables/variables.js" as Vars

Rectangle {
    id: mainContainer
    color: Theme.primary
    radius: height / 2

    width: workspaceLayout.implicitWidth + Vars.spacingLarge
    height: 40

    RowLayout {
        id: workspaceLayout
        anchors.centerIn: parent
        spacing: Vars.spacingSmall / 2

        Repeater {
            model: 5

            delegate: Rectangle {
                id: wsItem
                readonly property int wsId: modelData
                property bool isFocused: Hyprland.focusedWorkspace?.id === (wsId + 1)

                radius: height / 2
                implicitWidth: 32
                implicitHeight: 32

                // Blanket Style: Accent background when active, totally transparent when inactive
                color: isFocused ? Theme.primary_container : (wsMouseArea.pressed ? Qt.rgba(Theme.on_primary.r, Theme.on_primary.g, Theme.on_primary.b, 0.12) : (wsMouseArea.containsMouse ? Qt.rgba(Theme.on_primary.r, Theme.on_primary.g, Theme.on_primary.b, 0.08) : "transparent"))

                Behavior on color {
                    ColorAnimation { duration: 250; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Expressive }
                }

                Text {
                    font.family: Vars.fontFamily
                    font.pixelSize: 14
                    font.weight: isFocused ? 600 : 500
                    anchors.centerIn: parent
                    text: wsId + 1
                    
                    // Blanket Style: Full opacity accent text when active, faded base text when inactive
                    color: isFocused ? Theme.on_primary_container : Theme.on_primary
                    opacity: isFocused ? 1.0 : 0.5
                    
                    Behavior on opacity {
                        NumberAnimation { duration: 300 }
                    }
                }
                MouseArea {
                    id: wsMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Hyprland.dispatch("hl.dsp.focus { workspace = " + (wsId + 1) + " }");
                    }
                }
            }
        }
    }
}