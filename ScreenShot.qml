import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io


PanelWindow {
    id: root
    
    HyprlandFocusGrab { active: root.visible; windows: [root] }
    
    required property bool visibleState
    visible: visibleState
    signal closed
    signal openRequested
    property bool internalVisible: false
    property var m3Expressive: [0.05, 0.7, 0.1, 1.0]

    onVisibleChanged: {
        if (visible) {
            internalVisible = true;
            dimLayer.visible = true;
            dimLayer.opacity = 0.0; 
            frozenImage.visible = false;
            freezeProcess.command = ["grim", "/tmp/qs_freeze.png"];
            freezeProcess.running = true;
        } else {
            frozenImage.source = "";
        }
    }

    Process {
        id: freezeProcess
        onExited: {
            frozenImage.source = "file:///tmp/qs_freeze.png?" + Date.now();
            frozenImage.visible = true;
            dimLayer.opacity = 1.0; 
        }
    }

    exclusionMode: ExclusionMode.Ignore
    aboveWindows: true
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"

    Image {
        id: frozenImage
        anchors.fill: parent
        visible: false
        cache: false 
        asynchronous: false 
    }

    PhysicsString { id: sTL; anchors.fill: parent; visible: selectionBox.isDragging; anchorPoint: Qt.point(0, 0); targetPoint: Qt.point(selectionBox.x, selectionBox.y); stringColor: Theme.secondary }
    PhysicsString { id: sTR; anchors.fill: parent; visible: selectionBox.isDragging; anchorPoint: Qt.point(root.width, 0); targetPoint: Qt.point(selectionBox.x + selectionBox.width, selectionBox.y); stringColor: Theme.secondary }
    PhysicsString { id: sBL; anchors.fill: parent; visible: selectionBox.isDragging; anchorPoint: Qt.point(0, root.height); targetPoint: Qt.point(selectionBox.x, selectionBox.y + selectionBox.height); stringColor: Theme.secondary }
    PhysicsString { id: sBR; anchors.fill: parent; visible: selectionBox.isDragging; anchorPoint: Qt.point(root.width, root.height); targetPoint: Qt.point(selectionBox.x + selectionBox.width, selectionBox.y + selectionBox.height); stringColor: Theme.secondary }

    Rectangle {
        id: dimLayer
        anchors.fill: parent
        color: "#1a000000" // Slightly softer black
        opacity: 0.0
        Behavior on opacity {
            NumberAnimation { duration: 400; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Expressive }
        }
    }

    Rectangle {
        id: selectionBox
        // Blanket Style: A soft, translucent fill instead of a completely empty box
        color: Theme.secondary
        opacity: 0.25 // The fill is highly transparent
        
        // A softer border to match the aesthetic
        border.color: Theme.secondary
        border.width: 4 
        radius: 8
        
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
            frozenImage.visible = false;
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
                frozenImage.visible = false;
                closeTimer.start();
                return;
            }
            
            selectionBox.isDragging = false; 
            dimLayer.visible = false; 
            
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
            captureProcess.command = ["sh", "-c", `grim -g "${geometry}" /tmp/qs_crop.png`];
            captureProcess.running = true;
        }
    }

    Process {
        id: captureProcess
        onExited: {
            sattyProcess.running = true;
            internalVisible = false;
            root.closed();
        }
    }

    Process {
        id: sattyProcess
        command: ["sh", "-c", "satty --filename /tmp/qs_crop.png"]
    }
}