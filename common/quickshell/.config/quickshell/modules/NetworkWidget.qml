import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking
import qs

// NetworkManager through Quickshell.Networking. Popup lists Wi-Fi networks
// (scanning only while open); saved ones connect directly, new ones open nmtui.
// Middle-click: nmtui.
BarModule {
    id: root

    readonly property var devices: Networking.devices.values
    readonly property var wifi: devices.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wired: devices.find(d => d.type === DeviceType.Wired && d.connected) ?? null
    readonly property var networks: wifi ? wifi.networks.values : []
    readonly property var activeWifi: networks.find(n => n.connected) ?? null

    function strength(n) {
        const s = n.signalStrength;
        return s > 1 ? s / 100 : s;
    }

    onClicked: m => {
        if (m.button === Qt.MiddleButton) Quickshell.execDetached(["kitty", "-e", "nmtui"]);
        else popup.toggle();
    }

    BarText {
        text: root.wired ? Icons.ethernet
            : root.activeWifi ? Icons.wifi(root.strength(root.activeWifi))
            : Icons.wifiOff
        color: root.wired || root.activeWifi ? Theme.aqua : Theme.red
        font.pixelSize: 14
    }
    BarText {
        text: root.wired ? root.wired.name : root.activeWifi ? root.activeWifi.name : "offline"
        elide: Text.ElideRight
        Layout.maximumWidth: 110
    }

    // Keep the Wi-Fi scanner on only while the popup is open.
    Binding {
        when: root.wifi !== null
        target: root.wifi
        property: "scannerEnabled"
        value: popup.visible
    }

    BarPopup {
        id: popup
        anchorItem: root

        RowLayout {
            Layout.preferredWidth: 300

            SectionLabel {
                Layout.fillWidth: true
                Layout.topMargin: 0
                text: "Wi-Fi"
            }
            MenuRow {
                Layout.fillWidth: false
                text: Networking.wifiEnabled ? "on" : "off"
                textColor: Networking.wifiEnabled ? Theme.green : Theme.red
                onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
            }
        }

        BarText {
            visible: Networking.connectivity !== NetworkConnectivity.Full
                && Networking.connectivity !== NetworkConnectivity.Unknown
            text: "Connectivity: " + NetworkConnectivity.toString(Networking.connectivity)
            color: Theme.yellow
        }

        Repeater {
            model: root.networks
                .filter(n => n.name !== "")
                .sort((a, b) => (b.connected - a.connected) || (b.known - a.known) || (root.strength(b) - root.strength(a)))
                .slice(0, 12)

            MenuRow {
                required property var modelData

                icon: Icons.wifi(root.strength(modelData))
                iconColor: modelData.connected ? Theme.aqua : Theme.fg
                text: modelData.name
                active: modelData.connected
                detail: modelData.stateChanging ? "…"
                    : modelData.connected ? "connected"
                    : modelData.known ? "saved"
                    : modelData.security === WifiSecurityType.Open ? "open" : Icons.lock
                onClicked: {
                    if (modelData.connected) modelData.disconnect();
                    else if (modelData.known || modelData.security === WifiSecurityType.Open) modelData.connect();
                    else {
                        popup.close();
                        Quickshell.execDetached(["kitty", "-e", "nmtui", "connect", modelData.name]);
                    }
                }
            }
        }

        SectionLabel {
            visible: root.wired !== null
            text: "Wired"
        }
        MenuRow {
            visible: root.wired !== null
            icon: Icons.ethernet
            iconColor: Theme.aqua
            text: root.wired ? root.wired.name : ""
            detail: root.wired && root.wired.linkSpeed ? `${root.wired.linkSpeed} Mb/s` : ""
        }
    }
}
