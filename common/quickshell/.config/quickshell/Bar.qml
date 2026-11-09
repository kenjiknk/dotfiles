import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.I3
import qs.modules

// One bar per screen, with its popup layer, plus the OSD and notification
// toasts, which only show on the bar of the focused output.
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

    // On exit, hide the windows anchored to the bar before Quickshell starts
    // tearing down. Left visible, they hide themselves once the X screen is
    // gone and Quickshell segfaults in QXcbWindow::hide; its crash handler then
    // starts a second instance next to the new one. Component.onDestruction is
    // already too late for this.
    Connections {
        target: Qt.application
        function onAboutToQuit() {
            popupHost.visible = false;
            osdWindow.visible = false;
            toastWindow.visible = false;
        }
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

    // Root of the bar's items. BarPopup finds the popup layer through it.
    Item {
        id: barRoot

        readonly property Item popupLayer: layer

        anchors.fill: parent

        // A click on the empty part of the bar closes the open popup.
        MouseArea {
            anchors.fill: parent
            enabled: ShellState.activePopup !== null
            onClicked: ShellState.activePopup.close()
        }

        RowLayout {
            id: leftRow
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.leftMargin: 4
            spacing: 2

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

            // Groups, with a wider gap between them than inside them: media |
            // system | connections | audio | power and notifications | tray. A gap shows
            // only when the group before it does.
            MediaWidget {
                id: media
                maxTextWidth: Math.min(200, bar.sideRoom - bar.othersWidth(rightRow, media) - 40)
            }
            GroupGap { visible: media.visible }
            StatsWidget {}
            GroupGap {}
            NetworkWidget { id: net }
            BluetoothWidget { id: bt }
            GroupGap { visible: net.visible || bt.visible }
            VolumeWidget {}
            GroupGap {}
            BatteryWidget { id: battery }
            NotifWidget { id: notifs }
            GroupGap { visible: (battery.visible || notifs.visible) && tray.visible }
            TrayWidget { id: tray }
        }
    }

    // ---- Popup layer: one transparent window under the bar for every popup ----
    // It stays mapped, so picom never animates it and it never resizes. While no
    // popup shows, its mask is empty and clicks go through to the windows below;
    // while one does, it takes the clicks, and one outside the panel closes it.
    PopupWindow {
        id: popupHost
        anchor.window: bar
        anchor.rect.x: 0
        anchor.rect.y: bar.height
        anchor.edges: Edges.Top | Edges.Left
        anchor.gravity: Edges.Bottom | Edges.Right
        anchor.adjustment: PopupAdjustment.None
        implicitWidth: bar.width
        implicitHeight: Math.max(1, bar.screen.height - bar.height)
        visible: bar.visible
        color: "transparent"
        mask: Region { item: layer.busy ? layer : null }

        Item {
            id: layer

            // any panel still on screen, fading out included
            readonly property bool busy: {
                for (let i = 0; i < children.length; i++)
                    if (children[i] !== catcher && children[i].opacity > 0) return true;
                return false;
            }

            anchors.fill: parent

            MouseArea {
                id: catcher
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
                onClicked: if (ShellState.activePopup) ShellState.activePopup.close()
            }
        }
    }

    // ---- OSD (from ~/Scripts/osd), centered below the bar ----
    // Volume/brightness: icon, level bar and value. Keyboard layout (no level):
    // a small pill, e.g. "󰌌 US intl", with the variant dimmed.
    PopupWindow {
        id: osdWindow

        readonly property bool labelOnly: ShellState.osdValue < 0
        readonly property var labelParts: ShellState.osdLabel.split(" · ")

        visible: ShellState.osdVisible && bar.isFocused && bar.visible
        anchor.window: bar
        anchor.rect.x: bar.width / 2
        anchor.rect.y: bar.height + (labelOnly ? 8 : 12)
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom
        implicitWidth: labelOnly ? pill.implicitWidth : 280
        implicitHeight: labelOnly ? pill.implicitHeight : 48
        color: "transparent"

        Rectangle {
            visible: !osdWindow.labelOnly
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

        Rectangle {
            id: pill

            visible: osdWindow.labelOnly
            implicitWidth: pillRow.implicitWidth + 24
            implicitHeight: 28
            radius: height / 2
            color: Theme.bg
            border.color: Theme.surface
            border.width: 1

            RowLayout {
                id: pillRow
                anchors.centerIn: parent
                spacing: 6

                BarText {
                    text: ShellState.osdIcon
                    color: Theme.accent
                    font.pixelSize: 14
                }
                BarText {
                    text: osdWindow.labelParts[0]
                    font.weight: Font.DemiBold
                }
                BarText {
                    visible: osdWindow.labelParts.length > 1
                    text: osdWindow.labelParts.slice(1).join(" ")
                    color: Theme.dim
                }
            }
        }
    }

    // ---- Notification toasts, top-right below the bar ----
    PopupWindow {
        id: toastWindow
        visible: bar.isFocused && bar.visible && Notifs.toasts.length > 0
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
