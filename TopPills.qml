import QtQuick
import QtQuick.Layouts
import Quickshell
import "./Variables/variables.js" as Vars

PanelWindow {
    id: topWindow
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: 50
    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: 750
    color: "transparent"

    // 1. The Mask Region Array
    mask: Region {
        Region {
            item: topBarMask
        }
        Region {
            item: clockMask
        }

        // NEW: Tell Wayland to specifically track the expanding Control Center pill
        Region { item: controlCenterItem.panel }
    }

    // 2. Fixed Top Bar Mask
    Item {
        id: topBarMask
        width: parent.width
        // FIX: Keep this strictly locked to the top bar's height.
        // Do NOT let this expand, otherwise it creates an invisible wall across the screen.
        height: 50
    }

    // 3. Dynamic Clock Mask (Tracks the pendulum swing)
    Item {
        id: clockMask
        x: clockPillItem.x + clockPillItem.pillTranslateX
        y: clockPillItem.y + clockPillItem.pillTranslateY
        width: clockPillItem.width
        height: clockPillItem.height
    }

    // --- Main UI Content ---
    Item {
        anchors.fill: parent

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            anchors.topMargin: 8
            anchors.bottomMargin: 8

            HyprWorkspaces {
                Layout.alignment: Qt.AlignTop
            }

            Item {
                Layout.fillWidth: true
            }

            StatusBar {
                Layout.alignment: Qt.AlignTop
            }

            ControlCenter {
                id: controlCenterItem
                Layout.alignment: Qt.AlignTop
            }
        }
    }

    ClockPill {
        id: clockPillItem
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 5
    }
}
