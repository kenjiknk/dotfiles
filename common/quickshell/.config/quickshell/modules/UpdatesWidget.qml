import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs

// Days since the last full upgrade, from pacman.log. Shows only once it is a
// week old (yellow), red after two. Hidden on machines without pacman.log.
// Click: the exact date.
BarModule {
    id: root

    property var last: null
    readonly property int days: last ? Math.max(0, Math.floor((clock.date - last) / 86400000)) : 0

    visible: last !== null && days >= 7
    onClicked: popup.toggle()

    SystemClock {
        id: clock
        precision: SystemClock.Hours
    }

    // e.g. [2026-08-30T15:59:55-0300] [PACMAN] starting full system upgrade
    Process {
        id: query
        command: ["sh", "-c", "grep -F 'starting full system upgrade' /var/log/pacman.log | tail -n 1 | sed -n 's/^\\[\\([^]]*\\)\\].*/\\1/p'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const m = text.trim().match(/^(\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d)([+-]\d\d)(\d\d)$/);
                root.last = m ? new Date(`${m[1]}${m[2]}:${m[3]}`) : null;
            }
        }
    }

    // pacman.log only grows; re-read it hourly.
    Timer {
        interval: 3600 * 1000
        running: true
        repeat: true
        onTriggered: query.running = true
    }

    BarText {
        text: Icons.update
        color: root.days >= 14 ? Theme.red : Theme.yellow
        font.pixelSize: 14
    }
    BarText {
        text: `${root.days}d`
        color: root.days >= 14 ? Theme.red : Theme.yellow
    }

    BarPopup {
        id: popup
        anchorItem: root

        SectionLabel {
            Layout.topMargin: 0
            text: "Last full upgrade"
        }
        BarText { text: root.last ? Qt.formatDateTime(root.last, "yyyy-MM-dd HH:mm") : "" }
    }
}
