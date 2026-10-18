import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.plasma.plasma5support as Plasma5Support

// Pin, position and size of the Clawd window. clawd-window owns this state
// (the window buttons and shortcuts change it too), so the page reads it from
// there and writes it back on Apply instead of using cfg_ properties.
KCM.SimpleKCM {
    id: page

    readonly property string window: "'" + Qt.resolvedUrl("../bin/clawd-window").toString().replace("file://", "") + "'"
    // State as last read or applied: [pinned, position, size].
    property var saved: [0, 0, 0]
    readonly property var current: [pin.checked ? 1 : 0, positionBox.currentIndex, sizeBox.currentIndex]
    readonly property bool unsavedChanges: current.some((value, i) => value !== saved[i])

    function run(args) {
        exec.connectSource(window + " " + args)
    }

    // Called by the config dialog on Apply and OK.
    function saveConfig() {
        ["pin", "position", "size"].forEach((action, i) => {
            if (current[i] !== saved[i])
                run(action + " " + current[i])
        })
        saved = current
    }

    Plasma5Support.DataSource {
        id: exec
        engine: "executable"
        onNewData: (source, data) => {
            if (source === page.window + " state") {
                const [pinned, position, size] = data.stdout.trim().split(" ").map(Number)
                page.saved = [pinned ? 1 : 0, position % 3, size % 3]
                pin.checked = page.saved[0] === 1
                positionBox.currentIndex = page.saved[1]
                sizeBox.currentIndex = page.saved[2]
            }
            disconnectSource(source)
        }
    }

    Component.onCompleted: run("state")

    Kirigami.FormLayout {
        QQC2.CheckBox {
            id: pin
            Kirigami.FormData.label: i18n("Pin:")
            text: i18n("Keep open when it loses focus")
        }
        QQC2.ComboBox {
            id: positionBox
            Kirigami.FormData.label: i18n("Position:")
            model: [i18n("Center"), i18n("Left"), i18n("Right")]
        }
        QQC2.ComboBox {
            id: sizeBox
            Kirigami.FormData.label: i18n("Size:")
            model: [i18n("Small"), i18n("Medium"), i18n("Large")]
        }
    }
}
