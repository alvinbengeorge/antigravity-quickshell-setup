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

    readonly property string scriptPath: Quickshell.env("HOME") + "/Desktop/personal/custom_quickshell/bin/github_prs"

    Process {
        id: prProc
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
        if (prProc.running) return;
        root.loading = true;
        if (force) {
            prProc.command = [root.scriptPath, "--force"];
        } else {
            prProc.command = [root.scriptPath];
        }
        prProc.running = true;
    }

    property var extraPrs: ({})
    signal prFetched(string id, var pr)

    function getPr(identifier) {
        if (!identifier) return null;
        const str = String(identifier).replace(/^#/, "").trim().toLowerCase();
        for (let i = 0; i < root.prs.length; i++) {
            const p = root.prs[i];
            if (String(p.number) === str) {
                return p;
            }
        }
        if (root.extraPrs && root.extraPrs[str]) {
            return root.extraPrs[str];
        }
        return null;
    }

    function searchPrs(term) {
        if (!term) return [];
        const t = term.toLowerCase().trim();
        const results = [];
        for (let i = 0; i < root.prs.length; i++) {
            const p = root.prs[i];
            const title = (p.title || "").toLowerCase();
            const repo = (p.repo || "").toLowerCase();
            const num = String(p.number);
            if (title.includes(t) || repo.includes(t) || num === t) {
                results.push(p);
            }
        }
        return results;
    }

    Process {
        id: singlePrProc
        running: false
        property string pendingId: ""
        stdout: StdioCollector {
            id: singlePrCollector
            onStreamFinished: {
                try {
                    const raw = singlePrCollector.text.trim();
                    if (raw.length > 0) {
                        const data = JSON.parse(raw);
                        if (data.status === "ok" && data.pr) {
                            const newMap = Object.assign({}, root.extraPrs);
                            newMap[String(data.pr.number)] = data.pr;
                            root.extraPrs = newMap;
                            root.prFetched(String(data.pr.number), data.pr);
                        }
                    }
                } catch(e) {
                    console.log("Error parsing single GitHub PR: " + e);
                }
            }
        }
    }

    function fetchPr(identifier) {
        if (!identifier || singlePrProc.running) return;
        const str = String(identifier).replace(/^#/, "").trim();
        if (getPr(str)) return;
        singlePrProc.pendingId = str;
        singlePrProc.command = [root.scriptPath, "--pr", str];
        singlePrProc.running = true;
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
