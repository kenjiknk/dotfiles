pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// The notification daemon (org.freedesktop.Notifications). New notifications
// pop up as toasts below the bar for 10 s, then stay in the history the bell
// widget lists, up to `historyLimit`. Toasts are held back while the screen is
// locked (~/Scripts/lock) and while "do not disturb" is on.
Singleton {
    id: root

    readonly property int historyLimit: 20
    readonly property var list: server.trackedNotifications.values
    // ids whose toast is gone (timed out or closed); they stay in the history
    property var seen: ({})
    readonly property var toasts: (dnd || locked) ? [] : list.filter(n => !seen[n.id])
    property bool dnd: false
    property bool locked: false

    function markSeen(id) {
        seen = Object.assign({}, seen, { [id]: true });
    }

    function markAllSeen() {
        const all = Object.assign({}, seen);
        for (const n of list) all[n.id] = true;
        seen = all;
    }

    function clearAll() {
        for (const n of list.slice()) n.dismiss();
    }

    // The app's own timeout when it sets one, otherwise 10 s (as dunst had).
    function timeoutMs(n) {
        const t = n.expireTimeout > 0 ? n.expireTimeout * 1000 : 10000;
        return Math.max(2000, Math.min(30000, t));
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
            // Oldest out once the history is full.
            const extra = root.list.length - root.historyLimit;
            for (let i = 0; i < extra; i++) root.list[i].dismiss();
        }
    }
}
