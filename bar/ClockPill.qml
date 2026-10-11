import QtQuick
import QtQuick.Layouts
import Quickshell
import "../theme"
import "../services"

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

        // Time Text
        Text {
            text: Qt.formatTime(root.now, "HH:mm")
            font.family: Theme.fontMono
            font.pixelSize: 12
            font.bold: true
            color: Theme.textPrimary
        }

        // Date Text
        Text {
            text: Qt.formatDate(root.now, "ddd, MMM d")
            font.family: Theme.fontFamily
            font.pixelSize: 11
            color: Theme.textMuted
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
            width: 20
            height: 20
            radius: 10
            color: pwrMouse.containsMouse ? Theme.accentRose : "transparent"

            Text {
                anchors.centerIn: parent
                text: "⏻"
                font.pixelSize: 12
                color: pwrMouse.containsMouse ? Theme.textOnAccent : Theme.textMuted
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
