import QtQuick
import QtQuick.Layouts
import Quickshell
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
        hovered: clockItemMouse.containsMouse || pwrMouse.containsMouse
    }

    property var now: new Date()

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    implicitWidth: clockRow.implicitWidth + 16

    RowLayout {
        id: clockRow
        anchors.centerIn: parent
        spacing: 8

        // Time and Date click area
        Item {
            implicitWidth: timeDateRow.implicitWidth + 8
            implicitHeight: 24

            LiquidGlassSurface {
                radius: 8
                visible: ShellState.plasticEnabled && clockItemMouse.containsMouse
                accentColor: Theme.accentViolet
                hovered: clockItemMouse.containsMouse
                pressed: clockItemMouse.pressed
                showShadow: false
            }

            RowLayout {
                id: timeDateRow
                anchors.centerIn: parent
                spacing: 6

                // Time Text
                Text {
                    text: ShellState.use24Hour ? Qt.formatTime(root.now, "HH:mm") : Qt.formatTime(root.now, "h:mm AP")
                    font.family: Theme.fontMono
                    font.pixelSize: 12
                    color: Theme.textPrimary
                }

                // Date Text
                Text {
                    text: Qt.formatDate(root.now, "ddd, MMM d")
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    color: Theme.textMuted
                }

                // Dropdown indicator
                Icon {
                    name: ShellState.controlCenterOpen ? "chevron-up" : "chevron-down"
                    size: 11
                    color: ShellState.controlCenterOpen ? Theme.accentCyan : Theme.textMuted
                }
            }

            MouseArea {
                id: clockItemMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: (mouse) => {
                    if (mouse.button === Qt.RightButton) {
                        ShellState.toggleTimeFormat();
                    } else {
                        ShellState.toggleControlCenter();
                    }
                }
            }
        }

        // Unread Notification Badge / DND Indicator
        Rectangle {
            height: 20
            implicitWidth: notifBadgeRow.implicitWidth + 10
            radius: 10
            color: ShellState.glassEnabled ? "transparent" : (NotificationService.dnd ? Qt.rgba(Theme.textMuted.r, Theme.textMuted.g, Theme.textMuted.b, 0.15) : Qt.rgba(Theme.accentRose.r, Theme.accentRose.g, Theme.accentRose.b, 0.20))
            border.color: ShellState.glassEnabled ? "transparent" : (NotificationService.dnd ? Theme.borderDim : Theme.accentRose)
            border.width: ShellState.glassEnabled ? 0 : 1
            visible: NotificationService.dnd || NotificationService.unreadCount > 0

            LiquidGlassSurface {
                radius: 10
                visible: ShellState.glassEnabled
                accentColor: NotificationService.dnd ? Theme.textMuted : Theme.accentRose
                hovered: notifBadgeMouse.containsMouse
            }

            RowLayout {
                id: notifBadgeRow
                anchors.centerIn: parent
                spacing: 4

                Icon {
                    name: NotificationService.dnd ? "bell-off" : "bell"
                    size: 10
                    color: NotificationService.dnd ? Theme.textMuted : Theme.accentRose
                }
                Text {
                    visible: !NotificationService.dnd && NotificationService.unreadCount > 0
                    text: NotificationService.unreadCount.toString()
                    font.family: Theme.fontMono
                    font.pixelSize: 9
                    font.bold: true
                    color: Theme.accentRose
                }
                Text {
                    visible: NotificationService.dnd
                    text: "DND"
                    font.family: Theme.fontMono
                    font.pixelSize: 8
                    font.bold: true
                    color: Theme.textMuted
                }
            }

            MouseArea {
                id: notifBadgeMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    ShellState.controlCenterOpen = true;
                }
            }
        }

        // Divider
        Rectangle {
            width: 1
            height: 12
            color: Theme.borderDim
        }

        // Power button (Glass Gem)
        Item {
            id: pwrBtn
            width: 24
            height: 24

            LiquidGlassSurface {
                radius: 12
                visible: ShellState.glassEnabled
                accentColor: Theme.accentRose
                hovered: pwrMouse.containsMouse
            }

            Rectangle {
                anchors.fill: parent
                radius: 12
                visible: !ShellState.glassEnabled
                color: pwrMouse.containsMouse ? Theme.accentRose : "transparent"
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            Icon {
                anchors.centerIn: parent
                name: "power"
                size: 14
                color: ShellState.glassEnabled
                    ? (pwrMouse.containsMouse ? "#FFFFFF" : Theme.accentRose)
                    : (pwrMouse.containsMouse ? Theme.textOnAccent : Theme.accentRose)
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            MouseArea {
                id: pwrMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    ShellState.toggleSessionDialog();
                }
            }
        }
    }
}
