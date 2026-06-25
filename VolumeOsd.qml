import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Widgets

import "./Variables/colors.js" as Colors
import "./Variables/variables.js" as Vars

Scope {
    id: root
    
    property int spacingValue: 16
    property bool shouldShowOsd: false
    property real smoothVolume: Pipewire.defaultAudioSink?.audio?.volume ?? 0

    // Material 3 Expressive Easing Curve
    property var m3Expressive: [0.05, 0.7, 0.1, 1.0]

    property string volumeIcon: {
        let isMuted = Pipewire.defaultAudioSink?.audio?.muted ?? false;
        let vol = Pipewire.defaultAudioSink?.audio?.volume ?? 0;

        if (isMuted || vol <= 0.0)
            return "\uE04F";
        if (vol < 0.5)
            return "\uE04D";
        return "\uE050";
    }

    // Smooth width scaling of the volume bar
    Behavior on smoothVolume {
        NumberAnimation {
            duration: 250
            easing.type: Easing.BezierSpline
            easing.bezierCurve: root.m3Expressive
        }
    }

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    Connections {
        target: Pipewire.defaultAudioSink?.audio

        function onVolumeChanged() {
            root.shouldShowOsd = true;
            if (!globalMouseArea.containsMouse) {
                hideTimer.restart();
            }
        }

        function onMutedChanged() {
            root.shouldShowOsd = true;
            if (!globalMouseArea.containsMouse) {
                hideTimer.restart();
            }
        }
    }

    Timer {
        id: hideTimer
        interval: 1500
        onTriggered: root.shouldShowOsd = false
    }

    PanelWindow {
        id: osdWindow

        anchors.bottom: true
        
        implicitWidth: 380
        implicitHeight: 72
        color: "transparent"

        exclusionMode: ExclusionMode.Ignore
        aboveWindows: true

        // 1. FIXED: Define mask boundaries using an invisible Item
        Item {
            id: maskBounds
            width: parent.width
            height: root.shouldShowOsd ? parent.height : 8
            y: root.shouldShowOsd ? 0 : parent.height - 8
        }

        // 2. FIXED: Feed the tracking item directly into the mask property
        mask: Region { item: maskBounds }

        // Global interaction layer for hovering and scrolling
        MouseArea {
            id: globalMouseArea
            anchors.fill: parent
            hoverEnabled: true

            // Open on hover and hold open
            onEntered: {
                root.shouldShowOsd = true;
                hideTimer.stop();
            }

            // Start fade out timer only if the user isn't actively dragging the volume slider
            onExited: {
                if (!sliderMouseArea.pressed) {
                    hideTimer.restart();
                }
            }

            // Scroll anywhere on the OSD to adjust audio
            onWheel: (wheel) => {
                if (Pipewire.defaultAudioSink?.audio) {
                    let delta = wheel.angleDelta.y > 0 ? 0.02 : -0.02;
                    let newVol = Math.max(0.0, Math.min(1.0, Pipewire.defaultAudioSink.audio.volume + delta));
                    Pipewire.defaultAudioSink.audio.volume = newVol;
                }
            }
        }

        Rectangle {
            id: osdContainer
            width: parent.width
            height: 64
            
            anchors.bottom: parent.bottom
            anchors.bottomMargin: root.shouldShowOsd ? 8 : -64

            opacity: root.shouldShowOsd ? 1.0 : 0.0

            Behavior on anchors.bottomMargin {
                NumberAnimation {
                    duration: 350
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: root.m3Expressive
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: 250
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: root.m3Expressive
                }
            }

            color: Colors.primary.base
            radius: Math.min(width, height) * Vars.radiusAmount

            RowLayout {
                id: rowLayout
                anchors.fill: parent
                anchors.margins: spacingValue

                Text {
                    id: iconText
                    Layout.alignment: Qt.AlignVCenter
                    transformOrigin: Item.Center

                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 24
                    color: Colors.primary.on_base
                    text: root.volumeIcon

                    onTextChanged: {
                        if (!iconPop.running) {
                            iconPop.restart();
                        }
                    }

                    SequentialAnimation {
                        id: iconPop
                        NumberAnimation { target: iconText; property: "scale"; to: 1.25; duration: 150; easing.type: Easing.BezierSpline; easing.bezierCurve: root.m3Expressive }
                        NumberAnimation { target: iconText; property: "scale"; to: 1.0; duration: 250; easing.type: Easing.BezierSpline; easing.bezierCurve: root.m3Expressive }
                    }

                    // Click the icon to quickly toggle mute status
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (Pipewire.defaultAudioSink?.audio) {
                                Pipewire.defaultAudioSink.audio.muted = !Pipewire.defaultAudioSink.audio.muted;
                            }
                        }
                    }
                }

                // Interactive Volume Slider Track
                Rectangle {
                    id: sliderTrack
                    Layout.fillWidth: true
                    implicitHeight: 12
                    color: Colors.primary.container
                    radius: osdContainer.radius - spacingValue

                    // Active Fill Bar
                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        color: Colors.primary.on_container
                        radius: parent.radius
                        width: parent.width * root.smoothVolume
                    }

                    // Handles clicks and drags across the track
                    MouseArea {
                        id: sliderMouseArea
                        anchors.fill: parent
                        anchors.margins: -8 
                        preventStealing: true

                        function dragVolume(mouse) {
                            if (Pipewire.defaultAudioSink?.audio) {
                                let percentage = Math.max(0.0, Math.min(1.0, mouse.x / width));
                                Pipewire.defaultAudioSink.audio.volume = percentage;
                            }
                        }

                        onPressed: (mouse) => dragVolume(mouse)
                        onPositionChanged: (mouse) => {
                            if (pressed) dragVolume(mouse);
                        }
                        onReleased: {
                            if (!globalMouseArea.containsMouse) {
                                hideTimer.restart();
                            }
                        }
                    }
                }
            }
        }
    }
}