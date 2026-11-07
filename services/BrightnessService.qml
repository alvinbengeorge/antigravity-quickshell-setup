pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int percent: 40
    property int current: 38400
    property int max: 96000
    property bool isLoaded: false
    property bool showNext: false

    readonly property string backlightDir: "/sys/class/backlight/intel_backlight"

    // Process to query brightness directly
    Process {
        id: queryProc
        running: false
        command: ["brightnessctl", "-d", "intel_backlight", "-m"]
        stdout: StdioCollector {
            id: collector
            onStreamFinished: {
                const text = collector.text.trim();
                if (text.length > 0) {
                    // Output format: intel_backlight,backlight,38400,40%,96000
                    const parts = text.split(",");
                    if (parts.length >= 5) {
                        const cur = parseInt(parts[2]) || root.current;
                        const pctStr = parts[3].replace("%", "").trim();
                        const pct = parseInt(pctStr) || 40;
                        const mx = parseInt(parts[4]) || root.max;

                        root.current = cur;
                        root.max = mx;
                        const changed = (root.percent !== pct);
                        root.percent = pct;
                        root.isLoaded = true;
                        if (root.showNext || (root.isLoaded && changed)) {
                            root.showNext = false;
                            OsdService.showBrightness(pct);
                        }
                    }
                }
            }
        }
    }

    // Refresh on startup and periodically (every 2.5s) to stay in sync with external changes
    Timer {
        id: pollTimer
        interval: 2500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!queryProc.running) {
                queryProc.running = true;
            }
        }
    }

    function refresh(forceShow) {
        if (forceShow) root.showNext = true;
        if (!queryProc.running) {
            queryProc.running = true;
        }
        if (forceShow) {
            OsdService.showBrightness(root.percent);
        }
    }

    function increase() {
        Quickshell.execDetached(["brightnessctl", "-d", "intel_backlight", "set", "5%+"]);
        // Optimistic update
        root.percent = Math.min(100, root.percent + 5);
        OsdService.showBrightness(root.percent);
        queryProc.running = true;
    }

    function decrease() {
        Quickshell.execDetached(["brightnessctl", "-d", "intel_backlight", "set", "5%-"]);
        // Optimistic update
        root.percent = Math.max(1, root.percent - 5);
        OsdService.showBrightness(root.percent);
        queryProc.running = true;
    }

    function setPercent(pct) {
        const clamped = Math.max(1, Math.min(100, pct));
        Quickshell.execDetached(["brightnessctl", "-d", "intel_backlight", "set", clamped + "%"]);
        root.percent = clamped;
        OsdService.showBrightness(root.percent);
        queryProc.running = true;
    }
}
