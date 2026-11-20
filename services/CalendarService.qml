pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var todayEvents: []
    property var upcomingEvents: []
    property var nextEvent: null
    property int count: 0
    property bool loading: false
    property string lastUpdated: ""
    property string status: "idle"
    property var calendars: []
    readonly property bool hasEventsToday: count > 0

    readonly property string scriptPath: Quickshell.env("HOME") + "/Desktop/personal/custom_quickshell/bin/calendar_events"

    Process {
        id: calProc
        running: false
        command: [root.scriptPath]
        stdout: StdioCollector {
            id: collector
            onStreamFinished: {
                root.loading = false;
                try {
                    const raw = collector.text.trim();
                    if (raw.length > 0) {
                        const data = JSON.parse(raw);
                        if (data.status === "ok") {
                            root.todayEvents = data.today_events ?? [];
                            root.upcomingEvents = data.upcoming_events ?? [];
                            root.nextEvent = data.next_event ?? null;
                            root.count = data.count ?? root.todayEvents.length;
                            root.lastUpdated = data.last_updated ?? "";
                            root.calendars = data.calendars ?? [];
                            root.status = data.offline ? "offline" : "ok";
                        } else if (data.status === "offline") {
                            root.status = "offline";
                        }
                    }
                } catch(e) {
                    console.log("Error parsing Calendar events: " + e);
                    root.status = "error";
                }
            }
        }
        onExited: {
            root.loading = false;
        }
    }

    Timer {
        id: pollTimer
        interval: 300000 // Refresh every 5 minutes
        running: NetworkService.isOnline
        repeat: true
        triggeredOnStart: false
        onTriggered: {
            if (NetworkService.isOnline) {
                root.refresh(false);
            }
        }
    }

    Connections {
        target: NetworkService
        function onIsOnlineChanged() {
            if (NetworkService.isOnline) {
                root.refresh(false);
            } else {
                root.status = "offline";
                root.loading = false;
            }
        }
    }

    Component.onCompleted: {
        if (NetworkService.isOnline) {
            root.refresh(false);
        }
    }

    function refresh(force) {
        if (!NetworkService.isOnline) {
            root.status = "offline";
            root.loading = false;
            return;
        }
        if (calProc.running) return;
        root.loading = true;
        if (force) {
            calProc.command = [root.scriptPath, "--force"];
        } else {
            calProc.command = [root.scriptPath];
        }
        calProc.running = true;
    }

    function openMeet(url) {
        if (url && url.length > 0) {
            Quickshell.execDetached(["xdg-open", url]);
        }
    }

    function openCalendar() {
        Quickshell.execDetached(["xdg-open", "https://calendar.google.com"]);
    }
}
