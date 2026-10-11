pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int cpuPercent: 0
    property int memPercent: 0
    property int swapPercent: 0

    Process {
        id: statProc
        running: false
        command: ["python3", "-c", "import psutil; print(f'{int(psutil.cpu_percent(interval=0.1))} {int(psutil.virtual_memory().percent)} {int(psutil.swap_memory().percent)}')"]
        stdout: StdioCollector {
            id: collector
            onStreamFinished: {
                const parts = collector.text.trim().split(" ");
                if (parts.length >= 3) {
                    root.cpuPercent = parseInt(parts[0]) || 0;
                    root.memPercent = parseInt(parts[1]) || 0;
                    root.swapPercent = parseInt(parts[2]) || 0;
                }
            }
        }
    }

    Timer {
        id: statTimer
        interval: 2500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!statProc.running) {
                statProc.running = true;
            }
        }
    }
}
