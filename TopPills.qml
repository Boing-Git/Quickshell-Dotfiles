import QtQuick
import QtQuick.Layouts
import Quickshell
import "./Variables/colors.js" as Colors
import "./Variables/variables.js" as Vars

PanelWindow {
    exclusionMode: Exclusion.Normal
    exclusiveZone: 50
    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: 50
    color: "transparent"

    // Root wrapper to manage layering
    Item {
        anchors.fill: parent

        // ==========================================
        // 1. SIDES LAYOUT (Left and Right items)
        // ==========================================
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16

            HyprWorkspaces {}

            // Single massive spacer pushing everything else to the far right
            Item {
                Layout.fillWidth: true
            }
            StatusBar {}
            Bluetooth {}
            Wifi{} 
        }
    }
    ClockPill {}
}
