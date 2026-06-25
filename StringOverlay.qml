import QtQuick
import Quickshell

import "./Variables/colors.js" as Colors
import "./Variables/variables.js" as Vars

PanelWindow {
    id: clockPillRoot
    
    // Fill the entire screen so the strings can draw anywhere
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    
    // Ignore window management layouts and sit on top of everything
    exclusionMode: ExclusionMode.Ignore
    aboveWindows: true 
    color: "transparent"

    // String 1: Top-Left corner of screen to Left side of the Clock Pill
    PhysicsString {
        id: leftString
        anchors.fill: parent
        anchorPoint: Qt.point(0, 0)
        targetPoint: Qt.point(clockPillRoot.x, clockPillRoot.y + 15)
        stringColor: Colors.secondary.base
    }

    // String 2: Top-Right corner of screen to Right side of the Clock Pill
    PhysicsString {
        id: rightString
        anchors.fill: parent
        anchorPoint: Qt.point(Screens.width, 0)
        targetPoint: Qt.point(clockPillRoot.x + clockPillRoot.width, clockPillRoot.y + 15)
        stringColor: Colors.secondary.base
    }
}