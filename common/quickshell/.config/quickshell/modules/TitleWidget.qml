import QtQuick
import QtQuick.Layouts
import Quickshell.I3
import qs

// Focused window title; only on the bar of the focused output.
BarModule {
    id: root

    property string output
    property real maxTextWidth: 320

    hoverable: false
    visible: ShellState.focusedTitle !== "" && maxTextWidth >= 40
        && (!I3.focusedMonitor || I3.focusedMonitor.name === output)

    BarText {
        text: ShellState.focusedTitle
        color: Theme.dim
        elide: Text.ElideRight
        Layout.maximumWidth: root.maxTextWidth
    }
}
