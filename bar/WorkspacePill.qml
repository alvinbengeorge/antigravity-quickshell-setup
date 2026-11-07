import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../theme"
import "../services"
import "../components"

Rectangle {
    id: root
    height: 34
    radius: height / 2
    color: ShellState.glassEnabled ? "transparent" : Theme.bgPill
    border.color: ShellState.glassEnabled ? "transparent" : Theme.borderDim
    border.width: ShellState.glassEnabled ? 0 : 1

    LiquidGlassSurface {
        radius: root.radius
        visible: ShellState.glassEnabled
        accentColor: Theme.accentEmerald
    }

    property ShellScreen screen
    readonly property var hyprMonitor: screen ? Hyprland.monitorFor(screen) : null
    readonly property int activeWsId: hyprMonitor?.activeWorkspace?.id ?? (Hyprland.focusedWorkspace?.id ?? 1)

    implicitWidth: mainRow.width + 20

    Row {
        id: mainRow
        anchors.centerIn: parent
        spacing: 8

        // Gemini / Antigravity Icon Button (Plastic Gem)
        Item {
            id: geminiBtn
            width: 22
            height: 22
            anchors.verticalCenter: parent.verticalCenter

            LiquidGlassSurface {
                radius: 11
                visible: ShellState.plasticEnabled
                accentColor: geminiMouse.containsMouse ? Theme.accentCyan : Theme.accentViolet
                hovered: geminiMouse.containsMouse
                pressed: geminiMouse.pressed
                showShadow: false
            }

            Rectangle {
                anchors.fill: parent
                radius: 11
                visible: !ShellState.plasticEnabled
                color: geminiMouse.containsMouse ? Theme.accentCyan : Theme.accentViolet
                Behavior on color { ColorAnimation { duration: 120 } }
            }

            Icon {
                anchors.centerIn: parent
                name: "sparkles"
                size: 12
                color: ShellState.plasticEnabled
                    ? (geminiMouse.containsMouse ? Theme.accentCyan : Theme.accentViolet)
                    : Theme.textOnAccent
                Behavior on color { ColorAnimation { duration: 120 } }
            }

            MouseArea {
                id: geminiMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: ShellState.toggleLauncher()
            }
        }

        // Divider
        Rectangle {
            width: 1
            height: 14
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.borderDim
        }

        // Workspace Dots Row (Standard Row prevents any overlapping)
        Row {
            id: dotsRow
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            Repeater {
                model: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

                Item {
                    id: wsDot
                    required property int modelData

                    readonly property bool isCurrent: root.activeWsId === wsDot.modelData
                    
                    width: isCurrent ? 24 : 14
                    height: 14
                    anchors.verticalCenter: parent.verticalCenter

                    Behavior on width {
                        NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
                    }

                    // 3D Plastic Surface for active workspace or hovered button
                    LiquidGlassSurface {
                        radius: 7
                        visible: ShellState.plasticEnabled && (wsDot.isCurrent || mouseArea.containsMouse)
                        accentColor: wsDot.isCurrent ? Theme.accentViolet : Theme.accentSky
                        hovered: mouseArea.containsMouse
                        pressed: mouseArea.pressed
                        showShadow: false
                    }

                    // Translucent plastic bead for inactive idle workspaces in plastic mode
                    Rectangle {
                        anchors.fill: parent
                        radius: 7
                        visible: ShellState.plasticEnabled && !wsDot.isCurrent && !mouseArea.containsMouse
                        color: Qt.rgba(0.20, 0.28, 0.40, 0.25)
                        border.color: Qt.rgba(1.0, 1.0, 1.0, 0.14)
                        border.width: 1
                    }

                    // Standard flat styling when plastic mode is disabled
                    Rectangle {
                        anchors.fill: parent
                        radius: 7
                        visible: !ShellState.plasticEnabled
                        color: wsDot.isCurrent ? Theme.accentViolet : (mouseArea.containsMouse ? Theme.bgHover : "#2D3748")
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: wsDot.modelData.toString()
                        font.family: Theme.fontFamily
                        font.pixelSize: 9
                        font.bold: wsDot.isCurrent
                        color: wsDot.isCurrent
                            ? (ShellState.plasticEnabled ? Theme.accentViolet : Theme.textOnAccent)
                            : (mouseArea.containsMouse ? Theme.textPrimary : Theme.textMuted)
                        visible: wsDot.isCurrent || mouseArea.containsMouse
                    }

                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                        onClicked: mouse => {
                            if (mouse.button === Qt.RightButton || mouse.button === Qt.MiddleButton || (mouse.modifiers & Qt.ShiftModifier)) {
                                // Move active focused window to this workspace
                                Hyprland.dispatch("hl.dsp.window.move({ workspace = " + wsDot.modelData + " })");
                                Quickshell.execDetached(["hyprctl", "eval", "return hl.dispatch(hl.dsp.window.move({ workspace = " + wsDot.modelData + " }))"]);
                            } else {
                                // Switch / move focus to this workspace
                                Hyprland.dispatch("hl.dsp.focus({ workspace = " + wsDot.modelData + " })");
                                Quickshell.execDetached(["hyprctl", "eval", "return hl.dispatch(hl.dsp.focus({ workspace = " + wsDot.modelData + " }))"]);
                            }
                        }
                    }
                }
            }
        }
    }

    // Mouse Wheel on Workspace Pill to cycle workspaces
    MouseArea {
        anchors.fill: parent
        z: -1
        hoverEnabled: true
        onWheel: wheel => {
            let nextWs = root.activeWsId;
            if (wheel.angleDelta.y > 0) {
                nextWs = Math.max(1, root.activeWsId - 1);
            } else if (wheel.angleDelta.y < 0) {
                nextWs = Math.min(10, root.activeWsId + 1);
            }
            if (nextWs !== root.activeWsId) {
                Hyprland.dispatch("hl.dsp.focus({ workspace = " + nextWs + " })");
                Quickshell.execDetached(["hyprctl", "eval", "return hl.dispatch(hl.dsp.focus({ workspace = " + nextWs + " }))"]);
            }
        }
    }
}
