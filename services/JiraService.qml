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

    readonly property string scriptPath: Quickshell.env("HOME") + "/Desktop/personal/custom_quickshell/bin/jira_tasks"

    Process {
        id: jiraProc
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
        if (jiraProc.running) return;
        root.loading = true;
        if (force) {
            jiraProc.command = [root.scriptPath, "--force"];
        } else {
            jiraProc.command = [root.scriptPath];
        }
        jiraProc.running = true;
    }

    property var extraIssues: ({})
    signal issueFetched(string key, var issue)

    function getIssue(key) {
        if (!key) return null;
        const cleanKey = key.toUpperCase().trim();
        for (let i = 0; i < root.tasks.length; i++) {
            if (root.tasks[i].key && root.tasks[i].key.toUpperCase() === cleanKey) {
                return root.tasks[i];
            }
        }
        if (root.extraIssues && root.extraIssues[cleanKey]) {
            return root.extraIssues[cleanKey];
        }
        return null;
    }

    function searchTasks(term) {
        if (!term) return [];
        const t = term.toLowerCase().trim();
        const results = [];
        for (let i = 0; i < root.tasks.length; i++) {
            const task = root.tasks[i];
            const summary = (task.summary || "").toLowerCase();
            const key = (task.key || "").toLowerCase();
            if (summary.includes(t) || key.includes(t)) {
                results.push(task);
            }
        }
        return results;
    }

    Process {
        id: singleIssueProc
        running: false
        property string pendingKey: ""
        stdout: StdioCollector {
            id: singleCollector
            onStreamFinished: {
                try {
                    const raw = singleCollector.text.trim();
                    if (raw.length > 0) {
                        const data = JSON.parse(raw);
                        if (data.status === "ok" && data.issue) {
                            const newMap = Object.assign({}, root.extraIssues);
                            newMap[data.issue.key.toUpperCase()] = data.issue;
                            root.extraIssues = newMap;
                            root.issueFetched(data.issue.key.toUpperCase(), data.issue);
                        }
                    }
                } catch(e) {
                    console.log("Error parsing single Jira issue: " + e);
                }
            }
        }
    }

    function fetchIssue(key) {
        if (!key || singleIssueProc.running) return;
        const cleanKey = key.toUpperCase().trim();
        if (getIssue(cleanKey)) return;
        singleIssueProc.pendingKey = cleanKey;
        singleIssueProc.command = [root.scriptPath, "--issue", cleanKey];
        singleIssueProc.running = true;
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
