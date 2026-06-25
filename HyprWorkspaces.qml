import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "./Variables/colors.js" as Colors
import "./Variables/variables.js" as Vars

// Left Side: Hyprland Workspaces Pill
Rectangle {
    id: mainContainer
    color: Colors.primary.base
    radius: Math.min(width, height) * Vars.radiusAmount

    width: workspaceLayout.implicitWidth + 24
    height: workspaceLayout.implicitHeight + 16

    border.color: Colors.outline.variant
    border.width: 1

    RowLayout {
        id: workspaceLayout
        anchors.centerIn: parent
        spacing: 8

        Repeater {
            model: 5

            delegate: Rectangle {
                id: wsItem

                readonly property int wsId: modelData
                property bool isFocused: Hyprland.focusedWorkspace?.id === (wsId + 1)

                radius: Math.min(width, height) * Vars.radiusAmount + 2
                implicitWidth: 29
                implicitHeight: 29

                color: isFocused ? Colors.tertiary.on_base : Colors.primary.container

                Behavior on color {
                    ColorAnimation {
                        duration: 400
                    }
                }

                Text {
                    font.family: "Rubik"
                    font.pixelSize: 13
                    font.weight: 500
                    anchors.centerIn: parent
                    text: wsId + 1
                    color: isFocused ? Colors.secondary.base : Colors.primary.on_container
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Hyprland.dispatch("hl.dsp.focus { workspace = " + (wsId + 1) + " }");
                    }
                }
            }
        }
    }
}
