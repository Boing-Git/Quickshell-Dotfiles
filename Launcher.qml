import QtQuick
import Quickshell
import Quickshell.Hyprland
import "./Variables/variables.js" as Vars

PanelWindow {
    id: launcherRoot
    exclusiveZone: -1
    aboveWindows: true
    required property bool visibleState
    visible: visibleState

    signal closeRequested()
    signal appLaunched()

    property int offset: 0
    readonly property int viewLimit: 16
    
    property var displayModel: {
        var all = DesktopEntries.applications.values;
        return all.slice(offset, offset + viewLimit);
    }

    HyprlandFocusGrab {
        active: launcherRoot.visible
        windows: [launcherRoot]
    }

    anchors {
        bottom: true
        right: true
        left: true
    }

    margins {
        left: 40
        right: 40
        bottom: 10
    }

    color: "transparent"
    implicitHeight: 110

    Rectangle {
        id: launcherRect
        anchors.fill: parent
        color: Theme.surface
        radius: Math.min(width, height) * Vars.radiusAmount
        opacity: visibleState ? 1.0 : 0.0
        scale: visibleState ? 1.0 : 0.95

        Behavior on opacity {
            NumberAnimation { duration: 300; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Expressive }
        }
        Behavior on scale {
            NumberAnimation { duration: 300; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Expressive }
        }

        focus: true
        Keys.onEscapePressed: launcherRoot.appLaunched()

        ListView {
            id: appListView
            anchors.fill: launcherRect
            anchors.margins: 12
            orientation: ListView.Horizontal
            clip: true
            spacing: 4
            model: displayModel

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                hoverEnabled: true

                onWheel: wheel => {
                    var total = DesktopEntries.applications.values.length;
                    if (wheel.angleDelta.y < 0) { 
                        if (offset + viewLimit < total) offset++;
                    } else if (wheel.angleDelta.y > 0) {
                        if (offset > 0) offset--;
                    }
                }
            }

            delegate: Item {
                width: 110
                height: parent.height

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 4
                    // Blanket Style: Soft container color on hover instead of heavy contrast
                    color: Theme.primary_container
                    radius: Math.min(width, height) * Vars.radiusAmount
                    opacity: itemMouseArea.containsMouse ? 1.0 : 0.0

                    Behavior on opacity {
                        NumberAnimation { duration: 250; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Expressive }
                    }
                }

                MouseArea {
                    id: itemMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    preventStealing: true
                    cursorShape: Qt.PointingHandCursor

                    onClicked: {
                        Quickshell.execDetached({
                            command: modelData.command,
                            workingDirectory: modelData.workingDirectory
                        });
                        launcherRoot.appLaunched();
                    }
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 12

                    Image {
                        width: 36
                        height: 36
                        anchors.horizontalCenter: parent.horizontalCenter
                        source: modelData.icon ? "image://icon/" + modelData.icon : ""
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        
                        // Icon brightens on hover
                        opacity: itemMouseArea.containsMouse ? 1.0 : 0.8
                        Behavior on opacity { NumberAnimation { duration: 250 } }
                    }

                    Text {
                        width: 90
                        font.family: Vars.fontFamily
                        font.pixelSize: 13
                        font.weight: itemMouseArea.containsMouse ? Font.DemiBold : Font.Medium
                        text: modelData.name
                        
                        // Text switches to accent color on hover
                        color: itemMouseArea.containsMouse ? Theme.on_primary_container : Theme.on_surface
                        opacity: itemMouseArea.containsMouse ? 1.0 : 0.6
                        
                        horizontalAlignment: Text.AlignHCenter
                        maximumLineCount: 1
                        elide: Text.ElideRight
                        
                        Behavior on opacity { NumberAnimation { duration: 250 } }
                    }
                }
            }
        }
    }
}