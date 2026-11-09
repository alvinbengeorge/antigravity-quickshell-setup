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
    property int timeToEmpty: 0
    property int timeToFull: 0
    property real energyRate: 0.0
    property int displayMode: 0 // 0: percentage, 1: time, 2: power draw (watts)
    property bool showTimeRemaining: displayMode === 1

    readonly property string formattedTimeRemaining: {
        const secs = root.isCharging ? root.timeToFull : root.timeToEmpty;
        if (secs > 0) {
            const h = Math.floor(secs / 3600);
            const m = Math.floor((secs % 3600) / 60);
            return h + "h " + m + "min";
        }
        if (root.isCharging) {
            return (root.percentage >= 99 || root.status === "Full") ? "Full" : "Charging";
        }
        return root.percentage + "%";
    }

    readonly property string formattedWatts: {
        if (root.energyRate <= 0.0) return "0.0W";
        const w = (Math.round(root.energyRate * 10) / 10).toFixed(1);
        return (root.isCharging ? "+" : "") + w + "W";
    }

    readonly property string displayText: {
        if (displayMode === 1) return formattedTimeRemaining;
        if (displayMode === 2) return formattedWatts;
        return percentage + "%";
    }

    function cycleDisplayMode(): void {
        root.displayMode = (root.displayMode + 1) % 3;
    }

    function toggleDisplayMode(): void {
        cycleDisplayMode();
    }

    Process {
        id: batProc
        running: false
        command: ["python3", "-c", "import json, os\ncap, stat = 0, 'Unknown'\ntry:\n    with open('/sys/class/power_supply/BAT0/capacity') as f: cap = int(f.read().strip())\n    with open('/sys/class/power_supply/BAT0/status') as f: stat = f.read().strip()\nexcept Exception: pass\nte, tf, rate = 0, 0, 0.0\ntry:\n    import dbus\n    b = dbus.SystemBus()\n    d = b.get_object('org.freedesktop.UPower', '/org/freedesktop/UPower/devices/DisplayDevice')\n    p = dbus.Interface(d, 'org.freedesktop.DBus.Properties')\n    te = int(p.Get('org.freedesktop.UPower.Device', 'TimeToEmpty'))\n    tf = int(p.Get('org.freedesktop.UPower.Device', 'TimeToFull'))\n    rate = float(p.Get('org.freedesktop.UPower.Device', 'EnergyRate'))\nexcept Exception: pass\nprint(json.dumps({'capacity': cap, 'status': stat, 'time_empty': te, 'time_full': tf, 'energy_rate': round(rate, 1)}))"]
        stdout: StdioCollector {
            id: collector
            onStreamFinished: {
                const text = collector.text.trim();
                try {
                    const data = JSON.parse(text);
                    root.available = true;
                    root.percentage = data.capacity || 0;
                    root.status = data.status || "Unknown";
                    root.isCharging = (data.status === "Charging" || data.status === "Full");
                    if (data.time_empty > 0) root.timeToEmpty = data.time_empty;
                    if (data.time_full > 0) root.timeToFull = data.time_full;
                    if (data.energy_rate !== undefined) root.energyRate = data.energy_rate;
                } catch(e) {
                    if (UPower.displayDevice?.isLaptopBattery) {
                        root.available = true;
                        const p = UPower.displayDevice.percentage ?? 1.0;
                        root.percentage = Math.round(p <= 1.0 ? p * 100 : p);
                        root.isCharging = UPower.displayDevice.state === UPowerDeviceState.Charging;
                        root.status = root.isCharging ? "Charging" : "Discharging";
                        if (UPower.displayDevice.timeToEmpty > 0) root.timeToEmpty = UPower.displayDevice.timeToEmpty;
                        if (UPower.displayDevice.timeToFull > 0) root.timeToFull = UPower.displayDevice.timeToFull;
                        if (UPower.displayDevice.changeRate > 0) root.energyRate = UPower.displayDevice.changeRate;
                    }
                }
            }
        }
    }

    Process {
        id: openStatsProc
        running: false
        command: ["bash", "-c", "python3 -c \"\nimport subprocess, json\ntry:\n    clients = json.loads(subprocess.check_output(['hyprctl', 'clients', '-j']))\n    p = next((c for c in clients if 'org.gnome.PowerStats' in c.get('class', '')), None)\n    if p:\n        subprocess.run(['hyprctl', 'repl', f\\\"hl.dispatch(hl.dsp.focus({{ window = '{p['address']}' }}))\\\"], capture_output=True)\n    else:\n        subprocess.Popen(['setsid', 'gnome-power-statistics'])\nexcept Exception:\n    subprocess.Popen(['setsid', 'gnome-power-statistics'])\n\""]
    }

    function openPowerStatistics() {
        if (!openStatsProc.running) {
            openStatsProc.running = true;
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
