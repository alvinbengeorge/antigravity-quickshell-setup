import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import "../theme"
import "../services"
import "../components"

PanelWindow {
    id: mediaDropdownWindow

    visible: ShellState.mediaCardOpen && MediaService.hasMedia
    color: "transparent"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "quickshell:mediadropdown"
    WlrLayershell.layer: WlrLayer.Overlay

    onVisibleChanged: {
        if (visible) {
            MediaService.syncPosition();
        }
    }

    readonly property color accent: MediaService.artColor !== "" ? MediaService.artColor : Theme.accentCyan

    // Close when clicking outside the card
    MouseArea {
        anchors.fill: parent
        onClicked: ShellState.mediaCardOpen = false
    }

    // Floating Media Card
    Item {
        id: cardContainer
        anchors.horizontalCenter: parent.horizontalCenter
        y: 54
        width: 340
        height: 114

        // Ambient glow matching album art
        Rectangle {
            anchors.centerIn: parent
            width: parent.width + 14
            height: parent.height + 14
            radius: 20
            color: mediaDropdownWindow.accent
            opacity: 0.28
            z: -2
            Behavior on color { ColorAnimation { duration: 250 } }
        }

        // Frosted Card Surface
        Rectangle {
            id: cardBg
            anchors.fill: parent
            radius: 14
            color: ShellState.glassEnabled ? "transparent" : Qt.rgba(Theme.bgSurface.r, Theme.bgSurface.g, Theme.bgSurface.b, 0.95)
            border.color: ShellState.glassEnabled ? "transparent" : Qt.rgba(mediaDropdownWindow.accent.r, mediaDropdownWindow.accent.g, mediaDropdownWindow.accent.b, 0.50)
            border.width: 1

            LiquidGlassSurface {
                radius: 14
                visible: ShellState.glassEnabled
                accentColor: mediaDropdownWindow.accent
                showShadow: true
            }

            // Prevent clicks on the card from propagating to background dismiss area
            MouseArea {
                anchors.fill: parent
                onWheel: wheel => {
                    if (wheel.angleDelta.y > 0) {
                        AudioService.changeVolume(0.05);
                    } else if (wheel.angleDelta.y < 0) {
                        AudioService.changeVolume(-0.05);
                    }
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 12

                // Album Art Card (Clickable to Play/Pause)
                Item {
                    Layout.preferredWidth: 86
                    Layout.preferredHeight: 86
                    Layout.alignment: Qt.AlignVCenter

                    Rectangle {
                        id: artMask
                        anchors.fill: parent
                        radius: 10
                        color: Theme.bgHover
                        clip: true

                        Image {
                            id: albumArtImg
                            anchors.fill: parent
                            source: MediaService.trackArtUrl ? MediaService.trackArtUrl : (MediaService.trackArtLocal ? ("file://" + MediaService.trackArtLocal) : "")
                            fillMode: Image.PreserveAspectCrop
                            smooth: true
                            mipmap: true
                            visible: status === Image.Ready
                        }

                        // Fallback icon if no art
                        Icon {
                            anchors.centerIn: parent
                            visible: albumArtImg.status !== Image.Ready
                            name: "music"
                            size: 32
                            color: mediaDropdownWindow.accent
                        }

                        // Play/Pause hover overlay badge
                        Rectangle {
                            anchors.fill: parent
                            radius: 10
                            color: Qt.rgba(0, 0, 0, 0.35)
                            visible: artMouse.containsMouse
                            opacity: artMouse.containsMouse ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 100 } }

                            Icon {
                                anchors.centerIn: parent
                                name: MediaService.isPlaying ? "pause" : "play"
                                size: 28
                                color: "#FFFFFF"
                            }
                        }

                        MouseArea {
                            id: artMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: MediaService.playPause()
                        }
                    }

                    // Art subtle border
                    Rectangle {
                        anchors.fill: parent
                        radius: 10
                        color: "transparent"
                        border.color: Qt.rgba(255, 255, 255, 0.12)
                        border.width: 1
                    }
                }

                // Track Details & Interactive Controls
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 4

                    // Track Title
                    Text {
                        Layout.fillWidth: true
                        text: MediaService.trackTitle
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        font.bold: true
                        color: Theme.textPrimary
                        elide: Text.ElideRight
                    }

                    // Artist & Album
                    Text {
                        Layout.fillWidth: true
                        text: MediaService.trackArtist + (MediaService.trackAlbum ? (" • " + MediaService.trackAlbum) : "")
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        color: Theme.textSecondary
                        elide: Text.ElideRight
                    }

                    Item { Layout.preferredHeight: 2 }

                    // Interactive Tactile Scrubber Bar
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 14

                        Rectangle {
                            id: scrubTrack
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 4
                            radius: 2
                            color: Theme.bgHover

                            Rectangle {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: Math.max(0, Math.min(parent.width, parent.width * MediaService.progress))
                                radius: 2
                                color: mediaDropdownWindow.accent
                                Behavior on color { ColorAnimation { duration: 200 } }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: mouse => {
                                const fraction = Math.max(0.0, Math.min(1.0, mouse.x / width));
                                MediaService.seekFraction(fraction);
                            }
                        }
                    }

                    // Time Stamps & Control Buttons Row
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: MediaService.positionStr
                            font.family: Theme.fontMono
                            font.pixelSize: 10
                            color: Theme.textMuted
                        }

                        Item { Layout.fillWidth: true }

                        // Controls
                        Row {
                            spacing: 12
                            Layout.alignment: Qt.AlignVCenter

                            // Previous
                            MouseArea {
                                width: 22
                                height: 22
                                cursorShape: Qt.PointingHandCursor
                                onClicked: MediaService.previous()
                                Icon {
                                    anchors.centerIn: parent
                                    name: "skip-back"
                                    size: 14
                                    color: parent.containsMouse ? Theme.textPrimary : Theme.textSecondary
                                }
                                hoverEnabled: true
                            }

                            // Play / Pause
                            Rectangle {
                                width: 26
                                height: 26
                                radius: 13
                                color: playBtnMouse.containsMouse ? Qt.lighter(mediaDropdownWindow.accent, 1.15) : mediaDropdownWindow.accent
                                Behavior on color { ColorAnimation { duration: 120 } }

                                Icon {
                                    anchors.centerIn: parent
                                    name: MediaService.isPlaying ? "pause" : "play"
                                    size: 13
                                    color: Theme.textOnAccent || "#000000"
                                }

                                MouseArea {
                                    id: playBtnMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: MediaService.playPause()
                                }
                            }

                            // Next
                            MouseArea {
                                width: 22
                                height: 22
                                cursorShape: Qt.PointingHandCursor
                                onClicked: MediaService.next()
                                Icon {
                                    anchors.centerIn: parent
                                    name: "skip-forward"
                                    size: 14
                                    color: parent.containsMouse ? Theme.textPrimary : Theme.textSecondary
                                }
                                hoverEnabled: true
                            }
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: MediaService.lengthStr
                            font.family: Theme.fontMono
                            font.pixelSize: 10
                            color: Theme.textMuted
                        }
                    }
                }
            }
        }
    }
}
