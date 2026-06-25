import QtQuick
import Quickshell
import QtQuick.Layouts
import "./Variables/colors.js" as Colors
import "./Variables/variables.js" as Vars

// ==========================================
// 2. ABSOLUTE CENTER LAYER (Clock Pill)
// ==========================================
Rectangle {
    id: clockPill
    width: 100
    height: 40
    color: Colors.primary.base
    radius: Math.min(width, height) * Vars.radiusAmount

    // This anchors to the absolute center of the screen bar
    anchors.centerIn: parent

    SystemClock {
        id: systemClock
        precision: SystemClock.Minutes
    }

    Text {
        id: clockText
        font.family: "Rubik"
        font.pixelSize: 13
        font.weight: 500
        color: Colors.primary.on_base
        anchors.centerIn: parent
        text: Qt.formatDateTime(systemClock.date, "hh:mm ap").replace(/ [ap]m$/i, "")
    }
}
