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
    property bool isLoaded: false

    property string stateDir: Quickshell.env("HOME") + "/.local/state/quickshell/user"
    property string stateFile: stateDir + "/antigravity-wallpaper.json"

    Timer {
        id: wpWriteTimer
        interval: 50
        repeat: false
        onTriggered: {
            wpFileView.writeAdapter();
        }
    }

    FileView {
        id: wpFileView
        path: root.stateFile

        watchChanges: false
        onAdapterUpdated: wpWriteTimer.restart()
        onLoaded: {
            if (wpAdapter.mode) {
                root.mode = wpAdapter.mode;
            }
            if (wpAdapter.manualWallpaper) {
                root.manualWallpaper = wpAdapter.manualWallpaper;
            }
            root.isLoaded = true;
        }
        onLoadFailed: error => {
            root.isLoaded = true;
            wpAdapter.mode = root.mode;
            wpAdapter.manualWallpaper = root.manualWallpaper;
            wpWriteTimer.restart();
        }

        adapter: JsonAdapter {
            id: wpAdapter
            property string mode: "theme"
            property string manualWallpaper: ""
        }
    }

    function saveState() {
        if (!root.isLoaded) return;
        wpAdapter.mode = root.mode;
        wpAdapter.manualWallpaper = root.manualWallpaper;
        wpWriteTimer.restart();
    }

    onModeChanged: saveState()
    onManualWallpaperChanged: saveState()

    onCurrentWallpaperChanged: {
        if (Theme.fromWallpaperActive && root.currentWallpaper.length > 0) {
            Theme.extractTemporaryWallpaperTheme(root.currentWallpaper);
        }
        Theme.syncHyprlock();
    }

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
            if (root.mode !== "gradient" && newMode === "gradient") {
                root.previousMode = root.mode;
            }
            root.mode = newMode;
        }
    }

    property string previousMode: "manual"

    function toggleGradient() {
        if (root.mode === "gradient") {
            root.mode = (root.previousMode && root.previousMode !== "gradient") ? root.previousMode : "manual";
        } else {
            root.previousMode = (root.mode !== "gradient") ? root.mode : "manual";
            root.mode = "gradient";
        }
    }

    function setWallpaper(path) {
        root.manualWallpaper = path;
        root.previousMode = "manual";
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
