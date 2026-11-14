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

    readonly property string binPath: Quickshell.env("HOME") + "/Desktop/personal/custom_quickshell/bin/audio_beat_tracker"

    Process {
        id: trackerProc
        running: !ShellState.liteMode && MediaService.isPlaying
        command: [root.binPath]
        onExited: {
            if (!ShellState.liteMode && MediaService.isPlaying) {
                restartTimer.start();
            }
        }
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                if (ShellState.liteMode || !MediaService.isPlaying) return;
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
            if (!ShellState.liteMode && MediaService.isPlaying) {
                trackerProc.running = true;
            }
        }
    }

    Connections {
        target: MediaService
        function onIsPlayingChanged() {
            if (!MediaService.isPlaying) {
                trackerProc.running = false;
                restartTimer.stop();
                root.b0 = 0.0;
                root.b1 = 0.0;
                root.b2 = 0.0;
                root.b3 = 0.0;
                Quickshell.execDetached(["pkill", "-f", "audio_beat_tracker"]);
            } else if (!ShellState.liteMode) {
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
                Quickshell.execDetached(["pkill", "-f", "audio_beat_tracker"]);
            } else {
                trackerProc.running = true;
            }
        }
    }
}
