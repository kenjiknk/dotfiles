import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import qs

// UPower battery + power-profiles-daemon (icon on the bar unless balanced,
// switcher in the popup).
BarModule {
    id: root

    readonly property var dev: UPower.displayDevice
    readonly property real pct: dev ? (dev.percentage > 1 ? dev.percentage / 100 : dev.percentage) : 0
    readonly property bool charging: dev !== null && (dev.state === UPowerDeviceState.Charging
        || dev.state === UPowerDeviceState.FullyCharged || dev.state === UPowerDeviceState.PendingCharge)

    function duration(seconds) {
        if (!seconds || seconds <= 0) return "—";
        const total = Math.round(seconds / 60);
        const h = Math.floor(total / 60);
        const m = total % 60;
        return h > 0 ? `${h}h ${m}m` : `${m}m`;
    }

    visible: dev !== null && dev.isPresent
    onClicked: popup.toggle()

    BarText {
        text: Icons.battery(root.pct, root.charging)
        color: root.charging ? Theme.green : root.pct < 0.15 ? Theme.red : root.pct < 0.3 ? Theme.yellow : Theme.fg
        font.pixelSize: 14
    }
    BarText {
        text: `${Math.round(root.pct * 100)}%`
        color: !root.charging && root.pct < 0.15 ? Theme.red : Theme.fg
    }
    // Power profile, only when it is not the default one.
    BarText {
        visible: PowerProfiles.profile !== PowerProfile.Balanced
        text: PowerProfiles.profile === PowerProfile.PowerSaver ? Icons.leaf : Icons.rocket
        color: PowerProfiles.profile === PowerProfile.PowerSaver ? Theme.yellow : Theme.red
        font.pixelSize: 14
    }

    BarPopup {
        id: popup
        anchorItem: root

        SectionLabel {
            Layout.topMargin: 0
            text: "Battery"
        }

        GridLayout {
            Layout.preferredWidth: 260
            columns: 2
            columnSpacing: 16
            rowSpacing: 4

            BarText { text: "State"; color: Theme.dim }
            BarText { text: root.dev ? UPowerDeviceState.toString(root.dev.state) : "" }

            BarText { text: root.charging ? "Time to full" : "Time to empty"; color: Theme.dim }
            BarText { text: root.dev ? root.duration(root.charging ? root.dev.timeToFull : root.dev.timeToEmpty) : "" }

            BarText { text: "Rate"; color: Theme.dim }
            BarText { text: root.dev ? `${Math.abs(root.dev.changeRate).toFixed(1)} W` : "" }

            BarText { text: "Energy"; color: Theme.dim }
            BarText { text: root.dev ? `${root.dev.energy.toFixed(1)} / ${root.dev.energyCapacity.toFixed(1)} Wh` : "" }

            BarText {
                visible: root.dev && root.dev.healthSupported
                text: "Health"
                color: Theme.dim
            }
            BarText {
                visible: root.dev && root.dev.healthSupported
                text: root.dev ? `${Math.round(root.dev.healthPercentage)}%` : ""
            }
        }

        SectionLabel { text: "Power profile" }

        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            Repeater {
                model: [
                    { profile: PowerProfile.PowerSaver, icon: Icons.leaf, label: "Saver" },
                    { profile: PowerProfile.Balanced, icon: Icons.scale, label: "Balanced" },
                    { profile: PowerProfile.Performance, icon: Icons.rocket, label: "Perf" },
                ].filter(p => p.profile !== PowerProfile.Performance || PowerProfiles.hasPerformanceProfile)

                MenuRow {
                    required property var modelData
                    icon: modelData.icon
                    text: modelData.label
                    active: PowerProfiles.profile === modelData.profile
                    onClicked: PowerProfiles.profile = modelData.profile
                }
            }
        }
    }
}
