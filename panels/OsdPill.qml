import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../theme"
import "../services"
import "../components"

PanelWindow {
    id: osdWindow

    // Keep surface alive while opacity animation finishes
    visible: OsdService.active || pillCard.opacity > 0.01
    color: "transparent"

    anchors {
        top: true
    }

    margins {
        top: 54
    }

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "quickshell:osd"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    implicitWidth: 310
    implicitHeight: 52

    Rectangle {
        id: pillCard
        anchors.fill: parent
        radius: 26

        // Theme-aware glassmorphic styling
        color: ShellState.glassEnabled ? "transparent" : Theme.bgSurfaceGlass
        border.color: ShellState.glassEnabled ? "transparent" : (OsdService.isMuted ? Qt.alpha(Theme.accentRose, 0.6) : Qt.alpha(OsdService.accentColor, 0.45))
        border.width: ShellState.glassEnabled ? 0 : 1.5

        LiquidGlassSurface {
            radius: 26
            visible: ShellState.glassEnabled
            accentColor: OsdService.isMuted ? Theme.accentRose : OsdService.accentColor
            showShadow: false
        }

        // Smooth fade & scale transition
        opacity: OsdService.active ? 1.0 : 0.0
        scale: OsdService.active ? 1.0 : 0.94

        Behavior on opacity {
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }
        Behavior on scale {
            NumberAnimation { duration: 200; easing.type: Easing.OutBack }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 16
            spacing: 12

            // 3D Apple Plastic Icon Gem
            Item {
                width: 36
                height: 36

                LiquidGlassSurface {
                    radius: 18
                    visible: ShellState.glassEnabled
                    accentColor: OsdService.isMuted ? Theme.accentRose : OsdService.accentColor
                    showShadow: true
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 18
                    visible: !ShellState.glassEnabled
                    color: Qt.alpha(OsdService.accentColor, 0.15)
                    border.color: Qt.alpha(OsdService.accentColor, 0.35)
                    border.width: 1
                }

                Icon {
                    anchors.centerIn: parent
                    name: OsdService.icon
                    size: 16
                    color: ShellState.plasticMode ? "#FFFFFF" : OsdService.accentColor
                }
            }

            // Info & Progress Stack
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 5

                // Top label row (Title & Value)
                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: OsdService.title
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.bold: true
                        color: Theme.textPrimary
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: OsdService.valueText
                        font.family: Theme.fontMono
                        font.pixelSize: 11
                        font.bold: true
                        color: OsdService.accentColor
                    }
                }

                // Apple Plastic Glossy Progress Bar Track
                Rectangle {
                    id: progressTrack
                    Layout.fillWidth: true
                    height: 8
                    radius: 4
                    color: ShellState.plasticMode ? Qt.rgba(0.04, 0.07, 0.12, 0.75) : Theme.bgPill
                    border.color: ShellState.plasticMode ? Qt.rgba(1, 1, 1, 0.12) : "transparent"
                    border.width: ShellState.plasticMode ? 1 : 0
                    clip: true

                    // Filled Bar with Apple Plastic convex gloss
                    Rectangle {
                        id: progressFill
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: Math.max(height, Math.round(parent.width * OsdService.progress))
                        radius: 4
                        color: OsdService.accentColor

                        gradient: Gradient {
                            orientation: Gradient.Vertical
                            GradientStop { position: 0.0; color: Qt.lighter(OsdService.accentColor, 1.35) }
                            GradientStop { position: 0.45; color: OsdService.accentColor }
                            GradientStop { position: 1.0; color: Qt.darker(OsdService.accentColor, 1.25) }
                        }

                        // Top Gloss Specular Line
                        Rectangle {
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.margins: 1
                            height: 2
                            radius: 1
                            color: Qt.rgba(1, 1, 1, 0.65)
                            visible: ShellState.plasticMode
                        }

                        Behavior on width {
                            NumberAnimation { duration: 100; easing.type: Easing.OutQuad }
                        }
                    }

                    // Interactive Scrubbing MouseArea
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        function updateProg(mouseX) {
                            const pct = Math.max(0.01, Math.min(1.0, mouseX / progressTrack.width));
                            if (OsdService.osdType === "brightness") {
                                BrightnessService.setPercent(Math.round(pct * 100));
                            } else if (OsdService.osdType === "volume") {
                                AudioService.setVolume(pct);
                            }
                            OsdService.keepAlive();
                        }
                        onClicked: mouse => updateProg(mouse.x)
                        onPositionChanged: mouse => {
                            if (pressed) updateProg(mouse.x);
                        }
                        onWheel: wheel => {
                            if (OsdService.osdType === "brightness") {
                                if (wheel.angleDelta.y > 0) BrightnessService.increase();
                                else BrightnessService.decrease();
                            } else if (OsdService.osdType === "volume") {
                                if (wheel.angleDelta.y > 0) AudioService.changeVolume(0.05);
                                else AudioService.changeVolume(-0.05);
                            }
                            OsdService.keepAlive();
                        }
                    }
                }
            }
        }

        // Mouse Wheel Adjustment on the OSD Pill
        MouseArea {
            anchors.fill: parent
            z: -1
            hoverEnabled: true
            onWheel: wheel => {
                if (OsdService.osdType === "brightness") {
                    if (wheel.angleDelta.y > 0) BrightnessService.increase();
                    else BrightnessService.decrease();
                } else if (OsdService.osdType === "volume") {
                    if (wheel.angleDelta.y > 0) AudioService.changeVolume(0.05);
                    else AudioService.changeVolume(-0.05);
                }
                OsdService.keepAlive();
            }
        }
    }
}
