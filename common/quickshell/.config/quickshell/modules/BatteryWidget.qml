import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import qs

// UPower battery: percentage and time left (time to full while charging), plus
// power-profiles-daemon (icon on the bar unless balanced, switcher in the popup).
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

    readonly property int batteryState: dev ? dev.state : UPowerDeviceState.Unknown
    readonly property string stateText: {
        switch (batteryState) {
        case UPowerDeviceState.Discharging: return "On battery";
        case UPowerDeviceState.Charging: return "Charging";
        case UPowerDeviceState.FullyCharged: return "Full, plugged in";
        case UPowerDeviceState.PendingCharge: return "Plugged in, not charging";
        case UPowerDeviceState.Empty: return "Empty";
        default: return "Unknown";
        }
    }

    // Charge thresholds (battery care), e.g. start below 85 %, stop at 90 %.
    property int chargeStart: -1
    property int chargeStop: -1

    Process {
        running: true
        command: ["sh", "-c", "for b in /sys/class/power_supply/BAT*; do cat $b/charge_control_start_threshold $b/charge_control_end_threshold 2>/dev/null && break; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const [start, stop] = text.trim().split("\n").map(Number);
                if (stop > 0 && stop < 100) {
                    root.chargeStart = start || 0;
                    root.chargeStop = stop;
                }
            }
        }
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
    // Time left on battery; while charging, time until full. UPower reports 0
    // while it is still estimating, and on AC with the charge threshold reached.
    BarText {
        readonly property real seconds: !root.dev ? 0
            : root.dev.state === UPowerDeviceState.Discharging ? root.dev.timeToEmpty
            : root.dev.state === UPowerDeviceState.Charging ? root.dev.timeToFull
            : 0
        visible: seconds > 0
        text: root.duration(seconds)
        color: root.dev && root.dev.state === UPowerDeviceState.Charging ? Theme.dim
             : !root.charging && root.pct < 0.15 ? Theme.red : Theme.fg
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

        // Label/value rows; rows without data are left out. While the charge
        // moves, UPower needs a few seconds after (un)plugging to estimate.
        Repeater {
            model: {
                const d = root.dev;
                if (!d) return [];
                const moving = root.batteryState === UPowerDeviceState.Discharging
                    || root.batteryState === UPowerDeviceState.Charging;
                const charging = root.batteryState === UPowerDeviceState.Charging;
                const left = charging ? d.timeToFull : d.timeToEmpty;
                return [
                    { label: "State", value: root.stateText, show: true },
                    { label: charging ? "Time to full" : "Time left",
                      value: left > 0 ? root.duration(left) : "estimating…", bold: left > 0, show: moving },
                    { label: "Rate", value: `${Math.abs(d.changeRate).toFixed(1)} W`, show: Math.abs(d.changeRate) > 0.05 },
                    { label: "Charge limit", value: `${root.chargeStart}–${root.chargeStop}%`, show: root.chargeStop > 0 },
                    { label: "Energy", value: `${d.energy.toFixed(1)} / ${d.energyCapacity.toFixed(1)} Wh`, show: true },
                    { label: "Health", value: `${Math.round(d.healthPercentage)}%`, show: d.healthSupported },
                ].filter(r => r.show);
            }

            RowLayout {
                required property var modelData
                spacing: 16

                BarText {
                    Layout.preferredWidth: 96
                    text: parent.modelData.label
                    color: Theme.dim
                }
                BarText {
                    text: parent.modelData.value
                    font.bold: parent.modelData.bold === true
                }
            }
        }

        BarText {
            Layout.preferredWidth: 260
            Layout.fillWidth: true
            visible: root.batteryState === UPowerDeviceState.PendingCharge && root.chargeStop > 0
            text: `Charging resumes below ${root.chargeStart}% and stops at ${root.chargeStop}%, to spare the battery. Unplug it to see the time left.`
            wrapMode: Text.Wrap
            color: Theme.muted
            font.pixelSize: 11
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
