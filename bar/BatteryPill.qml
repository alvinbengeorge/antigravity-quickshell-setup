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
    border.color: BatteryService.isCharging ? Theme.accentEmerald : (BatteryService.percentage <= 20 ? Theme.accentRose : Theme.borderDim)
    border.width: 1

    visible: BatteryService.available

    implicitWidth: batRow.implicitWidth + 20

    RowLayout {
        id: batRow
        anchors.centerIn: parent
        spacing: 6

        Text {
            text: BatteryService.isCharging ? "⚡" : (BatteryService.percentage <= 20 ? "🪫" : "🔋")
            font.pixelSize: 13
        }

        Text {
            text: BatteryService.percentage + "%"
            font.family: Theme.fontMono
            font.pixelSize: 11
            color: BatteryService.isCharging ? Theme.accentEmerald : (BatteryService.percentage <= 20 ? Theme.accentRose : (BatteryService.percentage <= 40 ? Theme.accentAmber : Theme.textPrimary))
        }
    }
}
