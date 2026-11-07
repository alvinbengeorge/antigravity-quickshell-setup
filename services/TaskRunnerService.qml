pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var tasks: []
    property bool loading: false
    property string runningTaskId: ""
    property string activeCategory: "all"
    property string lastExecutedResult: ""

    readonly property string scriptPath: Quickshell.env("HOME") + "/Desktop/personal/custom_quickshell/scripts/task_runner.py"

    // Process to list tasks
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
                            root.tasks = data;
                        }
                    }
                } catch(e) {
                    console.log("Error loading tasks:", e);
                }
            }
        }
    }

    // Process to run task
    Process {
        id: runProc
        running: false
        property string targetTaskId: ""
        command: ["python3", root.scriptPath, "run", targetTaskId]
        stdout: StdioCollector {
            id: runCollector
            onStreamFinished: {
                root.runningTaskId = "";
                try {
                    const raw = runCollector.text.trim();
                    if (raw.length > 0) {
                        const res = JSON.parse(raw);
                        root.lastExecutedResult = res.status ?? "ok";
                    }
                } catch(e) {
                    root.lastExecutedResult = runCollector.text;
                }
            }
        }
    }

    // Process to save/create task
    Process {
        id: saveProc
        running: false
        property string payload: ""
        command: ["python3", root.scriptPath, "create", payload]
        stdout: StdioCollector {
            onStreamFinished: {
                root.refresh();
            }
        }
    }

    // Process to delete task
    Process {
        id: deleteProc
        running: false
        property string targetTaskId: ""
        command: ["python3", root.scriptPath, "delete", targetTaskId]
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

    function runTask(taskId: string): void {
        root.runningTaskId = taskId;
        runProc.targetTaskId = taskId;
        runProc.running = true;
    }

    function createTask(name: string, command: string, interactive: bool, category: string): void {
        const payload = JSON.stringify({
            name: name,
            command: command,
            interactive: interactive,
            category: category || "General"
        });
        saveProc.payload = payload;
        saveProc.running = true;
    }

    function deleteTask(taskId: string): void {
        deleteProc.targetTaskId = taskId;
        deleteProc.running = true;
    }

    Component.onCompleted: {
        refresh();
    }
}
