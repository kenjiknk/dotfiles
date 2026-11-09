//@ pragma UseQApplication
// Quickshell desktop shell for i3/X11: one bar per screen with popups, and the
// volume/brightness OSD. Started by i3 (~/.config/i3/config).
//
// IPC (`qs ipc show` lists it all):
//   qs ipc call bar toggle|open|close
//   qs ipc call osd flash <volume|mic|brightness|keyboard> <percent> <label>
//                                  (~/Scripts/osd; percent < 0 = label only)
//   qs ipc call notifs dnd|clear|lock|unlock                          (~/Scripts/lock)
//
// It is also the notification daemon (Notifs.qml): toasts below the bar and a
// history behind the bell.
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
        target: "notifs"

        function dnd(): void { Notifs.dnd = !Notifs.dnd; }
        function clear(): void { Notifs.clearAll(); }
        function lock(): void { Notifs.locked = true; }
        function unlock(): void { Notifs.locked = false; }
    }
}
