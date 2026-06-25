import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking
import Quickshell.Bluetooth
import "./Variables/colors.js" as Colors
import "./Variables/variables.js" as Vars

// Right Side: Control Center Pill
Rectangle {
    id: id
    property string id: ""
    Layout.preferredWidth: expanded ? 500 : 80
    Layout.preferredHeight: expanded ? 500 : 40
    color: Colors.primary.base
    radius: expanded ? Math.min(width, height) * Vars.radiusAmount - 150 : Math.min(width, height) * Vars.radiusAmount
    property bool expanded: false

    property var wifiDevice: Networking.devices.values.find(d => d.type === DeviceType.Wifi)
    property var active: wifiDevice ? wifiDevice.networks.values.find(n => n.connected) : null

    property var signal: active ? active.signalStrength : 0

    readonly property string wifiIcon: {
        if (!Networking.wifiEnabled)
            return "\e1da";
        if (!active)
            return "\uf067";

        let tier = Math.min(Math.floor(signal / 25), 3);

        // 2. Map that index directly to your specific codepoints
        let icons = ["\ue1ba", "\uebe4", "\uebd6", "\uebe1"];
        return icons[tier];
    }

    property var adapter: Bluetooth.defaultAdapter
    property bool adapterState: adapter ? adapter.enabled : null
    property var connectDevice: adapter ? adapter.devices.values.find(d => d.connected) : null

    readonly property string bluetoothIcon: {
        if (!adapterState)
            return "\ue1a9";
        if (!connectDevice)
            return "\ue1a7";
        return "\ue1a8";
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            expanded = !expanded;
        }
    }

     // Replaced RotationAnimation with NumberAnimation
    Behavior on radius {
        NumberAnimation {
            duration: 1000
            easing.type: Easing.InOutQuad
        }
    }
    // Replaced RotationAnimation with NumberAnimation
    Behavior on Layout.preferredWidth {
        NumberAnimation {
            duration: 1000
            easing.type: Easing.InOutQuad
        }
    }
    // Replaced RotationAnimation with NumberAnimation
    Behavior on Layout.preferredHeight {
        NumberAnimation {
            duration: 1000
            easing.type: Easing.InOutQuad
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 15
        anchors.rightMargin: 15
        spacing: 4

        Text {
            id: animatedIcon
            font.family: "Material Symbols Outlined"
            font.pixelSize: 15
            font.weight: 500
            color: Colors.primary.on_base
            text: "\uf46b"
            Layout.alignment: Qt.AlignVCenter

            property bool isFacingRight: false
            property var directionWay: isFacingRight ? RotationAnimation.Clockwise : RotationAnimation.Counterclockwise

            rotation: isFacingRight ? 180 : 0

            // Replaced RotationAnimation with NumberAnimation
            Behavior on rotation {
                RotationAnimation {
                    duration: 300
                    direction: directionWay
                    easing.type: Easing.InOutQuad
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: parent.isFacingRight = !parent.isFacingRight
            }
        }
        Text {
            font.family: "Material Symbols Outlined"
            font.pixelSize: 13
            font.weight: 500
            color: Colors.primary.on_base
            text: bluetoothIcon
            Layout.alignment: Qt.AlignVCenter
        }
        Item {
            Layout.fillWidth: true
        }

        Text {
            font.family: "Material Symbols Outlined"
            font.pixelSize: 13
            font.weight: 500
            color: Colors.primary.on_base
            text: wifiIcon
            Layout.alignment: Qt.AlignVCenter
        }
    }
}
