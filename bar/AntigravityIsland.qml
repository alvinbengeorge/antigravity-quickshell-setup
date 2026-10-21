import QtQuick
import QtQuick.Layouts
import Quickshell
import "../theme"
import "../services"

Rectangle {
    id: root
    height: 36
    radius: height / 2
    color: mouseArea.containsMouse ? Theme.bgHover : Theme.bgPill
    border.color: AntigravityService.isActive
        ? Theme.accentCyan
        : (MediaService.isPlaying ? Theme.accentViolet : (mouseArea.containsMouse ? Theme.accentSky : Theme.borderDim))
    border.width: 1

    implicitWidth: contentRow.implicitWidth + 24

    Behavior on implicitWidth { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
    Behavior on color { ColorAnimation { duration: 150 } }
    Behavior on border.color { ColorAnimation { duration: 150 } }

    RowLayout {
        id: contentRow
        anchors.centerIn: parent
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

            Text {
                anchors.centerIn: parent
                text: MediaService.isPlaying ? "🎵" : "✦"
                font.family: Theme.fontFamily
                font.pixelSize: 13
                color: AntigravityService.isActive ? Theme.accentCyan : Theme.accentViolet
            }
        }

        Text {
            text: "Antigravity"
            font.family: Theme.fontFamily
            font.pixelSize: 12
            color: Theme.textPrimary
        }

        // Status Badge Pill
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

        // --- Dynamic Island Media Player Section ---
        RowLayout {
            id: mediaSection
            spacing: 8
            visible: MediaService.hasMedia && MediaService.isPlaying

            // Divider
            Rectangle {
                width: 1
                height: 16
                color: Theme.borderDim
            }

            // Track Title & Artist
            Text {
                text: (MediaService.trackTitle || "Playing") + (MediaService.trackArtist ? " • " + MediaService.trackArtist : "")
                font.family: Theme.fontFamily
                font.pixelSize: 11
                color: Theme.accentSky
                elide: Text.ElideRight
                Layout.maximumWidth: 150
            }

            // Mini Controls
            RowLayout {
                spacing: 4

                // Prev Button
                Rectangle {
                    width: 20
                    height: 20
                    radius: 10
                    color: prevMouse.containsMouse ? Theme.bgHover : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "⏮"
                        font.pixelSize: 10
                        color: prevMouse.containsMouse ? Theme.accentSky : Theme.textMuted
                    }

                    MouseArea {
                        id: prevMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: MediaService.previous()
                    }
                }

                // Play / Pause Button
                Rectangle {
                    width: 22
                    height: 22
                    radius: 11
                    color: Theme.bgCard
                    border.color: playMouse.containsMouse ? Theme.accentViolet : Theme.borderDim
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: MediaService.isPlaying ? "⏸" : "▶"
                        font.pixelSize: 9
                        color: playMouse.containsMouse ? Theme.textPrimary : Theme.accentViolet
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
                Rectangle {
                    width: 20
                    height: 20
                    radius: 10
                    color: nextMouse.containsMouse ? Theme.bgHover : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "⏭"
                        font.pixelSize: 10
                        color: nextMouse.containsMouse ? Theme.accentSky : Theme.textMuted
                    }

                    MouseArea {
                        id: nextMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: MediaService.next()
                    }
                }
            }
        }
    }

    MouseArea {
        id: mouseArea
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
