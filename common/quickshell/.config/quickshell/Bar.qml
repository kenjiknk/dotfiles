import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.I3
import qs.modules

// One bar per screen, plus the OSD and notification toasts, which only show
// on the bar of the focused output.
PanelWindow {
    id: bar

    required property var modelData
    readonly property bool isFocused: !I3.focusedMonitor || I3.focusedMonitor.name === modelData.name
    // Room on each side of the centred clock. The window title (left) and the
    // track title (right) shrink to fit it instead of running into the clock.
    readonly property real sideRoom: (width - clock.implicitWidth) / 2 - 16

    function othersWidth(row, except) {
        let w = 0;
        for (const c of row.children)
            if (c !== except && c.visible) w += c.implicitWidth + row.spacing;
        return w;
    }

    screen: modelData
    visible: ShellState.barsVisible
    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: Theme.barHeight
    color: Theme.bg

    RowLayout {
        id: leftRow
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.leftMargin: 4
        spacing: 2

        LauncherWidget {}
        WorkspacesWidget { output: bar.modelData.name }
        TitleWidget {
            id: title
            output: bar.modelData.name
            maxTextWidth: Math.min(320, bar.sideRoom - bar.othersWidth(leftRow, title) - 24)
        }
        UpdatesWidget {}
    }

    ClockWidget {
        id: clock
        anchors.centerIn: parent
    }

    RowLayout {
        id: rightRow
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.rightMargin: 4
        spacing: 2

        MediaWidget {
            id: media
            maxTextWidth: Math.min(200, bar.sideRoom - bar.othersWidth(rightRow, media) - 40)
        }
        StatsWidget {}
        NetworkWidget {}
        BluetoothWidget {}
        KeyboardWidget {}
        VolumeWidget {}
        BrightnessWidget {}
        BatteryWidget {}
        NotifWidget {}
        TrayWidget {}
        PowerWidget {}
    }

    // ---- OSD: volume / brightness (from ~/Scripts/osd), centered below the bar ----
    PopupWindow {
        visible: ShellState.osdVisible && bar.isFocused && bar.visible
        anchor.window: bar
        anchor.rect.x: bar.width / 2
        anchor.rect.y: bar.height + 12
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom
        implicitWidth: 280
        implicitHeight: 48
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            radius: Theme.radius
            color: Theme.bg
            border.color: Theme.surface
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12

                BarText {
                    text: ShellState.osdIcon
                    color: Theme.yellow
                    font.pixelSize: 18
                }
                ThemedSlider {
                    value: ShellState.osdValue
                    interactive: false
                    fill: Theme.yellow
                }
                BarText {
                    text: ShellState.osdLabel
                    Layout.preferredWidth: 44
                    horizontalAlignment: Text.AlignRight
                }
            }
        }
    }

    // ---- Notification toasts, top-right below the bar ----
    PopupWindow {
        visible: Notifs.enabled && bar.isFocused && bar.visible && Notifs.toasts.length > 0
        anchor.window: bar
        anchor.rect.x: bar.width - 8
        anchor.rect.y: bar.height + 8
        anchor.edges: Edges.Bottom | Edges.Left
        anchor.gravity: Edges.Bottom | Edges.Left
        implicitWidth: 340
        implicitHeight: Math.max(1, toasts.implicitHeight)
        color: "transparent"

        ColumnLayout {
            id: toasts
            width: parent.width
            spacing: 6

            Repeater {
                model: Notifs.toasts.slice(-4)

                NotificationCard {
                    required property var modelData
                    notification: modelData
                    toast: true
                }
            }
        }
    }
}
