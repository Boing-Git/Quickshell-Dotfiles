import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking
import "./Variables/colors.js" as Colors
import "./Variables/variables.js" as Vars

// Right Side: Control Center Pill
Rectangle {
    id: controlCenterPill
    Layout.preferredWidth: 140
    Layout.preferredHeight: 40
    color: Colors.primary.base
    radius: Math.min(width, height) * Vars.radiusAmount
    property bool expanded : false

    property var wifiDevice: Networking.devices.values.find(d => d.type === DeviceType.Wifi)
    property var active: wifiDevice ? wifiDevice.networks.values.find(n => n.connected) : null

    property var signal: active ? active.signalStrength : 0

    readonly property string icon: {
        if (!Networking.wifiEnabled)
            return "\e1da";
        if (!active)
            return "\uf067";

        let tier = Math.min(Math.floor(signal / 25), 3);

        // 2. Map that index directly to your specific codepoints
        let icons = ["\ue1ba", "\uebe4", "\uebd6", "\uebe1"];
        return icons[tier];
    }

    MouseArea   {
        anchors.fill:parent
        onClicked:{
            expanded= !expanded
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 15
        anchors.rightMargin: 15
        spacing: 4

        Text {
            font.family: "Material Symbols Outlined"
            font.pixelSize: 13
            font.weight: 500
            color: Colors.primary.on_base
            text: icon
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            font.family: "Rubik"
            font.pixelSize: 13
            font.weight: 500
            color: Colors.primary.on_base
            text: active ? active.name : "Disconnected"
            Layout.alignment: Qt.AlignVcenter
        }
    }
}