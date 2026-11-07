pragma Singleton
import QtQuick
import Quickshell
import "../theme"

Singleton {
    id: root

    property bool active: false
    property string osdType: "volume" // "volume", "brightness", "custom"
    property string icon: "volume-2"
    property string title: "Volume"
    property real progress: 0.5 // 0.0 to 1.0 (clamped for bar)
    property string valueText: "50%"
    property bool isMuted: false
    property color accentColor: Theme.accentSky

    property bool ready: false

    Timer {
        id: startupTimer
        interval: 1500
        running: true
        repeat: false
        onTriggered: root.ready = true
    }

    Timer {
        id: hideTimer
        interval: 1600
        repeat: false
        onTriggered: {
            root.active = false;
        }
    }

    function keepAlive() {
        if (root.active) {
            hideTimer.restart();
        }
    }

    function show(type, valText, prog, ico, titl, accent, muted) {
        root.osdType = type;
        root.valueText = valText;
        root.progress = Math.max(0.0, Math.min(1.0, prog));
        root.icon = ico;
        root.title = titl;
        root.accentColor = accent;
        root.isMuted = Boolean(muted);

        root.active = true;
        hideTimer.restart();
    }

    function showVolume(vol, muted) {
        const pct = Math.round(vol * 100);
        const isMut = Boolean(muted);
        const ico = isMut ? "volume-x" : (pct > 50 ? "volume-2" : (pct > 0 ? "volume-1" : "volume-x"));
        const accent = isMut ? Theme.accentRose : Theme.accentSky;
        const valTxt = isMut ? "MUTED" : (pct + "%");
        const prog = isMut ? 0.0 : Math.min(1.0, vol);

        show("volume", valTxt, prog, ico, "Volume", accent, isMut);
    }

    function showBrightness(pct) {
        const clampedPct = Math.max(0, Math.min(100, pct));
        const ico = "sun";
        const accent = Theme.accentAmber;
        const valTxt = clampedPct + "%";
        const prog = clampedPct / 100.0;

        show("brightness", valTxt, prog, ico, "Brightness", accent, false);
    }

    Connections {
        target: AudioService
        function onVolumeChanged() {
            if (root.ready) {
                root.showVolume(AudioService.volume, AudioService.muted);
            }
        }
        function onMutedChanged() {
            if (root.ready) {
                root.showVolume(AudioService.volume, AudioService.muted);
            }
        }
    }

    Connections {
        target: BrightnessService
        function onPercentChanged() {
            if (root.ready) {
                root.showBrightness(BrightnessService.percent);
            }
        }
    }
}
