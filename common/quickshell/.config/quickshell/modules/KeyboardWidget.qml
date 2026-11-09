import QtQuick
import Quickshell
import qs

// Active keyboard layout from ~/Scripts/kbd-layout. Click: next layout.
BarModule {
    visible: ShellState.kbdLayout !== ""
    onClicked: Quickshell.execDetached([Quickshell.env("HOME") + "/Scripts/kbd-layout", "next"])

    BarText {
        text: Icons.keyboard
        color: Theme.dim
        font.pixelSize: 14
    }
    BarText { text: ShellState.kbdLayout }
}
