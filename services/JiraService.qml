pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var user: ({
        displayName: "alvin.george",
        emailAddress: "alvin.george@askmeidentity.com",
        avatarLocal: "/tmp/jira_avatar.png",
        avatarUrl: "",
        jiraUrl: "https://askmeidentity.atlassian.net",
        jiraHost: "askmeidentity.atlassian.net"
    })
    property var tasks: []
    property int count: 0
    property int inProgressCount: 0
    property int toDoCount: 0
    property int doneCount: 0
    property bool loading: false
    property string lastUpdated: "Just now"
    property string status: "idle"
    property string errorMessage: ""
    property string activeFilter: "all" // "all", "in_progress", "to_do", "done"

    readonly property string scriptPath: Quickshell.env("HOME") + "/Desktop/personal/custom_quickshell/scripts/get_jira_tasks.py"

    Process {
        id: jiraProc
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
                        if (data.status === "ok") {
                            root.user = data.user ?? root.user;
                            root.tasks = data.tasks ?? [];
                            if (data.counts) {
                                root.count = data.counts.total ?? 0;
                                root.inProgressCount = data.counts.in_progress ?? 0;
                                root.toDoCount = data.counts.to_do ?? 0;
                                root.doneCount = data.counts.done ?? 0;
                            } else {
                                root.count = root.tasks.length;
                            }
                            root.lastUpdated = data.last_updated ?? "";
                            root.status = "ok";
                            root.errorMessage = "";
                        } else {
                            root.status = "error";
                            root.errorMessage = data.error ?? "Unknown error";
                        }
                    }
                } catch(e) {
                    console.log("Error parsing Jira tasks: " + e);
                    root.status = "error";
                    root.errorMessage = String(e);
                }
            }
        }
        onExited: {
            root.loading = false;
        }
    }

    Timer {
        id: pollTimer
        interval: 120000 // Refresh every 2 minutes
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.refresh(false);
        }
    }

    function refresh(force) {
        if (jiraProc.running) return;
        root.loading = true;
        if (force) {
            jiraProc.command = ["python3", root.scriptPath, "--force"];
        } else {
            jiraProc.command = ["python3", root.scriptPath];
        }
        jiraProc.running = true;
    }

    function openTask(url) {
        if (url && url.length > 0) {
            Quickshell.execDetached(["xdg-open", url]);
        }
    }

    function openJira() {
        const url = (root.user && root.user.jiraUrl) ? (root.user.jiraUrl + "/jira/your-work") : "https://askmeidentity.atlassian.net/jira/your-work";
        Quickshell.execDetached(["xdg-open", url]);
    }
}
