pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int count: 0
    property var prs: []
    property bool loading: false
    property string lastUpdated: "Just now"
    property string status: "idle"

    readonly property string scriptPath: Quickshell.env("HOME") + "/Desktop/personal/custom_quickshell/scripts/get_github_prs.py"

    Process {
        id: prProc
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
                        root.count = data.count ?? 0;
                        root.prs = data.prs ?? [];
                        root.lastUpdated = data.last_updated ?? "";
                        root.status = data.status ?? "ok";
                    }
                } catch(e) {
                    console.log("Error parsing GitHub PRs: " + e);
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
        interval: 120000 // Refresh every 2 minutes
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.refresh(false);
        }
    }

    function refresh(force) {
        if (prProc.running) return;
        root.loading = true;
        if (force) {
            prProc.command = ["python3", root.scriptPath, "--force"];
        } else {
            prProc.command = ["python3", root.scriptPath];
        }
        prProc.running = true;
    }

    function openPr(url) {
        if (url && url.length > 0) {
            Quickshell.execDetached(["xdg-open", url]);
        }
    }

    function openAllPrs() {
        Quickshell.execDetached(["xdg-open", "https://github.com/pulls"]);
    }
}
