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
    color: (bgMouse.containsMouse || brandMouse.containsMouse) ? Theme.bgHover : Theme.bgPill
    border.color: AntigravityService.isActive
        ? Theme.accentCyan
        : (MediaService.hasMedia ? Theme.accentViolet : ((bgMouse.containsMouse || brandMouse.containsMouse) ? Theme.accentSky : Theme.borderDim))
    border.width: 1

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
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                Theme.nextTheme();
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

                // Pulsing Antigravity Star Icon
                Item {
                    width: 18
                    height: 18

                    Rectangle {
                        id: pulseGlow
                        anchors.centerIn: parent
                        width: 18
                        height: 18
                        radius: 9
                        color: AntigravityService.isActive ? Theme.accentCyan : Theme.accentViolet
                        opacity: 0.2

                        SequentialAnimation on scale {
                            running: AntigravityService.isActive || MediaService.isPlaying
                            loops: Animation.Infinite
                            PropertyAnimation { to: 1.5; duration: 900; easing.type: Easing.InOutQuad }
                            PropertyAnimation { to: 1.0; duration: 900; easing.type: Easing.InOutQuad }
                        }
                    }

                    Icon {
                        anchors.centerIn: parent
                        name: MediaService.isPlaying ? "music" : "sparkles"
                        size: 13
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
                Rectangle {
                    height: 18
                    radius: 9
                    color: AntigravityService.isActive
                        ? Qt.rgba(Theme.accentCyan.r, Theme.accentCyan.g, Theme.accentCyan.b, 0.18)
                        : Qt.rgba(Theme.accentViolet.r, Theme.accentViolet.g, Theme.accentViolet.b, 0.16)
                    border.color: AntigravityService.isActive
                        ? Theme.accentCyan
                        : Qt.rgba(Theme.accentViolet.r, Theme.accentViolet.g, Theme.accentViolet.b, 0.40)
                    border.width: 1
                    visible: AntigravityService.isActive || !MediaService.hasMedia
                    implicitWidth: statusText.implicitWidth + 12

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
                Rectangle {
                    height: 18
                    radius: 9
                    color: Qt.rgba(Theme.accentEmerald.r, Theme.accentEmerald.g, Theme.accentEmerald.b, 0.18)
                    border.color: Qt.rgba(Theme.accentEmerald.r, Theme.accentEmerald.g, Theme.accentEmerald.b, 0.40)
                    border.width: 1
                    visible: AntigravityService.stepCount > 0
                    implicitWidth: stepText.implicitWidth + 12

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
                    color: titleMouse.containsMouse ? Theme.accentCyan : Theme.accentSky
                    elide: Text.ElideRight
                    width: parent.width
                }

                MouseArea {
                    id: titleMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ShellState.toggleControlCenter()
                }
            }

            // Mini Controls
            RowLayout {
                spacing: 4

                // Prev Button
                Rectangle {
                    width: 22
                    height: 22
                    radius: 11
                    color: prevMouse.containsMouse ? Theme.bgHover : "transparent"

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

                // Play / Pause Button
                Rectangle {
                    width: 24
                    height: 24
                    radius: 12
                    color: playMouse.containsMouse ? Theme.bgHover : Theme.bgCard
                    border.color: playMouse.containsMouse ? Theme.accentCyan : Theme.accentViolet
                    border.width: 1

                    Icon {
                        anchors.centerIn: parent
                        name: MediaService.isPlaying ? "pause" : "play"
                        size: 11
                        color: playMouse.containsMouse ? Theme.accentCyan : Theme.accentViolet
                    }

                    MouseArea {
                        id: playMouse
                        anchors.fill: parent
                        anchors.margins: -2
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: MediaService.playPause()
                    }
                }

                // Next Button
                Rectangle {
                    width: 22
                    height: 22
                    radius: 11
                    color: nextMouse.containsMouse ? Theme.bgHover : "transparent"

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
