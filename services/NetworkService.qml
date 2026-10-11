pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool wifiEnabled: true
    property string activeSsid: ""
    property var networks: []
    property bool btPowered: false
    property var btDevices: []
    property bool refreshing: false

    function refresh() {
        if (!statusProc.running) {
            root.refreshing = true;
            statusProc.running = true;
        }
    }

    function toggleWifi() {
        const cmd = root.wifiEnabled ? ["nmcli", "radio", "wifi", "off"] : ["nmcli", "radio", "wifi", "on"];
        Quickshell.execDetached(cmd);
        refreshTimer.restart();
    }

    function toggleBluetooth() {
        const cmd = root.btPowered ? ["bluetoothctl", "power", "off"] : ["bluetoothctl", "power", "on"];
        Quickshell.execDetached(cmd);
        refreshTimer.restart();
    }

    function connectWifi(ssid) {
        Quickshell.execDetached(["nmcli", "device", "wifi", "connect", ssid]);
        refreshTimer.restart();
    }

    function toggleBtDevice(mac, connected) {
        const action = connected ? "disconnect" : "connect";
        Quickshell.execDetached(["bluetoothctl", action, mac]);
        refreshTimer.restart();
    }

    Process {
        id: statusProc
        running: false
        command: ["python3", Quickshell.env("HOME") + "/Desktop/personal/custom_quickshell/scripts/get_network_status.py"]
        stdout: StdioCollector {
            id: collector
            onStreamFinished: {
                root.refreshing = false;
                try {
                    const raw = collector.text.trim();
                    if (raw.length > 0) {
                        const data = JSON.parse(raw);
                        root.wifiEnabled = data.wifiEnabled ?? true;
                        root.activeSsid = data.activeSsid ?? "";
                        root.networks = data.networks ?? [];
                        root.btPowered = data.btPowered ?? false;
                        root.btDevices = data.btDevices ?? [];
                    }
                } catch (e) {
                    console.log("NetworkService parse error:", e);
                }
            }
        }
    }

    Timer {
        id: refreshTimer
        interval: 6000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!statusProc.running) {
                statusProc.running = true;
            }
        }
    }
}
