pragma Singleton
import QtQuick
import Quickshell

// Nerd Font (Material Design) glyphs used across the shell.
Singleton {
    readonly property string apps: "\u{F003B}"
    readonly property string cpu: "\u{F0EE0}"
    readonly property string memory: "\u{F035B}"
    readonly property string temp: "\u{F050F}"
    readonly property string ethernet: "\u{F0200}"
    readonly property string wifiOff: "\u{F092E}"
    readonly property string lock: "\u{F033E}"
    readonly property string unlock: "\u{F033F}"
    readonly property string bluetooth: "\u{F00AF}"
    readonly property string bluetoothOff: "\u{F00B2}"
    readonly property string bluetoothOn: "\u{F00B1}"
    readonly property string mic: "\u{F036C}"
    readonly property string micOff: "\u{F036D}"
    readonly property string play: "\u{F040A}"
    readonly property string pause: "\u{F03E4}"
    readonly property string next: "\u{F04AD}"
    readonly property string prev: "\u{F04AE}"
    readonly property string music: "\u{F075A}"
    readonly property string power: "\u{F0425}"
    readonly property string sleep: "\u{F0904}"
    readonly property string logout: "\u{F0343}"
    readonly property string reboot: "\u{F0709}"
    readonly property string bell: "\u{F009A}"
    readonly property string bellOff: "\u{F009B}"
    readonly property string close: "\u{F0156}"
    readonly property string check: "\u{F012C}"
    readonly property string chevronLeft: "\u{F0141}"
    readonly property string chevronRight: "\u{F0142}"
    readonly property string leaf: "\u{F032A}"
    readonly property string scale: "\u{F05D1}"
    readonly property string rocket: "\u{F0463}"
    readonly property string speaker: "\u{F04C3}"
    readonly property string keyboard: "\u{F030C}"
    readonly property string update: "\u{F06B0}"
    readonly property string disk: "\u{F02CA}"

    function volume(v, muted) {
        if (muted || v <= 0) return "\u{F075F}";
        if (v < 0.34) return "\u{F057F}";
        if (v < 0.67) return "\u{F0580}";
        return "\u{F057E}";
    }

    function brightness(v) {
        if (v < 0.34) return "\u{F00DE}";
        if (v < 0.67) return "\u{F00DF}";
        return "\u{F00E0}";
    }

    function wifi(strength) {
        if (strength < 0.25) return "\u{F091F}";
        if (strength < 0.5) return "\u{F0922}";
        if (strength < 0.75) return "\u{F0925}";
        return "\u{F0928}";
    }

    function battery(pct, charging) {
        if (charging) return "\u{F0084}";
        const levels = ["\u{F008E}", "\u{F007A}", "\u{F007B}", "\u{F007C}", "\u{F007D}",
                        "\u{F007E}", "\u{F007F}", "\u{F0080}", "\u{F0081}", "\u{F0082}", "\u{F0079}"];
        return levels[Math.max(0, Math.min(10, Math.round(pct * 10)))];
    }
}
