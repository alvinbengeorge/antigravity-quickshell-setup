import QtQuick
import QtQuick.Layouts
import Quickshell
import "../theme"
import "../services"
import "../components"

Rectangle {
    id: root
    height: 36
    radius: height / 2
    color: ShellState.glassEnabled ? "transparent" : (
        (!ShellState.liteMode && MediaService.isPlaying)
            ? Qt.tint(Theme.bgPill, Qt.alpha(root.currentMediaAccent, 0.12 + root.liveB0 * 0.10))
            : ((bgMouse.containsMouse || brandMouse.containsMouse) ? Theme.bgHover : Theme.bgPill)
    )
    border.color: ShellState.glassEnabled ? "transparent" : (
        (!ShellState.liteMode && MediaService.isPlaying)
            ? root.currentMediaAccent
            : (AntigravityService.isActive ? Theme.accentCyan : (MediaService.hasMedia ? Theme.accentViolet : ((bgMouse.containsMouse || brandMouse.containsMouse) ? Theme.accentSky : Theme.borderDim)))
    )
    border.width: ShellState.glassEnabled ? 0 : ((!ShellState.liteMode && MediaService.isPlaying) ? (1.0 + root.liveB0 * 1.2) : 1)

    // Live audio reactive bindings
    readonly property real liveB0: ShellState.liteMode ? 0.0 : AudioVisualizerService.b0
    readonly property real liveB1: ShellState.liteMode ? 0.0 : AudioVisualizerService.b1
    readonly property real liveB2: ShellState.liteMode ? 0.0 : AudioVisualizerService.b2
    readonly property real liveB3: ShellState.liteMode ? 0.0 : AudioVisualizerService.b3

    // Target accent color (dynamic album art color when playing, else Antigravity or Theme accent)
    readonly property color targetMediaAccent: (!ShellState.liteMode && MediaService.hasMedia && MediaService.isPlaying && MediaService.artColor !== "")
        ? MediaService.artColor
        : (AntigravityService.isActive ? Theme.accentCyan : (MediaService.hasMedia ? Theme.accentViolet : Theme.accentSky))

    // Silky liquid color fade in/out
    property color currentMediaAccent: targetMediaAccent
    Behavior on currentMediaAccent {
        ColorAnimation {
            duration: 750
            easing.type: Easing.OutCubic
        }
    }

    readonly property alias activeMediaAccent: root.currentMediaAccent

    // Evident living bass-pulse outer aura bloom (expands and shines outward with sub-bass/kick)
    Rectangle {
        id: bassAura
        anchors.fill: parent
        anchors.margins: (!ShellState.liteMode && MediaService.isPlaying) ? (-2.0 - root.liveB0 * 5.0) : -1.0
        radius: root.radius + ((!ShellState.liteMode && MediaService.isPlaying) ? (2.0 + root.liveB0 * 5.0) : 1.0)
        z: -3
        color: Qt.alpha(root.currentMediaAccent, (!ShellState.liteMode && MediaService.isPlaying) ? (0.10 + root.liveB0 * 0.28) : 0.0)
        border.color: Qt.alpha(root.currentMediaAccent, (!ShellState.liteMode && MediaService.isPlaying) ? (0.35 + root.liveB0 * 0.55) : 0.0)
        border.width: (!ShellState.liteMode && MediaService.isPlaying) ? (1.5 + root.liveB0 * 2.0) : 0.0
        visible: !ShellState.liteMode && MediaService.isPlaying

        Behavior on anchors.margins { NumberAnimation { duration: 45; easing.type: Easing.OutQuad } }
        Behavior on radius { NumberAnimation { duration: 45; easing.type: Easing.OutQuad } }
        Behavior on border.width { NumberAnimation { duration: 45; easing.type: Easing.OutQuad } }
        Behavior on color { ColorAnimation { duration: 80 } }
        Behavior on border.color { ColorAnimation { duration: 80 } }
    }

    // Direct perimeter bass rim
    Rectangle {
        id: bassRim
        anchors.fill: parent
        anchors.margins: -1
        radius: root.radius + 1
        z: -2
        color: "transparent"
        border.color: root.currentMediaAccent
        border.width: (!ShellState.liteMode && MediaService.isPlaying) ? (1.5 + root.liveB0 * 1.5) : 1.0
        opacity: (!ShellState.liteMode && MediaService.isPlaying) ? (0.45 + root.liveB0 * 0.50) : 0.0
        visible: !ShellState.liteMode

        Behavior on border.width { NumberAnimation { duration: 45; easing.type: Easing.OutQuad } }
        Behavior on opacity { NumberAnimation { duration: 45; easing.type: Easing.OutQuad } }
        Behavior on border.color { ColorAnimation { duration: 250 } }
    }

    LiquidGlassSurface {
        radius: root.radius
        visible: ShellState.glassEnabled
        accentColor: root.currentMediaAccent
        hovered: bgMouse.containsMouse || brandMouse.containsMouse
    }

    implicitWidth: Math.min(500, contentRow.implicitWidth + 20)

    Behavior on implicitWidth { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
    Behavior on color { ColorAnimation { duration: 150 } }
    Behavior on border.color { ColorAnimation { duration: 150 } }

    // Background click handler for empty margins of the pill
    MouseArea {
        id: bgMouse
        anchors.fill: parent
        z: -1
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                Theme.nextTheme();
            } else if (mouse.button === Qt.MiddleButton) {
                ShellState.toggleOmnibar();
            } else {
                ShellState.toggleAntigravityPanel();
            }
        }
    }

    RowLayout {
        id: contentRow
        anchors.centerIn: parent
        spacing: 9

        // Brand & System Status Section
        Item {
            id: brandSection
            implicitWidth: brandRow.implicitWidth
            implicitHeight: 24
            Layout.alignment: Qt.AlignVCenter

            RowLayout {
                id: brandRow
                anchors.fill: parent
                spacing: 9

                // Reactive Audio Spectrum Visualizer / Antigravity Gem
                Item {
                    id: gemContainer
                    width: 22
                    height: 22

                    // Quick volume control by scrolling wheel over the gem
                    MouseArea {
                        anchors.fill: parent
                        z: 10
                        acceptedButtons: Qt.NoButton
                        hoverEnabled: true
                        onWheel: wheel => {
                            if (wheel.angleDelta.y > 0) {
                                AudioService.changeVolume(0.05);
                            } else if (wheel.angleDelta.y < 0) {
                                AudioService.changeVolume(-0.05);
                            }
                        }
                    }

                    LiquidGlassSurface {
                        radius: 11
                        visible: ShellState.plasticEnabled
                        accentColor: MediaService.isPlaying ? root.currentMediaAccent : (AntigravityService.isActive ? Theme.accentCyan : Theme.accentViolet)
                        hovered: brandMouse.containsMouse
                        showShadow: false
                    }

                    // Background soft glow
                    Rectangle {
                        id: pulseGlow
                        anchors.centerIn: parent
                        width: 18
                        height: 18
                        radius: 9
                        visible: !ShellState.liteMode && !ShellState.plasticEnabled
                        color: (!ShellState.liteMode && MediaService.isPlaying) ? root.currentMediaAccent : (AntigravityService.isActive ? Theme.accentCyan : Theme.accentViolet)
                        opacity: (!ShellState.liteMode && MediaService.isPlaying) ? (0.25 + (root.liveB0 + root.liveB1) * 0.35) : (AntigravityService.isActive ? 0.25 : 0.15)
                        scale: (!ShellState.liteMode && MediaService.isPlaying) ? (1.0 + root.liveB0 * 0.20) : 1.0

                        Behavior on opacity { NumberAnimation { duration: 50 } }
                        Behavior on scale { NumberAnimation { duration: 50; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 250 } }
                    }

                    // 4-Band Live Spectrum Equalizer Visualizer (Active during playback in standard mode)
                    Item {
                        anchors.centerIn: parent
                        width: 16
                        height: 14
                        visible: !ShellState.liteMode && MediaService.isPlaying

                        Row {
                            anchors.centerIn: parent
                            spacing: 1.8

                            // Band 0: Sub-bass & kick drum
                            Item {
                                width: 2.2
                                height: 14
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 2.2
                                    height: Math.min(13.0, Math.max(2.5, 2.5 + root.liveB0 * 10.5))
                                    radius: 1.1
                                    color: root.activeMediaAccent
                                    Behavior on height { NumberAnimation { duration: 40; easing.type: Easing.OutCubic } }
                                    Behavior on color { ColorAnimation { duration: 250 } }
                                }
                            }

                            // Band 1: Bass & low-mids
                            Item {
                                width: 2.2
                                height: 14
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 2.2
                                    height: Math.min(13.0, Math.max(2.5, 2.5 + root.liveB1 * 10.5))
                                    radius: 1.1
                                    color: root.activeMediaAccent
                                    Behavior on height { NumberAnimation { duration: 40; easing.type: Easing.OutCubic } }
                                    Behavior on color { ColorAnimation { duration: 250 } }
                                }
                            }

                            // Band 2: Midrange / Vocals
                            Item {
                                width: 2.2
                                height: 14
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 2.2
                                    height: Math.min(13.0, Math.max(2.5, 2.5 + root.liveB2 * 10.5))
                                    radius: 1.1
                                    color: root.activeMediaAccent
                                    Behavior on height { NumberAnimation { duration: 40; easing.type: Easing.OutCubic } }
                                    Behavior on color { ColorAnimation { duration: 250 } }
                                }
                            }

                            // Band 3: Treble / Hi-hats
                            Item {
                                width: 2.2
                                height: 14
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 2.2
                                    height: Math.min(13.0, Math.max(2.5, 2.5 + root.liveB3 * 10.5))
                                    radius: 1.1
                                    color: root.activeMediaAccent
                                    Behavior on height { NumberAnimation { duration: 40; easing.type: Easing.OutCubic } }
                                    Behavior on color { ColorAnimation { duration: 250 } }
                                }
                            }
                        }
                    }

                    // Clean Static Icon (Shown when paused / no media, or in Lite Mode)
                    Icon {
                        anchors.centerIn: parent
                        visible: ShellState.liteMode || !MediaService.isPlaying
                        name: MediaService.hasMedia ? "music" : (AntigravityService.isActive ? "sparkles" : "sparkles")
                        size: 12
                        color: AntigravityService.isActive ? Theme.accentCyan : Theme.accentViolet
                    }
                }

                Text {
                    text: "Antigravity"
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    color: Theme.textPrimary
                }

                // Status Badge Pill (Shows active agent or theme, hidden during media playback to keep the bar balanced)
                Item {
                    height: 18
                    implicitWidth: statusText.implicitWidth + 14
                    visible: AntigravityService.isActive || !MediaService.hasMedia

                    LiquidGlassSurface {
                        radius: 9
                        visible: ShellState.glassEnabled
                        accentColor: AntigravityService.isActive ? Theme.accentCyan : Theme.accentViolet
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: 9
                        visible: !ShellState.glassEnabled
                        color: AntigravityService.isActive
                            ? Qt.rgba(Theme.accentCyan.r, Theme.accentCyan.g, Theme.accentCyan.b, 0.18)
                            : Qt.rgba(Theme.accentViolet.r, Theme.accentViolet.g, Theme.accentViolet.b, 0.16)
                        border.color: AntigravityService.isActive
                            ? Theme.accentCyan
                            : Qt.rgba(Theme.accentViolet.r, Theme.accentViolet.g, Theme.accentViolet.b, 0.40)
                        border.width: 1
                    }

                    Text {
                        id: statusText
                        anchors.centerIn: parent
                        text: AntigravityService.isActive ? "ACTIVE" : Theme.themeName.toUpperCase()
                        font.family: Theme.fontMono
                        font.pixelSize: 9
                        font.bold: true
                        color: AntigravityService.isActive ? Theme.accentCyan : Theme.accentViolet
                    }
                }

                // Steps badge if any
                Item {
                    height: 18
                    implicitWidth: stepText.implicitWidth + 14
                    visible: AntigravityService.stepCount > 0

                    LiquidGlassSurface {
                        radius: 9
                        visible: ShellState.glassEnabled
                        accentColor: Theme.accentEmerald
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: 9
                        visible: !ShellState.glassEnabled
                        color: Qt.rgba(Theme.accentEmerald.r, Theme.accentEmerald.g, Theme.accentEmerald.b, 0.18)
                        border.color: Qt.rgba(Theme.accentEmerald.r, Theme.accentEmerald.g, Theme.accentEmerald.b, 0.40)
                        border.width: 1
                    }

                    Text {
                        id: stepText
                        anchors.centerIn: parent
                        text: AntigravityService.stepCount + " steps"
                        font.family: Theme.fontMono
                        font.pixelSize: 9
                        font.bold: true
                        color: Theme.accentEmerald
                    }
                }

                // Omnibar Shortcut Trigger Pill
                Item {
                    height: 18
                    implicitWidth: omniTriggerText.implicitWidth + 12
                    visible: !MediaService.hasMedia

                    LiquidGlassSurface {
                        radius: 6
                        visible: ShellState.plasticEnabled
                        accentColor: Theme.accentCyan
                        hovered: omniTriggerMouse.containsMouse
                        pressed: omniTriggerMouse.pressed
                        showShadow: false
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: 5
                        visible: !ShellState.plasticEnabled
                        color: omniTriggerMouse.containsMouse ? Qt.rgba(Theme.accentCyan.r, Theme.accentCyan.g, Theme.accentCyan.b, 0.25) : Qt.rgba(Theme.borderDim.r, Theme.borderDim.g, Theme.borderDim.b, 0.4)
                        border.color: omniTriggerMouse.containsMouse ? Theme.accentCyan : Theme.borderDim
                        border.width: 1
                    }

                    Text {
                        id: omniTriggerText
                        anchors.centerIn: parent
                        text: "⌘K"
                        font.family: Theme.fontMono
                        font.pixelSize: 9
                        font.bold: true
                        color: omniTriggerMouse.containsMouse ? Theme.accentCyan : Theme.textMuted
                    }

                    MouseArea {
                        id: omniTriggerMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ShellState.toggleOmnibar()
                    }
                }
            }

            MouseArea {
                id: brandMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: (mouse) => {
                    if (mouse.button === Qt.RightButton) {
                        Theme.nextTheme();
                    } else {
                        ShellState.toggleAntigravityPanel();
                    }
                }
            }
        }

        // --- Dynamic Island Media Player Section ---
        RowLayout {
            id: mediaSection
            spacing: 8
            visible: MediaService.hasMedia

            // Divider
            Rectangle {
                width: 1
                height: 16
                color: Theme.borderDim
            }

            // Track Title (Clickable: opens Control Center media player)
            Item {
                implicitWidth: Math.min(130, trackTitleText.implicitWidth)
                implicitHeight: 20
                Layout.alignment: Qt.AlignVCenter

                Text {
                    id: trackTitleText
                    anchors.verticalCenter: parent.verticalCenter
                    text: MediaService.trackTitle || "Playing"
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    color: titleMouse.containsMouse ? root.activeMediaAccent : Theme.textPrimary
                    elide: Text.ElideRight
                    width: parent.width
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                MouseArea {
                    id: titleMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ShellState.toggleMediaCard()
                    onWheel: wheel => {
                        if (wheel.angleDelta.y > 0) {
                            MediaService.seekRelative(5);
                        } else if (wheel.angleDelta.y < 0) {
                            MediaService.seekRelative(-5);
                        }
                    }
                }
            }

            // Mini Controls
            RowLayout {
                spacing: 4

                // Prev Button
                Item {
                    width: 22
                    height: 22

                    LiquidGlassSurface {
                        radius: 11
                        visible: ShellState.plasticEnabled && prevMouse.containsMouse
                        accentColor: Theme.accentCyan
                        hovered: prevMouse.containsMouse
                        pressed: prevMouse.pressed
                        showShadow: false
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: 11
                        visible: !ShellState.plasticEnabled
                        color: prevMouse.containsMouse ? Theme.bgHover : "transparent"
                    }

                    Icon {
                        anchors.centerIn: parent
                        name: "skip-back"
                        size: 11
                        color: prevMouse.containsMouse ? Theme.accentCyan : Theme.textMuted
                    }

                    MouseArea {
                        id: prevMouse
                        anchors.fill: parent
                        anchors.margins: -2
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: MediaService.previous()
                    }
                }

                // Play / Pause Button (Plastic Gem)
                Item {
                    width: 24
                    height: 24

                    LiquidGlassSurface {
                        radius: 12
                        visible: ShellState.plasticEnabled
                        accentColor: MediaService.isPlaying ? Theme.accentEmerald : Theme.accentViolet
                        hovered: playMouse.containsMouse
                        pressed: playMouse.pressed
                        showShadow: false
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: 12
                        visible: !ShellState.plasticEnabled
                        color: playMouse.containsMouse ? Theme.bgHover : Theme.bgCard
                        border.color: playMouse.containsMouse ? Theme.accentCyan : Theme.accentViolet
                        border.width: 1
                    }

                    Icon {
                        anchors.centerIn: parent
                        name: MediaService.isPlaying ? "pause" : "play"
                        size: 11
                        color: ShellState.plasticEnabled
                            ? (MediaService.isPlaying ? Theme.accentEmerald : Theme.accentViolet)
                            : (playMouse.containsMouse ? Theme.accentCyan : Theme.accentViolet)
                    }

                    MouseArea {
                        id: playMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: MediaService.playPause()
                    }
                }

                // Next Button
                Item {
                    width: 22
                    height: 22

                    LiquidGlassSurface {
                        radius: 11
                        visible: ShellState.plasticEnabled && nextMouse.containsMouse
                        accentColor: Theme.accentCyan
                        hovered: nextMouse.containsMouse
                        pressed: nextMouse.pressed
                        showShadow: false
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: 11
                        visible: !ShellState.plasticEnabled
                        color: nextMouse.containsMouse ? Theme.bgHover : "transparent"
                    }

                    Icon {
                        anchors.centerIn: parent
                        name: "skip-forward"
                        size: 11
                        color: nextMouse.containsMouse ? Theme.accentCyan : Theme.textMuted
                    }

                    MouseArea {
                        id: nextMouse
                        anchors.fill: parent
                        anchors.margins: -2
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: MediaService.next()
                    }
                }
            }
        }
    }
}
