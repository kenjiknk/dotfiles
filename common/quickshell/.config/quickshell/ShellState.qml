pragma Singleton
import QtQuick
import Quickshell
import Quickshell.I3
import Quickshell.Io

// Global state shared by every bar: IPC-controlled toggles, the focused
// window title (i3 IPC events) and the on-screen display.
Singleton {
    id: root

    property bool barsVisible: true
    // the BarPopup that is open, if any (opening another closes it)
    property var activePopup: null

    // ---- i3: focused window title and binding mode ----
    property string focusedTitle: ""
    property string i3Mode: "default"

    I3IpcListener {
        subscriptions: ["window", "workspace", "mode"]
        onIpcEvent: event => {
            let data;
            try { data = JSON.parse(event.data); } catch (e) { return; }
            const type = String(event.type).toLowerCase();
            if (type.includes("mode")) {
                root.i3Mode = data.change;
            } else if (type.includes("window") && data.container) {
                if ((data.change === "focus" || data.change === "title") && data.container.focused)
                    root.focusedTitle = data.container.name || "";
                // A background window retitling itself (a browser tab, `watch`)
                // cannot change the focused title; only structural changes can.
                else if (data.change !== "title" && data.change !== "urgent" && data.change !== "mark")
                    titleQuery.running = true;
            } else if (type.includes("workspace")) {
                titleQuery.running = true;
            }
        }
    }

    // Asks i3 for the whole tree and finds the focused window; used at start
    // and whenever focus may have moved to an empty workspace.
    Process {
        id: titleQuery
        command: ["i3-msg", "-t", "get_tree"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const find = node => {
                    if (node.focused)
                        return node;
                    for (const child of [...(node.nodes || []), ...(node.floating_nodes || [])]) {
                        const hit = find(child);
                        if (hit) return hit;
                    }
                    return null;
                };
                try {
                    const node = find(JSON.parse(text));
                    root.focusedTitle = node && node.window ? (node.name || "") : "";
                } catch (e) {}
            }
        }
    }

    // ---- On-screen display, driven by ~/Scripts/osd over IPC ----
    property bool osdVisible: false
    property string osdIcon: ""
    property real osdValue: 0
    property string osdLabel: ""

    // kind: volume | mic | brightness | keyboard (anything else: no icon).
    // A negative percent shows the label alone, without the bar.
    function flashOsd(kind, percent, label) {
        const v = percent < 0 ? -1 : percent / 100;
        const off = label === "Muted";
        osdIcon = kind === "volume" ? Icons.volume(v, off)
            : kind === "mic" ? (off ? Icons.micOff : Icons.mic)
            : kind === "brightness" ? Icons.brightness(v)
            : kind === "keyboard" ? Icons.keyboard
            : "";
        osdValue = v;
        osdLabel = label || `${percent}`;
        osdVisible = true;
        osdTimer.restart();
    }

    Timer {
        id: osdTimer
        interval: 1500
        onTriggered: root.osdVisible = false
    }
}
