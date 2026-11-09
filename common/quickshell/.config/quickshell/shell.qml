//@ pragma UseQApplication
// Quickshell desktop shell for i3/X11: one bar per screen with popups, and the
// volume/brightness OSD. Started by i3 (~/.config/i3/config).
//
// IPC (`qs ipc show` lists it all):
//   qs ipc call bar toggle|open|close
//   qs ipc call osd flash <volume|mic|brightness> <percent> <label>   (~/Scripts/osd)
//   qs ipc call keyboard refresh                                       (~/Scripts/kbd-layout)
//
// Notifications stay with dunst. The Quickshell daemon is here but off: to try
// it, `pkill dunst; pkill -x qs; QS_NOTIFS=1 qs -d`.
import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
    Variants {
        model: Quickshell.screens

        Bar {}
    }

    IpcHandler {
        target: "bar"

        function toggle(): void { ShellState.barsVisible = !ShellState.barsVisible; }
        function open(): void { ShellState.barsVisible = true; }
        function close(): void { ShellState.barsVisible = false; }
    }

    IpcHandler {
        target: "osd"

        function flash(kind: string, percent: int, label: string): void { ShellState.flashOsd(kind, percent, label); }
    }

    IpcHandler {
        target: "keyboard"

        function refresh(): void { ShellState.refreshLayout(); }
    }

    IpcHandler {
        target: "notifs"

        function dnd(): void { Notifs.dnd = !Notifs.dnd; }
        function clear(): void { Notifs.clearAll(); }
    }
}
