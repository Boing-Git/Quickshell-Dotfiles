import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io

import "./Variables/colors.js" as Colors

PanelWindow {
    id: root
    HyprlandFocusGrab {
        active: root.visible
        windows: [root]
    }
    required property bool visibleState
    visible: visibleState
    signal closed
    signal openRequested
    property bool internalVisible: false
    property var m3Expressive: [0.05, 0.7, 0.1, 1.0]

    function activate() {
        internalVisible = true;
        dimLayer.opacity = 1.0;
    }
    exclusionMode: ExclusionMode.Ignore
    aboveWindows: true
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"

    // Elastic strings linking screen corners (0,0) to selectionBox corners
    PhysicsString {
        id: sTL
        anchors.fill: parent
        visible: selectionBox.isDragging
        anchorPoint: Qt.point(0, 0)
        targetPoint: Qt.point(selectionBox.x, selectionBox.y)
        stringColor: Colors.secondary.base
    }
    PhysicsString {
        id: sTR
        anchors.fill: parent
        visible: selectionBox.isDragging
        anchorPoint: Qt.point(root.width, 0)
        targetPoint: Qt.point(selectionBox.x + selectionBox.width, selectionBox.y)
        stringColor: Colors.secondary.base
    }
    PhysicsString {
        id: sBL
        anchors.fill: parent
        visible: selectionBox.isDragging
        anchorPoint: Qt.point(0, root.height)
        targetPoint: Qt.point(selectionBox.x, selectionBox.y + selectionBox.height)
        stringColor: Colors.secondary.base
    }
    PhysicsString {
        id: sBR
        anchors.fill: parent
        visible: selectionBox.isDragging
        anchorPoint: Qt.point(root.width, root.height)
        targetPoint: Qt.point(selectionBox.x + selectionBox.width, selectionBox.y + selectionBox.height)
        stringColor: Colors.secondary.base
    }

    Rectangle {
        id: dimLayer
        anchors.fill: parent
        color: "#0d000000"
        opacity: 0.0
        Behavior on opacity {
            NumberAnimation {
                duration: 400
                easing.type: Easing.BezierSpline
                easing.bezierCurve: root.m3Expressive
            }
        }
    }

    Rectangle {
        id: selectionBox
        color: "transparent"
        border.color: Colors.secondary.base
        border.width: 10
        radius: 4
        property bool isDragging: false
        visible: isDragging
        onXChanged: update()
        onYChanged: update()
        onWidthChanged: update()
        onHeightChanged: update()
        function update() {
            sTL.targetPoint = Qt.point(x + 8, y + 8);
            sTR.targetPoint = Qt.point(x - 8 + width, y + 8);
            sBL.targetPoint = Qt.point(x + 8, y - 8 + height);
            sBR.targetPoint = Qt.point(x - 8 + width, y - 8 + height);
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.CrossCursor
        focus: true
        Keys.onEscapePressed: {
            dimLayer.opacity = 0;
            closeTimer.start();
        }
        property int startX: 0
        property int startY: 0
        onPressed: mouse => {
            startX = mouse.x;
            startY = mouse.y;
            selectionBox.x = startX;
            selectionBox.y = startY;
            selectionBox.width = 0;
            selectionBox.height = 0;
            selectionBox.isDragging = true;
        }
        onPositionChanged: mouse => {
            selectionBox.x = Math.min(startX, mouse.x);
            selectionBox.y = Math.min(startY, mouse.y);
            selectionBox.width = Math.abs(mouse.x - startX);
            selectionBox.height = Math.abs(mouse.y - startY);
        }
        onReleased: {
            let x = Math.round(selectionBox.x);
            let y = Math.round(selectionBox.y);
            let w = Math.round(selectionBox.width);
            let h = Math.round(selectionBox.height);
            if (w < 10 || h < 10) {
                dimLayer.opacity = 0;
                closeTimer.start();
                return;
            }
            selectionBox.isDragging = false;
            dimLayer.opacity = 0;
            captureTimer.geometry = `${x},${y} ${w}x${h}`;
            captureTimer.start();
        }
    }

    Timer {
        id: closeTimer
        interval: 400
        onTriggered: {
            internalVisible = false;
            root.closed();
        }
    }
    Timer {
        id: captureTimer
        interval: 50
        property string geometry: ""
        onTriggered: {
            captureProcess.command = ["sh", "-c", `grim -g "${geometry}" - | satty --filename -`];
            captureProcess.running = true;
            internalVisible = false;
            root.closed();
        }
    }
    Process {
        id: captureProcess
    }
}
