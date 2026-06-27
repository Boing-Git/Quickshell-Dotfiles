import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris
import "./Variables/variables.js" as Vars

Item {
    id: root
    
    // Fixed layout footprint - never animates, no parent relayout
    Layout.preferredWidth: 110
    Layout.preferredHeight: 40
    
    property bool expanded: false
    // Navigation state: "" (Main Dashboard), "wifi" (Wi-Fi Settings), "bluetooth" (Bluetooth Settings)
    property string currentSubMenu: ""
    property var historyList: []
    
    // Expose the visual panel for mask tracking in TopPills
    property alias panel: panel

    Process {
        id: scaleCmd
        property real targetScale: 1.0
        command: ["hyprctl", "eval", "hl.monitor({ output = \"\", mode = \"preferred\", position = \"auto\", scale = " + targetScale + " })"]
        running: false
    }

    // ==========================================
    // BACKEND DATA BINDINGS
    // ==========================================
    
    // 1. Wi-Fi
    property var wifiDevice: Networking.devices.values.find(d => d.type === DeviceType.Wifi)
    property var activeNet: wifiDevice ? wifiDevice.networks.values.find(n => n.connected) : null
    property var signal: activeNet ? activeNet.signalStrength : 0

    readonly property string wifiIcon: {
        if (!Networking.wifiEnabled) return "\ue1da"; 
        if (!activeNet) return "\uf067"; 
        let tier = Math.min(Math.floor(signal / 25), 3);
        let icons = ["\ue1ba", "\uebe4", "\uebd6", "\uebe1"];
        return icons[tier];
    }

    // 2. Bluetooth
    property var adapter: Bluetooth.defaultAdapter
    property bool adapterState: adapter ? adapter.enabled : false
    property var connectDevice: adapter ? adapter.devices.values.find(d => d.connected) : null

    readonly property string bluetoothIcon: {
        if (!adapterState) return "\ue1a9"; 
        if (!connectDevice) return "\ue1a7"; 
        return "\ue1a8"; 
    }

    // 3. Audio & Media
    property var audioNode: Pipewire.defaultAudioSink
    property real currentVolume: audioNode && audioNode.audio ? audioNode.audio.volume : 0.0
    property var mprisPlayer: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null
    property bool isPlaying: mprisPlayer ? mprisPlayer.isPlaying : false

    // The visual panel that animates independently of the layout
    Rectangle {
        id: panel
        anchors.top: parent.top
        anchors.right: parent.right
        
        width: root.expanded ? 390 : 110
        height: root.expanded ? 660 : 40
        
        color: Theme.primary
        radius: root.expanded ? Vars.radiusExtraLarge : height / 2
        clip: true

        Behavior on radius { SpringAnimation { spring: 2.0; damping: 0.8 } }
        Behavior on width { SpringAnimation { spring: 2.0; damping: 0.8 } }
        Behavior on height { SpringAnimation { spring: 2.0; damping: 0.8 } }

        // ==========================================
        // COLLAPSED BAR PILL
        // ==========================================
        Item {
            anchors.top: parent.top
            anchors.right: parent.right
            width: 110
            height: 40
            
            opacity: root.expanded ? 0.0 : 1.0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 200 } }

            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: ccMouseArea.pressed ? Qt.rgba(Theme.on_primary.r, Theme.on_primary.g, Theme.on_primary.b, 0.12) : (ccMouseArea.containsMouse ? Qt.rgba(Theme.on_primary.r, Theme.on_primary.g, Theme.on_primary.b, 0.08) : "transparent")
                Behavior on color { ColorAnimation { duration: 250; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Expressive } }
            }

        RowLayout {
            id: collapsedUI
            anchors.fill: parent
            anchors.leftMargin: Vars.spacingMedium
            anchors.rightMargin: Vars.spacingMedium
            spacing: Vars.spacingSmall 

            Text {
                font.family: "Material Symbols Outlined"
                font.pixelSize: 18
                font.weight: 500
                color: Theme.on_primary
                text: "\uf46b"
                Layout.alignment: Qt.AlignVCenter
                rotation: root.expanded ? 180 : 0
                Behavior on rotation { RotationAnimation { duration: 400; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Expressive } }
            }
            
            Text {
                font.family: "Material Symbols Outlined"
                font.pixelSize: 16
                font.weight: 500
                color: Theme.on_primary
                opacity: adapterState ? 1.0 : 0.4
                text: bluetoothIcon
                Layout.alignment: Qt.AlignVCenter
            }
            
            Item { Layout.fillWidth: true } 

            Text {
                font.family: "Material Symbols Outlined"
                font.pixelSize: 16
                font.weight: 500
                color: Theme.on_primary
                opacity: activeNet ? 1.0 : 0.4
                text: wifiIcon
                Layout.alignment: Qt.AlignVCenter
            }
        }
        
        MouseArea {
            id: ccMouseArea
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.expanded = true
        }
    }

    // ==========================================
    // EXPANDED PANEL CONTAINER
    // ==========================================
    Item {
        id: expandedUI
        anchors.top: parent.top
        anchors.right: parent.right
        width: 390
        height: 660
        
        opacity: root.expanded ? 1.0 : 0.0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 300 } }

        // ------------------------------------------
        // VIEW 1: MAIN DASHBOARD MENU
        // ------------------------------------------
        Flickable {
            id: mainDashboardFlickable
            anchors.fill: parent
            anchors.margins: Vars.spacingLarge
            contentHeight: mainDashboardView.implicitHeight
            visible: root.currentSubMenu === ""
            clip: true
            
            // Allow tracking scroll to hide popups if needed, or just fluid scrolling
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: mainDashboardView
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: Vars.spacingMedium

            // Header Row
            RowLayout {
                Layout.fillWidth: true
                spacing: Vars.spacingMedium
                
                Rectangle {
                    width: 40; height: 40; radius: Vars.radiusMedium
                    color: backHover.pressed ? Qt.rgba(Theme.on_primary.r, Theme.on_primary.g, Theme.on_primary.b, 0.12) : (backHover.containsMouse ? Qt.rgba(Theme.on_primary.r, Theme.on_primary.g, Theme.on_primary.b, 0.08) : "transparent")
                    Text { anchors.centerIn: parent; font.family: "Material Symbols Outlined"; font.pixelSize: 20; color: Theme.on_primary; text: "\ue5c4" }
                    MouseArea { id: backHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.expanded = false }
                    Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Expressive } }
                }
                Text { text: "Control Center"; font.family: Vars.fontFamily; font.pixelSize: 20; font.weight: 600; color: Theme.on_primary }
            }

            // Quick Settings 2x3 Grid
            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: 10
                rowSpacing: 10

                // Tile 1: Wi-Fi
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 64
                    radius: Vars.radiusMedium
                    color: Networking.wifiEnabled ? Theme.primary_container : Qt.rgba(Theme.on_primary.r, Theme.on_primary.g, Theme.on_primary.b, 0.06)
                    
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: root.currentSubMenu = "wifi"
                    }

                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: Vars.spacingSmall; anchors.rightMargin: Vars.spacingSmall; spacing: Vars.spacingSmall
                        
                        // Action 1: Toggle Button
                        Rectangle {
                            width: 40; height: 40; radius: Vars.radiusMedium
                            color: Networking.wifiEnabled ? Qt.rgba(Theme.on_primary_container.r, Theme.on_primary_container.g, Theme.on_primary_container.b, 0.15) : Qt.rgba(Theme.on_primary.r, Theme.on_primary.g, Theme.on_primary.b, 0.1)
                            Text {
                                anchors.centerIn: parent; font.family: "Material Symbols Outlined"; font.pixelSize: 22
                                color: Networking.wifiEnabled ? Theme.on_primary_container : Theme.on_primary; text: wifiIcon
                            }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
                            }
                        }
                        
                        // Action 2: Sub-menu Trigger (handled by tile MouseArea)
                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 0; Layout.alignment: Qt.AlignVCenter
                            Text { text: "Wi-Fi"; font.family: Vars.fontFamily; font.pixelSize: 13; font.weight: 600; color: Networking.wifiEnabled ? Theme.on_primary_container : Theme.on_primary }
                            Text { text: activeNet ? activeNet.name : "Off"; font.family: Vars.fontFamily; font.pixelSize: 10; opacity: 0.7; color: Networking.wifiEnabled ? Theme.on_primary_container : Theme.on_primary; elide: Text.ElideRight; Layout.fillWidth: true }
                        }
                    }
                }

                // Tile 2: Audio
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 64
                    radius: Vars.radiusMedium
                    color: Theme.primary_container
                    
                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: Vars.spacingSmall; anchors.rightMargin: Vars.spacingSmall; spacing: Vars.spacingSmall
                        
                        Rectangle {
                            width: 40; height: 40; radius: Vars.radiusMedium; color: "transparent"
                            Text { anchors.centerIn: parent; font.family: "Material Symbols Outlined"; font.pixelSize: 22; color: Theme.on_primary_container; text: audioNode && audioNode.audio.muted ? "\ue04f" : "\ue050" }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: if(audioNode) audioNode.audio.muted = !audioNode.audio.muted }
                        }
                        
                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 0; Layout.alignment: Qt.AlignVCenter
                            Text { text: "Audio"; font.family: Vars.fontFamily; font.pixelSize: 13; font.weight: 600; color: Theme.on_primary_container }
                            Text { text: audioNode ? audioNode.description : "Default"; font.family: Vars.fontFamily; font.pixelSize: 10; opacity: 0.7; color: Theme.on_primary_container; elide: Text.ElideRight; Layout.fillWidth: true }
                        }
                    }
                }

                // Tile 3: Bluetooth
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 64
                    radius: Vars.radiusMedium
                    color: adapterState ? Theme.primary_container : Qt.rgba(Theme.on_primary.r, Theme.on_primary.g, Theme.on_primary.b, 0.06)
                    
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: root.currentSubMenu = "bluetooth"
                    }

                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: Vars.spacingSmall; anchors.rightMargin: Vars.spacingSmall; spacing: Vars.spacingSmall
                        
                        // Action 1: Toggle Button
                        Rectangle {
                            width: 40; height: 40; radius: Vars.radiusMedium
                            color: adapterState ? Qt.rgba(Theme.on_primary_container.r, Theme.on_primary_container.g, Theme.on_primary_container.b, 0.15) : Qt.rgba(Theme.on_primary.r, Theme.on_primary.g, Theme.on_primary.b, 0.1)
                            Text { anchors.centerIn: parent; font.family: "Material Symbols Outlined"; font.pixelSize: 22; color: adapterState ? Theme.on_primary_container : Theme.on_primary; text: bluetoothIcon }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: if (adapter) adapter.enabled = !adapter.enabled
                            }
                        }
                        
                        // Action 2: Sub-menu Trigger (handled by tile MouseArea)
                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 0; Layout.alignment: Qt.AlignVCenter
                            Text { text: "Bluetooth"; font.family: Vars.fontFamily; font.pixelSize: 13; font.weight: 600; color: adapterState ? Theme.on_primary_container : Theme.on_primary }
                            Text { text: connectDevice ? connectDevice.name : (adapterState ? "On" : "Off"); font.family: Vars.fontFamily; font.pixelSize: 10; opacity: 0.7; color: adapterState ? Theme.on_primary_container : Theme.on_primary; elide: Text.ElideRight; Layout.fillWidth: true }
                        }
                    }
                }

                // Tile 4: Display 
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 64
                    radius: Vars.radiusMedium
                    color: root.currentSubMenu === "display" ? Theme.primary_container : Qt.rgba(Theme.on_primary.r, Theme.on_primary.g, Theme.on_primary.b, 0.06)
                    
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: root.currentSubMenu = "display"
                    }

                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: Vars.spacingSmall; anchors.rightMargin: Vars.spacingSmall; spacing: Vars.spacingSmall
                        Rectangle {
                            width: 40; height: 40; radius: Vars.radiusMedium; color: "transparent"
                            Text { anchors.centerIn: parent; font.family: "Material Symbols Outlined"; text: "\ue30d"; font.pixelSize: 22; color: root.currentSubMenu === "display" ? Theme.on_primary_container : Theme.on_primary }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 0; Layout.alignment: Qt.AlignVCenter
                            Text { text: "Display"; font.family: Vars.fontFamily; font.pixelSize: 13; font.weight: 600; color: root.currentSubMenu === "display" ? Theme.on_primary_container : Theme.on_primary; elide: Text.ElideRight; Layout.fillWidth: true }
                            Text { text: "Scale"; font.family: Vars.fontFamily; font.pixelSize: 10; opacity: 0.7; color: root.currentSubMenu === "display" ? Theme.on_primary_container : Theme.on_primary; elide: Text.ElideRight; Layout.fillWidth: true }
                        }
                    }
                }

                // Tile 5: Peace 
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 64
                    radius: Vars.radiusMedium
                    color: Qt.rgba(Theme.on_primary.r, Theme.on_primary.g, Theme.on_primary.b, 0.06)
                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: Vars.spacingSmall; anchors.rightMargin: Vars.spacingSmall; spacing: Vars.spacingSmall
                        Rectangle {
                            width: 40; height: 40; radius: Vars.radiusMedium; color: "transparent"
                            Text { anchors.centerIn: parent; font.family: "Material Symbols Outlined"; text: "\ue15c"; font.pixelSize: 22; color: Theme.on_primary }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 0; Layout.alignment: Qt.AlignVCenter
                            Text { text: "Peace"; font.family: Vars.fontFamily; font.pixelSize: 13; font.weight: 600; color: Theme.on_primary; elide: Text.ElideRight; Layout.fillWidth: true }
                            Text { text: "Off"; font.family: Vars.fontFamily; font.pixelSize: 10; opacity: 0.7; color: Theme.on_primary; elide: Text.ElideRight; Layout.fillWidth: true }
                        }
                    }
                }

                // Tile 6: Night Light
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 64
                    radius: Vars.radiusMedium
                    color: Qt.rgba(Theme.on_primary.r, Theme.on_primary.g, Theme.on_primary.b, 0.06)
                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: Vars.spacingSmall; anchors.rightMargin: Vars.spacingSmall; spacing: Vars.spacingSmall
                        Rectangle {
                            width: 40; height: 40; radius: Vars.radiusMedium; color: "transparent"
                            Text { anchors.centerIn: parent; font.family: "Material Symbols Outlined"; text: "\ue51c"; font.pixelSize: 22; color: Theme.on_primary }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 0; Layout.alignment: Qt.AlignVCenter
                            Text { text: "Night Light"; font.family: Vars.fontFamily; font.pixelSize: 13; font.weight: 600; color: Theme.on_primary; elide: Text.ElideRight; Layout.fillWidth: true }
                            Text { text: "Off"; font.family: Vars.fontFamily; font.pixelSize: 10; opacity: 0.7; color: Theme.on_primary; elide: Text.ElideRight; Layout.fillWidth: true }
                        }
                    }
                }
            }

            // Sliders Section
            ColumnLayout {
                Layout.fillWidth: true; spacing: Vars.spacingMedium
                
                // Volume Row
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48
                    radius: Vars.radiusMedium
                    color: Qt.rgba(Theme.on_primary.r, Theme.on_primary.g, Theme.on_primary.b, 0.06)
                    clip: true

                    Rectangle {
                        width: Math.max(parent.height, parent.width * currentVolume)
                        height: parent.height; radius: Vars.radiusMedium; color: Theme.primary_container
                    }

                    Text { anchors.left: parent.left; anchors.leftMargin: Vars.spacingMedium; anchors.verticalCenter: parent.verticalCenter; font.family: "Material Symbols Outlined"; font.pixelSize: 20; color: Theme.on_primary_container; text: audioNode && audioNode.audio.muted ? "\ue04f" : "\ue050" }
                    MouseArea {
                        anchors.fill: parent
                        onPositionChanged: (mouse) => { if(audioNode) audioNode.audio.volume = Math.max(0, Math.min(1, mouse.x / width)) }
                        onPressed: (mouse) => { if(audioNode) audioNode.audio.volume = Math.max(0, Math.min(1, mouse.x / width)) }
                    }
                }

                // Brightness Row
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48
                    radius: Vars.radiusMedium
                    color: Qt.rgba(Theme.on_primary.r, Theme.on_primary.g, Theme.on_primary.b, 0.06)
                    
                    Rectangle { 
                        width: parent.width * 0.35 // Simulated brightness
                        height: parent.height; radius: Vars.radiusMedium; color: Theme.primary_container 
                    }
                    Text { anchors.left: parent.left; anchors.leftMargin: Vars.spacingMedium; anchors.verticalCenter: parent.verticalCenter; font.family: "Material Symbols Outlined"; font.pixelSize: 20; color: Theme.on_primary_container; text: "\ue518" }
                }
            }

            // Media Player Area
            Rectangle {
                id: mediaPlayerRoot
                Layout.fillWidth: true
                Layout.preferredHeight: 180
                radius: Vars.radiusExtraLarge
                color: Theme.primary_container
                clip: true

                property real timeScale: mprisPlayer && mprisPlayer.length > 10000000 ? 1000000 : (mprisPlayer && mprisPlayer.length > 10000 ? 1000 : 1)

                function formatTime(val) {
                    if (isNaN(val) || val <= 0) return "0:00";
                    let totalSeconds = Math.floor(val / timeScale);
                    let mins = Math.floor(totalSeconds / 60);
                    let secs = Math.floor(totalSeconds % 60);
                    return mins + ":" + (secs < 10 ? "0" : "") + secs;
                }

                Timer {
                    interval: 1000
                    repeat: true
                    running: mprisPlayer && mprisPlayer.isPlaying
                    onTriggered: {
                        if (mprisPlayer && typeof mprisPlayer.positionChanged === "function") {
                            mprisPlayer.positionChanged();
                        }
                    }
                }

                // Background Image (if any)
                Image {
                    id: albumArtImage
                    anchors.fill: parent
                    source: mprisPlayer && mprisPlayer.trackArtUrl ? mprisPlayer.trackArtUrl : ""
                    fillMode: Image.PreserveAspectCrop
                    visible: source !== ""
                }
                
                // Corner masks to simulate rounding against the Control Center background
                Item {
                    anchors.fill: parent
                    visible: albumArtImage.source !== ""

                    property real r: Vars.radiusExtraLarge
                    property color maskColor: Theme.surface
                    
                    // Top-Left
                    Item {
                        x: 0; y: 0; width: parent.r; height: parent.r; clip: true
                        Rectangle {
                            x: -parent.r; y: -parent.r; width: parent.r * 4; height: parent.r * 4; radius: parent.r * 2
                            color: "transparent"; border.color: parent.parent.maskColor; border.width: parent.r
                        }
                    }
                    // Top-Right
                    Item {
                        x: parent.width - parent.r; y: 0; width: parent.r; height: parent.r; clip: true
                        Rectangle {
                            x: -parent.r * 2; y: -parent.r; width: parent.r * 4; height: parent.r * 4; radius: parent.r * 2
                            color: "transparent"; border.color: parent.parent.maskColor; border.width: parent.r
                        }
                    }
                    // Bottom-Left
                    Item {
                        x: 0; y: parent.height - parent.r; width: parent.r; height: parent.r; clip: true
                        Rectangle {
                            x: -parent.r; y: -parent.r * 2; width: parent.r * 4; height: parent.r * 4; radius: parent.r * 2
                            color: "transparent"; border.color: parent.parent.maskColor; border.width: parent.r
                        }
                    }
                    // Bottom-Right
                    Item {
                        x: parent.width - parent.r; y: parent.height - parent.r; width: parent.r; height: parent.r; clip: true
                        Rectangle {
                            x: -parent.r * 2; y: -parent.r * 2; width: parent.r * 4; height: parent.r * 4; radius: parent.r * 2
                            color: "transparent"; border.color: parent.parent.maskColor; border.width: parent.r
                        }
                    }
                }
                
                // Fallback background icon when no album art
                Item {
                    anchors.fill: parent
                    visible: !mprisPlayer || !mprisPlayer.trackArtUrl
                    
                    Text {
                        anchors.centerIn: parent
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 120
                        color: Theme.primary
                        opacity: 0.15
                        text: "\ue405" // audiotrack
                    }
                }

                // Dark gradient overlay for text readability when there is album art
                Rectangle {
                    anchors.fill: parent
                    color: mprisPlayer && mprisPlayer.trackArtUrl ? Qt.rgba(0,0,0,0.6) : "transparent"
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Vars.spacingLarge
                    spacing: Vars.spacingSmall
                    
                    // Metadata and Controls row
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: Vars.spacingMedium
                        
                        // Text Column
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: 2
                            Layout.alignment: Qt.AlignVCenter
                            
                            Text { 
                                text: mprisPlayer ? (mprisPlayer.trackTitle || (mprisPlayer.metadata ? mprisPlayer.metadata["xesam:title"] : null) || mprisPlayer.identity || "Unknown Title") : "No Media Playing"
                                font.family: Vars.fontFamily
                                font.pixelSize: 20
                                font.weight: 700
                                color: mprisPlayer && mprisPlayer.trackArtUrl ? "white" : Theme.on_primary_container
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            Text { 
                                text: mprisPlayer && mprisPlayer.trackArtist ? mprisPlayer.trackArtist : "Artist"
                                font.family: Vars.fontFamily
                                font.pixelSize: 14
                                color: mprisPlayer && mprisPlayer.trackArtUrl ? "white" : Theme.on_primary_container
                                opacity: 0.8
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            Text { 
                                text: mprisPlayer && mprisPlayer.trackAlbum ? mprisPlayer.trackAlbum : ""
                                font.family: Vars.fontFamily
                                font.pixelSize: 12
                                color: mprisPlayer && mprisPlayer.trackArtUrl ? "white" : Theme.on_primary_container
                                opacity: 0.6
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                                visible: text !== ""
                            }
                            
                            Item { Layout.fillHeight: true }
                        }
                        
                        // Playback Controls
                        RowLayout {
                            spacing: Vars.spacingSmall
                            Layout.alignment: Qt.AlignVCenter
                            
                            // Shuffle
                            Rectangle {
                                width: 44; height: 44; radius: width/2
                                color: "transparent"
                                visible: mprisPlayer ? mprisPlayer.shuffleSupported : false
                                Text { 
                                    anchors.centerIn: parent
                                    font.family: "Material Symbols Outlined"
                                    font.pixelSize: 24
                                    color: mprisPlayer && mprisPlayer.trackArtUrl ? (mprisPlayer.shuffle ? "white" : Qt.rgba(1,1,1,0.5)) : (mprisPlayer && mprisPlayer.shuffle ? Theme.on_primary_container : Qt.rgba(Theme.on_primary_container.r, Theme.on_primary_container.g, Theme.on_primary_container.b, 0.5))
                                    text: "\ue043" 
                                }
                                MouseArea { 
                                    id: shuffleHover
                                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: if(mprisPlayer) mprisPlayer.shuffle = !mprisPlayer.shuffle 
                                }
                                Rectangle {
                                    anchors.fill: parent; radius: width/2
                                    color: mprisPlayer && mprisPlayer.trackArtUrl ? "white" : Theme.on_primary_container
                                    opacity: shuffleHover.containsMouse ? 0.15 : 0
                                    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Expressive } }
                                }
                            }

                            // Previous
                            Rectangle {
                                width: 44; height: 44; radius: width/2
                                color: "transparent"
                                Text { anchors.centerIn: parent; font.family: "Material Symbols Outlined"; font.pixelSize: 28; color: mprisPlayer && mprisPlayer.trackArtUrl ? "white" : Theme.on_primary_container; text: "\ue045" }
                                MouseArea { 
                                    id: prevHover
                                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: if(mprisPlayer) mprisPlayer.previous() 
                                }
                                Rectangle {
                                    anchors.fill: parent; radius: width/2
                                    color: mprisPlayer && mprisPlayer.trackArtUrl ? "white" : Theme.on_primary_container
                                    opacity: prevHover.containsMouse ? 0.15 : 0
                                    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Expressive } }
                                }
                            }
                            
                            // Play/Pause
                            Rectangle {
                                width: 56; height: 56; radius: Vars.radiusMedium
                                color: mprisPlayer && mprisPlayer.trackArtUrl ? "white" : Theme.primary
                                scale: playHover.pressed ? 0.9 : (playHover.containsMouse ? 1.05 : 1.0)
                                Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Expressive } }

                                Text { 
                                    anchors.centerIn: parent; font.family: "Material Symbols Outlined"; font.pixelSize: 32
                                    color: mprisPlayer && mprisPlayer.trackArtUrl ? "black" : Theme.on_primary
                                    text: isPlaying ? "\ue034" : "\ue037" 
                                }
                                MouseArea { 
                                    id: playHover
                                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: if(mprisPlayer) {
                                        if (typeof mprisPlayer.togglePlaying === "function") mprisPlayer.togglePlaying();
                                        else if (typeof mprisPlayer.playPause === "function") mprisPlayer.playPause();
                                    } 
                                }
                            }

                            // Next
                            Rectangle {
                                width: 44; height: 44; radius: width/2
                                color: "transparent"
                                Text { anchors.centerIn: parent; font.family: "Material Symbols Outlined"; font.pixelSize: 28; color: mprisPlayer && mprisPlayer.trackArtUrl ? "white" : Theme.on_primary_container; text: "\ue044" }
                                MouseArea { 
                                    id: nextHover
                                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: if(mprisPlayer) mprisPlayer.next() 
                                }
                                Rectangle {
                                    anchors.fill: parent; radius: width/2
                                    color: mprisPlayer && mprisPlayer.trackArtUrl ? "white" : Theme.on_primary_container
                                    opacity: nextHover.containsMouse ? 0.15 : 0
                                    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Expressive } }
                                }
                            }
                        }
                    }
                    
                    // Seek Bar and Timestamps
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Vars.spacingMedium
                        
                        // Current time
                        Text {
                            text: mprisPlayer && mprisPlayer.position !== undefined ? mediaPlayerRoot.formatTime(mprisPlayer.position) : "0:00"
                            font.family: Vars.fontFamily
                            font.pixelSize: 11
                            color: mprisPlayer && mprisPlayer.trackArtUrl ? "white" : Theme.on_primary_container
                            opacity: 0.8
                        }
                        
                        // Seek slider
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 6
                            radius: Math.floor(Vars.radiusSmall / 2.5)
                            color: mprisPlayer && mprisPlayer.trackArtUrl ? Qt.rgba(1,1,1,0.2) : Qt.rgba(Theme.on_primary_container.r, Theme.on_primary_container.g, Theme.on_primary_container.b, 0.2)
                            
                            Rectangle { 
                                width: parent.width * (mprisPlayer && mprisPlayer.length > 0 && mprisPlayer.position !== undefined ? (mprisPlayer.position / mprisPlayer.length) : 0)
                                height: parent.height
                                color: mprisPlayer && mprisPlayer.trackArtUrl ? "white" : Theme.primary
                                radius: Math.floor(Vars.radiusSmall / 2.5)
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                function seekToMouse(mouse) {
                                    if(mprisPlayer && mprisPlayer.length > 0) {
                                        let ratio = Math.max(0, Math.min(1, mouse.x / width));
                                        let newPos = ratio * mprisPlayer.length;
                                        // Some Mpris implementations use seek instead of position assignment
                                        if (mprisPlayer.canSeek) {
                                            mprisPlayer.position = newPos; 
                                        }
                                    }
                                }
                                onPressed: (mouse) => seekToMouse(mouse)
                                onPositionChanged: (mouse) => {
                                    if (pressed) {
                                        seekToMouse(mouse)
                                    }
                                }
                            }
                        }
                        
                        // Remaining time
                        Text {
                            text: mprisPlayer && mprisPlayer.length > 0 && mprisPlayer.position !== undefined ? "-" + mediaPlayerRoot.formatTime(mprisPlayer.length - mprisPlayer.position) : "0:00"
                            font.family: Vars.fontFamily
                            font.pixelSize: 11
                            color: mprisPlayer && mprisPlayer.trackArtUrl ? "white" : Theme.on_primary_container
                            opacity: 0.8
                        }
                    }
                }
            }

            // ==========================================
            // NOTIFICATIONS AREA
            // ==========================================
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: Vars.spacingSmall
                spacing: Vars.spacingSmall
                
                Text { text: "Notifications"; font.family: Vars.fontFamily; font.pixelSize: 18; font.weight: 600; color: Theme.on_primary; Layout.fillWidth: true }
                
                // Clear all button
                Rectangle {
                    width: 32; height: 32; radius: Vars.radiusMedium
                    color: clearHover.pressed ? Qt.rgba(Theme.on_primary.r, Theme.on_primary.g, Theme.on_primary.b, 0.12) : (clearHover.containsMouse ? Qt.rgba(Theme.on_primary.r, Theme.on_primary.g, Theme.on_primary.b, 0.08) : "transparent")
                    Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Expressive } }
                    visible: root.historyList.length > 0
                    
                    Text { anchors.centerIn: parent; font.family: "Material Symbols Outlined"; font.pixelSize: 20; color: Theme.on_primary; text: "\ue15b" }
                    
                    MouseArea {
                        id: clearHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Vars.clearNotifications()
                    }
                }
            }
            
            Text {
                text: "No new notifications"
                font.family: Vars.fontFamily; font.pixelSize: 14; color: Theme.on_surface_variant
                visible: root.historyList.length === 0
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: Vars.spacingLarge
                Layout.bottomMargin: Vars.spacingLarge
            }

            Timer {
                interval: 200
                running: true
                repeat: true
                property int lastSync: -1
                onTriggered: {
                    if (lastSync !== Vars.historyUpdated) {
                        lastSync = Vars.historyUpdated;
                        root.historyList = Vars.notificationHistory.slice();
                    }
                }
            }

            Repeater {
                model: root.historyList

                NotificationCard {
                    isPopup: false
                    fontName: Vars.fontFamily
                }
            }
        }
    }

        // ------------------------------------------
        // VIEW 2: WI-FI DETAILED SUB-MENU VIEW
        // ------------------------------------------
        ColumnLayout {
            id: wifiSubMenuView
            anchors.fill: parent
            anchors.margins: Vars.spacingLarge
            spacing: Vars.spacingMedium
            visible: root.currentSubMenu === "wifi"

            // Header matching the UI screenshot
            RowLayout {
                Layout.fillWidth: true
                spacing: Vars.spacingMedium
                
                Rectangle {
                    width: 40; height: 40; radius: Vars.radiusMedium
                    color: backHoverWifi.pressed ? Qt.rgba(Theme.on_primary.r, Theme.on_primary.g, Theme.on_primary.b, 0.12) : (backHoverWifi.containsMouse ? Qt.rgba(Theme.on_primary.r, Theme.on_primary.g, Theme.on_primary.b, 0.08) : "transparent")
                    Text { anchors.centerIn: parent; font.family: "Material Symbols Outlined"; font.pixelSize: 20; color: Theme.on_primary; text: "\ue5c4" }
                    MouseArea { id: backHoverWifi; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.currentSubMenu = "" }
                    Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Expressive } }
                }
                Text { text: "Wi-Fi Networks"; font.family: Vars.fontFamily; font.pixelSize: 20; font.weight: 600; color: Theme.on_primary; Layout.fillWidth: true }
                
                // Master Toggle Switch
                Rectangle {
                    width: 56; height: 32; radius: Vars.radiusMedium
                    color: Networking.wifiEnabled ? "white" : Qt.rgba(0,0,0,0.1)
                    Rectangle {
                        width: 24; height: 24; radius: Vars.radiusMedium
                        color: Networking.wifiEnabled ? Theme.primary : "white"
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left; anchors.leftMargin: Networking.wifiEnabled ? 28 : 4
                        Behavior on anchors.leftMargin { NumberAnimation { duration: 150 } }
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Networking.wifiEnabled = !Networking.wifiEnabled }
                }
            }

            Flickable {
                Layout.fillWidth: true; Layout.fillHeight: true
                contentHeight: wifiListContainer.childrenRect.height; clip: true

                ColumnLayout {
                    id: wifiListContainer
                    anchors.left: parent.left; anchors.right: parent.right; spacing: Vars.spacingSmall

                    Repeater {
                        model: wifiDevice ? wifiDevice.networks.values : []
                        delegate: Rectangle {
                            Layout.fillWidth: true; Layout.preferredHeight: 64; radius: Vars.radiusMedium
                            color: modelData.connected ? Qt.rgba(Theme.on_primary.r, Theme.on_primary.g, Theme.on_primary.b, 0.2) : Qt.rgba(Theme.on_primary.r, Theme.on_primary.g, Theme.on_primary.b, 0.05)
                            
                            RowLayout {
                                anchors.fill: parent; anchors.margins: Vars.spacingMedium; spacing: Vars.spacingMedium
                                Text {
                                    font.family: "Material Symbols Outlined"; font.pixelSize: 24
                                    color: Theme.on_primary; text: "\ue63e"
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 0
                                    Text { text: modelData.name; font.family: Vars.fontFamily; font.pixelSize: 14; font.weight: 600; color: Theme.on_primary }
                                    Text { text: modelData.connected ? "Connected" : "Available"; font.family: Vars.fontFamily; font.pixelSize: 12; opacity: 0.7; color: Theme.on_primary }
                                }
                            }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (modelData.connected) {
                                        modelData.disconnect();
                                    } else {
                                        modelData.connect();
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // ------------------------------------------
        // VIEW 3: BLUETOOTH DETAILED SUB-MENU VIEW
        // ------------------------------------------
        ColumnLayout {
            id: bluetoothSubMenuView
            anchors.fill: parent
            anchors.margins: Vars.spacingLarge
            spacing: Vars.spacingMedium
            visible: root.currentSubMenu === "bluetooth"

            // Header matching the UI screenshot
            RowLayout {
                Layout.fillWidth: true
                spacing: Vars.spacingMedium
                
                Rectangle {
                    width: 40; height: 40; radius: Vars.radiusMedium
                    color: Qt.rgba(Theme.on_primary.r, Theme.on_primary.g, Theme.on_primary.b, 0.08)
                    Text { anchors.centerIn: parent; font.family: "Material Symbols Outlined"; font.pixelSize: 20; color: Theme.on_primary; text: "\ue5c4" }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.currentSubMenu = "" }
                }
                Text { text: "Bluetooth Devices"; font.family: Vars.fontFamily; font.pixelSize: 20; font.weight: 600; color: Theme.on_primary; Layout.fillWidth: true }
                
                // Master Toggle Switch
                Rectangle {
                    width: 56; height: 32; radius: Vars.radiusMedium
                    color: adapterState ? "white" : Qt.rgba(0,0,0,0.1)
                    Rectangle {
                        width: 24; height: 24; radius: Vars.radiusMedium
                        color: adapterState ? Theme.primary : "white"
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left; anchors.leftMargin: adapterState ? 28 : 4
                        Behavior on anchors.leftMargin { NumberAnimation { duration: 150 } }
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: if(adapter) adapter.enabled = !adapter.enabled }
                }
            }

            Flickable {
                Layout.fillWidth: true; Layout.fillHeight: true
                contentHeight: bluetoothListContainer.childrenRect.height; clip: true

                ColumnLayout {
                    id: bluetoothListContainer
                    anchors.left: parent.left; anchors.right: parent.right; spacing: Vars.spacingSmall

                    Repeater {
                        model: adapter ? adapter.devices.values : []
                        delegate: Rectangle {
                            Layout.fillWidth: true; Layout.preferredHeight: 64; radius: Vars.radiusMedium
                            color: modelData.connected ? Qt.rgba(Theme.on_primary.r, Theme.on_primary.g, Theme.on_primary.b, 0.2) : Qt.rgba(Theme.on_primary.r, Theme.on_primary.g, Theme.on_primary.b, 0.05)
                            
                            RowLayout {
                                anchors.fill: parent; anchors.margins: Vars.spacingMedium; spacing: Vars.spacingMedium
                                Text {
                                    font.family: "Material Symbols Outlined"; font.pixelSize: 24
                                    color: Theme.on_primary; text: "\ue1a7"
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 0
                                    Text { text: modelData.name ? modelData.name : "Unknown Device"; font.family: Vars.fontFamily; font.pixelSize: 14; font.weight: 600; color: Theme.on_primary }
                                    Text { text: modelData.connected ? "Connected" : "Paired Asset"; font.family: Vars.fontFamily; font.pixelSize: 12; opacity: 0.7; color: Theme.on_primary }
                                }
                            }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (modelData.connected) {
                                        modelData.disconnect();
                                    } else {
                                        modelData.connect();
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // ------------------------------------------
        // VIEW 4: DISPLAY DETAILED SUB-MENU VIEW
        // ------------------------------------------
        ColumnLayout {
            id: displaySubMenuView
            anchors.fill: parent
            anchors.margins: Vars.spacingLarge
            spacing: Vars.spacingMedium
            visible: root.currentSubMenu === "display"

            // Header matching the UI screenshot
            RowLayout {
                Layout.fillWidth: true
                spacing: Vars.spacingMedium
                
                Rectangle {
                    width: 40; height: 40; radius: Vars.radiusMedium
                    color: Qt.rgba(Theme.on_primary.r, Theme.on_primary.g, Theme.on_primary.b, 0.08)
                    Text { anchors.centerIn: parent; font.family: "Material Symbols Outlined"; font.pixelSize: 20; color: Theme.on_primary; text: "\ue5c4" }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.currentSubMenu = "" }
                }
                Text { text: "Display Scale"; font.family: Vars.fontFamily; font.pixelSize: 20; font.weight: 600; color: Theme.on_primary; Layout.fillWidth: true }
            }

            Flickable {
                Layout.fillWidth: true; Layout.fillHeight: true
                contentHeight: displayListContainer.childrenRect.height; clip: true

                ColumnLayout {
                    id: displayListContainer
                    anchors.left: parent.left; anchors.right: parent.right; spacing: Vars.spacingSmall

                    Repeater {
                        model: [1.0, 1.25, 1.5, 2.0]
                        delegate: Rectangle {
                            Layout.fillWidth: true; Layout.preferredHeight: 64; radius: Vars.radiusMedium
                            color: Qt.rgba(Theme.on_primary.r, Theme.on_primary.g, Theme.on_primary.b, 0.05)
                            
                            RowLayout {
                                anchors.fill: parent; anchors.margins: Vars.spacingMedium; spacing: Vars.spacingMedium
                                Text {
                                    font.family: "Material Symbols Outlined"; font.pixelSize: 24
                                    color: Theme.on_primary; text: "\ue30d"
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 0
                                    Text { text: modelData + "x Scale"; font.family: Vars.fontFamily; font.pixelSize: 14; font.weight: 600; color: Theme.on_primary }
                                    Text { text: "Apply scale"; font.family: Vars.fontFamily; font.pixelSize: 12; opacity: 0.7; color: Theme.on_primary }
                                }
                            }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    scaleCmd.targetScale = modelData;
                                    scaleCmd.running = true;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    }
}