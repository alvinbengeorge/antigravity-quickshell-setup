pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var cpu: ({
        percent: 0,
        cores: 1,
        load_1: 0,
        load_5: 0,
        load_15: 0
    })

    property var ram: ({
        total_mb: 0,
        used_mb: 0,
        free_mb: 0,
        avail_mb: 0,
        cached_mb: 0,
        shmem_mb: 0,
        used_percent: 0,
        avail_percent: 0
    })

    property var swap: ({
        total_mb: 0,
        used_mb: 0,
        free_mb: 0,
        used_percent: 0
    })

    property var groups: []
    property var topByMem: []
    property var topByCpu: []
    property var topBySwap: []

    property bool loading: false
    property string lastUpdated: "Just now"
    property string activeTab: "ram" // "ram", "cpu", "swap", "groups"
    property string searchQuery: ""

    readonly property string scriptPath: Quickshell.env("HOME") + "/Desktop/personal/custom_quickshell/scripts/system_monitor.py"

    // ── Telemetry Data Query Process ─────────────────────────────────────────
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
                        if (data.cpu) root.cpu = data.cpu;
                        if (data.ram) root.ram = data.ram;
                        if (data.swap) root.swap = data.swap;
                        root.groups = data.groups ?? [];
                        root.topByMem = data.top_by_mem ?? [];
                        root.topByCpu = data.top_by_cpu ?? [];
                        root.topBySwap = data.top_by_swap ?? [];

                        const now = new Date();
                        const h = String(now.getHours()).padStart(2, '0');
                        const m = String(now.getMinutes()).padStart(2, '0');
                        const s = String(now.getSeconds()).padStart(2, '0');
                        root.lastUpdated = `${h}:${m}:${s}`;
                    }
                } catch(e) {
                    console.log("[SystemMonitorService] Error parsing telemetry:", e);
                }
            }
        }
    }

    // ── Kill Process ─────────────────────────────────────────────────────────
    Process {
        id: killProc
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                // Refresh list right after kill
                root.refresh();
            }
        }
    }

    function killProcess(pid, force) {
        if (!pid) return;
        killProc.command = ["python3", root.scriptPath, "kill", String(pid), force ? "1" : "0"];
        killProc.running = true;
    }

    // ── Drop Caches ──────────────────────────────────────────────────────────
    Process {
        id: dropCachesProc
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                root.refresh();
            }
        }
    }

    function dropCaches() {
        // Run sync and attempt drop caches
        dropCachesProc.command = ["python3", root.scriptPath, "drop_caches"];
        dropCachesProc.running = true;
    }

    // ── Manual Refresh ───────────────────────────────────────────────────────
    function refresh() {
        if (!dataProc.running) {
            root.loading = true;
            dataProc.running = true;
        }
    }

    // ── Auto Refresh Timer when panel is open ────────────────────────────────
    Timer {
        id: autoRefreshTimer
        interval: ShellState.liteMode ? 6000 : 3500
        repeat: true
        running: ShellState.systemMonitorOpen
        triggeredOnStart: false
        onTriggered: {
            root.refresh();
        }
    }

    // Fetch immediately whenever the monitor is opened
    Connections {
        target: ShellState
        function onSystemMonitorOpenChanged() {
            if (ShellState.systemMonitorOpen) {
                root.refresh();
            }
        }
    }
}
