pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

Singleton {
    id: root

    // Reactive Pipewire properties (guarded by ready state)
    readonly property bool pwReady: Pipewire.defaultAudioSink?.ready ?? false
    readonly property real pwVolume: (pwReady && Pipewire.defaultAudioSink?.audio) ? Pipewire.defaultAudioSink.audio.volume : -1
    readonly property bool pwMuted: (pwReady && Pipewire.defaultAudioSink?.audio) ? Pipewire.defaultAudioSink.audio.muted : false

    property real volume: 1.0
    property bool muted: false

    onPwVolumeChanged: {
        if (pwReady && pwVolume > 0) {
            root.volume = pwVolume;
        }
    }

    onPwMutedChanged: {
        if (pwReady) {
            root.muted = pwMuted;
        }
    }

    // Polling and authoritative query via wpctl
    Process {
        id: wpctlProc
        running: false
        command: ["bash", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@"]
        stdout: StdioCollector {
            id: collector
            onStreamFinished: {
                const text = collector.text.trim();
                const isMuted = text.includes("[MUTED]");
                const match = text.match(/Volume:\s+([0-9.]+)/);
                if (match) {
                    root.volume = parseFloat(match[1]);
                }
                root.muted = isMuted;
            }
        }
    }

    // Continuous Real-Time event stream via pactl subscribe
    Process {
        id: subProc
        running: true
        command: ["pactl", "subscribe"]
        stdout: SplitParser {
            onRead: data => {
                if (data.includes("sink") || data.includes("server") || data.includes("change")) {
                    if (!wpctlProc.running) {
                        wpctlProc.running = true;
                    }
                }
            }
        }
    }

    // Periodic safety sync interval
    Timer {
        interval: ShellState.liteMode ? 4000 : 1500
        running: true
        repeat: true
        onTriggered: {
            if (!wpctlProc.running) {
                wpctlProc.running = true;
            }
        }
    }

    Component.onCompleted: {
        wpctlProc.running = true;
    }

    function toggleMute() {
        root.muted = !root.muted;
        Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]);
        if (!wpctlProc.running) wpctlProc.running = true;
    }

    function changeVolume(delta) {
        const next = Math.max(0, Math.min(1.5, root.volume + delta));
        root.volume = next;
        const pct = Math.round(Math.abs(delta) * 100);
        const arg = delta > 0 ? (pct + "%+") : (pct + "%-");
        Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", arg]);
        if (!wpctlProc.running) wpctlProc.running = true;
    }

    function setVolume(target) {
        const next = Math.max(0, Math.min(1.5, target));
        root.volume = next;
        Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", Math.round(next * 100) + "%"]);
        if (!wpctlProc.running) wpctlProc.running = true;
    }
}
