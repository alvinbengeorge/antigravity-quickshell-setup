pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string status: "loading" // "ready", "qr_ready", "disconnected", "stopped", "offline", "loading", "reconnecting", "disconnecting"
    property var session: null
    property int unreadCount: 0
    property var chats: []
    property string qrPath: "/tmp/openwa_qr.png"
    property string lastUpdated: ""
    property bool loading: false
    property string errorMessage: ""

    readonly property string userPhone: (session && session.phone) ? session.phone : ""
    readonly property string userName: (session && session.pushName) ? session.pushName : "Alvin"
    readonly property string sessionId: (session && session.id) ? session.id : "5e24dc37-3676-48a7-9c50-35559fefbed6"

    readonly property string scriptPath: Quickshell.env("HOME") + "/Desktop/personal/custom_quickshell/scripts/get_openwa_status.py"

    Process {
        id: statusProc
        running: false
        command: ["python3", root.scriptPath]
        stdout: StdioCollector {
            id: collector
            onStreamFinished: {
                root.loading = false;
                try {
                    const raw = collector.text.trim();
                    if (raw.length > 0) {
                        const data = JSON.parse(raw);
                        root.status = data.status || "error";
                        root.session = data.session || null;
                        root.unreadCount = data.unread_total ?? 0;
                        root.chats = data.chats ?? [];
                        root.lastUpdated = data.last_updated ?? "";
                        if (data.qr_path) {
                            root.qrPath = data.qr_path;
                        }
                        root.errorMessage = data.error || "";
                    }
                } catch(e) {
                    console.log("Error parsing OpenWA status: " + e);
                    root.status = "error";
                    root.errorMessage = "" + e;
                }
            }
        }
        onExited: {
            root.loading = false;
        }
    }

    // Action Process (Reconnect / Start Container)
    Process {
        id: actionProc
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                // Trigger refresh after action finishes
                refreshTimer.start();
            }
        }
    }

    Timer {
        id: refreshTimer
        interval: 1500
        repeat: false
        onTriggered: root.refresh()
    }

    Timer {
        id: pollTimer
        interval: {
            if (root.status === "reconnecting" || root.status === "loading") return 4000;
            if (root.status === "qr_ready") return 6000;
            if (root.status === "offline" || root.status === "disconnected") return 12000;
            return 25000; // Normal idle poll
        }
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    function refresh(): void {
        if (statusProc.running) return;
        root.loading = true;
        statusProc.command = ["python3", root.scriptPath];
        statusProc.running = true;
    }

    function reconnectSession(): void {
        if (actionProc.running) return;
        root.status = "reconnecting";
        root.loading = true;
        actionProc.command = ["python3", root.scriptPath, "--reconnect", root.sessionId];
        actionProc.running = true;
    }

    function disconnectSession(): void {
        if (actionProc.running) return;
        root.status = "disconnecting";
        root.loading = true;
        actionProc.command = ["python3", root.scriptPath, "--disconnect", root.sessionId];
        actionProc.running = true;
    }

    function startGateway(): void {
        if (actionProc.running) return;
        root.status = "loading";
        root.loading = true;
        actionProc.command = ["python3", root.scriptPath, "--start-gateway"];
        actionProc.running = true;
    }

    function openDashboard(): void {
        Quickshell.execDetached(["xdg-open", "http://localhost:2785"]);
    }

    function openWeb(): void {
        Quickshell.execDetached(["xdg-open", "https://web.whatsapp.com"]);
    }
}
