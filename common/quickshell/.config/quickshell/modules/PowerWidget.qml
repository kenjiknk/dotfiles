import QtQuick
import QtQuick.Layouts
import Quickshell
import qs

// Session menu. Logout, reboot and power off need a second click.
BarModule {
    id: root

    onClicked: popup.toggle()

    BarText {
        text: Icons.power
        color: Theme.red
        font.pixelSize: 14
    }

    BarPopup {
        id: popup

        property string armed: ""

        anchorItem: root
        onVisibleChanged: armed = ""

        Repeater {
            model: [
                { id: "lock", icon: Icons.lock, label: "Lock", cmd: ["loginctl", "lock-session"], confirm: false },
                { id: "suspend", icon: Icons.sleep, label: "Suspend", cmd: ["systemctl", "suspend"], confirm: false },
                { id: "logout", icon: Icons.logout, label: "Log out", cmd: ["i3-msg", "exit"], confirm: true },
                { id: "reboot", icon: Icons.reboot, label: "Reboot", cmd: ["systemctl", "reboot"], confirm: true },
                { id: "poweroff", icon: Icons.power, label: "Power off", cmd: ["systemctl", "poweroff"], confirm: true },
            ]

            MenuRow {
                required property var modelData
                readonly property bool isArmed: popup.armed === modelData.id

                Layout.preferredWidth: 200
                icon: modelData.icon
                iconColor: isArmed ? Theme.red : Theme.fg
                text: isArmed ? "Click again" : modelData.label
                textColor: isArmed ? Theme.red : Theme.fg
                onClicked: {
                    if (modelData.confirm && !isArmed) {
                        popup.armed = modelData.id;
                        return;
                    }
                    popup.visible = false;
                    Quickshell.execDetached(modelData.cmd);
                }
            }
        }
    }
}
