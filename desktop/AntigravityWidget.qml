import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../theme"
import "../services"
import "../components"

PanelWindow {
    id: root

    property bool alignLeft: true

    visible: !ShellState.liteMode && ShellState.desktopAntigravityVisible

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

    implicitWidth: 320
    implicitHeight: mainCard.implicitHeight

    onImplicitHeightChanged: {
        if (implicitHeight > 100) {
            ShellState.antigravityWidgetHeight = implicitHeight;
        }
    }

    function getResetSummary(desc, fallback) {
        if (!desc || desc.length === 0) return fallback;
        const match = desc.match(/refresh(?:es)?\s+in\s+([^.]+)/i);
        if (match && match[1]) {
            return "Resets in " + match[1].trim();
        }
        const timeMatch = desc.match(/(\d+\s*(?:hours?|hrs?|minutes?|mins?)[^.]*)/i);
        if (timeMatch && timeMatch[1]) {
            return "Resets in " + timeMatch[1].trim();
        }
        return desc;
    }

    color: "transparent"

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "quickshell:desktop:antigravity"
    WlrLayershell.layer: WlrLayer.Bottom

    Rectangle {
        id: mainCard
        width: 320
        implicitHeight: contentCol.implicitHeight + 28
        height: implicitHeight
        radius: 18
        color: ShellState.glassEnabled ? "transparent" : Theme.bgSurfaceGlass
        border.color: ShellState.glassEnabled ? "transparent" : Theme.borderGlow
        border.width: ShellState.glassEnabled ? 0 : 1

        LiquidGlassSurface {
            radius: 18
            visible: ShellState.glassEnabled
            accentColor: Theme.accentCyan
            showShadow: true
        }

        ColumnLayout {
            id: contentCol
            width: parent.width - 28
            x: 14
            y: 14
            spacing: 10

            // ── Header ───────────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    width: 28
                    height: 28
                    radius: 14
                    color: ShellState.plasticEnabled
                        ? "transparent"
                        : (AntigravityService.isActive ? "#1A06B6D4" : "#1A8B5CF6")
                    border.color: ShellState.plasticEnabled
                        ? "transparent"
                        : (AntigravityService.isActive ? Theme.accentCyan : Theme.accentViolet)
                    border.width: ShellState.plasticEnabled ? 0 : 1

                    LiquidGlassSurface {
                        radius: 14
                        visible: ShellState.plasticEnabled
                        accentColor: AntigravityService.isActive ? Theme.accentCyan : Theme.accentViolet
                        showShadow: false
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "✦"
                        font.pixelSize: 14
                        color: AntigravityService.isActive ? Theme.accentCyan : Theme.accentViolet
                    }
                }

                ColumnLayout {
                    spacing: 1
                    Text {
                        text: "ANTIGRAVITY ENGINE"
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
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
                    height: 20
                    implicitWidth: statusRow.implicitWidth + 12
                    radius: 10
                    color: Theme.bgPill
                    border.color: AntigravityService.isActive ? Theme.accentCyan : Theme.borderDim
                    border.width: 1

                    RowLayout {
                        id: statusRow
                        anchors.centerIn: parent
                        spacing: 5

                        Rectangle {
                            width: 5
                            height: 5
                            radius: 3
                            color: AntigravityService.isActive ? Theme.accentCyan : Theme.textMuted

                            SequentialAnimation on opacity {
                                running: !ShellState.liteMode && AntigravityService.isActive
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

                // Refresh
                Rectangle {
                    width: 22
                    height: 22
                    radius: 11
                    color: refreshMouse.containsMouse ? Theme.bgHover : Theme.bgPill
                    border.color: Theme.borderDim
                    border.width: 1

                    Text {
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
                        onClicked: AntigravityService.refresh()
                    }
                }

                // HUD
                Rectangle {
                    width: 22
                    height: 22
                    radius: 11
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
                        onClicked: ShellState.toggleAntigravityPanel()
                    }
                }
            }

            // ── Session Info Strip ────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                height: 28
                radius: 8
                color: Theme.bgCard
                border.color: Theme.borderDim
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 6

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

            // ── Gemini Models Card (Dual bars + Reset timers) ─────────────────
            Rectangle {
                Layout.fillWidth: true
                radius: 10
                color: Theme.bgCard
                border.color: Theme.borderDim
                border.width: 1
                implicitHeight: gmCol.implicitHeight + 20
                Layout.preferredHeight: implicitHeight

                ColumnLayout {
                    id: gmCol
                    width: parent.width - 20
                    x: 10
                    y: 10
                    spacing: 7

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "GEMINI MODELS"
                            font.family: Theme.fontMono
                            font.pixelSize: 10
                            font.bold: true
                            color: Theme.accentSky
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: "5h: " + AntigravityService.gemini5hRemaining + "%  |  Wk: " + AntigravityService.geminiWeeklyRemaining + "%"
                            font.family: Theme.fontMono
                            font.pixelSize: 10
                            font.bold: true
                            color: AntigravityService.geminiWeeklyRemaining < 20 ? Theme.accentRose
                                 : AntigravityService.gemini5hRemaining < 50 ? Theme.accentAmber
                                 : Theme.accentSky
                        }
                    }

                    // Dual side-by-side bars (5h left, Weekly right)
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
                                width: Math.max(4, parent.width * Math.min(1.0, AntigravityService.gemini5hRemaining / 100.0))
                                radius: 3
                                color: AntigravityService.gemini5hRemaining < 20 ? Theme.accentRose
                                     : AntigravityService.gemini5hRemaining < 50 ? Theme.accentAmber
                                     : Theme.accentSky
                                Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutQuad } }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 6
                            radius: 3
                            color: Theme.bgBase

                            Rectangle {
                                height: parent.height
                                width: Math.max(4, parent.width * Math.min(1.0, AntigravityService.geminiWeeklyRemaining / 100.0))
                                radius: 3
                                color: AntigravityService.geminiWeeklyRemaining < 20 ? Theme.accentRose
                                     : AntigravityService.geminiWeeklyRemaining < 50 ? Theme.accentAmber
                                     : Theme.accentEmerald
                                Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutQuad } }
                            }
                        }
                    }

                    // Reset Time Descriptions for both 5h and Weekly
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 5
                            Text {
                                text: "5h:"
                                font.family: Theme.fontMono
                                font.pixelSize: 9
                                font.bold: true
                                color: Theme.accentSky
                            }
                            Text {
                                Layout.fillWidth: true
                                text: root.getResetSummary(AntigravityService.gemini5hDesc, "Rolling 5-hour window")
                                font.family: Theme.fontFamily
                                font.pixelSize: 9
                                color: Theme.textMuted
                                elide: Text.ElideRight
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 5
                            Text {
                                text: "Wk:"
                                font.family: Theme.fontMono
                                font.pixelSize: 9
                                font.bold: true
                                color: Theme.accentEmerald
                            }
                            Text {
                                Layout.fillWidth: true
                                text: root.getResetSummary(AntigravityService.geminiWeeklyDesc, "Weekly tier allocation")
                                font.family: Theme.fontFamily
                                font.pixelSize: 9
                                color: Theme.textMuted
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }

            // ── Claude & GPT Card (Dual bars + Reset timer) ────────────────────
            Rectangle {
                Layout.fillWidth: true
                radius: 10
                color: Theme.bgCard
                border.color: Theme.borderDim
                border.width: 1
                implicitHeight: clCol.implicitHeight + 20
                Layout.preferredHeight: implicitHeight

                ColumnLayout {
                    id: clCol
                    width: parent.width - 20
                    x: 10
                    y: 10
                    spacing: 7

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "CLAUDE & GPT"
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

                    // Reset info for Claude & GPT
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 5
                        Text {
                            text: "Reset:"
                            font.family: Theme.fontMono
                            font.pixelSize: 9
                            font.bold: true
                            color: Theme.accentViolet
                        }
                        Text {
                            Layout.fillWidth: true
                            text: root.getResetSummary(AntigravityService.claudeWeeklyDesc || AntigravityService.claude5hDesc, "Auxiliary fallback models quota.")
                            font.family: Theme.fontFamily
                            font.pixelSize: 9
                            color: Theme.textMuted
                            elide: Text.ElideRight
                        }
                    }
                }
            }

            // ── Context Window Card (compact) ─────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                radius: 10
                color: Theme.bgCard
                border.color: Theme.borderDim
                border.width: 1
                implicitHeight: ctxCol.implicitHeight + 20
                Layout.preferredHeight: implicitHeight

                ColumnLayout {
                    id: ctxCol
                    width: parent.width - 20
                    x: 10
                    y: 10
                    spacing: 7

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "CONTEXT WINDOW"
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
                            color: AntigravityService.contextPercent > 80 ? Theme.accentRose
                                 : AntigravityService.contextPercent > 50 ? Theme.accentAmber
                                 : Theme.accentSky
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 6
                        radius: 3
                        color: Theme.bgBase

                        Rectangle {
                            height: parent.height
                            width: Math.max(4, parent.width * Math.min(1.0, AntigravityService.contextPercent / 100.0))
                            radius: 3
                            color: AntigravityService.contextPercent > 80 ? Theme.accentRose
                                 : AntigravityService.contextPercent > 50 ? Theme.accentAmber
                                 : Theme.accentSky
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "Total Processed:"
                            font.family: Theme.fontMono
                            font.pixelSize: 9
                            color: Theme.textMuted
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: AntigravityService.totalSessionTokensStr + " tokens"
                            font.family: Theme.fontMono
                            font.pixelSize: 9
                            font.bold: true
                            color: Theme.accentViolet
                        }
                    }
                }
            }

            // ── Quick Actions ─────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 7

                Rectangle {
                    Layout.fillWidth: true
                    height: 30
                    radius: 8
                    color: a1Mouse.containsMouse ? Theme.bgHover : Theme.bgCard
                    border.color: Theme.borderDim
                    border.width: 1

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 5
                        Text { text: "↺"; font.pixelSize: 12; color: Theme.accentViolet }
                        Text { text: "Resume"; font.family: Theme.fontFamily; font.pixelSize: 10; font.bold: true; color: Theme.textPrimary }
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
                    height: 30
                    radius: 8
                    color: a2Mouse.containsMouse ? Theme.bgHover : Theme.bgCard
                    border.color: Theme.borderDim
                    border.width: 1

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 5
                        Text { text: "+"; font.pixelSize: 13; font.bold: true; color: Theme.accentCyan }
                        Text { text: "New CLI"; font.family: Theme.fontFamily; font.pixelSize: 10; font.bold: true; color: Theme.textPrimary }
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
                    height: 30
                    radius: 8
                    color: a3Mouse.containsMouse ? Theme.bgHover : Theme.bgCard
                    border.color: Theme.borderDim
                    border.width: 1

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 5
                        Text { text: "📂"; font.pixelSize: 11 }
                        Text { text: "Brain"; font.family: Theme.fontFamily; font.pixelSize: 10; font.bold: true; color: Theme.textPrimary }
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
