import QtQuick
import QtQuick.Layouts
import Quickshell.I3
import qs

// Workspaces of this bar's output. Click to switch, scroll to cycle.
BarModule {
    id: root

    property string output

    hoverable: false
    padding: 2
    spacing: 3
    onScrolled: step => I3.dispatch(step > 0 ? "workspace prev_on_output" : "workspace next_on_output")

    Repeater {
        model: I3.workspaces.values
            .filter(ws => ws.monitor && ws.monitor.name === root.output)
            .sort((a, b) => a.number - b.number)

        Rectangle {
            id: ws

            required property var modelData
            readonly property bool hot: modelData.focused || modelData.urgent

            Layout.preferredWidth: Math.max(22, label.implicitWidth + 12)
            Layout.preferredHeight: Theme.barHeight - 8
            radius: 4
            color: modelData.urgent ? Theme.red
                 : modelData.focused ? Theme.accent
                 : modelData.active ? Theme.surface
                 : hover.containsMouse ? Theme.bg2 : "transparent"
            Behavior on color { ColorAnimation { duration: 120 } }

            BarText {
                id: label
                anchors.centerIn: parent
                text: ws.modelData.name
                font.bold: ws.modelData.focused
                color: ws.hot ? Theme.bg : ws.modelData.active ? Theme.fg : Theme.dim
            }

            MouseArea {
                id: hover
                anchors.fill: parent
                hoverEnabled: true
                onClicked: ws.modelData.activate()
            }
        }
    }

    // i3 binding mode (e.g. "resize"), from the IPC "mode" event.
    Rectangle {
        visible: ShellState.i3Mode !== "default"
        Layout.preferredWidth: modeLabel.implicitWidth + 12
        Layout.preferredHeight: Theme.barHeight - 8
        radius: 4
        color: Theme.orange

        BarText {
            id: modeLabel
            anchors.centerIn: parent
            text: ShellState.i3Mode
            color: Theme.bg
            font.bold: true
        }
    }
}
