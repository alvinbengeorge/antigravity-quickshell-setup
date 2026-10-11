import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../theme"
import "../services"

Rectangle {
    id: root
    height: 34
    radius: height / 2
    color: Theme.bgPill
    border.color: Theme.borderDim
    border.width: 1

    property ShellScreen screen
    readonly property var hyprMonitor: screen ? Hyprland.monitorFor(screen) : null
    readonly property int activeWsId: hyprMonitor?.activeWorkspace?.id ?? (Hyprland.focusedWorkspace?.id ?? 1)

    implicitWidth: mainRow.width + 20

    Row {
        id: mainRow
        anchors.centerIn: parent
        spacing: 8

        // Gemini / Antigravity Icon Button
        Rectangle {
            id: geminiBtn
            width: 22
            height: 22
            radius: 11
            anchors.verticalCenter: parent.verticalCenter
            color: geminiMouse.containsMouse ? Theme.accentCyan : Theme.accentViolet

            Behavior on color { ColorAnimation { duration: 120 } }

            Text {
                anchors.centerIn: parent
                text: "✦"
                font.family: Theme.fontFamily
                font.pixelSize: 12
                color: Theme.textOnAccent
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

                Rectangle {
                    id: wsDot
                    required property int modelData

                    readonly property bool isCurrent: root.activeWsId === wsDot.modelData
                    
                    width: isCurrent ? 24 : 14
                    height: 14
                    radius: 7
                    anchors.verticalCenter: parent.verticalCenter
                    color: isCurrent ? Theme.accentViolet : (mouseArea.containsMouse ? Theme.bgHover : "#2D3748")

                    Behavior on width {
                        NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
                    }

                    Behavior on color {
                        ColorAnimation { duration: 120 }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: wsDot.modelData.toString()
                        font.family: Theme.fontFamily
                        font.pixelSize: 9
                        font.bold: true
                        color: wsDot.isCurrent ? Theme.textOnAccent : Theme.textMuted
                        visible: wsDot.isCurrent || mouseArea.containsMouse
                    }

                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Hyprland.dispatch("workspace " + wsDot.modelData);
                        }
                    }
                }
            }
        }
    }
}
