import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "../theme"

Rectangle {
    id: root
    height: 34
    radius: height / 2
    color: Theme.bgPill
    border.color: Theme.borderDim
    border.width: 1

    readonly property string winTitle: Hyprland.activeToplevel?.title ?? ""
    visible: root.winTitle.length > 0

    // Constrain width so it never overlaps the center island
    property real maxAllowedWidth: 220
    Layout.maximumWidth: root.maxAllowedWidth
    implicitWidth: Math.min(Math.min(220, root.maxAllowedWidth), titleRow.implicitWidth + 24)

    RowLayout {
        id: titleRow
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 8

        Text {
            text: "❖"
            font.family: Theme.fontFamily
            font.pixelSize: 13
            color: Theme.accentSky
        }

        Text {
            Layout.fillWidth: true
            text: root.winTitle
            font.family: Theme.fontFamily
            font.pixelSize: 11
            color: Theme.textSecondary
            elide: Text.ElideRight
            clip: true
        }
    }
}
