import QtQuick
import QtQuick.Layouts
import Quickshell
import "./Variables/colors.js" as Colors
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
    implicitHeight: controlCenterItem.expanded ? 500 : 50
    color: "transparent"
    mask: inputMask

    // Input region: 50px bar only when closed, full height when CC is open
    Item {
        id: inputMask
        visible: false
        width: parent.width
        height: controlCenterItem.expanded ? parent.height : 50
    }

    Item {
        anchors.fill: parent

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16

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
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
    }
}