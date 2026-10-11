import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../theme"
import "../services"

PanelWindow {
    id: sessionWindow

    visible: ShellState.sessionDialogOpen
    color: "transparent"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "quickshell:session"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: ShellState.sessionDialogOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    // Backdrop click
    MouseArea {
        anchors.fill: parent
        onClicked: ShellState.sessionDialogOpen = false

        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: 0.65
        }
    }

    // Modal Card
    Rectangle {
        width: 480
        implicitHeight: sessionCol.implicitHeight + 36
        anchors.centerIn: parent
        radius: Theme.cardRadius
        color: Theme.bgModal
        border.color: Theme.borderGlow
        border.width: 1

        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        ColumnLayout {
            id: sessionCol
            anchors.fill: parent
            anchors.margins: 24
            spacing: 20

            // Title
            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "SYSTEM SESSION"
                    font.family: Theme.fontMono
                    font.pixelSize: 12
                    font.bold: true
                    color: Theme.accentSky
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: "Esc to close"
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    color: Theme.textMuted
                }
            }

            // Power Buttons Row
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Repeater {
                    model: [
                        { name: "Lock", icon: "🔒", cmd: ["loginctl", "lock-session"], color: Theme.accentSky },
                        { name: "Logout", icon: "🚪", cmd: ["hyprctl", "dispatch", "exit"], color: Theme.accentAmber },
                        { name: "Sleep", icon: "🌙", cmd: ["systemctl", "suspend"], color: Theme.accentViolet },
                        { name: "Reboot", icon: "🔄", cmd: ["systemctl", "reboot"], color: Theme.accentCyan },
                        { name: "Power Off", icon: "⏻", cmd: ["systemctl", "poweroff"], color: Theme.accentRose }
                    ]

                    Rectangle {
                        id: btnItem
                        Layout.fillWidth: true
                        height: 72
                        radius: 12
                        color: btnMouse.containsMouse ? Theme.bgHover : Theme.bgPill
                        border.color: btnMouse.containsMouse ? modelData.color : Theme.borderDim
                        border.width: 1

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 4

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: modelData.icon
                                font.pixelSize: 20
                                color: modelData.color
                            }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: modelData.name
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                font.bold: true
                                color: Theme.textPrimary
                            }
                        }

                        MouseArea {
                            id: btnMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                ShellState.sessionDialogOpen = false;
                                Quickshell.execDetached(modelData.cmd);
                            }
                        }
                    }
                }
            }
        }
    }
}
