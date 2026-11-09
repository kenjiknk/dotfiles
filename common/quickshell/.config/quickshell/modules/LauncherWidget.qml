import QtQuick
import qs

BarModule {
    onClicked: ShellState.launcherOpen = !ShellState.launcherOpen

    BarText {
        text: Icons.apps
        color: Theme.accent
        font.pixelSize: 15
    }
}
