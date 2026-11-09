import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import qs

// BlueZ over D-Bus. Click = popup, middle = bluetui, right = power toggle.
BarModule {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var devices: adapter ? adapter.devices.values : []
    readonly property var connected: devices.filter(d => d.connected)

    function batteryText(d) {
        if (!d.batteryAvailable) return "";
        const b = d.battery > 1 ? d.battery : d.battery * 100;
        return ` ${Math.round(b)}%`;
    }

    visible: adapter !== null
    onClicked: m => {
        if (m.button === Qt.RightButton) adapter.enabled = !adapter.enabled;
        else if (m.button === Qt.MiddleButton) Quickshell.execDetached(["kitty", "-e", "bluetui"]);
        else popup.toggle();
    }

    BarText {
        text: !root.adapter || !root.adapter.enabled ? Icons.bluetoothOff
            : root.connected.length > 0 ? Icons.bluetoothOn : Icons.bluetooth
        color: root.adapter && root.adapter.enabled ? Theme.blue : Theme.muted
        font.pixelSize: 14
    }
    BarText {
        visible: root.connected.length > 0
        text: root.connected.length > 0 ? root.connected[0].name + root.batteryText(root.connected[0]) : ""
        elide: Text.ElideRight
        Layout.maximumWidth: 120
    }

    BarPopup {
        id: popup
        anchorItem: root
        onVisibleChanged: if (!visible && root.adapter && root.adapter.discovering) root.adapter.discovering = false

        RowLayout {
            Layout.preferredWidth: 300

            SectionLabel {
                Layout.fillWidth: true
                Layout.topMargin: 0
                text: root.adapter ? root.adapter.name : "Bluetooth"
            }
            MenuRow {
                Layout.fillWidth: false
                visible: root.adapter && root.adapter.enabled
                text: root.adapter && root.adapter.discovering ? "scanning…" : "scan"
                textColor: Theme.blue
                onClicked: root.adapter.discovering = !root.adapter.discovering
            }
            MenuRow {
                Layout.fillWidth: false
                text: root.adapter && root.adapter.enabled ? "on" : "off"
                textColor: root.adapter && root.adapter.enabled ? Theme.green : Theme.red
                onClicked: root.adapter.enabled = !root.adapter.enabled
            }
        }

        Repeater {
            model: root.devices
                .filter(d => d.paired || d.name !== d.address)
                .sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired) || a.name.localeCompare(b.name))
                .slice(0, 12)

            MenuRow {
                required property var modelData

                icon: Icons.bluetooth
                iconColor: modelData.connected ? Theme.blue : Theme.fg
                text: modelData.name
                active: modelData.connected
                detail: modelData.pairing ? "pairing…"
                    : modelData.state === BluetoothDeviceState.Connecting ? "connecting…"
                    : modelData.connected ? "connected" + root.batteryText(modelData)
                    : modelData.paired ? "paired" : "new"
                onClicked: {
                    if (modelData.connected) modelData.disconnect();
                    else if (modelData.paired) modelData.connect();
                    else modelData.pair();
                }
            }
        }

        BarText {
            visible: root.devices.length === 0
            text: "No devices"
            color: Theme.muted
        }
    }
}
