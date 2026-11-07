import QtQuick
import QtQuick.Layouts
import "../theme"
import "../services"

Rectangle {
    id: root

    property string text: ""
    property string icon: ""
    property color accentColor: Theme.accentCyan
    property bool checked: false
    property bool checkable: false
    property bool compact: false
    property real customRadius: -1
    property bool glassOverride: true
    property alias containsMouse: mouseArea.containsMouse
    property alias pressed: mouseArea.pressed

    signal clicked()

    readonly property bool isGlass: ShellState.glassEnabled && glassOverride

    implicitHeight: compact ? 30 : 36
    implicitWidth: Math.max(implicitHeight, contentRow.implicitWidth + (compact ? 16 : 24))
    radius: (customRadius >= 0) ? customRadius : (compact ? 8 : (height / 2))

    // Interactive spring physics
    scale: mouseArea.pressed ? 0.96 : (mouseArea.containsMouse ? 1.02 : 1.0)
    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }

    // Surface Fill Color
    color: root.isGlass ? "transparent" : (root.checked ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.22) : (mouseArea.containsMouse ? Theme.bgHover : Theme.bgPill))
    border.color: root.isGlass ? "transparent" : (root.checked ? root.accentColor : (mouseArea.containsMouse ? Theme.accentCyan : Theme.borderDim))
    border.width: root.isGlass ? 0 : 1

    Behavior on color { ColorAnimation { duration: 150 } }
    Behavior on border.color { ColorAnimation { duration: 150 } }

    // ── 3D Optical Glass Surface Shader ─────────────────────────────────
    LiquidGlassSurface {
        radius: root.radius
        visible: root.isGlass
        accentColor: root.checked ? root.accentColor : (mouseArea.containsMouse ? root.accentColor : Theme.accentCyan)
        hovered: mouseArea.containsMouse
        pressed: mouseArea.pressed
        showShadow: false
    }

    // ── Content Layout ──────────────────────────────────────────────────
    RowLayout {
        id: contentRow
        anchors.centerIn: parent
        spacing: 6

        // Optional Icon
        Text {
            id: iconItem
            text: root.icon
            font.pixelSize: root.compact ? 12 : 14
            visible: root.icon.length > 0
            color: root.checked
                ? root.accentColor
                : (mouseArea.containsMouse ? Theme.textPrimary : Theme.textSecondary)
        }

        // Optional Text Label
        Text {
            id: labelItem
            text: root.text
            font.family: Theme.fontFamily
            font.pixelSize: root.compact ? 11 : 12
            font.bold: root.checked || mouseArea.containsMouse
            color: root.checked
                ? root.accentColor
                : (mouseArea.containsMouse ? Theme.textPrimary : Theme.textSecondary)
            visible: root.text.length > 0
        }
    }

    // ── Interaction ─────────────────────────────────────────────────────
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (root.checkable) {
                root.checked = !root.checked;
            }
            root.clicked();
        }
    }
}
