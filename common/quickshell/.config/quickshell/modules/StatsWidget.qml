import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs

// CPU / memory / temperature read straight from /proc and /sys with FileView,
// root filesystem usage from df. On the bar: one dim icon, or the readings that
// are out of range. Click = popup with every reading, history, top processes
// and disks; middle = btop.
BarModule {
    id: root

    property real cpu: 0
    property real mem: 0
    property real temp: 0
    property var history: []
    property var lastCpu: null
    property string tempPath: ""
    property var disks: []
    readonly property real rootUse: (disks.find(d => d.mount === "/") || { use: 0 }).use

    onClicked: m => {
        if (m.button === Qt.MiddleButton) Quickshell.execDetached(["kitty", "-e", "btop"]);
        else popup.toggle();
    }

    FileView {
        id: stat
        path: "/proc/stat"
        onLoaded: {
            const f = text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
            const idle = f[3] + f[4];
            const total = f.reduce((a, b) => a + b, 0);
            if (root.lastCpu) {
                const dt = total - root.lastCpu.total;
                if (dt > 0) root.cpu = 1 - (idle - root.lastCpu.idle) / dt;
                root.history = [...root.history, root.cpu].slice(-40);
            }
            root.lastCpu = { idle, total };
        }
    }

    FileView {
        id: meminfo
        path: "/proc/meminfo"
        onLoaded: {
            const get = key => Number((text().match(new RegExp(key + ":\\s+(\\d+)")) || [0, 0])[1]);
            const total = get("MemTotal");
            if (total > 0) root.mem = 1 - get("MemAvailable") / total;
        }
    }

    FileView {
        id: tempFile
        path: root.tempPath
        onLoaded: root.temp = Number(text()) / 1000
    }

    // Find the k10temp hwmon once; hwmonN numbering is not stable across boots.
    Process {
        running: true
        command: ["sh", "-c", "for h in /sys/class/hwmon/hwmon*; do [ \"$(cat $h/name)\" = k10temp ] && echo $h/temp1_input && break; done"]
        stdout: StdioCollector { onStreamFinished: root.tempPath = text.trim() }
    }

    property int diskTick: 0

    // Real filesystems only; one line per mount: "size used use% mount".
    Process {
        id: df
        command: ["df", "-P", "-k", "-x", "tmpfs", "-x", "devtmpfs", "-x", "efivarfs", "-x", "overlay"]
        stdout: StdioCollector {
            onStreamFinished: root.disks = text.trim().split("\n").slice(1)
                .map(l => l.trim().split(/\s+/))
                .filter(f => f.length >= 6 && f[0].startsWith("/dev/"))
                .map(f => ({ mount: f.slice(5).join(" "), size: Number(f[1]), used: Number(f[2]), use: Number(f[1]) > 0 ? Number(f[2]) / Number(f[1]) : 0 }))
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            stat.reload();
            meminfo.reload();
            if (root.tempPath) tempFile.reload();
            if (popup.visible) top.running = true;
            if (++diskTick % 15 === 1) df.running = true; // every 30 s
        }
    }

    // All four readings, each with its warning and critical level.
    readonly property var readings: [
        { icon: Icons.cpu, label: "CPU", value: cpu, warn: 0.8, crit: 0.95, text: `${Math.round(cpu * 100)}%` },
        { icon: Icons.memory, label: "Memory", value: mem, warn: 0.85, crit: 0.95, text: `${Math.round(mem * 100)}%` },
        { icon: Icons.temp, label: "Temp", value: temp, warn: 85, crit: 95, text: `${Math.round(temp)}°`, show: tempPath !== "" },
        { icon: Icons.disk, label: "Disk /", value: rootUse, warn: 0.9, crit: 0.97, text: `${Math.round(rootUse * 100)}%` },
    ].filter(r => r.show !== false)
    // On the bar only what is out of range shows, in yellow or red; when all
    // is well the widget is a single dim icon.
    readonly property var alerts: readings.filter(r => r.value >= r.warn)

    function levelColor(r, normal) {
        return r.value >= r.crit ? Theme.red : r.value >= r.warn ? Theme.yellow : normal;
    }

    BarText {
        visible: root.alerts.length === 0
        text: Icons.cpu
        color: Theme.dim
        // This glyph is drawn small within its box; 18 px matches the other icons.
        font.pixelSize: 18
    }
    Repeater {
        model: root.alerts

        RowLayout {
            required property var modelData
            spacing: 4

            BarText {
                text: parent.modelData.icon
                color: root.levelColor(parent.modelData, Theme.fg)
                font.pixelSize: 16
            }
            BarText {
                text: parent.modelData.text
                color: root.levelColor(parent.modelData, Theme.fg)
            }
        }
    }

    BarPopup {
        id: popup
        anchorItem: root
        onVisibleChanged: if (visible) top.running = true

        // Every reading, normal or not.
        RowLayout {
            Layout.preferredWidth: 320
            spacing: 0

            Repeater {
                model: root.readings

                ColumnLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 0

                    BarText {
                        Layout.alignment: Qt.AlignHCenter
                        text: `${parent.modelData.icon} ${parent.modelData.text}`
                        color: root.levelColor(parent.modelData, Theme.fg)
                        font.bold: true
                    }
                    BarText {
                        Layout.alignment: Qt.AlignHCenter
                        text: parent.modelData.label
                        color: Theme.muted
                        font.pixelSize: 10
                    }
                }
            }
        }

        SectionLabel { text: "CPU history" }

        // Sparkline built from plain Rectangles.
        Rectangle {
            Layout.preferredWidth: 320
            Layout.preferredHeight: 60
            color: Theme.bg1
            radius: 4

            Row {
                anchors.fill: parent
                anchors.margins: 4
                spacing: 2
                layoutDirection: Qt.RightToLeft

                Repeater {
                    model: root.history.slice().reverse()

                    Rectangle {
                        required property real modelData
                        anchors.bottom: parent.bottom
                        width: (320 - 8) / 40 - 2
                        height: Math.max(1, modelData * 52)
                        radius: 1
                        color: modelData > 0.8 ? Theme.red : modelData > 0.5 ? Theme.yellow : Theme.blue
                    }
                }
            }
        }

        SectionLabel { text: "Top processes" }

        Process {
            id: top
            command: ["ps", "-eo", "comm,%cpu,%mem", "--sort=-%cpu", "--no-headers"]
            stdout: StdioCollector {
                onStreamFinished: procs.model = text.trim().split("\n").slice(0, 8)
                    .map(l => l.trim().split(/\s+/))
            }
        }

        Repeater {
            id: procs

            RowLayout {
                required property var modelData
                Layout.fillWidth: true

                BarText {
                    Layout.fillWidth: true
                    text: parent.modelData.slice(0, -2).join(" ")
                    elide: Text.ElideRight
                }
                BarText {
                    Layout.preferredWidth: 60
                    horizontalAlignment: Text.AlignRight
                    text: parent.modelData[parent.modelData.length - 2] + "%"
                    color: Theme.blue
                }
                BarText {
                    Layout.preferredWidth: 60
                    horizontalAlignment: Text.AlignRight
                    text: parent.modelData[parent.modelData.length - 1] + "%"
                    color: Theme.purple
                }
            }
        }

        SectionLabel { text: "Disks" }

        Repeater {
            model: root.disks

            ColumnLayout {
                required property var modelData
                Layout.fillWidth: true
                spacing: 2

                RowLayout {
                    BarText {
                        Layout.fillWidth: true
                        text: parent.parent.modelData.mount
                    }
                    BarText {
                        text: `${(parent.parent.modelData.used / 1048576).toFixed(0)} / ${(parent.parent.modelData.size / 1048576).toFixed(0)} GiB`
                        color: Theme.dim
                        font.pixelSize: 11
                    }
                }
                ThemedSlider {
                    value: parent.modelData.use
                    interactive: false
                    fill: parent.modelData.use > 0.9 ? Theme.red : Theme.aqua
                }
            }
        }

        BarText {
            text: "middle-click the bar widget to open btop"
            color: Theme.muted
            font.pixelSize: 10
        }
    }
}
