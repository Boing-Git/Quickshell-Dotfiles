import QtQuick
import Quickshell
import QtQuick.Layouts
import "./Variables/variables.js" as Vars

Item {
    id: root
    width: 100
    height: 40

    // No physics strings or translation properties needed

    Rectangle {
        id: clockRect
        width: parent.width
        height: parent.height
        color: Theme.primary
        radius: height / 2
        z: 1

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: dragArea.pressed ? Qt.rgba(Theme.on_primary.r, Theme.on_primary.g, Theme.on_primary.b, 0.12) : (dragArea.containsMouse ? Qt.rgba(Theme.on_primary.r, Theme.on_primary.g, Theme.on_primary.b, 0.08) : "transparent")
            Behavior on color { ColorAnimation { duration: 250; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Expressive } }
        }


        SystemClock {
            id: systemClock
            precision: SystemClock.Minutes
        }

        Text {
            id: clockText
            font.family: Vars.fontFamily
            font.pixelSize: 14
            font.weight: 600 // Slightly bolder to match the new crisp aesthetic
            color: Theme.on_primary
            anchors.centerIn: parent
            text: Qt.formatDateTime(systemClock.date, "hh:mm ap").replace(/ [ap]m$/i, "")
        }

        MouseArea {
            id: dragArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
        }
    }

}