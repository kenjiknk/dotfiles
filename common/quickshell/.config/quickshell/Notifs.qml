pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

// The notification daemon (org.freedesktop.Notifications). New notifications
// pop up as toasts below the bar for 10 s, then stay in the history the bell
// widget lists, up to `historyLimit`. Toasts are held back while the screen is
// locked (~/Scripts/lock) and while "do not disturb" is on.
Singleton {
    id: root

    readonly property int historyLimit: 20
    readonly property int maxToasts: 4
    readonly property var list: server.trackedNotifications.values
    // ids whose toast is gone (timed out or closed); they stay in the history
    property var seen: ({})
    readonly property var toasts: (dnd || locked) ? [] : list.filter(n => !seen[n.id])
    // Do not disturb and the lock hold are kept across config reloads (a theme
    // switch rewrites Theme.qml, which reloads the shell); otherwise a reload
    // would silently switch them off. PersistentProperties keeps plain values
    // only (an object comes back undefined), hence not `seen`.
    property alias dnd: persist.dnd
    property alias locked: persist.locked

    PersistentProperties {
        id: persist
        reloadableId: "notifs"

        property bool dnd: false
        property bool locked: false
    }

    // The notifications themselves survive a reload (keepOnReload) but `seen`
    // starts empty: count them all as seen, or each would pop up again.
    Component.onCompleted: markAllSeen()

    // A fresh start (i3 restart, crash relaunch) does not get the persistent
    // state above, so read the lock from the system: hold toasts back if the
    // screen is locked right now. ~/Scripts/lock lifts the hold on unlock.
    Process {
        running: true
        command: ["pgrep", "-x", "i3lock"]
        onExited: code => { if (code === 0) persist.locked = true; }
    }

    function markSeen(id) {
        seen = Object.assign({}, seen, { [id]: true });
    }

    // An app updating a notification in place (replaces_id: progress, chat)
    // keeps its id; let the new content pop up again.
    function unsee(id) {
        if (!seen[id]) return;
        const copy = Object.assign({}, seen);
        delete copy[id];
        seen = copy;
    }

    // id of the toast under the pointer; its timer waits meanwhile
    property int hoveredId: -1

    // One entry per notification, kept for as long as the notification lives
    // (Variants reuses entries when the list changes), so its toast timer does
    // not restart whenever another notification comes or goes.
    Variants {
        model: root.list

        Scope {
            id: entry

            required property var modelData

            Connections {
                target: entry.modelData
                function onSummaryChanged() { root.unsee(entry.modelData.id); }
                function onBodyChanged() { root.unsee(entry.modelData.id); }
            }

            Timer {
                running: root.toasts.includes(entry.modelData) && root.hoveredId !== entry.modelData.id
                interval: root.timeoutMs(entry.modelData)
                onTriggered: root.markSeen(entry.modelData.id)
            }
        }
    }

    // Only maxToasts show at once: older unseen ones go straight to the
    // history instead of waiting behind them. Runs after every change of the
    // queue, so it also applies when do not disturb or the lock ends. Deferred:
    // changing `seen` while `toasts` is still being evaluated is dropped.
    function trimToasts() {
        const extra = toasts.length - maxToasts;
        if (extra > 0)
            for (const old of toasts.slice(0, extra)) markSeen(old.id);
    }
    onToastsChanged: Qt.callLater(trimToasts)

    function markAllSeen() {
        const all = Object.assign({}, seen);
        for (const n of list) all[n.id] = true;
        seen = all;
    }

    function clearAll() {
        for (const n of list.slice()) n.dismiss();
    }

    // The app's own timeout when it sets one, otherwise 10 s (as dunst had).
    // Quickshell passes expireTimeout through in milliseconds; -1 = not set.
    function timeoutMs(n) {
        const t = n.expireTimeout > 0 ? n.expireTimeout : 10000;
        return Math.max(1000, Math.min(30000, t));
    }

    function defaultAction(n) {
        return n.actions.find(a => a.identifier === "default") ?? null;
    }

    NotificationServer {
        id: server

        keepOnReload: true
        actionsSupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: n => {
            n.tracked = true;
            // Shown while locked or in do-not-disturb: straight to the history.
            if (root.dnd || root.locked) root.markSeen(n.id);
            // Oldest out once the history is full. Snapshot first: `list` is a
            // live binding and shrinks with every dismiss.
            for (const old of root.list.slice(0, Math.max(0, root.list.length - root.historyLimit)))
                old.dismiss();
        }
    }
}
