import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../theme"
import "../services"

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
                color: Theme.bgSurfaceGlass
                border.color: modelData.urgency === 2 ? Theme.accentRose : Theme.borderGlow
                border.width: 1

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
                        Text {
                            text: modelData.urgency === 2 ? "🚨" : "🔔"
                            font.pixelSize: 12
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

                            Text {
                                anchors.centerIn: parent
                                text: "✕"
                                font.pixelSize: 9
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
