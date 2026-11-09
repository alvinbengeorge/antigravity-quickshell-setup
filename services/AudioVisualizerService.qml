pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property real b0: 0.0
    property real b1: 0.0
    property real b2: 0.0
    property real b3: 0.0

    readonly property string scriptPath: Quickshell.env("HOME") + "/Desktop/personal/custom_quickshell/scripts/audio_beat_tracker.py"

    Process {
        id: trackerProc
        running: !ShellState.liteMode
        command: ["python3", "-u", root.scriptPath]
        onExited: {
            if (!ShellState.liteMode) {
                restartTimer.start();
            }
        }
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                if (ShellState.liteMode) return;
                try {
                    const parsed = JSON.parse(data.trim());
                    root.b0 = parsed.b0;
                    root.b1 = parsed.b1;
                    root.b2 = parsed.b2;
                    root.b3 = parsed.b3;
                } catch(e) {}
            }
        }
    }

    Timer {
        id: restartTimer
        interval: 1000
        repeat: false
        onTriggered: {
            if (!ShellState.liteMode) {
                trackerProc.running = true;
            }
        }
    }

    Connections {
        target: ShellState
        function onLiteModeChanged() {
            if (ShellState.liteMode) {
                trackerProc.running = false;
                restartTimer.stop();
                root.b0 = 0.0;
                root.b1 = 0.0;
                root.b2 = 0.0;
                root.b3 = 0.0;
                Quickshell.execDetached(["pkill", "-f", "audio_beat_tracker.py"]);
            } else {
                trackerProc.running = true;
            }
        }
    }
}
