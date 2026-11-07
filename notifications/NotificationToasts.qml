import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../theme"
import "../services"
import "../components"

PanelWindow {
    id: toastWindow

    visible: NotificationService.activeToasts.length > 0
    color: "transparent"

    anchors {
        top: true
        right: true
    }

    margins {
        top: 56
        right: 18
    }

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "quickshell:notifications"
    WlrLayershell.layer: WlrLayer.Overlay

    implicitWidth: 380
    implicitHeight: toastCol.implicitHeight

    ColumnLayout {
        id: toastCol
        width: 380
        spacing: 10

        Repeater {
            model: NotificationService.activeToasts

            delegate: Rectangle {
                id: toastCard
                Layout.fillWidth: true
                radius: Theme.cardRadius
                color: ShellState.glassEnabled ? "transparent" : Theme.bgSurfaceGlass
                border.color: ShellState.glassEnabled ? "transparent" : (modelData.urgency === 2 ? Theme.accentRose : Theme.borderGlow)
                border.width: ShellState.glassEnabled ? 0 : 1

                LiquidGlassSurface {
                    radius: Theme.cardRadius
                    visible: ShellState.glassEnabled
                    accentColor: modelData.urgency === 2 ? Theme.accentRose : Theme.accentCyan
                    showShadow: true
                }

                implicitHeight: contentCol.implicitHeight + 24

                // Auto dismiss timer
                Timer {
                    id: dismissTimer
                    interval: 5000
                    running: !toastMouse.containsMouse
                    repeat: false
                    onTriggered: {
                        NotificationService.dismissToast(modelData.toastUid);
                    }
                }

                MouseArea {
                    id: toastMouse
                    anchors.fill: parent
                    hoverEnabled: true
                }

                ColumnLayout {
                    id: contentCol
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 6

                    // App Header
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        // App Icon or default bell
                        Icon {
                            name: modelData.urgency === 2 ? "alert-circle" : "bell"
                            size: 14
                            color: modelData.urgency === 2 ? Theme.accentRose : Theme.accentSky
                        }

                        Text {
                            text: modelData.appName
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            font.bold: true
                            color: Theme.accentSky
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Text {
                            text: modelData.time
                            font.family: Theme.fontMono
                            font.pixelSize: 9
                            color: Theme.textMuted
                        }

                        // Close button
                        Rectangle {
                            width: 18
                            height: 18
                            radius: 9
                            color: closeMouse.containsMouse ? Theme.bgHover : "transparent"

                            Icon {
                                anchors.centerIn: parent
                                name: "x"
                                size: 10
                                color: closeMouse.containsMouse ? Theme.accentRose : Theme.textMuted
                            }

                            MouseArea {
                                id: closeMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: NotificationService.dismissToast(modelData.toastUid)
                            }
                        }
                    }

                    // Summary
                    Text {
                        Layout.fillWidth: true
                        text: modelData.summary
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        font.bold: true
                        color: Theme.textPrimary
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                    }

                    // Body
                    Text {
                        Layout.fillWidth: true
                        text: modelData.body
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        color: Theme.textSecondary
                        wrapMode: Text.Wrap
                        maximumLineCount: 3
                        elide: Text.ElideRight
                        visible: modelData.body && modelData.body.length > 0
                    }
                }
            }
        }
    }
}
