import QtQuick
import "../theme"
import "../services"

Item {
    id: root

    property real radius: height / 2
    property bool hovered: false
    property bool pressed: false
    property color baseColor: "transparent"
    property color accentColor: Theme.accentCyan
    property bool showShadow: true

    anchors.fill: parent
    z: -1

    // ── Soft ambient depth shadow (3D Elevation) ────────────────────────
    Rectangle {
        anchors.fill: parent
        anchors.topMargin: 1
        anchors.bottomMargin: -1
        radius: root.radius
        visible: root.showShadow
        color: Qt.rgba(0, 0, 0, root.hovered ? 0.28 : 0.16)
        z: -2
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    // ── GPU Accelerated 3D Optical Glass Shader ─────────────────────────
    ShaderEffect {
        id: glassEffect
        anchors.fill: parent
        z: -1

        property color uBaseColor: root.baseColor
        property color uAccentColor: root.accentColor
        property vector2d uSize: Qt.vector2d(Math.max(1, root.width), Math.max(1, root.height))
        property real uRadius: root.radius
        property real uHover: root.hovered ? 1.0 : 0.0
        property real uPressed: root.pressed ? 1.0 : 0.0

        Behavior on uHover { NumberAnimation { duration: 160 } }
        Behavior on uPressed { NumberAnimation { duration: 100 } }
        Behavior on uAccentColor { ColorAnimation { duration: 750; easing.type: Easing.OutCubic } }
        Behavior on uBaseColor { ColorAnimation { duration: 500; easing.type: Easing.OutCubic } }

        fragmentShader: Qt.resolvedUrl("liquid_glass.frag.qsb")
    }
}
