import QtQuick

Canvas {
    id: canvas
    anchors.fill: parent

    // --- Physics Configuration ---
    property point anchorPoint: Qt.point(0, 0)      // The fixed screen corner
    property point targetPoint: Qt.point(100, 100)  // The moving rectangle corner
    property real gravity: 0.5                      // Downward force
    property real friction: 0.98                    // Damping (air resistance)
    property int segmentCount: 30                   // Increased for smoother curves
    property real restLength: 3                    // Distance between segments
    property color stringColor: "#3498db"
    property real stringWidth: 10
    // ADD THIS: Force a repaint when visibility changes or properties change
    onVisibleChanged: requestPaint()
    onStringWidthChanged: requestPaint()
    onStringColorChanged: requestPaint()
    property var points: []

    // 1. Initialize nodes with explicit anchor pinning
    Component.onCompleted: {
        let pts = [];
        for (let i = 0; i < segmentCount; i++) {
            pts.push({
                x: anchorPoint.x,
                y: anchorPoint.y,
                oldX: anchorPoint.x,
                oldY: anchorPoint.y
            });
        }
        points = pts;
        physicsTimer.start();
    }

    // 2. Optimized Verlet Physics Simulation Loop
    Timer {
        id: physicsTimer
        interval: 16
        running: true
        repeat: true
        onTriggered: {
            if (!canvas.points || canvas.points.length === 0)
                return;

            // Pin the start and end nodes to the two control points
            canvas.points[0].x = canvas.anchorPoint.x;
            canvas.points[0].y = canvas.anchorPoint.y;
            canvas.points[canvas.segmentCount - 1].x = canvas.targetPoint.x;
            canvas.points[canvas.segmentCount - 1].y = canvas.targetPoint.y;

            // Verlet Integration for free nodes (nodes 1 to segmentCount-2)
            for (let i = 1; i < canvas.segmentCount - 1; i++) {
                let p = canvas.points[i];
                let vx = (p.x - p.oldX) * canvas.friction;
                let vy = (p.y - p.oldY) * canvas.friction;
                p.oldX = p.x;
                p.oldY = p.y;
                p.x += vx;
                p.y += vy + canvas.gravity;
            }

            // Constraint Solver (Multiple passes for stiffness)
            for (let k = 0; k < 8; k++) {
                for (let i = 0; i < canvas.segmentCount - 1; i++) {
                    let p1 = canvas.points[i];
                    let p2 = canvas.points[i + 1];
                    let dx = p2.x - p1.x;
                    let dy = p2.y - p1.y;
                    let dist = Math.sqrt(dx * dx + dy * dy);
                    if (dist === 0)
                        dist = 0.1;

                    let diff = (canvas.restLength - dist) / dist * 0.5;
                    let offX = dx * diff;
                    let offY = dy * diff;

                    if (i !== 0) {
                        p1.x -= offX;
                        p1.y -= offY;
                    }
                    if (i !== canvas.segmentCount - 2) {
                        p2.x += offX;
                        p2.y += offY;
                    }
                }
            }
            canvas.requestPaint();
        }
    }

    onPaint: {
        let ctx = getContext("2d");

        // 1. Clear the canvas completely
        ctx.clearRect(0, 0, width, height);

        // 2. CRITICAL: Reset the context state to clear persistent line properties
        // This removes any previous lineWidth, strokeStyle, or transformations
        if (ctx.reset) {
            ctx.reset();
        } else {
            // Fallback for older Qt versions: manually reset key properties
            ctx.setTransform(1, 0, 0, 1, 0, 0);
        }

        if (!points || points.length < 2)
            return;

        // 3. Apply properties AFTER reset
        ctx.strokeStyle = canvas.stringColor;
        ctx.lineWidth = canvas.stringWidth;
        ctx.lineCap = "round";
        ctx.lineJoin = "round";

        // 4. Defensive check: If lineWidth is somehow invalid, force it again
        if (ctx.lineWidth !== canvas.stringWidth) {
            ctx.lineWidth = canvas.stringWidth;
        }

        ctx.beginPath();
        ctx.moveTo(points[0].x, points[0].y);

        for (let i = 1; i < points.length - 1; i++) {
            let xc = (points[i].x + points[i + 1].x) / 2;
            let yc = (points[i].y + points[i + 1].y) / 2;
            ctx.quadraticCurveTo(points[i].x, points[i].y, xc, yc);
        }

        ctx.lineTo(points[points.length - 1].x, points[points.length - 1].y);
        ctx.stroke();
    }
}
