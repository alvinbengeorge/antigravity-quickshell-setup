pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int cpuPercent: 0
    property int memPercent: 0
    property int swapPercent: 0
    property string netDown: "0B"
    property string netUp: "0B"

    readonly property string rustBinary: Quickshell.env("HOME") + "/Desktop/personal/custom_quickshell/bin/fast_system_stats"

    Process {
        id: statProc
        running: false
        command: [root.rustBinary]
        stdout: StdioCollector {
            id: collector
            onStreamFinished: {
                try {
                    const text = collector.text.trim();
                    if (text.length > 0) {
                        const data = JSON.parse(text);
                        root.cpuPercent = data.cpu ?? 0;
                        root.memPercent = data.mem ?? 0;
                        root.swapPercent = data.swap ?? 0;
                        root.netDown = data.down ?? "0B";
                        root.netUp = data.up ?? "0B";
                    }
                } catch (e) {
                    console.log("SystemStats parse error:", e);
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
