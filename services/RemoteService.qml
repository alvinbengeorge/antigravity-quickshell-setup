pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../theme"

Singleton {
    id: root

    property bool isOnline: false
    property string remoteUrl: "https://192.168.0.191.nip.io:3457"
    property string dashedUrl: "https://192-168-0-191.nip.io:3457"
    property string mdnsUrl: "https://fedora.local:3457"
    property string ip: "192.168.0.191"
    property int port: 3457
    property string qrPath: Quickshell.env("HOME") + "/.local/state/quickshell/user/remote_qr.png"
    property real lastUpdate: 0

    readonly property string stateDir: Quickshell.env("HOME") + "/.local/state/quickshell/user"
    readonly property string infoFile: stateDir + "/remote_info.json"

    // Process to check live systemd unit status
    Process {
        id: statusProc
        running: false
        command: ["systemctl", "--user", "is-active", "antigravity-remote"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.isOnline = (text.trim() === "active");
            }
        }
    }

    Timer {
        id: pollTimer
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!statusProc.running) statusProc.running = true;
        }
    }

    FileView {
        id: remoteInfoView
        path: root.infoFile
        watchChanges: true
        onLoaded: {
            if (remoteAdapter.url) root.remoteUrl = remoteAdapter.url;
            if (remoteAdapter.dashedUrl) root.dashedUrl = remoteAdapter.dashedUrl;
            if (remoteAdapter.mdnsUrl) root.mdnsUrl = remoteAdapter.mdnsUrl;
            if (remoteAdapter.ip) root.ip = remoteAdapter.ip;
            if (remoteAdapter.port) root.port = remoteAdapter.port;
            if (remoteAdapter.timestamp) root.lastUpdate = remoteAdapter.timestamp;
        }

        adapter: JsonAdapter {
            id: remoteAdapter
            property string url: ""
            property string dashedUrl: ""
            property string mdnsUrl: ""
            property string ip: ""
            property int port: 3457
            property real timestamp: 0
        }
    }

    function toggleDaemon() {
        if (root.isOnline) {
            Quickshell.execDetached(["systemctl", "--user", "stop", "antigravity-remote"]);
        } else {
            Quickshell.execDetached(["systemctl", "--user", "start", "antigravity-remote"]);
        }
        restartTimer.start();
    }

    function restartDaemon() {
        Quickshell.execDetached(["systemctl", "--user", "restart", "antigravity-remote"]);
        restartTimer.start();
    }

    Timer {
        id: restartTimer
        interval: 1200
        onTriggered: {
            if (!statusProc.running) statusProc.running = true;
        }
    }
}
