import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import "./Variables/colors.js" as Colors
import "./Variables/variables.js" as Vars

// Right Side: Control Center Pill
Rectangle {
    id: controlCenterPill
    Layout.preferredWidth: 130
    Layout.preferredHeight: 40
    color: Colors.primary.base
    radius: Math.min(width, height) * Vars.radiusAmount

    property var adapter: Bluetooth.defaultAdapter
    property bool adapterState: adapter ? adapter.enabled : null
    property var connectDevice: adapter ? adapter.devices.values.find(d => d.connected) : null
    readonly property string icon: {
        if (!adapterState)
            return "\ue1a9";
        if (!connectDevice)
            return "\ue1a7";
        return "\ue1a8";
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 15
        anchors.rightMargin: 15
        spacing: 4

        Text {
            font.family: "Material Symbols Outlined"
            font.pixelSize: 15
            font.weight: 1000
            color: Colors.primary.on_base
            text: icon
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            font.family: "Rubik"
            font.pixelSize: 13
            font.weight: 500
            color: Colors.primary.on_base
            text: connectDevice ? connectDevice.name : "Disconnected"
            Layout.alignment: Qt.AlignLeft
        }
    }
}
