import QtQuick
import Quickshell
import Quickshell.Hyprland
import "./Variables/colors.js" as Colors
import "./Variables/variables.js" as Vars

PanelWindow {
    id: launcherRoot
    exclusiveZone: -1
    aboveWindows: true

    // 1. Property MUST be defined here
    required property bool visibleState
    visible: visibleState

    signal closeRequested()
    signal appLaunched()

    // --- Added Sliding Window Logic ---
    property int offset: 0
    readonly property int viewLimit: 13
    
    // This dynamically updates whenever 'offset' changes
    property var displayModel: {
        var all = DesktopEntries.applications.values;
        return all.slice(offset, offset + viewLimit);
    }
    // ----------------------------------

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
    implicitHeight: 100

    Rectangle {
        id: launcherRect
        anchors.fill: parent
        color: Colors.primary.base
        radius: Math.min(width, height) * Vars.radiusAmount
        opacity: visibleState ? 1.0 : 0.0
        scale: visibleState ? 1.0 : 0.95

        Behavior on opacity {
            NumberAnimation {
                duration: 300
                easing.type: Easing.BezierSpline
                easing.bezierCurve: [0, 0, 0.05, 0.7, 0.1, 1.0, 1, 1]
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: 300
                easing.type: Easing.BezierSpline
                easing.bezierCurve: [0, 0, 0.05, 0.7, 0.1, 1.0, 1, 1]
            }
        }

        focus: true
        Keys.onEscapePressed: launcherRoot.appLaunched()

        ListView {
            id: appListView
            anchors.fill: launcherRect
            orientation: ListView.Horizontal
            clip: true
            leftMargin: 5

            // --- Updated to use the filtered model ---
            model: displayModel
            // -----------------------------------------

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                // Added hoverEnabled to ensure wheel events are captured correctly
                hoverEnabled: true

                onWheel: wheel => {
                    var total = DesktopEntries.applications.values.length;
                    // Adjust offset instead of contentX
                    if (wheel.angleDelta.y < 0) { 
                        // Scroll Right: add one if not at the end
                        if (offset + viewLimit < total) offset++;
                    } else if (wheel.angleDelta.y > 0) {
                        // Scroll Left: remove one if not at the start
                        if (offset > 0) offset--;
                    }
                }
            }

            delegate: Item {
                width: 140
                height: parent.height

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 4
                    color: Colors.primary.on_base
                    // Perfectly matched curve logic
                    radius: launcherRect.radius - anchors.margins
                    opacity: itemMouseArea.containsMouse ? 1.0 : 0.0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 300
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: [0, 0.05, 0.7, 0.1, 1.0]
                        }
                    }
                }

                MouseArea {
                    id: itemMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    preventStealing: true

                    onClicked: {
                        Quickshell.execDetached({
                            command: modelData.command,
                            workingDirectory: modelData.workingDirectory
                        });
                        launcherRoot.appLaunched();
                    }
                }

                Column {
                    anchors.fill: parent
                    anchors.topMargin: 10
                    anchors.bottomMargin: 10
                    spacing: 8
                    opacity: itemMouseArea.containsMouse ? 0.8 : 1.0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 300
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: [0, 0, 0.05, 0.7, 0.1, 1.0, 1, 1]
                        }
                    }

                    Image {
                        width: 32
                        height: 32
                        anchors.horizontalCenter: parent.horizontalCenter
                        source: modelData.icon ? "image://icon/" + modelData.icon : ""
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                    }

                    Text {
                        width: parent.width
                        font.family: "Rubik"
                        font.pixelSize: 13
                        font.weight: Font.Medium
                        text: modelData.name
                        color: Colors.textColor
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        maximumLineCount: 1
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }
}