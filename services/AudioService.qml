pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

Singleton {
    id: root

    // Reactive Pipewire properties
    readonly property real pwVolume: Pipewire.defaultAudioSink?.audio?.volume ?? -1
    readonly property bool pwMuted: Pipewire.defaultAudioSink?.audio?.muted ?? false

    property real volume: pwVolume >= 0 ? pwVolume : 1.0
    property bool muted: pwMuted

    onPwVolumeChanged: {
        if (pwVolume >= 0) root.volume = pwVolume;
    }

    onPwMutedChanged: {
        root.muted = pwMuted;
    }

    // Polling and fallback query via wpctl
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
                if (data.includes("sink") || data.includes("server")) {
                    if (!wpctlProc.running) {
                        wpctlProc.running = true;
                    }
                }
            }
        }
    }

    // Fast backup interval (500ms) to ensure volume never lags
    Timer {
        interval: 500
        running: true
        repeat: true
        onTriggered: {
            if (Pipewire.defaultAudioSink?.audio?.volume !== undefined && Pipewire.defaultAudioSink?.audio?.volume >= 0) {
                root.volume = Pipewire.defaultAudioSink.audio.volume;
                root.muted = Pipewire.defaultAudioSink.audio.muted ?? false;
            } else if (!wpctlProc.running) {
                wpctlProc.running = true;
            }
        }
    }

    function toggleMute() {
        if (Pipewire.defaultAudioSink?.audio) {
            Pipewire.defaultAudioSink.audio.muted = !Pipewire.defaultAudioSink.audio.muted;
            root.muted = Pipewire.defaultAudioSink.audio.muted;
        } else {
            Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]);
            if (!wpctlProc.running) wpctlProc.running = true;
        }
    }

    function changeVolume(delta) {
        if (Pipewire.defaultAudioSink?.audio) {
            const next = Math.max(0, Math.min(1.5, root.volume + delta));
            Pipewire.defaultAudioSink.audio.volume = next;
            root.volume = next;
        } else {
            const arg = delta > 0 ? "5%+" : "5%-";
            Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", arg]);
            if (!wpctlProc.running) wpctlProc.running = true;
        }
    }
}
