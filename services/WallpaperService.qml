pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../theme"

Singleton {
    id: root

    property string wallpaperDir: Quickshell.env("HOME") + "/Pictures/Wallpapers"
    property var wallpapers: []
    property int currentIndex: 0
    property string manualWallpaper: ""
    property string mode: "theme" // "theme", "manual", "gradient"
    property real dimOpacity: 0.22 // subtle dark scrim for contrast

    readonly property string currentWallpaper: {
        if (root.mode === "theme") {
            return Theme.currentWallpaper;
        } else if (root.mode === "manual") {
            return root.manualWallpaper;
        }
        return "";
    }

    readonly property string currentFileName: {
        const full = root.currentWallpaper;
        if (!full || full.length === 0) return "Procedural Gradient";
        const parts = full.split("/");
        return parts[parts.length - 1];
    }

    function setMode(newMode) {
        if (newMode === "theme" || newMode === "manual" || newMode === "gradient") {
            root.mode = newMode;
        }
    }

    function setWallpaper(path) {
        root.manualWallpaper = path;
        root.mode = "manual";
    }

    function nextWallpaper() {
        if (root.wallpapers.length === 0) return;
        root.currentIndex = (root.currentIndex + 1) % root.wallpapers.length;
        root.manualWallpaper = root.wallpaperDir + "/" + root.wallpapers[root.currentIndex];
        root.mode = "manual";
    }

    function prevWallpaper() {
        if (root.wallpapers.length === 0) return;
        root.currentIndex = (root.currentIndex - 1 + root.wallpapers.length) % root.wallpapers.length;
        root.manualWallpaper = root.wallpaperDir + "/" + root.wallpapers[root.currentIndex];
        root.mode = "manual";
    }

    // Auto-discover wallpapers from ~/Pictures/Wallpapers
    Process {
        id: scanProc
        running: true
        command: ["python3", "-c", "import os, json; dir = os.path.expanduser('~/Pictures/Wallpapers'); files = [f for f in os.listdir(dir) if f.lower().endswith(('.jpg','.jpeg','.png','.webp'))] if os.path.isdir(dir) else []; files.sort(); print(json.dumps(files))"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const list = JSON.parse(text.trim());
                    if (Array.isArray(list) && list.length > 0) {
                        root.wallpapers = list;
                    }
                } catch(e) {}
            }
        }
    }
}
