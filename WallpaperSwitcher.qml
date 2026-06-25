import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Import your generated colors library
import "./Variables/colors.js" as Colors

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
        color: Colors.surface.base
        radius: 32
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
                        font.family: "Rubik"
                        font.pixelSize: 22
                        font.bold: true
                        color: Colors.surface.on_base
                    }
                    Text {
                        text: switcherRoot.currentWallpaper ? "Active: " + switcherRoot.currentWallpaper.substring(switcherRoot.currentWallpaper.lastIndexOf('/') + 1) : "Select a wallpaper to shift system palettes"
                        font.family: "Rubik"
                        font.pixelSize: 12
                        color: Colors.surface.on_variant
                        elide: Text.ElideMiddle
                        Layout.maximumWidth: 320
                    }
                }

                Rectangle {
                    id: searchBox
                    Layout.fillWidth: true
                    Layout.preferredHeight: 44
                    color: Colors.surface.container
                    border.color: searchInput.activeFocus ? Colors.primary.base : Colors.outline.variant
                    border.width: 1
                    radius: 22

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16

                        TextInput {
                            id: searchInput
                            Layout.fillWidth: true
                            font.family: "Rubik"
                            font.pixelSize: 14
                            color: Colors.surface.on_base
                            focus: true
                            selectByMouse: true

                            Text {
                                text: "Search wallpapers..."
                                font.family: "Rubik"
                                font.pixelSize: 14
                                color: Colors.surface.on_variant
                                visible: !searchInput.text && !searchInput.activeFocus
                            }

                            Keys.onDownPressed: listView.focus = true
                            Keys.onReturnPressed: listView.focus = true
                        }

                        Text {
                            text: "✕"
                            font.pixelSize: 14
                            color: Colors.surface.on_variant
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
                        color: refreshBtn.down ? Colors.surface.variant : (refreshBtn.hovered ? Colors.surface.container_highest : Colors.surface.container_high)
                        border.color: Colors.outline.variant
                        border.width: 1
                        radius: 100
                    }
                    contentItem: Text {
                        text: refreshBtn.text
                        font.family: "Rubik"
                        color: Colors.primary.base
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

                // Vertical wheel → horizontal item-by-item scroll using MouseArea
                MouseArea {
                    anchors.fill: parent

                    // CRITICAL: Tells the MouseArea to ignore clicks so they pass through to your wallpaper tiles!
                    acceptedButtons: Qt.NoButton
                    hoverEnabled: true

                    onWheel: wheel => {
                        var total = listView.count; // Use the ListView's built-in item count

                        if (wheel.angleDelta.y < 0) {
                            // Scroll Right (Next item): add one if not at the end
                            if (listView.currentIndex < total - 1) {
                                listView.currentIndex++;
                            }
                        } else if (wheel.angleDelta.y > 0) {
                            // Scroll Left (Previous item): remove one if not at the start
                            if (listView.currentIndex > 0) {
                                listView.currentIndex--;
                            }
                        }
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
                        radius: 16
                        color: switcherRoot.currentWallpaper === filePath ? Colors.secondary.container : ((tileMouseArea.containsMouse || delegateItem.ListView.isCurrentItem && listView.activeFocus) ? Colors.surface.container_highest : Colors.surface.container)

                        border.color: (switcherRoot.currentWallpaper === filePath || (delegateItem.ListView.isCurrentItem && listView.activeFocus)) ? Colors.primary.base : Colors.outline.variant
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
                                    color: Colors.surface.container_highest
                                    visible: mediaLoader.status !== Loader.Ready || (mediaLoader.item && mediaLoader.item.status !== Image.Ready)
                                    Text {
                                        anchors.centerIn: parent
                                        text: "Loading..."
                                        font.family: "Rubik"
                                        color: Colors.surface.on_variant
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
                                    color: Colors.surface.variant
                                    visible: filePath.toLowerCase().endsWith(".gif")
                                    Text {
                                        anchors.centerIn: parent
                                        text: "GIF"
                                        font.family: "Rubik"
                                        font.bold: true
                                        font.pixelSize: 10
                                        color: Colors.surface.on_variant
                                    }
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: fileName
                                font.family: "Rubik"
                                color: switcherRoot.currentWallpaper === filePath ? Colors.primary.base : Colors.surface.on_base
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

        Quickshell.execDetached({
            command: ["awww", "img", filePath, "--transition-type", "center", "--transition-duration", "1.5", "--transition-bezier", "0.05,0.7,0.1,1"]
        });

        Quickshell.execDetached({
            command: ["bash", "-c", "matugen", "image", filePath, "--source-color-index 0"]
        });
    }

    // --- Matugen Process ---
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
            console.log("[MATUGEN] Exited: " + code + " | Reload Quickshell to apply new palette.");
        }
    }

    // --- File IO Engine ---
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
