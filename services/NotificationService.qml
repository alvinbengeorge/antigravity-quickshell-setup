pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

Singleton {
    id: root

    property var history: []
    property var activeToasts: []
    property int unreadCount: 0
    property bool dnd: false
    property int nextToastId: 1
    property bool isLoaded: false

    // Track active DBus Notification QObjects at runtime (not persisted to disk)
    property var activeNotifMap: ({})

    property string stateDir: Quickshell.env("HOME") + "/.local/state/quickshell/user"
    property string stateFile: stateDir + "/antigravity-notifications.json"

    Timer {
        id: notifWriteTimer
        interval: 80
        repeat: false
        onTriggered: {
            if (root.isLoaded) {
                notifAdapter.dnd = root.dnd;
                notifAdapter.history = root.history;
                notifFileView.writeAdapter();
            }
        }
    }

    FileView {
        id: notifFileView
        path: root.stateFile

        watchChanges: false
        onAdapterUpdated: notifWriteTimer.restart()
        onLoaded: {
            if (notifAdapter.dnd !== undefined) {
                root.dnd = notifAdapter.dnd;
            }
            if (notifAdapter.history && Array.isArray(notifAdapter.history)) {
                root.history = notifAdapter.history;
            }
            root.isLoaded = true;
        }
        onLoadFailed: error => {
            console.log("Notification state load error:", error);
            root.isLoaded = true;
            root.saveState();
        }

        adapter: JsonAdapter {
            id: notifAdapter
            property bool dnd: false
            property var history: []
        }
    }

    function saveState() {
        if (!root.isLoaded) return;
        notifAdapter.dnd = root.dnd;
        notifAdapter.history = root.history;
        notifWriteTimer.restart();
    }

    NotificationServer {
        id: server
        keepOnReload: true
        actionsSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: true
        bodyMarkupSupported: true
        bodySupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: notification => {
            notification.tracked = true;
            root.activeNotifMap[notification.id] = notification;

            const now = new Date();
            const timeStr = Qt.formatTime(now, "HH:mm");

            const item = {
                "id": notification.id,
                "appName": notification.appName || "System",
                "appIcon": notification.appIcon || "",
                "summary": notification.summary || "Notification",
                "body": notification.body || "",
                "time": timeStr,
                "urgency": notification.urgency !== undefined ? notification.urgency : 1
            };

            // Prepend to history, avoid duplicates
            const newHistory = [item, ...root.history.filter(h => h.id !== notification.id)];
            if (newHistory.length > 50) newHistory.pop();
            root.history = newHistory;
            root.saveState();

            // If not in Do Not Disturb, show toast and increment unread
            if (!root.dnd) {
                root.unreadCount++;
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
        if (root.activeNotifMap[id]) {
            try {
                root.activeNotifMap[id].dismiss();
            } catch(e) {}
            delete root.activeNotifMap[id];
        }
        root.history = root.history.filter(h => h.id !== id);
        root.saveState();
    }

    function clearAll() {
        for (let id in root.activeNotifMap) {
            try {
                root.activeNotifMap[id].dismiss();
            } catch(e) {}
        }
        root.activeNotifMap = {};
        root.history = [];
        root.activeToasts = [];
        root.unreadCount = 0;
        root.saveState();
    }

    function toggleDnd() {
        root.dnd = !root.dnd;
        if (root.dnd) {
            root.activeToasts = [];
        }
        root.saveState();
    }

    function markAllRead() {
        root.unreadCount = 0;
    }
}
