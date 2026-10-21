import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import "../theme"

Rectangle {
    id: root
    height: 34
    radius: height / 2
    color: Theme.bgPill
    border.color: Theme.borderDim
    border.width: 1

    visible: SystemTray.items.values.length > 0
    implicitWidth: trayRow.implicitWidth + 16

    RowLayout {
        id: trayRow
        anchors.centerIn: parent
        spacing: 8

        Repeater {
            model: SystemTray.items.values

            delegate: Rectangle {
                width: 22
                height: 22
                radius: 6
                color: itemMouse.containsMouse ? Theme.bgHover : "transparent"

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
