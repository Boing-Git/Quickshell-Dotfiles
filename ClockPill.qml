import QtQuick
import Quickshell
import QtQuick.Layouts
import "./Variables/variables.js" as Vars

Item {
    id: root
    width: 100
    height: 40

    property real pillTranslateX: pillTranslate.x
    property real pillTranslateY: pillTranslate.y

    PhysicsString {
        id: tether
        width: 300
        height: 300
        x: (root.width - width) / 2
        y: 0
        z: 0
        segmentCount: 15 
        restLength: 1.5 
        stringColor: Theme.primary
        stringWidth: 4
        anchorPoint: Qt.point(width / 2, 0)
        targetPoint: Qt.point((width / 2) + pillTranslate.x, (root.height / 2) + pillTranslate.y)
    }

    Rectangle {
        id: clockRect
        width: parent.width
        height: parent.height
        color: Theme.primary
        radius: height / 2
        z: 1

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: dragArea.pressed ? Qt.rgba(Theme.on_primary.r, Theme.on_primary.g, Theme.on_primary.b, 0.12) : (dragArea.containsMouse ? Qt.rgba(Theme.on_primary.r, Theme.on_primary.g, Theme.on_primary.b, 0.08) : "transparent")
            Behavior on color { ColorAnimation { duration: 250; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Expressive } }
        }

        transform: Translate {
            id: pillTranslate
            x: 0
            y: 0
        }

        SystemClock {
            id: systemClock
            precision: SystemClock.Minutes
        }

        Text {
            id: clockText
            font.family: Vars.fontFamily
            font.pixelSize: 14
            font.weight: 600 // Slightly bolder to match the new crisp aesthetic
            color: Theme.on_primary
            anchors.centerIn: parent
            text: Qt.formatDateTime(systemClock.date, "hh:mm ap").replace(/ [ap]m$/i, "")
        }

        MouseArea {
            id: dragArea
            anchors.fill: parent
            cursorShape: Qt.OpenHandCursor
            
            property real startMouseX: 0
            property real startMouseY: 0
            property real startTransX: 0
            property real startTransY: 0
            property real stringLength: 65 

            onPressed: (mouse) => {
                cursorShape = Qt.ClosedHandCursor
                let mapped = mapToItem(root, mouse.x, mouse.y)
                startMouseX = mapped.x
                startMouseY = mapped.y
                startTransX = pillTranslate.x
                startTransY = pillTranslate.y
                
                returnAnimX.stop()
                returnAnimY.stop()
            }

            onPositionChanged: (mouse) => {
                let mapped = mapToItem(root, mouse.x, mouse.y)
                let dx = startTransX + (mapped.x - startMouseX)
                let dy = startTransY + (mapped.y - startMouseY)
                let distance = Math.sqrt(dx * dx + dy * dy)

                if (distance > stringLength) {
                    dx = (dx / distance) * stringLength
                    dy = (dy / distance) * stringLength
                }

                pillTranslate.x = dx
                pillTranslate.y = dy
            }

            onReleased: {
                cursorShape = Qt.OpenHandCursor
                returnAnimX.start()
                returnAnimY.start()
            }
        }
    }

    SpringAnimation {
        id: returnAnimX
        target: pillTranslate
        property: "x"
        to: 0
        spring: 1.5     
        damping: 0.05   
        mass: 1.5       
    }
    
    SpringAnimation {
        id: returnAnimY
        target: pillTranslate
        property: "y"
        to: 0
        spring: 2.0     
        damping: 0.4    
        mass: 1.5
    }
}