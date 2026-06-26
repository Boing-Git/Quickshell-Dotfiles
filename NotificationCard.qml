import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import "./Variables/variables.js" as Vars

Item {
    id: rootCard
    required property var modelData
    property bool isPopup: false
    property string fontName: "Rubik"
    
    // We bind height to the card container's height so the list layout reacts properly
    width: parent ? parent.width : 360
    height: container.height

    // Animate height changes for smooth insertions/removals
    Behavior on height {
        NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
    }

    // A state flag to indicate if we are dismissing so we can trigger animations
    property bool dismissing: false

    // Drag-to-dismiss properties
    property real dragThreshold: width * 0.4

    // Actual visual card
    Rectangle {
        id: container
        width: parent.width
        height: cardContent.implicitHeight + 24
        
        // Drag logic transforms the container X
        x: 0
        
        radius: 16 // Material 3 expressive rounded corners
        color: Theme.surface
        border.color: modelData.urgency === NotificationUrgency.Critical ? Theme.error :
                      modelData.urgency === NotificationUrgency.Low      ? Theme.primary_container : Theme.surface_variant
        border.width: 1
        clip: true

        // Spring animation for X (when released)
        Behavior on x {
            SpringAnimation {
                spring: dismissing ? 1.5 : 3.0
                damping: dismissing ? 1.0 : 0.7
                epsilon: 0.1
            }
        }

        // Opacity animation for entry/exit
        opacity: dismissing ? 0.0 : 1.0
        Behavior on opacity {
            NumberAnimation { duration: dismissing ? 200 : 300; easing.type: Easing.OutCubic }
        }

        // Entry animation (opacity from 0)
        Component.onCompleted: {
            if (isPopup) {
                opacity = 0;
                Qt.callLater(() => { opacity = 1.0; });
            }
        }

        Accessible.role: Accessible.StaticText
        Accessible.name: (modelData.urgency === NotificationUrgency.Critical ? "[Critical] " :
                         modelData.urgency === NotificationUrgency.Low       ? "[Low] "      : "") +
                         (modelData.appName || "Notification") + ": " + modelData.summary

        HoverHandler {
            id: cardHover
            onHoveredChanged: modelData.hovered = hovered
        }

        // Drag handling
        MouseArea {
            anchors.fill: parent
            drag.target: container
            drag.axis: Drag.XAxis
            
            // Limit drag depending on whether we want free drag
            drag.minimumX: -rootCard.width * 1.5
            drag.maximumX: rootCard.width * 1.5
            
            onReleased: {
                if (Math.abs(container.x) > rootCard.dragThreshold) {
                    // Passed threshold, dismiss
                    rootCard.dismissing = true;
                    // Push it off screen
                    container.x = container.x > 0 ? rootCard.width * 1.5 : -rootCard.width * 1.5;
                    
                    // Delay actual dismiss to let animation play
                    dismissTimer.start();
                } else {
                    // Snap back
                    container.x = 0;
                }
            }
            cursorShape: Qt.PointingHandCursor
            
            // Just clicking without dragging dismisses too? No, usually a click on background is default action
            onClicked: (mouse) => {
                if (Math.abs(container.x) < 5) {
                    // Normal click action
                    // if it has default action we might invoke it, otherwise dismiss
                    modelData.dismiss();
                }
            }
        }

        Timer {
            id: dismissTimer
            interval: 250
            onTriggered: modelData.dismiss()
        }

        Rectangle {
            width: 4
            height: parent.height - 16
            radius: 2
            anchors.left: parent.left
            anchors.leftMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            color: modelData.urgency === NotificationUrgency.Critical ? Theme.error :
                   modelData.urgency === NotificationUrgency.Low      ? Theme.primary_container : Theme.primary
        }

        ColumnLayout {
            id: cardContent
            anchors.fill: parent
            anchors.leftMargin: 18
            anchors.rightMargin: 12
            anchors.topMargin: 12
            anchors.bottomMargin: 12
            spacing: 8

            // Header row
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Item {
                    Layout.preferredWidth: 18
                    Layout.preferredHeight: 18
                    Layout.alignment: Qt.AlignVCenter

                    IconImage {
                        anchors.centerIn: parent
                        source: Quickshell.iconPath(modelData.appIcon, true)
                        implicitSize: 18
                        visible: modelData.appIcon !== ""
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: modelData.appIcon === ""
                        text: {
                            const name = (modelData.appName || "").toLowerCase();
                            if (modelData.urgency === NotificationUrgency.Critical) return "";
                            if (name.includes("discord"))  return "";
                            if (name.includes("firefox"))  return "";
                            if (name.includes("chrome"))   return "";
                            if (name.includes("telegram")) return "";
                            if (name.includes("spotify"))  return "";
                            if (name.includes("terminal") || name.includes("kitty") || name.includes("alacritty")) return "";
                            return "\ue7f4"; // Default material notification icon
                        }
                        color: modelData.urgency === NotificationUrgency.Critical
                               ? Theme.error : Theme.primary
                        font.pixelSize: 16
                        font.family: modelData.appIcon === "" && text === "\ue7f4" ? "Material Symbols Outlined" : rootCard.fontName
                    }
                }

                Text {
                    text: modelData.appName || "Notification"
                    color: Theme.on_surface_variant
                    font.pixelSize: 12
                    font.family: rootCard.fontName
                    Layout.alignment: Qt.AlignVCenter
                }

                Item { Layout.fillWidth: true }
                
                // Timestamp could go here (if supported), or just standard close button
                Rectangle {
                    width: 24
                    height: 24
                    radius: 12
                    color: closeHover.containsMouse ? Theme.surface_variant : "transparent"
                    Layout.alignment: Qt.AlignVCenter
                    
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: "\ue5cd"
                        color: closeHover.containsMouse ? Theme.error : Theme.on_surface_variant
                        font.pixelSize: 16
                        font.family: "Material Symbols Outlined"
                    }

                    MouseArea {
                        id: closeHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            rootCard.dismissing = true;
                            dismissTimer.start();
                        }
                    }
                }
            }

            // Summary (Title)
            Text {
                text: modelData.summary
                color: Theme.on_surface
                font.pixelSize: 15
                font.family: rootCard.fontName
                font.weight: 700
                elide: Text.ElideRight
                Layout.fillWidth: true
                visible: text !== ""
            }

            // Body and Image
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                visible: modelData.body !== "" || modelData.image !== ""

                Text {
                    text: modelData.body
                    color: Theme.on_surface_variant
                    font.pixelSize: 14
                    font.family: rootCard.fontName
                    wrapMode: Text.Wrap
                    maximumLineCount: 3
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    visible: text !== ""
                    textFormat: Text.PlainText
                }

                Rectangle {
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40
                    radius: 8
                    color: Theme.surface_variant
                    clip: true
                    visible: modelData.image !== ""

                    Image {
                        anchors.fill: parent
                        source: modelData.image
                        fillMode: Image.PreserveAspectCrop
                        sourceSize.width: 40
                        sourceSize.height: 40
                    }
                }
            }

            // Actions
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                visible: modelData.actions && modelData.actions.length > 0

                Repeater {
                    model: modelData.actions || []

                    Rectangle {
                        id: actionBtn
                        required property var modelData

                        Layout.preferredHeight: 32
                        Layout.preferredWidth: actionText.width + 24
                        radius: 8
                        color: actionHover.containsMouse ? Theme.surface_variant : Theme.surface_container

                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }

                        Text {
                            id: actionText
                            anchors.centerIn: parent
                            text: actionBtn.modelData.text || ""
                            color: Theme.primary
                            font.pixelSize: 13
                            font.family: rootCard.fontName
                            font.weight: 600
                        }

                        MouseArea {
                            id: actionHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: rootCard.modelData.invokeAction(actionBtn.modelData.identifier)
                        }
                    }
                }
            }

            // Progress bar (Timeout)
            Rectangle {
                Layout.fillWidth: true
                height: 3
                radius: 1.5
                color: Theme.surface_container
                Layout.topMargin: 4
                visible: rootCard.modelData.urgency !== NotificationUrgency.Critical && isPopup

                Rectangle {
                    id: progressBar
                    height: parent.height
                    width: parent.width
                    radius: 1.5
                    color: rootCard.modelData.urgency === NotificationUrgency.Critical
                           ? Theme.error : Theme.primary
                    opacity: 0.8

                    SequentialAnimation {
                        running: rootCard.modelData.urgency !== NotificationUrgency.Critical && isPopup
                        PauseAnimation { duration: 50 }
                        NumberAnimation {
                            target: progressBar
                            property: "width"
                            to: 0
                            duration: rootCard.modelData.expireTimeout > 0
                                      ? rootCard.modelData.expireTimeout
                                      : rootCard.modelData.defaultTimeout
                        }
                    }
                }
            }
        }
    }
}
