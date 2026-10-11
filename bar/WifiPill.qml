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
    border.color: NetworkService.wifiEnabled && NetworkService.activeSsid.length > 0 ? Theme.accentCyan : Theme.borderDim
    border.width: 1

    implicitWidth: wifiRow.implicitWidth + 20

    RowLayout {
        id: wifiRow
        anchors.centerIn: parent
        spacing: 6

        Image {
            source: NetworkService.wifiEnabled ? "../assets/wifi.svg" : "../assets/wifi-off.svg"
            width: 15
            height: 15
            sourceSize.width: 15
            sourceSize.height: 15
            fillMode: Image.PreserveAspectFit
        }

        Text {
            text: {
                if (!NetworkService.wifiEnabled) return "Off";
                if (NetworkService.activeSsid.length > 0) return NetworkService.activeSsid;
                return "Disconnected";
            }
            font.family: Theme.fontFamily
            font.pixelSize: 11
            elide: Text.ElideRight
            Layout.maximumWidth: 110
            color: NetworkService.wifiEnabled && NetworkService.activeSsid.length > 0 ? Theme.accentCyan : Theme.textMuted
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            ShellState.toggleControlCenter();
        }
    }
}
