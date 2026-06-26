import QtQuick

Canvas {
    id: canvas
    
    // --- Physics Configuration Defaults ---
    // These defaults will power the screenshot tool safely.
    property point anchorPoint: Qt.point(0, 0)
    property point targetPoint: Qt.point(100, 100)
    property real gravity: 0.5
    property real friction: 0.98
    property int segmentCount: 30
    property real restLength: 3
    property color stringColor: "#3498db"
    property real stringWidth: 10

    onVisibleChanged: requestPaint()
    onStringWidthChanged: requestPaint()
    onStringColorChanged: requestPaint()
    property var points: []

    Component.onCompleted: {
        let pts = [];
        for (let i = 0; i < segmentCount; i++) {
            pts.push({
                x: anchorPoint.x, y: anchorPoint.y,
                oldX: anchorPoint.x, oldY: anchorPoint.y
            });
        }
        points = pts;
        physicsTimer.start();
    }

    Timer {
        id: physicsTimer
        interval: 16
        running: true
        repeat: true
        onTriggered: {
            if (!canvas.points || canvas.points.length === 0) return;

            canvas.points[0].x = canvas.anchorPoint.x;
            canvas.points[0].y = canvas.anchorPoint.y;
            canvas.points[canvas.segmentCount - 1].x = canvas.targetPoint.x;
            canvas.points[canvas.segmentCount - 1].y = canvas.targetPoint.y;

            for (let i = 1; i < canvas.segmentCount - 1; i++) {
                let p = canvas.points[i];
                let vx = (p.x - p.oldX) * canvas.friction;
                let vy = (p.y - p.oldY) * canvas.friction;
                p.oldX = p.x;
                p.oldY = p.y;
                p.x += vx;
                p.y += vy + canvas.gravity;
            }

            for (let k = 0; k < 8; k++) {
                for (let i = 0; i < canvas.segmentCount - 1; i++) {
                    let p1 = canvas.points[i];
                    let p2 = canvas.points[i + 1];
                    let dx = p2.x - p1.x;
                    let dy = p2.y - p1.y;
                    let dist = Math.sqrt(dx * dx + dy * dy);
                    if (dist === 0) dist = 0.1;

                    let diff = (canvas.restLength - dist) / dist * 0.5;
                    let offX = dx * diff;
                    let offY = dy * diff;

                    if (i !== 0) { p1.x -= offX; p1.y -= offY; }
                    if (i !== canvas.segmentCount - 2) { p2.x += offX; p2.y += offY; }
                }
            }
            canvas.requestPaint();
        }
    }

    onPaint: {
        let ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);

        if (ctx.reset) { ctx.reset(); } 
        else { ctx.setTransform(1, 0, 0, 1, 0, 0); }

        if (!points || points.length < 2) return;

        ctx.strokeStyle = canvas.stringColor;
        ctx.lineWidth = canvas.stringWidth;
        ctx.lineCap = "round";
        ctx.lineJoin = "round";

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