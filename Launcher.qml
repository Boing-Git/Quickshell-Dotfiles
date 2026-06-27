import QtQuick
import QtQuick.Layouts
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

    property var filteredModel: {
        var filterText = searchInput.text.toLowerCase();
        var all = DesktopEntries.applications.values;
        if (filterText === "") return all;
        return all.filter(app => Vars.fuzzyMatch(filterText, app.name));
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
    implicitHeight: 180

    Rectangle {
        id: launcherRect
        anchors.fill: parent
        color: Theme.primary
        radius: Vars.radiusExtraLarge
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
        Keys.onDownPressed: appListView.focus = true

        ColumnLayout {
            anchors.fill: parent
            anchors.leftMargin: 80
            anchors.rightMargin: 80
            anchors.topMargin: Vars.spacingLarge
            anchors.bottomMargin: Vars.spacingLarge
            spacing: Vars.spacingMedium

            Rectangle {
                id: searchBox
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                color: searchInput.activeFocus ? Qt.rgba(Theme.on_primary.r, Theme.on_primary.g, Theme.on_primary.b, 0.12) : Qt.rgba(Theme.on_primary.r, Theme.on_primary.g, Theme.on_primary.b, 0.08)
                border.color: searchInput.activeFocus ? Theme.primary_container : "transparent"
                border.width: searchInput.activeFocus ? 2 : 0
                radius: Vars.radiusMedium

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Vars.spacingMedium
                    anchors.rightMargin: Vars.spacingMedium

                    TextInput {
                        id: searchInput
                        Layout.fillWidth: true
                        font.family: Vars.fontFamily
                        font.pixelSize: 14
                        color: Theme.on_primary
                        focus: true
                        selectByMouse: true

                        Text {
                            text: "Search apps..."
                            font.family: Vars.fontFamily
                            font.pixelSize: 14
                            color: Theme.on_primary
                            opacity: 0.6
                            visible: !searchInput.text && !searchInput.activeFocus
                        }

                        Keys.onDownPressed: appListView.focus = true
                        Keys.onReturnPressed: appListView.focus = true
                    }

                    Text {
                        text: "✕"
                        font.pixelSize: 14
                        color: Theme.on_primary
                        visible: searchInput.text.length > 0
                        Layout.alignment: Qt.AlignVCenter
                        MouseArea {
                            anchors.fill: parent
                            onClicked: searchInput.text = ""
                        }
                    }
                }
            }

            ListView {
                id: appListView
                Layout.fillWidth: true
                Layout.fillHeight: true
                orientation: ListView.Horizontal
                clip: true
                spacing: 4
                model: launcherRoot.filteredModel
                snapMode: ListView.SnapToItem
                boundsBehavior: Flickable.StopAtBounds

                focus: true
                keyNavigationEnabled: true
                highlightFollowsCurrentItem: true
                
                highlightRangeMode: ListView.ApplyRange
                preferredHighlightBegin: 20
                preferredHighlightEnd: appListView.width - 20
                highlightMoveDuration: 150

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton
                    hoverEnabled: true

                    onWheel: wheel => {
                        var delta = wheel.pixelDelta.y !== 0 ? wheel.pixelDelta.y : (wheel.angleDelta.y / 120) * 80;
                        var newX = appListView.contentX - delta;

                        var maxContentX = Math.max(0, appListView.contentWidth - appListView.width);
                        appListView.contentX = Math.max(0, Math.min(newX, maxContentX));
                    }
                }

                Keys.onReturnPressed: if (currentItem) currentItem.triggerSelection()
                Keys.onSpacePressed: if (currentItem) currentItem.triggerSelection()

                delegate: Item {
                    id: delegateItem
                    width: 110
                    height: appListView.height

                    function triggerSelection() {
                        Quickshell.execDetached({
                            command: modelData.command,
                            workingDirectory: modelData.workingDirectory
                        });
                        launcherRoot.appLaunched();
                    }

                    property bool isCurrent: delegateItem.ListView.isCurrentItem && appListView.activeFocus
                    
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 4
                        color: isCurrent ? Theme.primary_container : (itemMouseArea.containsMouse ? Qt.rgba(Theme.on_primary.r, Theme.on_primary.g, Theme.on_primary.b, 0.08) : "transparent")
                        radius: Vars.radiusMedium
                        border.color: Theme.on_primary
                        border.width: isCurrent ? 2 : 0

                        Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Expressive } }
                    }

                    MouseArea {
                        id: itemMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        preventStealing: false
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            appListView.currentIndex = index;
                            delegateItem.triggerSelection();
                        }
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: Vars.spacingMedium

                        Image {
                            width: 36
                            height: 36
                            anchors.horizontalCenter: parent.horizontalCenter
                            source: modelData.icon ? "image://icon/" + modelData.icon : ""
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                            
                            opacity: isCurrent ? 1.0 : (itemMouseArea.containsMouse ? 0.9 : 0.7)
                            Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Expressive } }
                        }

                        Text {
                            width: 90
                            font.family: Vars.fontFamily
                            font.pixelSize: 13
                            font.weight: isCurrent ? Font.DemiBold : Font.Medium
                            text: modelData.name
                            
                            color: isCurrent ? Theme.on_primary_container : Theme.on_primary
                            opacity: isCurrent ? 1.0 : (itemMouseArea.containsMouse ? 0.8 : 0.6)
                            
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
}