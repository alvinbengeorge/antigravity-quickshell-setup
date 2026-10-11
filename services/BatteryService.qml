pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

Singleton {
    id: root

    property bool available: true
    property int percentage: 100
    property bool isCharging: false
    property string status: "Full"

    Process {
        id: batProc
        running: false
        command: ["bash", "-c", "if [ -d /sys/class/power_supply/BAT0 ]; then echo $(cat /sys/class/power_supply/BAT0/capacity) $(cat /sys/class/power_supply/BAT0/status); else echo 'none'; fi"]
        stdout: StdioCollector {
            id: collector
            onStreamFinished: {
                const text = collector.text.trim();
                if (text === "none" || text.length === 0) {
                    if (UPower.displayDevice?.isLaptopBattery) {
                        root.available = true;
                        const p = UPower.displayDevice.percentage ?? 1.0;
                        root.percentage = Math.round(p <= 1.0 ? p * 100 : p);
                        root.isCharging = UPower.displayDevice.state === UPowerDeviceState.Charging;
                        root.status = root.isCharging ? "Charging" : "Discharging";
                    } else {
                        root.available = false;
                    }
                    return;
                }
                const parts = text.split(" ");
                if (parts.length >= 2) {
                    root.available = true;
                    root.percentage = parseInt(parts[0]) || 0;
                    root.status = parts[1];
                    root.isCharging = (parts[1] === "Charging" || parts[1] === "Full");
                }
            }
        }
    }

    Timer {
        id: batTimer
        interval: 4000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!batProc.running) {
                batProc.running = true;
            }
        }
    }
}
