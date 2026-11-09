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
    border.color: ShellState.glassEnabled ? "transparent" : (BatteryService.isCharging ? Theme.accentEmerald : (BatteryService.percentage <= 20 ? Theme.accentRose : Theme.borderDim))
    border.width: ShellState.glassEnabled ? 0 : 1

    LiquidGlassSurface {
        radius: root.radius
        visible: ShellState.glassEnabled
        accentColor: BatteryService.isCharging ? Theme.accentEmerald : (BatteryService.percentage <= 20 ? Theme.accentRose : Theme.accentCyan)
        hovered: batPillMouse.containsMouse
        pressed: batPillMouse.pressed
    }

    visible: BatteryService.available

    implicitWidth: batRow.implicitWidth + 20

    MouseArea {
        id: batPillMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                BatteryService.openPowerStatistics();
            } else {
                BatteryService.cycleDisplayMode();
            }
        }
    }

    RowLayout {
        id: batRow
        anchors.centerIn: parent
        spacing: 6

        Text {
            text: BatteryService.isCharging ? "⚡" : (BatteryService.percentage <= 20 ? "🪫" : "🔋")
            font.pixelSize: 13
        }

        Text {
            text: BatteryService.displayText
            font.family: Theme.fontMono
            font.pixelSize: 11
            color: BatteryService.isCharging ? Theme.accentEmerald : (BatteryService.percentage <= 20 ? Theme.accentRose : (BatteryService.percentage <= 40 ? Theme.accentAmber : Theme.textPrimary))
        }
    }
}
