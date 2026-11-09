import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs

// Laptop backlight: reads sysfs with FileView, writes via brightnessctl.
// Scroll = ±5%, click = popup slider.
BarModule {
    id: root

    property string device: ""
    property real max: 1
    property real value: 0

    function set(v) {
        v = Math.max(0.01, Math.min(1, v));
        value = v;
        Quickshell.execDetached(["brightnessctl", "-q", "set", `${Math.round(v * 100)}%`]);
    }

    visible: device !== ""
    onScrolled: step => set(value + step * 0.05)
    onClicked: popup.toggle()

    Process {
        running: true
        command: ["sh", "-c", "d=$(ls /sys/class/backlight | head -n1); [ -n \"$d\" ] && echo \"$d $(cat /sys/class/backlight/$d/max_brightness)\""]
        stdout: StdioCollector {
            onStreamFinished: {
                const [dev, max] = text.trim().split(" ");
                if (dev) {
                    root.max = Number(max) || 1;
                    root.device = dev;
                }
            }
        }
    }

    // sysfs does not emit inotify events for backlight changes, so poll.
    FileView {
        id: current
        path: root.device ? `/sys/class/backlight/${root.device}/brightness` : ""
        onLoaded: root.value = Number(text()) / root.max
    }
    Timer {
        interval: 3000
        running: root.device !== ""
        repeat: true
        triggeredOnStart: true
        onTriggered: current.reload()
    }

    BarText {
        text: Icons.brightness(root.value)
        color: Theme.yellow
        font.pixelSize: 14
    }
    BarText { text: `${Math.round(root.value * 100)}%` }

    BarPopup {
        id: popup
        anchorItem: root

        SectionLabel {
            Layout.topMargin: 0
            text: "Brightness — " + root.device
        }
        RowLayout {
            Layout.preferredWidth: 260

            BarText {
                text: Icons.brightness(root.value)
                color: Theme.yellow
                font.pixelSize: 14
            }
            ThemedSlider {
                value: root.value
                fill: Theme.yellow
                onMoved: v => root.set(v)
            }
            BarText {
                text: `${Math.round(root.value * 100)}%`
                Layout.preferredWidth: 36
                horizontalAlignment: Text.AlignRight
            }
        }
    }
}
