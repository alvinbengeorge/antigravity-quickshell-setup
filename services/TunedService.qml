pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool available: false
    property string activeProfile: "throughput-performance"
    property var activeMeta: ({
        id: "throughput-performance",
        name: "Performance",
        icon: "zap",
        color: "#F59E0B",
        summary: "Maximum multi-core CPU throughput"
    })
    property var profiles: []
    property bool switching: false

    function refresh() {
        if (!statusProc.running) {
            statusProc.running = true;
        }
    }

    function switchProfile(profileId) {
        if (!profileId || (root.activeProfile === profileId && !root.switching)) return;
        root.switching = true;
        root.activeProfile = profileId;
        
        // Optimistic metadata update
        for (let i = 0; i < root.profiles.length; i++) {
            if (root.profiles[i].id === profileId) {
                root.activeMeta = root.profiles[i];
                break;
            }
        }

        Quickshell.execDetached([
            "python3",
            Quickshell.env("HOME") + "/Desktop/personal/custom_quickshell/scripts/tuned_manager.py",
            "switch",
            profileId
        ]);

        refreshTimer.restart();
    }

    Process {
        id: statusProc
        running: false
        command: [
            "python3",
            Quickshell.env("HOME") + "/Desktop/personal/custom_quickshell/scripts/tuned_manager.py"
        ]
        stdout: StdioCollector {
            id: collector
            onStreamFinished: {
                root.switching = false;
                const text = collector.text.trim();
                if (!text) return;
                try {
                    const data = JSON.parse(text);
                    root.available = data.available ?? false;
                    if (data.activeProfile) root.activeProfile = data.activeProfile;
                    if (data.activeMeta) root.activeMeta = data.activeMeta;
                    if (data.profiles && Array.isArray(data.profiles)) root.profiles = data.profiles;
                } catch(e) {
                    console.warn("Failed to parse TuneD status JSON:", e);
                }
            }
        }
    }

    Timer {
        id: refreshTimer
        interval: 1200
        repeat: false
        onTriggered: root.refresh()
    }

    Timer {
        id: pollTimer
        interval: 8000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
