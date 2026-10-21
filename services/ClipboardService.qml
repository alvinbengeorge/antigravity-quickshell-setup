pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var rawItems: []
    property var items: []
    property var selectedItem: null
    property string selectedId: ""
    property string previewText: ""
    property string previewImagePath: ""
    property bool isImage: false
    property bool isLoading: false

    readonly property string helperScript: Quickshell.env("HOME") + "/Desktop/personal/custom_quickshell/scripts/cliphist_helper.py"

    function refresh() {
        if (root.isLoading) return;
        root.isLoading = true;
        fetchProc.running = true;
    }

    Process {
        id: fetchProc
        running: false
        command: ["python3", root.helperScript, "list", "80"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.isLoading = false;
                try {
                    const parsed = JSON.parse(text.trim());
                    if (Array.isArray(parsed)) {
                        root.rawItems = parsed;
                        root.items = parsed;
                        if (parsed.length > 0) {
                            // Re-select current or first
                            let found = false;
                            if (root.selectedId) {
                                for (let i = 0; i < parsed.length; i++) {
                                    if (parsed[i].id === root.selectedId) {
                                        root.selectItem(parsed[i]);
                                        found = true;
                                        break;
                                    }
                                }
                            }
                            if (!found) {
                                root.selectItem(parsed[0]);
                            }
                        }
                    }
                } catch(e) {}
            }
        }
    }

    function search(query) {
        if (!query || query.trim().length === 0) {
            root.items = root.rawItems;
            return;
        }
        const q = query.toLowerCase();
        root.items = root.rawItems.filter(item => {
            return (item.text && item.text.toLowerCase().includes(q)) ||
                   (item.meta && item.meta.toLowerCase().includes(q)) ||
                   (item.type && item.type.toLowerCase().includes(q));
        });
    }

    function selectItem(item) {
        if (!item) return;
        root.selectedItem = item;
        root.selectedId = item.id;

        if (item.type === "image") {
            root.isImage = true;
            root.previewText = "";
            root.previewImagePath = item.thumb ? ("file://" + item.thumb) : "";
        } else {
            root.isImage = false;
            root.previewImagePath = "";
            decodeProc.command = ["python3", root.helperScript, "decode-text", item.id];
            decodeProc.running = true;
        }
    }

    Process {
        id: decodeProc
        running: false
        command: []
        stdout: StdioCollector {
            onStreamFinished: {
                root.previewText = text;
            }
        }
    }

    function copyItem(id) {
        Quickshell.execDetached(["python3", root.helperScript, "copy", id]);
        ShellState.clipboardOpen = false;
    }

    function deleteItem(id, rawText) {
        Quickshell.execDetached(["python3", root.helperScript, "delete", id, rawText || ""]);
        root.rawItems = root.rawItems.filter(i => i.id !== id);
        root.items = root.items.filter(i => i.id !== id);
        if (root.items.length > 0) {
            root.selectItem(root.items[0]);
        } else {
            root.selectedItem = null;
            root.selectedId = "";
            root.previewText = "";
            root.previewImagePath = "";
            root.isImage = false;
        }
    }

    function clearAll() {
        Quickshell.execDetached(["python3", root.helperScript, "wipe"]);
        root.rawItems = [];
        root.items = [];
        root.selectedItem = null;
        root.selectedId = "";
        root.previewText = "";
        root.previewImagePath = "";
        root.isImage = false;
    }
}
