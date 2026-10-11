pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property var allApps: {
        const apps = DesktopEntries.applications.values || [];
        const result = [];
        const seen = new Set();
        for (let i = 0; i < apps.length; i++) {
            const app = apps[i];
            if (!app || app.noDisplay) continue;
            if (!app.name || app.name.trim().length === 0) continue;
            // Filter duplicate names
            const key = app.name.trim().toLowerCase();
            if (seen.has(key)) continue;
            seen.add(key);
            result.push(app);
        }
        result.sort((a, b) => a.name.localeCompare(b.name));
        return result;
    }

    function search(query) {
        if (!query || query.trim().length === 0) {
            return allApps;
        }
        const q = query.trim().toLowerCase();
        return allApps.filter(app => {
            const nameMatch = app.name && app.name.toLowerCase().includes(q);
            const commentMatch = app.comment && app.comment.toLowerCase().includes(q);
            const execMatch = app.execString && app.execString.toLowerCase().includes(q);
            return nameMatch || commentMatch || execMatch;
        });
    }
}
