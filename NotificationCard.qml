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
        
        radius: Vars.radiusMedium // Material 3 expressive rounded corners
        color: Theme.primary
        border.color: modelData.urgency === NotificationUrgency.Critical ? Theme.error :
                      modelData.urgency === NotificationUrgency.Low      ? Theme.primary_container : Theme.primary_container
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
                Vars.pushNotification(rootCard.modelData);
            }
        }

        Accessible.role: Accessible.StaticText
        Accessible.name: (modelData.urgency === NotificationUrgency.Critical ? "[Critical] " :
                         modelData.urgency === NotificationUrgency.Low       ? "[Low] "      : "") +
                         (modelData.appName || "Notification") + ": " + (modelData.summary || "")

        HoverHandler {
            id: cardHover
            onHoveredChanged: {
                if (modelData.hovered !== undefined) {
                    modelData.hovered = hovered
                }
            }
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
            
            onClicked: (mouse) => {
                if (Math.abs(container.x) < 5) {
                    if (typeof modelData.dismiss === "function") {
                        modelData.dismiss();
                    }
                }
            }
        }

        Timer {
            id: dismissTimer
            interval: 250
            onTriggered: {
                if (isPopup) {
                    rootCard.visible = false;
                    rootCard.height = 0;
                } else {
                    if (typeof modelData.dismiss === "function") {
                        modelData.dismiss();
                    }
                }
            }
        }

        Rectangle {
            width: 4
            height: parent.height - 16
            radius: Math.floor(Vars.radiusSmall / 4)
            anchors.left: parent.left
            anchors.leftMargin: Vars.spacingSmall
            anchors.verticalCenter: parent.verticalCenter
            color: modelData.urgency === NotificationUrgency.Critical ? Theme.error :
                   modelData.urgency === NotificationUrgency.Low      ? Theme.primary_container : Theme.on_primary
        }

        ColumnLayout {
            id: cardContent
            anchors.fill: parent
            anchors.leftMargin: Vars.spacingMedium
            anchors.rightMargin: Vars.spacingMedium
            anchors.topMargin: Vars.spacingMedium
            anchors.bottomMargin: Vars.spacingMedium
            spacing: Vars.spacingSmall

            // Header row
            RowLayout {
                Layout.fillWidth: true
                spacing: Vars.spacingSmall

                Item {
                    Layout.preferredWidth: 18
                    Layout.preferredHeight: 18
                    Layout.alignment: Qt.AlignVCenter

                    IconImage {
                        anchors.centerIn: parent
                        source: Quickshell.iconPath(modelData.appIcon || "", true)
                        implicitSize: 18
                        visible: modelData.appIcon !== "" && modelData.appIcon !== undefined
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: modelData.appIcon === "" || modelData.appIcon === undefined
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
                               ? Theme.error : Theme.on_primary
                        font.pixelSize: 16
                        font.family: (modelData.appIcon === "" || modelData.appIcon === undefined) && text === "\ue7f4" ? "Material Symbols Outlined" : rootCard.fontName
                    }
                }

                Text {
                    text: modelData.appName || "Notification"
                    color: Theme.on_primary_container
                    font.pixelSize: 12
                    font.family: rootCard.fontName
                    Layout.alignment: Qt.AlignVCenter
                }

                Item { Layout.fillWidth: true }
                
                Rectangle {
                    width: 24
                    height: 24
                    radius: Math.floor(Vars.radiusMedium * 0.75)
                    color: closeHover.pressed ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.12) : (closeHover.containsMouse ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.08) : "transparent")
                    Layout.alignment: Qt.AlignVCenter
                    
                    Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Expressive } }

                    Text {
                        anchors.centerIn: parent
                        text: "\ue5cd"
                        color: closeHover.containsMouse ? Theme.error : Theme.on_primary_container
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
                text: modelData.summary || ""
                color: Theme.on_primary
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
                spacing: Vars.spacingSmall
                visible: (modelData.body !== "" && modelData.body !== undefined) || (modelData.image !== "" && modelData.image !== undefined)

                Text {
                    text: modelData.body || ""
                    color: Theme.on_primary_container
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
                    radius: Vars.radiusSmall
                    color: Theme.primary_container
                    clip: true
                    visible: modelData.image !== "" && modelData.image !== undefined

                    Image {
                        anchors.fill: parent
                        source: modelData.image || ""
                        fillMode: Image.PreserveAspectCrop
                        sourceSize.width: 40
                        sourceSize.height: 40
                    }
                }
            }

            // Actions
            RowLayout {
                Layout.fillWidth: true
                spacing: Vars.spacingSmall
                visible: modelData.actions !== undefined && modelData.actions.length > 0

                Repeater {
                    model: modelData.actions || []

                    Rectangle {
                        id: actionBtn
                        required property var modelData

                        Layout.preferredHeight: 32
                        Layout.preferredWidth: actionText.width + 24
                        radius: Vars.radiusSmall
                        color: actionHover.pressed ? Qt.rgba(Theme.on_primary.r, Theme.on_primary.g, Theme.on_primary.b, 0.2) : (actionHover.containsMouse ? Qt.rgba(Theme.on_primary.r, Theme.on_primary.g, Theme.on_primary.b, 0.16) : Qt.rgba(Theme.on_primary.r, Theme.on_primary.g, Theme.on_primary.b, 0.1))

                        Behavior on color {
                            ColorAnimation { duration: 150; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Expressive }
                        }

                        Text {
                            id: actionText
                            anchors.centerIn: parent
                            text: actionBtn.modelData.text || ""
                            color: Theme.on_primary
                            font.pixelSize: 13
                            font.family: rootCard.fontName
                            font.weight: 600
                        }

                        MouseArea {
                            id: actionHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (typeof rootCard.modelData.invokeAction === "function") {
                                    rootCard.modelData.invokeAction(actionBtn.modelData.identifier);
                                }
                            }
                        }
                    }
                }
            }

            // Progress bar (Timeout)
            Rectangle {
                Layout.fillWidth: true
                height: 3
                radius: Math.floor(Vars.radiusSmall / 5)
                color: Qt.rgba(Theme.on_primary.r, Theme.on_primary.g, Theme.on_primary.b, 0.2)
                Layout.topMargin: (Vars.spacingSmall / 2)
                visible: rootCard.modelData.urgency !== NotificationUrgency.Critical && isPopup

                Rectangle {
                    id: progressBar
                    height: parent.height
                    width: parent.width
                    radius: Math.floor(Vars.radiusSmall / 5)
                    color: rootCard.modelData.urgency === NotificationUrgency.Critical
                           ? Theme.error : Theme.on_primary
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
                                      : (rootCard.modelData.defaultTimeout || 5000)
                        }
                        onFinished: {
                            if (isPopup) {
                                rootCard.dismissing = true;
                                dismissTimer.start();
                            }
                        }
                    }
                }
            }
        }
    }
}
