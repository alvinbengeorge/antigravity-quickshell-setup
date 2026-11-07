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
        running: true
        command: ["python3", "-u", root.scriptPath]
        onExited: restartTimer.start()
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
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
        onTriggered: trackerProc.running = true
    }
}
