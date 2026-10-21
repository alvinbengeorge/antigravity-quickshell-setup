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
    color: Theme.bgPill
    border.color: Theme.borderDim
    border.width: 1

    property var now: new Date()

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    implicitWidth: clockRow.implicitWidth + 20

    RowLayout {
        id: clockRow
        anchors.centerIn: parent
        spacing: 10

        // Time and Date click area
        Item {
            implicitWidth: timeDateRow.implicitWidth
            implicitHeight: timeDateRow.implicitHeight

            RowLayout {
                id: timeDateRow
                anchors.centerIn: parent
                spacing: 8

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

        // Unread Notification Badge
        Rectangle {
            height: 18
            implicitWidth: notifBadgeRow.implicitWidth + 8
            radius: 9
            color: Qt.rgba(Theme.accentRose.r, Theme.accentRose.g, Theme.accentRose.b, 0.20)
            border.color: Theme.accentRose
            border.width: 1
            visible: NotificationService.unreadCount > 0

            RowLayout {
                id: notifBadgeRow
                anchors.centerIn: parent
                spacing: 4

                Icon {
                    name: "bell"
                    size: 10
                    color: Theme.accentRose
                }
                Text {
                    text: NotificationService.unreadCount.toString()
                    font.family: Theme.fontMono
                    font.pixelSize: 9
                    font.bold: true
                    color: Theme.accentRose
                }
            }

            MouseArea {
                anchors.fill: parent
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

        // Power button
        Rectangle {
            id: pwrBtn
            width: 24
            height: 24
            radius: 12
            color: pwrMouse.containsMouse ? Theme.accentRose : "transparent"

            Behavior on color { ColorAnimation { duration: 150 } }

            Icon {
                anchors.centerIn: parent
                name: "power"
                size: 15
                color: pwrMouse.containsMouse ? Theme.textOnAccent : Theme.accentRose
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            MouseArea {
                id: pwrMouse
                anchors.fill: parent
                anchors.margins: -2
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    ShellState.toggleSessionDialog();
                }
            }
        }
    }
}
