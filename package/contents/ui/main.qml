import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as Plasma5Support

PlasmoidItem {
    id: root

    readonly property string bin: Qt.resolvedUrl("../bin/").toString().replace("file://", "")
    readonly property string statusCommand: "'" + bin + "clawd-status'"
    property bool working: false

    preferredRepresentation: fullRepresentation
    toolTipMainText: "Claude"
    toolTipSubText: working ? "Working…" : "Click to open"

    Plasma5Support.DataSource {
        id: exec
        engine: "executable"
        onNewData: (source, data) => {
            if (source === root.statusCommand) {
                root.working = data.stdout.trim() === "working"
            }
            disconnectSource(source)
        }
    }

    // The widget's global shortcut (Configure Clawd > Keyboard Shortcuts).
    Connections {
        target: Plasmoid
        function onActivated() {
            exec.connectSource("'" + root.bin + "clawd-toggle'")
        }
    }

    Timer {
        interval: 1500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: exec.connectSource(root.statusCommand)
    }

    fullRepresentation: MouseArea {
        Layout.minimumWidth: height * 1.8
        Layout.preferredWidth: height * 1.8
        hoverEnabled: true
        onClicked: exec.connectSource("'" + root.bin + "clawd-toggle'")

        Clawd {
            anchors.fill: parent
            anchors.margins: parent.height * 0.06
            working: root.working
            color: Kirigami.Theme.textColor
        }
    }
}
