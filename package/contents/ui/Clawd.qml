import QtQuick

// Pixel-art Clawd drawn on a 12x7 grid. Blinks every 10 s; runs while `working`.
Item {
    id: clawd

    property bool working: false
    property color color: "#D97757"

    property bool blinking: false
    property int step: 0

    readonly property real px: Math.max(1, Math.floor(Math.min(width / 12, height / 7)))
    readonly property bool lift: working && step === 1

    // [x, y, w, h] in grid units. Eyes are holes in the body so the panel
    // shows through, which keeps the sprite monochrome like other panel icons.
    readonly property var pixels: {
        const eyes = [3, 8]
        const out = [
            [2, 0, 8, 1],                               // body above eyes
            [2, 3, 8, 2],                               // body below eyes
            [0, 2, 2, 2], [10, 2, 2, 2],                // arms
            [2, 1, 1, 2], [4, 1, 4, 2], [9, 1, 1, 2],   // body between eyes
            [2, 5, 1, working && step === 1 ? 1 : 2],   // legs alternate
            [4, 5, 1, working && step === 0 ? 1 : 2],   // in pairs while
            [7, 5, 1, working && step === 1 ? 1 : 2],   // running
            [9, 5, 1, working && step === 0 ? 1 : 2],
        ]
        // Closed eyes: fill the hole except a thin slit at the bottom.
        if (blinking)
            for (const x of eyes)
                out.push([x, 1, 1, 1.5])
        return out
    }

    implicitWidth: 24
    implicitHeight: 14

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
        interval: 140
        running: clawd.working
        repeat: true
        onTriggered: clawd.step = (clawd.step + 1) % 2
        onRunningChanged: if (!running) clawd.step = 0
    }

    Item {
        width: 12 * clawd.px
        height: 7 * clawd.px
        anchors.centerIn: parent
        // Bob up a pixel on alternate run frames.
        anchors.verticalCenterOffset: clawd.lift ? -clawd.px : 0

        Repeater {
            model: clawd.pixels
            delegate: Rectangle {
                required property var modelData
                x: modelData[0] * clawd.px
                y: modelData[1] * clawd.px
                width: modelData[2] * clawd.px
                height: modelData[3] * clawd.px
                color: clawd.color
                antialiasing: false
            }
        }
    }
}
