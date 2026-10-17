import QtQuick

// Pixel-art Clawd on a 15x8 grid (the 12x7 sprite plus room for speed lines
// and the run bob). Blinks every 10 s; runs a 4-frame cycle while `working`.
Item {
    id: clawd

    property bool working: false
    property color color: "#D97757"

    property bool blinking: false
    property int step: 0

    readonly property real px: Math.max(1, Math.floor(Math.min(width / 15, height / 8)))

    // Sprite origin inside the grid; the run bob lifts it half a pixel on
    // the passing frames (1 and 3).
    readonly property real ox: 1.5
    readonly property real oy: working && step % 2 === 1 ? 0 : 0.5

    // [x, y, w, h, opacity] in grid units, relative to the sprite origin.
    // Eyes are holes in the body so the panel shows through, which keeps the
    // sprite monochrome like other panel icons.
    readonly property var pixels: {
        const run = working
        const s = step
        // Eyes look ahead (half a pixel right) while running.
        const e = run ? 0.5 : 0
        const out = [
            [2, 0, 8, 1, 1],                                        // body above eyes
            [2, 3, 8, 2, 1],                                        // body below eyes
            [2, 1, 1 + e, 2, 1],                                    // body around
            [4 + e, 1, 4, 2, 1],                                    // the eye
            [9 + e, 1, 1 - e, 2, 1],                                // holes
        ]

        if (!run) {
            out.push([0, 2, 2, 2, 1], [10, 2, 2, 2, 1])            // arms
            for (const x of [2, 4, 7, 9])
                out.push([x, 5, 1, 2, 1])                           // legs
        } else {
            // Arms swing in opposition.
            const up = s < 2
            out.push([0, up ? 1.5 : 2.5, 2, 1.5, 1], [10, up ? 2.5 : 1.5, 2, 1.5, 1])
            // Legs: [back pair x, back length, front pair x, front length].
            const legs = [
                [1.5, 2, 7.5, 1],     // back legs push off, front legs lifted
                [2, 1.5, 7, 1.5],     // passing
                [2.5, 1, 8, 2],       // front legs reach, back legs lifted
                [2, 1.5, 7, 1.5],     // passing
            ][s]
            out.push([legs[0], 5, 1, legs[1], 1], [legs[0] + 2, 5, 1, legs[1], 1])
            out.push([legs[2], 5, 1, legs[3], 1], [legs[2] + 2, 5, 1, legs[3], 1])
            // Speed lines trailing behind, flickering between two heights.
            if (s % 2 === 0)
                out.push([-1.5, 1.5, 1, 0.5, 0.6], [-1.5, 3.5, 1.25, 0.5, 0.4])
            else
                out.push([-1.25, 2.5, 1, 0.5, 0.6], [-1.5, 4.5, 0.75, 0.5, 0.35])
            // A puff of dust where the back feet push off.
            if (s === 0)
                out.push([0.5, 6.5, 0.5, 0.5, 0.5])
        }

        // Closed eyes: fill the holes except a thin slit at the bottom.
        if (blinking)
            for (const x of [3 + e, 8 + e])
                out.push([x, 1, 1, 1.5, 1])
        return out
    }

    implicitWidth: 30
    implicitHeight: 16

    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: {
            clawd.blinking = true
            unblink.restart()
        }
    }
    Timer {
        id: unblink
        interval: 160
        onTriggered: clawd.blinking = false
    }
    Timer {
        interval: 110
        running: clawd.working
        repeat: true
        onTriggered: clawd.step = (clawd.step + 1) % 4
        onRunningChanged: if (!running) clawd.step = 0
    }

    Item {
        width: 15 * clawd.px
        height: 8 * clawd.px
        anchors.centerIn: parent

        Repeater {
            model: clawd.pixels
            delegate: Rectangle {
                required property var modelData
                x: (clawd.ox + modelData[0]) * clawd.px
                y: (clawd.oy + modelData[1]) * clawd.px
                width: modelData[2] * clawd.px
                height: modelData[3] * clawd.px
                color: clawd.color
                opacity: modelData[4]
                antialiasing: false
            }
        }
    }
}
