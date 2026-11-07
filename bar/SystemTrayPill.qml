import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
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
        accentColor: Theme.accentCyan
    }

    visible: SystemTray.items.values.length > 0
    implicitWidth: trayRow.implicitWidth + 16

    RowLayout {
        id: trayRow
        anchors.centerIn: parent
        spacing: 8

        Repeater {
            model: SystemTray.items.values

            delegate: Item {
                width: 22
                height: 22

                LiquidGlassSurface {
                    radius: 6
                    visible: ShellState.plasticEnabled && itemMouse.containsMouse
                    accentColor: Theme.accentCyan
                    hovered: itemMouse.containsMouse
                    pressed: itemMouse.pressed
                    showShadow: false
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 6
                    visible: !ShellState.plasticEnabled
                    color: itemMouse.containsMouse ? Theme.bgHover : "transparent"
                }

                MouseArea {
                    id: itemMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton

                    onClicked: mouse => {
                        if (mouse.button === Qt.LeftButton) {
                            modelData.activate();
                        } else if (mouse.button === Qt.RightButton) {
                            modelData.secondaryActivate();
                        }
                    }

                    IconImage {
                        anchors.centerIn: parent
                        width: 16
                        height: 16
                        source: modelData.icon || ""
                    }
                }
            }
        }
    }
}
