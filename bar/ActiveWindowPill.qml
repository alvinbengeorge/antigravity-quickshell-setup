import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
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
        accentColor: Theme.accentSky
        hovered: winMouse.containsMouse
        pressed: winMouse.pressed
    }

    readonly property string winTitle: Hyprland.activeToplevel?.title ?? ""
    visible: root.winTitle.length > 0

    // Constrain width so it never overlaps the center island
    property real maxAllowedWidth: 220
    Layout.maximumWidth: root.maxAllowedWidth
    implicitWidth: Math.min(Math.min(220, root.maxAllowedWidth), titleRow.implicitWidth + 24)

    MouseArea {
        id: winMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: ShellState.toggleWindowSwitcher()
    }

    RowLayout {
        id: titleRow
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 8

        Icon {
            name: "monitor"
            size: 13
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
