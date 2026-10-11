import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../theme"
import "../services"

PanelWindow {
    id: root

    property bool alignLeft: true
    property bool showClaude: true

    visible: ShellState.desktopAntigravityVisible

    anchors {
        top: true
        left: root.alignLeft
        right: !root.alignLeft
    }

    margins {
        top: 76
        left: root.alignLeft ? 48 : 0
        right: !root.alignLeft ? 48 : 0
    }

    implicitWidth: 380
    implicitHeight: mainCard.implicitHeight

    color: "transparent"

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "quickshell:desktop:antigravity"
    WlrLayershell.layer: WlrLayer.Bottom

    Rectangle {
        id: mainCard
        width: 380
        implicitHeight: contentCol.implicitHeight + 36
        radius: 20
        color: Theme.bgSurfaceGlass
        border.color: Theme.borderGlow
        border.width: 1

        // Top gradient sheen accent line
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            color: Qt.rgba(Theme.accentViolet.r, Theme.accentViolet.g, Theme.accentViolet.b, 0.45)
            radius: parent.radius
        }

        ColumnLayout {
            id: contentCol
            anchors.fill: parent
            anchors.margins: 18
            spacing: 14

            // Header Bar
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                // Star icon with pulsing glow
                Rectangle {
                    width: 32
                    height: 32
                    radius: 16
                    color: AntigravityService.isActive ? "#1A06B6D4" : "#1A8B5CF6"
                    border.color: AntigravityService.isActive ? Theme.accentCyan : Theme.accentViolet
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "✦"
                        font.pixelSize: 16
                        color: AntigravityService.isActive ? Theme.accentCyan : Theme.accentViolet
                    }
                }

                ColumnLayout {
                    spacing: 1
                    Text {
                        text: "ANTIGRAVITY ENGINE"
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        font.bold: true
                        color: Theme.textPrimary
                    }
                    Text {
                        text: "Usage & Quota Telemetry"
                        font.family: Theme.fontMono
                        font.pixelSize: 9
                        color: Theme.textMuted
                    }
                }

                Item { Layout.fillWidth: true }

                // State Badge
                Rectangle {
                    height: 22
                    implicitWidth: statusRow.implicitWidth + 12
                    radius: 11
                    color: Theme.bgPill
                    border.color: AntigravityService.isActive ? Theme.accentCyan : Theme.borderDim
                    border.width: 1

                    RowLayout {
                        id: statusRow
                        anchors.centerIn: parent
                        spacing: 5

                        Rectangle {
                            width: 6
                            height: 6
                            radius: 3
                            color: AntigravityService.isActive ? Theme.accentCyan : Theme.textMuted

                            SequentialAnimation on opacity {
                                running: AntigravityService.isActive
                                loops: Animation.Infinite
                                PropertyAnimation { to: 0.3; duration: 800 }
                                PropertyAnimation { to: 1.0; duration: 800 }
                            }
                        }

                        Text {
                            text: AntigravityService.isActive ? "ACTIVE" : "IDLE"
                            font.family: Theme.fontMono
                            font.pixelSize: 9
                            font.bold: true
                            color: AntigravityService.isActive ? Theme.accentCyan : Theme.textMuted
                        }
                    }
                }

                // Refresh Button
                Rectangle {
                    width: 24
                    height: 24
                    radius: 12
                    color: refreshMouse.containsMouse ? Theme.bgHover : Theme.bgPill
                    border.color: Theme.borderDim
                    border.width: 1

                    Text {
                        id: refreshIcon
                        anchors.centerIn: parent
                        text: "↻"
                        font.pixelSize: 12
                        color: refreshMouse.containsMouse ? Theme.accentSky : Theme.textMuted
                    }

                    MouseArea {
                        id: refreshMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            AntigravityService.refresh();
                        }
                    }
                }

                // Expand / HUD Button
                Rectangle {
                    width: 24
                    height: 24
                    radius: 12
                    color: hudMouse.containsMouse ? Theme.bgHover : Theme.bgPill
                    border.color: Theme.borderDim
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "↗"
                        font.pixelSize: 11
                        color: hudMouse.containsMouse ? Theme.accentSky : Theme.textMuted
                    }

                    MouseArea {
                        id: hudMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            ShellState.toggleAntigravityPanel();
                        }
                    }
                }
            }

            // Session Info Strip
            Rectangle {
                Layout.fillWidth: true
                height: 30
                radius: 8
                color: Theme.bgCard
                border.color: Theme.borderDim
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 8

                    Text {
                        text: "ID:"
                        font.family: Theme.fontMono
                        font.pixelSize: 9
                        font.bold: true
                        color: Theme.textMuted
                    }

                    Text {
                        Layout.fillWidth: true
                        text: AntigravityService.latestId !== "None" ? AntigravityService.latestId : "No active session"
                        font.family: Theme.fontMono
                        font.pixelSize: 9
                        color: Theme.textSecondary
                        elide: Text.ElideMiddle
                    }

                    Text {
                        text: AntigravityService.stepCount > 0 ? (AntigravityService.stepCount + " steps") : (AntigravityService.conversationCount + " sessions")
                        font.family: Theme.fontMono
                        font.pixelSize: 9
                        font.bold: true
                        color: Theme.accentSky
                    }
                }
            }

            // Gemini 5-Hour Demand Quota Card
            Rectangle {
                Layout.fillWidth: true
                radius: 12
                color: Theme.bgCard
                border.color: Theme.borderDim
                border.width: 1
                implicitHeight: g5Col.implicitHeight + 18

                ColumnLayout {
                    id: g5Col
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "GEMINI 5-HOUR LIMIT"
                            font.family: Theme.fontMono
                            font.pixelSize: 10
                            font.bold: true
                            color: Theme.accentSky
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: AntigravityService.gemini5hRemaining + "% REMAINING"
                            font.family: Theme.fontMono
                            font.pixelSize: 10
                            font.bold: true
                            color: AntigravityService.gemini5hRemaining < 20 ? Theme.accentRose : (AntigravityService.gemini5hRemaining < 50 ? Theme.accentAmber : Theme.accentCyan)
                        }
                    }

                    // Progress Bar
                    Rectangle {
                        Layout.fillWidth: true
                        height: 8
                        radius: 4
                        color: Theme.bgBase

                        Rectangle {
                            height: parent.height
                            width: Math.max(6, parent.width * Math.min(1.0, AntigravityService.gemini5hRemaining / 100.0))
                            radius: 4
                            color: AntigravityService.gemini5hRemaining < 20 ? Theme.accentRose : (AntigravityService.gemini5hRemaining < 50 ? Theme.accentAmber : Theme.accentCyan)

                            Behavior on width {
                                NumberAnimation { duration: 300; easing.type: Easing.OutQuad }
                            }
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: AntigravityService.gemini5hDesc || "Rolling 5-hour demand window allocation."
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        color: Theme.textMuted
                        wrapMode: Text.Wrap
                    }
                }
            }

            // Gemini Weekly Allocation Card
            Rectangle {
                Layout.fillWidth: true
                radius: 12
                color: Theme.bgCard
                border.color: Theme.borderDim
                border.width: 1
                implicitHeight: gwCol.implicitHeight + 18

                ColumnLayout {
                    id: gwCol
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "GEMINI WEEKLY LIMIT"
                            font.family: Theme.fontMono
                            font.pixelSize: 10
                            font.bold: true
                            color: Theme.accentEmerald
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: AntigravityService.geminiWeeklyRemaining + "% REMAINING"
                            font.family: Theme.fontMono
                            font.pixelSize: 10
                            font.bold: true
                            color: AntigravityService.geminiWeeklyRemaining < 20 ? Theme.accentRose : (AntigravityService.geminiWeeklyRemaining < 50 ? Theme.accentAmber : Theme.accentEmerald)
                        }
                    }

                    // Progress Bar
                    Rectangle {
                        Layout.fillWidth: true
                        height: 8
                        radius: 4
                        color: Theme.bgBase

                        Rectangle {
                            height: parent.height
                            width: Math.max(6, parent.width * Math.min(1.0, AntigravityService.geminiWeeklyRemaining / 100.0))
                            radius: 4
                            color: AntigravityService.geminiWeeklyRemaining < 20 ? Theme.accentRose : (AntigravityService.geminiWeeklyRemaining < 50 ? Theme.accentAmber : Theme.accentEmerald)

                            Behavior on width {
                                NumberAnimation { duration: 300; easing.type: Easing.OutQuad }
                            }
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: AntigravityService.geminiWeeklyDesc || "Weekly tier allocation window."
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        color: Theme.textMuted
                        wrapMode: Text.Wrap
                    }
                }
            }

            // Claude & Auxiliary Model Quotas Card
            Rectangle {
                Layout.fillWidth: true
                radius: 12
                color: Theme.bgCard
                border.color: Theme.borderDim
                border.width: 1
                implicitHeight: clCol.implicitHeight + 16

                ColumnLayout {
                    id: clCol
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "CLAUDE & GPT MODELS"
                            font.family: Theme.fontMono
                            font.pixelSize: 10
                            font.bold: true
                            color: Theme.accentViolet
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: "5h: " + AntigravityService.claude5hRemaining + "%  |  Wk: " + AntigravityService.claudeWeeklyRemaining + "%"
                            font.family: Theme.fontMono
                            font.pixelSize: 10
                            font.bold: true
                            color: AntigravityService.claudeWeeklyRemaining < 20 ? Theme.accentRose : Theme.accentViolet
                        }
                    }

                    // Combined Mini Dual Bar
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Rectangle {
                            Layout.fillWidth: true
                            height: 6
                            radius: 3
                            color: Theme.bgBase

                            Rectangle {
                                height: parent.height
                                width: Math.max(4, parent.width * Math.min(1.0, AntigravityService.claude5hRemaining / 100.0))
                                radius: 3
                                color: Theme.accentViolet
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 6
                            radius: 3
                            color: Theme.bgBase

                            Rectangle {
                                height: parent.height
                                width: Math.max(4, parent.width * Math.min(1.0, AntigravityService.claudeWeeklyRemaining / 100.0))
                                radius: 3
                                color: AntigravityService.claudeWeeklyRemaining < 20 ? Theme.accentRose : Theme.accentViolet
                            }
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: AntigravityService.claudeWeeklyDesc || "Auxiliary fallback models quota."
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        color: Theme.textMuted
                        wrapMode: Text.Wrap
                    }
                }
            }

            // Context Window & Session Tokens
            Rectangle {
                Layout.fillWidth: true
                radius: 12
                color: Theme.bgCard
                border.color: Theme.borderDim
                border.width: 1
                implicitHeight: ctxCol.implicitHeight + 16

                ColumnLayout {
                    id: ctxCol
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "ACTIVE CONTEXT WINDOW"
                            font.family: Theme.fontMono
                            font.pixelSize: 10
                            font.bold: true
                            color: Theme.textMuted
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: AntigravityService.contextTokensStr + " / 1.0M (" + AntigravityService.contextPercent + "%)"
                            font.family: Theme.fontMono
                            font.pixelSize: 10
                            font.bold: true
                            color: AntigravityService.contextPercent > 80 ? Theme.accentRose : (AntigravityService.contextPercent > 50 ? Theme.accentAmber : Theme.accentSky)
                        }
                    }

                    // Context Bar
                    Rectangle {
                        Layout.fillWidth: true
                        height: 6
                        radius: 3
                        color: Theme.bgBase

                        Rectangle {
                            height: parent.height
                            width: Math.max(4, parent.width * Math.min(1.0, AntigravityService.contextPercent / 100.0))
                            radius: 3
                            color: AntigravityService.contextPercent > 80 ? Theme.accentRose : (AntigravityService.contextPercent > 50 ? Theme.accentAmber : Theme.accentSky)
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "Total Processed Tokens:"
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            color: Theme.textMuted
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: AntigravityService.totalSessionTokensStr + " tokens"
                            font.family: Theme.fontMono
                            font.pixelSize: 10
                            font.bold: true
                            color: Theme.accentViolet
                        }
                    }
                }
            }

            // Quick Actions Bar
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    height: 36
                    radius: 8
                    color: a1Mouse.containsMouse ? Theme.bgHover : Theme.bgCard
                    border.color: Theme.borderDim
                    border.width: 1

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6
                        Text { text: "↺"; font.pixelSize: 13; color: Theme.accentViolet }
                        Text { text: "Resume"; font.family: Theme.fontFamily; font.pixelSize: 11; font.bold: true; color: Theme.textPrimary }
                    }

                    MouseArea {
                        id: a1Mouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: AntigravityService.continueCli()
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 36
                    radius: 8
                    color: a2Mouse.containsMouse ? Theme.bgHover : Theme.bgCard
                    border.color: Theme.borderDim
                    border.width: 1

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6
                        Text { text: "+"; font.pixelSize: 14; font.bold: true; color: Theme.accentCyan }
                        Text { text: "New CLI"; font.family: Theme.fontFamily; font.pixelSize: 11; font.bold: true; color: Theme.textPrimary }
                    }

                    MouseArea {
                        id: a2Mouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: AntigravityService.launchCli()
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 36
                    radius: 8
                    color: a3Mouse.containsMouse ? Theme.bgHover : Theme.bgCard
                    border.color: Theme.borderDim
                    border.width: 1

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6
                        Text { text: "📂"; font.pixelSize: 12 }
                        Text { text: "Brain"; font.family: Theme.fontFamily; font.pixelSize: 11; font.bold: true; color: Theme.textPrimary }
                    }

                    MouseArea {
                        id: a3Mouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: AntigravityService.openBrainDir()
                    }
                }
            }
        }
    }
}
