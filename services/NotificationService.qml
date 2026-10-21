pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root

    property var history: []
    property var activeToasts: []
    property int unreadCount: 0
    property bool dnd: false
    property int nextToastId: 1

    NotificationServer {
        id: server
        actionsSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: true
        bodyMarkupSupported: true
        bodySupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: notification => {
            notification.tracked = true;

            const now = new Date();
            const timeStr = Qt.formatTime(now, "HH:mm");

            const item = {
                "id": notification.id,
                "serverNotif": notification,
                "appName": notification.appName || "System",
                "appIcon": notification.appIcon || "",
                "summary": notification.summary || "Notification",
                "body": notification.body || "",
                "time": timeStr,
                "urgency": notification.urgency !== undefined ? notification.urgency : 1
            };

            // Prepend to history
            const newHistory = [item, ...root.history];
            if (newHistory.length > 50) newHistory.pop();
            root.history = newHistory;
            root.unreadCount++;

            // If not in Do Not Disturb, show toast
            if (!root.dnd) {
                root.showToast(item);
            }
        }
    }

    function showToast(item) {
        const toastItem = Object.assign({}, item, { toastUid: root.nextToastId++ });
        root.activeToasts = [...root.activeToasts, toastItem];
    }

    function dismissToast(toastUid) {
        root.activeToasts = root.activeToasts.filter(t => t.toastUid !== toastUid);
    }

    function dismissHistory(id) {
        root.history = root.history.filter(h => h.id !== id);
    }

    function clearAll() {
        root.history = [];
        root.activeToasts = [];
        root.unreadCount = 0;
    }

    function toggleDnd() {
        root.dnd = !root.dnd;
        if (root.dnd) {
            root.activeToasts = [];
        }
    }

    function markAllRead() {
        root.unreadCount = 0;
    }
}
