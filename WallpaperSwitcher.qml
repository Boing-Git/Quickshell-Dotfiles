import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Import your generated colors & variables libraries
import "./Variables/variables.js" as Vars

PanelWindow {
    id: switcherRoot
    exclusiveZone: -1
    aboveWindows: true

    property string wallpaperDir: Quickshell.env("HOME") + "/Pictures/Wallpapers"
    property string currentWallpaper: ""

    required property bool visibleState
    visible: visibleState

    signal closeRequested
    signal appLaunched

    HyprlandFocusGrab {
        active: switcherRoot.visible
        windows: [switcherRoot]
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
    implicitHeight: 300

    Rectangle {
        id: switcherRect
        anchors.fill: parent

        // Matched template colors & dynamic radius
        color: Theme.primary
        radius: Math.min(width, height) * Vars.radiusAmount - 50

        opacity: visibleState ? 1.0 : 0.0
        scale: visibleState ? 1.0 : 0.95

        // Matched template animations
        Behavior on opacity {
            NumberAnimation {
                duration: 1000
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Vars.m3Expressive
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: 1000
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Vars.m3Expressive
            }
        }

        focus: true
        Keys.onEscapePressed: switcherRoot.appLaunched()
        Keys.onDownPressed: listView.focus = true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 16

            RowLayout {
                Layout.fillWidth: true
                spacing: 16

                ColumnLayout {
                    spacing: 4
                    Text {
                        text: "Wallpaper Engine Hub"
                        font.family: Vars.fontFamily
                        font.pixelSize: 22
                        font.bold: true
                        color: Theme.on_primary // Matched template
                    }
                    Text {
                        text: switcherRoot.currentWallpaper ? "Active: " + switcherRoot.currentWallpaper.substring(switcherRoot.currentWallpaper.lastIndexOf('/') + 1) : "Select a wallpaper to shift system palettes"
                        font.family: Vars.fontFamily
                        font.pixelSize: 12
                        color: Theme.on_primary
                        opacity: 0.8 // Slightly faded for visual hierarchy
                        elide: Text.ElideMiddle
                        Layout.maximumWidth: 320
                    }
                }

                Rectangle {
                    id: searchBox
                    Layout.fillWidth: true
                    Layout.preferredHeight: 44
                    color: "transparent"
                    border.color: Theme.on_primary
                    border.width: searchInput.activeFocus ? 2 : 1
                    radius: Math.min(width, height) * Vars.radiusAmount // Adopted variable radius

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16

                        TextInput {
                            id: searchInput
                            Layout.fillWidth: true
                            font.family: Vars.fontFamily
                            font.pixelSize: 14
                            color: Theme.on_primary
                            focus: true
                            selectByMouse: true

                            Text {
                                text: "Search wallpapers..."
                                font.family: Vars.fontFamily
                                font.pixelSize: 14
                                color: Theme.on_primary
                                opacity: 0.6
                                visible: !searchInput.text && !searchInput.activeFocus
                            }

                            Keys.onDownPressed: listView.focus = true
                            Keys.onReturnPressed: listView.focus = true
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

                Button {
                    id: refreshBtn
                    text: "Scan Folder"
                    onClicked: {
                        console.log("[SCAN] Refresh button clicked. Scanning folder...");
                        loadWallpapersProc.running = true;
                    }

                    background: Rectangle {
                        color: refreshBtn.down ? Theme.on_primary : (refreshBtn.hovered ? Theme.primary_container : "transparent")
                        border.color: Theme.on_primary
                        border.width: 1
                        radius: Math.min(width, height) * Vars.radiusAmount
                    }
                    contentItem: Text {
                        text: refreshBtn.text
                        font.family: Vars.fontFamily
                        color: (refreshBtn.down || refreshBtn.hovered) ? Theme.primary : Theme.on_primary
                        font.bold: true
                        font.pixelSize: 14
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            ListView {
                id: listView
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                orientation: ListView.Horizontal
                spacing: 12
                cacheBuffer: 600
                model: sortFilterProxyModel.proxyModel
                snapMode: ListView.SnapToItem
                boundsBehavior: Flickable.StopAtBounds

                focus: true
                keyNavigationEnabled: true
                highlightFollowsCurrentItem: true

                highlightRangeMode: ListView.ApplyRange
                preferredHighlightBegin: 20
                preferredHighlightEnd: listView.width - 20
                highlightMoveDuration: 150

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton
                    hoverEnabled: true

                    onWheel: wheel => {
                        var delta = wheel.pixelDelta.y !== 0 ? wheel.pixelDelta.y : (wheel.angleDelta.y / 120) * 80;
                        var newX = listView.contentX - delta;

                        var maxContentX = Math.max(0, listView.contentWidth - listView.width);
                        listView.contentX = Math.max(0, Math.min(newX, maxContentX));
                    }
                }

                Keys.onReturnPressed: if (currentItem)
                    currentItem.triggerSelection()
                Keys.onSpacePressed: if (currentItem)
                    currentItem.triggerSelection()

                delegate: Item {
                    id: delegateItem
                    width: 240
                    height: listView.height

                    function triggerSelection() {
                        executeWallpaperChange(filePath);
                    }

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 8
                        radius: Math.min(width, height) * (Vars.radiusAmount / 3) // Half-radius for inner elements to look proportional

                        // Adaptive primary colors
                        color: switcherRoot.currentWallpaper === filePath ? Theme.on_primary : ((tileMouseArea.containsMouse || delegateItem.ListView.isCurrentItem && listView.activeFocus) ? Theme.primary_container : "transparent")

                        border.color: Theme.on_primary
                        border.width: (switcherRoot.currentWallpaper === filePath || (delegateItem.ListView.isCurrentItem && listView.activeFocus)) ? 2 : 1
                        clip: true

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 8

                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                clip: true

                                Loader {
                                    id: mediaLoader
                                    anchors.fill: parent
                                    asynchronous: true
                                    sourceComponent: filePath.toLowerCase().endsWith(".gif") ? animatedPreview : staticPreview
                                }

                                Component {
                                    id: staticPreview
                                    Image {
                                        source: "file://" + filePath
                                        sourceSize: Qt.size(240, 180)
                                        fillMode: Image.PreserveAspectCrop
                                        asynchronous: true
                                    }
                                }

                                Component {
                                    id: animatedPreview
                                    AnimatedImage {
                                        source: "file://" + filePath
                                        fillMode: Image.PreserveAspectCrop
                                        asynchronous: true
                                        playing: tileMouseArea.containsMouse || (delegateItem.ListView.isCurrentItem && listView.activeFocus)
                                        paused: !tileMouseArea.containsMouse && !(delegateItem.ListView.isCurrentItem && listView.activeFocus)
                                    }
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    color: Theme.primary_container
                                    visible: mediaLoader.status !== Loader.Ready || (mediaLoader.item && mediaLoader.item.status !== Image.Ready)
                                    Text {
                                        anchors.centerIn: parent
                                        text: "Loading..."
                                        font.family: Vars.fontFamily
                                        color: Theme.on_primary_container
                                        font.pixelSize: 11
                                    }
                                }

                                Rectangle {
                                    anchors.top: parent.top
                                    anchors.right: parent.right
                                    anchors.margins: 6
                                    width: 32
                                    height: 18
                                    radius: 4
                                    color: Theme.primary
                                    visible: filePath.toLowerCase().endsWith(".gif")
                                    Text {
                                        anchors.centerIn: parent
                                        text: "GIF"
                                        font.family: Vars.fontFamily
                                        font.bold: true
                                        font.pixelSize: 10
                                        color: Theme.on_primary
                                    }
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: fileName
                                font.family: Vars.fontFamily
                                // Invert text color if tile is selected (since background becomes on_base)
                                color: switcherRoot.currentWallpaper === filePath ? Theme.primary : Theme.on_primary
                                font.pixelSize: 12
                                font.weight: switcherRoot.currentWallpaper === filePath ? Font.Bold : Font.Normal
                                elide: Text.ElideRight
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }

                        MouseArea {
                            id: tileMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            preventStealing: false

                            onClicked: {
                                listView.currentIndex = index;
                                delegateItem.triggerSelection();
                            }
                        }
                    }
                }
            }
        }
    }

    function executeWallpaperChange(filePath) {
        console.log("[USER ACTION] Wallpaper selected: " + filePath);
        switcherRoot.currentWallpaper = filePath;

        matugenProc.command = ["matugen", "image", filePath, "-m", "light", "--source-color-index", "0"];
        matugenProc.running = true;

    }

    Process {
        id: matugenProc

        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text.trim().length > 0)
                    console.log("[MATUGEN STDOUT]\n" + this.text);
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim().length > 0)
                    console.error("[MATUGEN STDERR]\n" + this.text);
            }
        }

        onExited: (code, status) => {
            console.log("[MATUGEN] Exited: " + code + " | Reloading Quickshell to apply new palette.");

            Quickshell.execDetached({
                command: ['bash', '-c', '.config/quickshell/sync_colors.py']
            });

            Quickshell.execDetached({
                command: ['bash', '-c', 'qs kill; sleep 0.1; qs']
            });
        }
    }

    ListModel {
        id: wallpaperModel
    }

    QtObject {
        id: sortFilterProxyModel
        property string filterText: searchInput.text
        onFilterTextChanged: updateVisualGrid()
        function updateVisualGrid() {
            proxyModel.clear();
            for (var i = 0; i < wallpaperModel.count; i++) {
                var item = wallpaperModel.get(i);
                if (filterText === "" || item.fileName.toLowerCase().indexOf(filterText.toLowerCase()) !== -1) {
                    proxyModel.append({
                        "filePath": item.filePath,
                        "fileName": item.fileName
                    });
                }
            }
        }
        property ListModel proxyModel: ListModel {}
    }

    Process {
        id: loadWallpapersProc
        command: ["find", switcherRoot.wallpaperDir, "-maxdepth", "2", "-type", "f", "-regextype", "posix-extended", "-regex", ".*\\.(jpg|jpeg|png|webp|gif)$"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                console.log("[SCAN] Finder finished. Processing files...");
                wallpaperModel.clear();
                var lines = this.text.split("\n");
                var validCount = 0;
                for (var i = 0; i < lines.length; i++) {
                    var path = lines[i].trim();
                    if (path.length > 0) {
                        var name = path.substring(path.lastIndexOf('/') + 1);
                        wallpaperModel.append({
                            "filePath": path,
                            "fileName": name
                        });
                        validCount++;
                    }
                }
                sortFilterProxyModel.updateVisualGrid();
                console.log("[SCAN] Successfully loaded " + validCount + " wallpapers into memory.");
            }
        }
    }
}
