pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool wifiEnabled: true
    property string activeSsid: ""
    property var activeWifi: ({
        ssid: "",
        signal: 0,
        freq: "",
        security: "",
        rate: "",
        ip: "",
        bars: ""
    })
    property var networks: []
    property bool btPowered: false
    property var btDevices: []
    property int connectedBtCount: 0
    property var primaryConnectedBt: null
    property bool refreshing: false

    // Collapsible drawer states in Control Center
    property bool wifiDrawerOpen: false
    property bool btDrawerOpen: false

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

    function rescanWifi() {
        Quickshell.execDetached(["python3", Quickshell.env("HOME") + "/Desktop/personal/custom_quickshell/scripts/get_network_status.py", "--rescan-wifi"]);
        root.refreshing = true;
        refreshTimer.restart();
    }

    function disconnectWifi() {
        Quickshell.execDetached(["python3", Quickshell.env("HOME") + "/Desktop/personal/custom_quickshell/scripts/get_network_status.py", "--disconnect-wifi"]);
        refreshTimer.restart();
    }

    function connectWifi(ssid, password) {
        let args = ["python3", Quickshell.env("HOME") + "/Desktop/personal/custom_quickshell/scripts/get_network_status.py", "--connect-wifi", ssid];
        if (password && password.length > 0) {
            args.push(password);
        }
        Quickshell.execDetached(args);
        refreshTimer.restart();
    }

    function toggleBtDevice(mac, connected) {
        Quickshell.execDetached(["python3", Quickshell.env("HOME") + "/Desktop/personal/custom_quickshell/scripts/get_network_status.py", "--toggle-bt", mac]);
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
                        root.activeWifi = data.activeWifi ?? ({
                            ssid: "",
                            signal: 0,
                            freq: "",
                            security: "",
                            rate: "",
                            ip: "",
                            bars: ""
                        });
                        root.networks = data.networks ?? [];
                        root.btPowered = data.btPowered ?? false;
                        root.btDevices = data.btDevices ?? [];
                        root.connectedBtCount = data.connectedBtCount ?? 0;
                        root.primaryConnectedBt = data.primaryConnectedBt ?? null;
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
