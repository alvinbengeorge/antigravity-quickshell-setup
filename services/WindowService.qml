pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var windows: []
    property bool loading: false
    property int selectedIndex: 0

    readonly property string scriptPath: Quickshell.env("HOME") + "/Desktop/personal/custom_quickshell/scripts/window_switcher.py"

    // Process to query open windows
    Process {
        id: listProc
        running: false
        command: ["python3", root.scriptPath, "list"]
        stdout: StdioCollector {
            id: listCollector
            onStreamFinished: {
                root.loading = false;
                try {
                    const raw = listCollector.text.trim();
                    if (raw.length > 0) {
                        const data = JSON.parse(raw);
                        if (Array.isArray(data)) {
                            root.windows = data;
                            if (root.selectedIndex >= data.length) {
                                root.selectedIndex = 0;
                            }
                        }
                    }
                } catch(e) {
                    console.log("Error loading windows:", e);
                }
            }
        }
    }

    // Process to focus window
    Process {
        id: focusProc
        running: false
        property string targetAddr: ""
        command: ["python3", root.scriptPath, "focus", targetAddr]
    }

    // Process to close window
    Process {
        id: closeProc
        running: false
        property string targetAddr: ""
        command: ["python3", root.scriptPath, "close", targetAddr]
        stdout: StdioCollector {
            onStreamFinished: {
                root.refresh();
            }
        }
    }

    function refresh(): void {
        if (!listProc.running) {
            root.loading = true;
            listProc.running = true;
        }
    }

    function focusWindow(address: string): void {
        focusProc.targetAddr = address;
        focusProc.running = true;
    }

    function closeWindow(address: string): void {
        closeProc.targetAddr = address;
        closeProc.running = true;
    }

    Component.onCompleted: {
        refresh();
    }
}
