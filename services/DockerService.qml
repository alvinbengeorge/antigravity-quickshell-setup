pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var containers: []
    property var images: []
    property var summary: ({
        total: 0,
        running: 0,
        stopped: 0,
        paused: 0,
        images_count: 0
    })
    property bool daemonRunning: true
    property bool loading: false
    property bool statsLoading: false
    property string lastUpdated: "Just now"
    property string activeFilter: "all" // "all", "running", "stopped", "compose"
    property string searchQuery: ""

    // Log viewer state
    property string logsContent: ""
    property string activeLogContainer: ""
    property bool logsLoading: false

    readonly property string scriptPath: Quickshell.env("HOME") + "/Desktop/personal/custom_quickshell/scripts/docker_manager.py"

    // ── Data Query Process ──────────────────────────────────────────────────
    Process {
        id: dataProc
        running: false
        command: ["python3", root.scriptPath, "data"]
        stdout: StdioCollector {
            id: dataCollector
            onStreamFinished: {
                root.loading = false;
                try {
                    const raw = dataCollector.text.trim();
                    if (raw.length > 0) {
                        const data = JSON.parse(raw);
                        root.daemonRunning = data.daemon_running ?? false;
                        root.containers = data.containers ?? [];
                        root.images = data.images ?? [];
                        if (data.summary) {
                            root.summary = data.summary;
                        }
                        const now = new Date();
                        const h = String(now.getHours()).padStart(2, '0');
                        const m = String(now.getMinutes()).padStart(2, '0');
                        const s = String(now.getSeconds()).padStart(2, '0');
                        root.lastUpdated = `${h}:${m}:${s}`;
                    }
                } catch(e) {
                    console.log("Error parsing docker data:", e);
                }
            }
        }
    }

    // ── Stats Refresh Process ───────────────────────────────────────────────
    Process {
        id: statsProc
        running: false
        command: ["python3", root.scriptPath, "stats"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.statsLoading = false;
                // Re-read data with new stats
                dataProc.running = true;
            }
        }
    }

    // Background timer to refresh live stats when panel is open
    Timer {
        id: statsTimer
        interval: 6000
        repeat: true
        running: ShellState.dockerOpen
        onTriggered: {
            if (ShellState.dockerOpen && !statsProc.running && !dataProc.running) {
                statsProc.running = true;
            }
        }
    }

    // Periodic lightweight background poll to keep TopBar pill up to date (every 15s)
    Timer {
        id: pillPollTimer
        interval: ShellState.liteMode ? 30000 : 15000
        repeat: true
        running: true
        onTriggered: {
            if (!ShellState.dockerOpen && !dataProc.running) {
                dataProc.running = true;
            }
        }
    }

    // ── Action Process ──────────────────────────────────────────────────────
    Process {
        id: actionProc
        running: false
        property string pendingAction: ""
        property string pendingTarget: ""

        command: ["python3", root.scriptPath, "action", pendingAction, pendingTarget]
        stdout: StdioCollector {
            onStreamFinished: {
                root.loading = false;
                root.refresh();
            }
        }
    }

    // ── Logs Query Process ──────────────────────────────────────────────────
    Process {
        id: logsProc
        running: false
        property string logTarget: ""
        property string logLines: "150"

        command: ["python3", root.scriptPath, "action", "logs", logTarget, logLines]
        stdout: StdioCollector {
            id: logsCollector
            onStreamFinished: {
                root.logsLoading = false;
                try {
                    const raw = logsCollector.text.trim();
                    if (raw.length > 0) {
                        const data = JSON.parse(raw);
                        root.logsContent = data.logs ?? "No logs found.";
                    }
                } catch(e) {
                    root.logsContent = logsCollector.text;
                }
            }
        }
    }

    // ── Public API Methods ──────────────────────────────────────────────────
    function refresh(): void {
        if (!dataProc.running) {
            root.loading = true;
            dataProc.running = true;
        }
    }

    function updateStats(): void {
        if (!statsProc.running) {
            root.statsLoading = true;
            statsProc.running = true;
        }
    }

    function startContainer(idOrName: string): void {
        executeAction("start", idOrName);
    }

    function stopContainer(idOrName: string): void {
        executeAction("stop", idOrName);
    }

    function restartContainer(idOrName: string): void {
        executeAction("restart", idOrName);
    }

    function pauseContainer(idOrName: string): void {
        executeAction("pause", idOrName);
    }

    function unpauseContainer(idOrName: string): void {
        executeAction("unpause", idOrName);
    }

    function removeContainer(idOrName: string): void {
        executeAction("remove", idOrName);
    }

    function removeImage(id: string): void {
        executeAction("remove_image", id);
    }

    function pruneContainers(): void {
        executeAction("prune_containers", "");
    }

    function pruneImages(): void {
        executeAction("prune_images", "");
    }

    function startAll(): void {
        executeAction("start_all", "");
    }

    function stopAll(): void {
        executeAction("stop_all", "");
    }

    function openTerminal(idOrName: string): void {
        executeAction("terminal", idOrName);
    }

    function openLiveLogs(idOrName: string): void {
        executeAction("live_logs", idOrName);
    }

    function fetchLogs(idOrName: string, lines: string): void {
        root.activeLogContainer = idOrName;
        root.logsLoading = true;
        logsProc.logTarget = idOrName;
        logsProc.logLines = lines || "150";
        logsProc.running = true;
    }

    function executeAction(act: string, target: string): void {
        root.loading = true;
        actionProc.pendingAction = act;
        actionProc.pendingTarget = target;
        actionProc.running = true;
    }

    // Initial load
    Component.onCompleted: {
        refresh();
    }
}
