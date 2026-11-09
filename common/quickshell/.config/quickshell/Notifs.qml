pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// Notification daemon. Off by default because dunst already owns
// org.freedesktop.Notifications; enable with QS_NOTIFS=1 after stopping dunst.
Singleton {
    id: root

    readonly property bool enabled: Quickshell.env("QS_NOTIFS") === "1"
    readonly property var list: loader.item ? loader.item.trackedNotifications.values : []
    // ids whose popup already timed out; they stay in the history list
    property var seen: ({})
    readonly property var toasts: list.filter(n => !seen[n.id])
    property bool dnd: false

    function markSeen(id) {
        seen = Object.assign({}, seen, { [id]: true });
    }

    function clearAll() {
        for (const n of list.slice()) n.dismiss();
    }

    function timeoutMs(n) {
        if (n.urgency === NotificationUrgency.Critical) return 0;
        const t = n.expireTimeout > 0 ? n.expireTimeout * 1000 : 5000;
        return Math.max(2000, Math.min(15000, t));
    }

    LazyLoader {
        id: loader
        active: root.enabled

        NotificationServer {
            keepOnReload: true
            actionsSupported: true
            bodyMarkupSupported: true
            bodyHyperlinksSupported: true
            imageSupported: true
            persistenceSupported: true
            onNotification: n => {
                n.tracked = true;
                if (root.dnd) root.markSeen(n.id);
            }
        }
    }
}
