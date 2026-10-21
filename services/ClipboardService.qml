pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var rawItems: []
    property var items: []
    property string selectedId: ""
    property string previewContent: ""
    property bool isLoading: false

    function refresh() {
        if (root.isLoading) return;
        root.isLoading = true;
        fetchProc.running = true;
    }

    Process {
        id: fetchProc
        running: false
        command: ["python3", "-c", "import subprocess, json; res = subprocess.run(['cliphist', 'list'], capture_output=True, text=True); lines = res.stdout.strip().splitlines()[:100]; out = [];\nfor line in lines:\n    parts = line.split('\t', 1)\n    if len(parts) == 2:\n        i, t = parts[0], parts[1]\n        kind = 'image' if t.startswith('[[ binary') else ('url' if t.startswith('http://') or t.startswith('https://') else ('code' if any(k in t for k in ['def ', 'function', 'class ', 'import ', '{', '}', 'const ', 'var ']) else 'text'))\n        out.append({'id': i, 'text': t, 'type': kind})\nprint(json.dumps(out))"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.isLoading = false;
                try {
                    const parsed = JSON.parse(text.trim());
                    if (Array.isArray(parsed)) {
                        root.rawItems = parsed;
                        root.items = parsed;
                        if (parsed.length > 0 && root.selectedId.length === 0) {
                            root.selectItem(parsed[0].id);
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
        root.items = root.rawItems.filter(item => item.text.toLowerCase().includes(q));
    }

    function selectItem(id) {
        root.selectedId = id;
        decodeProc.command = ["cliphist", "decode", id];
        decodeProc.running = true;
    }

    Process {
        id: decodeProc
        running: false
        command: []
        stdout: StdioCollector {
            onStreamFinished: {
                root.previewContent = text;
            }
        }
    }

    function copyItem(id) {
        Quickshell.execDetached([
            "python3", "-c",
            `import subprocess; p1 = subprocess.Popen(['cliphist', 'decode', '${id}'], stdout=subprocess.PIPE); p2 = subprocess.run(['wl-copy'], stdin=p1.stdout)`
        ]);
        ShellState.clipboardOpen = false;
    }

    function deleteItem(id, rawText) {
        Quickshell.execDetached([
            "python3", "-c",
            `import subprocess; p = subprocess.Popen(['cliphist', 'delete'], stdin=subprocess.PIPE, text=True); p.communicate('${id}\\t${rawText}\\n')`
        ]);
        root.rawItems = root.rawItems.filter(i => i.id !== id);
        root.items = root.items.filter(i => i.id !== id);
        if (root.items.length > 0) {
            root.selectItem(root.items[0].id);
        } else {
            root.previewContent = "";
        }
    }

    function clearAll() {
        Quickshell.execDetached(["cliphist", "wipe"]);
        root.rawItems = [];
        root.items = [];
        root.previewContent = "";
        root.selectedId = "";
    }
}
