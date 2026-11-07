import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../theme"
import "../services"
import "../components"

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

    // Backdrop click with smooth dimming
    MouseArea {
        anchors.fill: parent
        onClicked: ShellState.sessionDialogOpen = false

        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: 0.68

            Behavior on opacity { NumberAnimation { duration: 200 } }
        }
    }

    // Modal Card
    Rectangle {
        id: modalCard
        width: 580
        implicitHeight: sessionCol.implicitHeight + 48
        anchors.centerIn: parent
        radius: 20
        color: ShellState.glassEnabled ? "transparent" : Theme.bgModal
        border.color: ShellState.glassEnabled ? "transparent" : Theme.borderGlow
        border.width: ShellState.glassEnabled ? 0 : 1

        LiquidGlassSurface {
            radius: 20
            visible: ShellState.glassEnabled
            accentColor: Theme.accentCyan
            showShadow: true
        }

        scale: ShellState.sessionDialogOpen ? 1.0 : 0.95
        opacity: ShellState.sessionDialogOpen ? 1.0 : 0.0

        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 180 } }

        // Block click passthrough
        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        // Focus scope for keyboard shortcuts
        FocusScope {
            anchors.fill: parent
            focus: ShellState.sessionDialogOpen

            Keys.onEscapePressed: {
                ShellState.sessionDialogOpen = false;
            }

            Keys.onPressed: (event) => {
                if (event.key === Qt.Key_Escape) {
                    ShellState.sessionDialogOpen = false;
                    event.accepted = true;
                } else if (event.key === Qt.Key_L) {
                    executeAction(["hyprlock"]);
                    event.accepted = true;
                } else if (event.key === Qt.Key_S) {
                    executeAction(["systemctl", "suspend"]);
                    event.accepted = true;
                } else if (event.key === Qt.Key_E) {
                    executeAction(["hyprctl", "eval", "return hl.dispatch(hl.dsp.exit())"]);
                    event.accepted = true;
                } else if (event.key === Qt.Key_R) {
                    executeAction(["systemctl", "reboot"]);
                    event.accepted = true;
                } else if (event.key === Qt.Key_P) {
                    executeAction(["systemctl", "poweroff"]);
                    event.accepted = true;
                }
            }

            function executeAction(cmd) {
                ShellState.sessionDialogOpen = false;
                Quickshell.execDetached(cmd);
            }

            ColumnLayout {
                id: sessionCol
                anchors.fill: parent
                anchors.margins: 24
                spacing: 20

                // Header
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Icon {
                        name: "power"
                        size: 14
                        color: Theme.accentSky
                    }

                    Text {
                        text: "SYSTEM SESSION"
                        font.family: Theme.fontMono
                        font.pixelSize: 11
                        font.bold: true
                        color: Theme.accentSky
                    }

                    Item { Layout.fillWidth: true }

                    // Keyboard Hint Badge
                    Rectangle {
                        height: 20
                        implicitWidth: escRow.implicitWidth + 10
                        radius: 5
                        color: Theme.bgPill
                        border.color: Theme.borderDim
                        border.width: 1

                        RowLayout {
                            id: escRow
                            anchors.centerIn: parent
                            spacing: 4

                            Text {
                                text: "ESC"
                                font.family: Theme.fontMono
                                font.pixelSize: 9
                                font.bold: true
                                color: Theme.textMuted
                            }
                            Text {
                                text: "close"
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                color: Theme.textMuted
                            }
                        }
                    }
                }

                // Power Buttons Row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Repeater {
                        model: [
                            { name: "Lock", key: "L", icon: "lock", cmd: ["hyprlock"], color: Theme.accentSky, desc: "Secure screen" },
                            { name: "Sleep", key: "S", icon: "moon", cmd: ["systemctl", "suspend"], color: Theme.accentViolet, desc: "Suspend system" },
                            { name: "Logout", key: "E", icon: "log-out", cmd: ["hyprctl", "eval", "return hl.dispatch(hl.dsp.exit())"], color: Theme.accentAmber, desc: "End session" },
                            { name: "Reboot", key: "R", icon: "refresh-cw", cmd: ["systemctl", "reboot"], color: Theme.accentCyan, desc: "Restart machine" },
                            { name: "Shut Down", key: "P", icon: "power", cmd: ["systemctl", "poweroff"], color: Theme.accentRose, desc: "Power off" }
                        ]

                        Rectangle {
                            id: btnCard
                            Layout.fillWidth: true
                            height: 106
                            radius: 14

                            readonly property bool isHovered: btnMouse.containsMouse

                            color: ShellState.glassEnabled
                                ? "transparent"
                                : (isHovered ? Qt.rgba(modelData.color.r, modelData.color.g, modelData.color.b, 0.14) : Theme.bgCard)
                            border.color: ShellState.glassEnabled
                                ? "transparent"
                                : (isHovered ? modelData.color : Theme.borderDim)
                            border.width: ShellState.glassEnabled ? 0 : 1

                            LiquidGlassSurface {
                                radius: 14
                                visible: ShellState.glassEnabled
                                accentColor: modelData.color
                                hovered: btnCard.isHovered
                                showShadow: true
                            }

                            scale: isHovered ? 1.03 : 1.0

                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on border.color { ColorAnimation { duration: 150 } }
                            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 8

                                // Circular Icon Well (Plastic Gem)
                                Rectangle {
                                    Layout.alignment: Qt.AlignHCenter
                                    width: 44
                                    height: 44
                                    radius: 22
                                    color: ShellState.plasticEnabled
                                        ? "transparent"
                                        : (btnCard.isHovered ? Qt.rgba(modelData.color.r, modelData.color.g, modelData.color.b, 0.22) : Theme.bgSurface)
                                    border.color: ShellState.plasticEnabled
                                        ? "transparent"
                                        : (btnCard.isHovered ? modelData.color : Theme.borderDim)
                                    border.width: ShellState.plasticEnabled ? 0 : 1

                                    LiquidGlassSurface {
                                        radius: 22
                                        visible: ShellState.plasticEnabled
                                        accentColor: modelData.color
                                        hovered: btnCard.isHovered
                                        showShadow: false
                                    }

                                    Behavior on color { ColorAnimation { duration: 150 } }
                                    Behavior on border.color { ColorAnimation { duration: 150 } }

                                    Icon {
                                        anchors.centerIn: parent
                                        name: modelData.icon
                                        size: 20
                                        color: modelData.color
                                    }
                                }

                                // Action Label & Key Hint
                                RowLayout {
                                    Layout.alignment: Qt.AlignHCenter
                                    spacing: 4

                                    Text {
                                        text: modelData.name
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: btnCard.isHovered ? modelData.color : Theme.textPrimary
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                    }

                                    // Key badge
                                    Rectangle {
                                        width: 14
                                        height: 14
                                        radius: 3
                                        color: Theme.bgPill
                                        border.color: Theme.borderDim
                                        border.width: 1

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.key
                                            font.family: Theme.fontMono
                                            font.pixelSize: 8
                                            font.bold: true
                                            color: Theme.textMuted
                                        }
                                    }
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
}
