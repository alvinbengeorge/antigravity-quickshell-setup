import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../theme"
import "../services"
import "../components"

PanelWindow {
    id: previewWindow

    visible: (ShellState.workspacePreviewOpen || ShellState.workspacePreviewHovered) && ShellState.hoveredWorkspace > 0
    color: "transparent"

    // Anchored right below the top-bar (strictly y >= 46) so it NEVER steals hover from the bar
    anchors {
        top: true
        left: true
        right: true
    }

    margins {
        top: 48
    }

    implicitHeight: 380

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "quickshell:workspacepreview"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    readonly property var wsWindows: WindowService.windowsForWorkspace(ShellState.hoveredWorkspace)
    readonly property bool isCurrentWs: ShellState.hoveredWorkspace === (Hyprland.focusedWorkspace?.id ?? 1)

    Timer {
        id: cardLeaveTimer
        interval: 260
        repeat: false
        onTriggered: {
            if (!cardBridgeMouse.containsMouse) {
                ShellState.workspacePreviewHovered = false;
                ShellState.workspacePreviewOpen = false;
            }
        }
    }

    // Floating Workspace Preview Card
    Item {
        id: cardContainer
        x: Math.max(16, Math.min(previewWindow.width - card.width - 16, ShellState.hoveredWorkspaceGlobalX - card.width / 2))
        y: 4
        width: card.width
        height: card.height

        Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

        // Hover bridge area around the card to keep it open when moving mouse into it
        MouseArea {
            id: cardBridgeMouse
            anchors.fill: parent
            anchors.margins: -10
            anchors.topMargin: -8
            z: -1
            hoverEnabled: true
            onEntered: {
                cardLeaveTimer.stop();
                ShellState.workspacePreviewHovered = true;
            }
            onExited: {
                cardLeaveTimer.restart();
            }
        }

        // Ambient depth glow
        Rectangle {
            anchors.centerIn: parent
            width: parent.width + 12
            height: parent.height + 12
            radius: 18
            color: previewWindow.isCurrentWs ? Theme.accentEmerald : Theme.accentViolet
            opacity: 0.24
            z: -2
            Behavior on color { ColorAnimation { duration: 250 } }
        }

        // Card Surface
        Rectangle {
            id: card
            width: 270
            height: cardCol.implicitHeight + 24
            radius: 14
            color: ShellState.glassEnabled ? "transparent" : Qt.rgba(Theme.bgSurface.r, Theme.bgSurface.g, Theme.bgSurface.b, 0.94)
            border.color: ShellState.glassEnabled ? "transparent" : Qt.rgba((previewWindow.isCurrentWs ? Theme.accentEmerald : Theme.accentViolet).r, (previewWindow.isCurrentWs ? Theme.accentEmerald : Theme.accentViolet).g, (previewWindow.isCurrentWs ? Theme.accentEmerald : Theme.accentViolet).b, 0.45)
            border.width: ShellState.glassEnabled ? 0 : 1
            clip: true

            LiquidGlassSurface {
                radius: 14
                visible: ShellState.glassEnabled
                accentColor: previewWindow.isCurrentWs ? Theme.accentEmerald : Theme.accentViolet
                showShadow: true
            }

            ColumnLayout {
                id: cardCol
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 12
                spacing: 8

                // Header Row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Rectangle {
                        height: 20
                        implicitWidth: wsLabel.implicitWidth + 12
                        radius: 6
                        color: Qt.alpha(previewWindow.isCurrentWs ? Theme.accentEmerald : Theme.accentViolet, 0.20)
                        border.color: previewWindow.isCurrentWs ? Theme.accentEmerald : Theme.accentViolet
                        border.width: 1

                        Text {
                            id: wsLabel
                            anchors.centerIn: parent
                            text: "WORKSPACE " + ShellState.hoveredWorkspace
                            font.family: Theme.fontMono
                            font.pixelSize: 9
                            font.bold: true
                            color: previewWindow.isCurrentWs ? Theme.accentEmerald : Theme.accentViolet
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: previewWindow.isCurrentWs ? "● ACTIVE" : (previewWindow.wsWindows.length > 0 ? (previewWindow.wsWindows.length + (previewWindow.wsWindows.length === 1 ? " window" : " windows")) : "Empty")
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        font.bold: previewWindow.isCurrentWs
                        color: previewWindow.isCurrentWs ? Theme.accentEmerald : Theme.textMuted
                    }
                }

                // Divider
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Theme.borderDim
                }

                // Windows List Section (when workspace has open windows)
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    visible: previewWindow.wsWindows.length > 0

                    Repeater {
                        model: previewWindow.wsWindows

                        Rectangle {
                            Layout.fillWidth: true
                            height: 34
                            radius: 8
                            color: winItemMouse.containsMouse ? Theme.bgHover : (modelData.is_active ? Qt.alpha(Theme.accentSky, 0.12) : Theme.bgPill)
                            border.color: modelData.is_active ? Theme.accentSky : (winItemMouse.containsMouse ? Theme.accentCyan : Theme.borderDim)
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 8

                                // App Category / Icon Box
                                Rectangle {
                                    width: 22
                                    height: 22
                                    radius: 6
                                    color: Qt.alpha(modelData.accent_color || Theme.accentSky, 0.20)

                                    Icon {
                                        anchors.centerIn: parent
                                        name: modelData.icon || "monitor"
                                        size: 12
                                        color: modelData.accent_color || Theme.accentSky
                                    }
                                }

                                // Window Title & Class
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1

                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.title || modelData.class
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 10
                                        font.bold: true
                                        color: modelData.is_active ? Theme.accentSky : Theme.textPrimary
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.category_label || modelData.class
                                        font.family: Theme.fontMono
                                        font.pixelSize: 8
                                        color: Theme.textMuted
                                        elide: Text.ElideRight
                                    }
                                }

                                // Action indicator
                                Icon {
                                    name: modelData.is_active ? "check" : "chevron-right"
                                    size: 11
                                    color: modelData.is_active ? Theme.accentSky : (winItemMouse.containsMouse ? Theme.accentCyan : Theme.textMuted)
                                }
                            }

                            MouseArea {
                                id: winItemMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    WindowService.focusWindow(modelData.address);
                                    ShellState.workspacePreviewHovered = false;
                                    ShellState.workspacePreviewOpen = false;
                                }
                            }
                        }
                    }
                }

                // Empty Workspace State
                Item {
                    Layout.fillWidth: true
                    height: 48
                    visible: previewWindow.wsWindows.length === 0

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 8

                        Icon {
                            name: "layers"
                            size: 14
                            color: Theme.textMuted
                        }

                        ColumnLayout {
                            spacing: 1
                            Text {
                                text: "Workspace is empty"
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                font.bold: true
                                color: Theme.textPrimary
                            }
                            Text {
                                text: "Click to switch here"
                                font.family: Theme.fontFamily
                                font.pixelSize: 9
                                color: Theme.textMuted
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Quickshell.execDetached(["hyprctl", "eval", "return hl.dispatch(hl.dsp.focus({ workspace = " + ShellState.hoveredWorkspace + " }))"]);
                            ShellState.workspacePreviewHovered = false;
                            ShellState.workspacePreviewOpen = false;
                        }
                    }
                }
            }
        }
    }
}
