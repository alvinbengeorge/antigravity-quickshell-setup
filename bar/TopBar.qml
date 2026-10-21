import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../theme"
import "../services"

PanelWindow {
    id: barWindow

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: 50
    exclusiveZone: 46
    color: "transparent"

    WlrLayershell.namespace: "quickshell:antigravity:bar"
    WlrLayershell.layer: WlrLayer.Top

    Item {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.topMargin: 6

        // Center Island (Antigravity Dynamic Island)
        AntigravityIsland {
            id: centerIsland
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
        }

        // Left Island (Workspaces, Active Window & Active Apps / System Tray)
        RowLayout {
            id: leftRow
            anchors.left: parent.left
            anchors.right: centerIsland.left
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            WorkspacePill {
                id: wsPill
                screen: barWindow.screen
            }

            ActiveWindowPill {
                id: activeWinPill
                maxAllowedWidth: Math.max(60, leftRow.width - wsPill.width - (trayPill.visible ? trayPill.width + leftRow.spacing : 0) - leftRow.spacing - 12)
            }

            SystemTrayPill {
                id: trayPill
            }

            Item {
                Layout.fillWidth: true
            }
        }

        // Right Island (System Stats, Audio & Clock)
        RowLayout {
            id: rightRow
            anchors.right: parent.right
            anchors.left: centerIsland.right
            anchors.leftMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Item {
                Layout.fillWidth: true
            }

            SystemPill {}
            WifiPill {}
            BatteryPill {}
            ClockPill {}
        }
    }
}
