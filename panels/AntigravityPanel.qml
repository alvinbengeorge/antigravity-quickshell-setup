import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import "../theme"
import "../services"
import "../components"

PanelWindow {
    id: hudWindow

    function cleanDesc(d) {
        if (!d) return "";
        let s = d.split(". If on a supported")[0].split("If on a supported")[0].trim();
        if (!s.endsWith(".") && s.length > 0) s += ".";
        return s;
    }

    visible: ShellState.antigravityPanelOpen
    color: "transparent"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "quickshell:antigravity:hud"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: ShellState.antigravityPanelOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    // Click outside to close
    MouseArea {
        anchors.fill: parent
        onClicked: ShellState.antigravityPanelOpen = false

        // Dim backdrop
        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: 0.70
        }
    }

    // Main HUD Container Card - Solid dark obsidian
    Rectangle {
        id: card
        width: 640
        height: cardContent.childrenRect.height + 48
        implicitHeight: height
        anchors.centerIn: parent
        radius: Theme.cardRadius
        color: ShellState.glassEnabled ? "transparent" : Theme.bgModal
        border.color: ShellState.glassEnabled ? "transparent" : Theme.borderGlow
        border.width: ShellState.glassEnabled ? 0 : 1

        LiquidGlassSurface {
            radius: Theme.cardRadius
            visible: ShellState.glassEnabled
            accentColor: Theme.accentViolet
            showShadow: true
        }

        // Consume clicks inside the card so it doesn't dismiss
        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        ColumnLayout {
            id: cardContent
            width: parent.width - 48
            x: 24
            y: 24
            spacing: 14

            // Header Row
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Rectangle {
                    width: 38
                    height: 38
                    radius: 19
                    color: ShellState.plasticEnabled ? "transparent" : Theme.accentViolet

                    LiquidGlassSurface {
                        radius: 19
                        visible: ShellState.plasticEnabled
                        accentColor: Theme.accentViolet
                        showShadow: false
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "✦"
                        font.pixelSize: 22
                        color: ShellState.plasticEnabled ? Theme.accentViolet : Theme.textOnAccent
                    }
                }

                ColumnLayout {
                    spacing: 2
                    Text {
                        text: "GOOGLE ANTIGRAVITY"
                        font.family: Theme.fontFamily
                        font.pixelSize: 17
                        font.bold: true
                        color: Theme.textPrimary
                    }
                    Text {
                        text: "Autonomous AI Agent HUD & Workspace Controller"
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        color: Theme.textMuted
                    }
                }

                Item { Layout.fillWidth: true }

                // Status Badge
                Rectangle {
                    height: 26
                    radius: 13
                    color: AntigravityService.isActive ? Qt.rgba(Theme.accentCyan.r, Theme.accentCyan.g, Theme.accentCyan.b, 0.18) : Theme.bgPill
                    border.color: AntigravityService.isActive ? Theme.accentCyan : Theme.borderDim
                    border.width: 1
                    implicitWidth: statusText.implicitWidth + 20

                    Text {
                        id: statusText
                        anchors.centerIn: parent
                        text: AntigravityService.isActive ? "● RUNNING" : "● IDLE"
                        font.family: Theme.fontMono
                        font.pixelSize: 11
                        font.bold: true
                        color: AntigravityService.isActive ? Theme.accentCyan : Theme.textMuted
                    }
                }

                // Close Button
                Rectangle {
                    width: 28
                    height: 28
                    radius: 14
                    color: closeMouse.containsMouse ? Theme.bgHover : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        font.pixelSize: 12
                        color: Theme.textMuted
                    }

                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ShellState.antigravityPanelOpen = false
                    }
                }
            }

            // Target Workspace Directory Pill
            Rectangle {
                Layout.fillWidth: true
                height: 32
                radius: 8
                color: Theme.bgBase
                border.color: Theme.borderDim
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 8

                    Text {
                        text: "📁 Default Workspace:"
                        font.family: Theme.fontMono
                        font.pixelSize: 10
                        font.bold: true
                        color: Theme.accentSky
                    }

                    Text {
                        Layout.fillWidth: true
                        text: AntigravityService.defaultWorkspace
                        font.family: Theme.fontMono
                        font.pixelSize: 10
                        color: Theme.textSecondary
                        elide: Text.ElideMiddle
                    }

                    Text {
                        text: "Open"
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        font.bold: true
                        color: openWsMouse.containsMouse ? Theme.accentSky : Theme.textMuted

                        MouseArea {
                            id: openWsMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: AntigravityService.openWorkspaceDir()
                        }
                    }
                }
            }

            // Divider
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.borderDim
            }

            // Quick Prompt Input
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: "QUICK INSTRUCTION / PROMPT"
                    font.family: Theme.fontMono
                    font.pixelSize: 10
                    font.bold: true
                    color: Theme.accentSky
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 44
                    radius: 10
                    color: Theme.bgBase
                    border.color: promptInput.activeFocus ? Theme.accentCyan : Theme.borderDim
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 8
                        spacing: 8

                        Text {
                            text: "❯"
                            font.family: Theme.fontMono
                            font.pixelSize: 13
                            color: Theme.accentCyan
                        }

                        TextInput {
                            id: promptInput
                            Layout.fillWidth: true
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            color: Theme.textPrimary
                            clip: true
                            selectByMouse: true

                            Text {
                                text: "Instruct Antigravity (Press Enter to execute)..."
                                font.family: Theme.fontFamily
                                font.pixelSize: 13
                                color: Theme.textMuted
                                visible: !promptInput.text && !promptInput.activeFocus
                            }

                            onAccepted: {
                                if (promptInput.text.trim().length > 0) {
                                    AntigravityService.runPrompt(promptInput.text.trim());
                                    promptInput.text = "";
                                    ShellState.antigravityPanelOpen = false;
                                }
                            }
                        }

                        Rectangle {
                            width: 30
                            height: 30
                            radius: 6
                            color: Theme.accentViolet
                            visible: promptInput.text.length > 0

                            Text {
                                anchors.centerIn: parent
                                text: "↵"
                                font.pixelSize: 14
                                color: Theme.textOnAccent
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (promptInput.text.trim().length > 0) {
                                        AntigravityService.runPrompt(promptInput.text.trim());
                                        promptInput.text = "";
                                        ShellState.antigravityPanelOpen = false;
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Quick Actions Row
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "QUICK AGENT CONTROLS"
                    font.family: Theme.fontMono
                    font.pixelSize: 10
                    font.bold: true
                    color: Theme.textMuted
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    // Continue button (in fixed workspace)
                    Rectangle {
                        Layout.fillWidth: true
                        height: 48
                        radius: 10
                        color: act1Mouse.containsMouse ? Theme.bgHover : Theme.bgCard
                        border.color: Theme.borderDim
                        border.width: 1

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 8
                            Text { text: "↺"; font.pixelSize: 16; color: Theme.accentViolet }
                            Text { text: "Resume (in workspace)"; font.family: Theme.fontFamily; font.pixelSize: 11; font.bold: true; color: Theme.textPrimary }
                        }

                        MouseArea {
                            id: act1Mouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                AntigravityService.continueCli();
                                ShellState.antigravityPanelOpen = false;
                            }
                        }
                    }

                    // New Agent button (in fixed workspace)
                    Rectangle {
                        Layout.fillWidth: true
                        height: 48
                        radius: 10
                        color: act2Mouse.containsMouse ? Theme.bgHover : Theme.bgCard
                        border.color: Theme.borderDim
                        border.width: 1

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 8
                            Text { text: "+"; font.pixelSize: 16; font.bold: true; color: Theme.accentCyan }
                            Text { text: "New Session"; font.family: Theme.fontFamily; font.pixelSize: 11; font.bold: true; color: Theme.textPrimary }
                        }

                        MouseArea {
                            id: act2Mouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                AntigravityService.launchCli();
                                ShellState.antigravityPanelOpen = false;
                            }
                        }
                    }

                    // Artifacts button
                    Rectangle {
                        Layout.fillWidth: true
                        height: 48
                        radius: 10
                        color: act3Mouse.containsMouse ? Theme.bgHover : Theme.bgCard
                        border.color: Theme.borderDim
                        border.width: 1

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 8
                            Text { text: "📂"; font.pixelSize: 14 }
                            Text { text: "Brain Artifacts"; font.family: Theme.fontFamily; font.pixelSize: 11; font.bold: true; color: Theme.textPrimary }
                        }

                        MouseArea {
                            id: act3Mouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                AntigravityService.openBrainDir();
                                ShellState.antigravityPanelOpen = false;
                            }
                        }
                    }
                }
            }

            // Session Telemetry Card
            Rectangle {
                Layout.fillWidth: true
                height: telemetryCol.childrenRect.height + 24
                implicitHeight: height
                Layout.preferredHeight: height
                radius: 10
                color: Theme.bgCard
                border.color: Theme.borderDim
                border.width: 1

                Column {
                    id: telemetryCol
                    width: parent.width - 24
                    x: 12
                    y: 12
                    spacing: 8

                    RowLayout {
                        width: parent.width
                        Text { text: "ACTIVE CONVERSATION"; font.family: Theme.fontMono; font.pixelSize: 10; color: Theme.textMuted }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: AntigravityService.latestId
                            font.family: Theme.fontMono
                            font.pixelSize: 11
                            color: Theme.accentSky
                            elide: Text.ElideMiddle
                        }
                    }

                    RowLayout {
                        width: parent.width
                        Text { text: "TOTAL RECORDED SESSIONS"; font.family: Theme.fontMono; font.pixelSize: 10; color: Theme.textMuted }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: AntigravityService.conversationCount + " sessions"
                            font.family: Theme.fontMono
                            font.pixelSize: 11
                            color: Theme.textPrimary
                        }
                    }

                    RowLayout {
                        width: parent.width
                        Text { text: "CURRENT TRAJECTORY STEPS"; font.family: Theme.fontMono; font.pixelSize: 10; color: Theme.textMuted }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: AntigravityService.stepCount + " steps"
                            font.family: Theme.fontMono
                            font.pixelSize: 11
                            color: Theme.accentEmerald
                        }
                    }

                    // Context Window Usage & Limit
                    Column {
                        width: parent.width
                        spacing: 4

                        RowLayout {
                            width: parent.width
                            Text { text: "CONTEXT USAGE (1.0M LIMIT)"; font.family: Theme.fontMono; font.pixelSize: 10; color: Theme.textMuted }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: AntigravityService.contextTokensStr + " / 1.0M (" + AntigravityService.contextPercent + "%)"
                                font.family: Theme.fontMono
                                font.pixelSize: 11
                                font.bold: true
                                color: AntigravityService.contextPercent > 80 ? Theme.accentRose : (AntigravityService.contextPercent > 50 ? Theme.accentAmber : Theme.accentCyan)
                            }
                        }

                        // Mini progress bar
                        Rectangle {
                            width: parent.width
                            height: 6
                            radius: 3
                            color: Theme.bgBase

                            Rectangle {
                                height: parent.height
                                width: Math.max(4, parent.width * Math.min(1.0, AntigravityService.contextPercent / 100.0))
                                radius: 3
                                color: AntigravityService.contextPercent > 80 ? Theme.accentRose : (AntigravityService.contextPercent > 50 ? Theme.accentAmber : Theme.accentCyan)
                            }
                        }
                    }

                    RowLayout {
                        width: parent.width
                        Text { text: "SESSION TOKENS PROCESSED"; font.family: Theme.fontMono; font.pixelSize: 10; color: Theme.textMuted }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: AntigravityService.totalSessionTokensStr + " tokens"
                            font.family: Theme.fontMono
                            font.pixelSize: 11
                            color: Theme.accentViolet
                        }
                    }

                    // Quota Limits Section
                    Rectangle {
                        width: parent.width
                        height: 1
                        color: Theme.borderDim
                    }

                    Text {
                        text: "CLOUD USAGE LIMITS & TIERS"
                        font.family: Theme.fontMono
                        font.pixelSize: 10
                        font.bold: true
                        color: Theme.accentSky
                    }

                    // Gemini 5-Hour Limit
                    Column {
                        width: parent.width
                        spacing: 5

                        RowLayout {
                            width: parent.width
                            Text { text: "Gemini 5-Hour Limit Remaining"; font.family: Theme.fontFamily; font.pixelSize: 11; color: Theme.textSecondary }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: AntigravityService.gemini5hRemaining + "%"
                                font.family: Theme.fontMono
                                font.pixelSize: 11
                                font.bold: true
                                color: AntigravityService.gemini5hRemaining < 20 ? Theme.accentRose : (AntigravityService.gemini5hRemaining < 50 ? Theme.accentAmber : Theme.accentCyan)
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 6
                            radius: 3
                            color: Theme.bgBase

                            Rectangle {
                                height: parent.height
                                width: Math.max(4, parent.width * Math.min(1.0, AntigravityService.gemini5hRemaining / 100.0))
                                radius: 3
                                color: AntigravityService.gemini5hRemaining < 20 ? Theme.accentRose : (AntigravityService.gemini5hRemaining < 50 ? Theme.accentAmber : Theme.accentCyan)
                            }
                        }

                        Text {
                            width: parent.width
                            text: hudWindow.cleanDesc(AntigravityService.gemini5hDesc) || "Rolling 5-hour demand window."
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            color: Theme.textMuted
                            wrapMode: Text.Wrap
                        }
                    }

                    // Gemini Weekly Limit
                    Column {
                        width: parent.width
                        spacing: 5

                        RowLayout {
                            width: parent.width
                            Text { text: "Gemini Weekly Limit Remaining"; font.family: Theme.fontFamily; font.pixelSize: 11; color: Theme.textSecondary }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: AntigravityService.geminiWeeklyRemaining + "%"
                                font.family: Theme.fontMono
                                font.pixelSize: 11
                                font.bold: true
                                color: AntigravityService.geminiWeeklyRemaining < 20 ? Theme.accentRose : (AntigravityService.geminiWeeklyRemaining < 50 ? Theme.accentAmber : Theme.accentEmerald)
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 6
                            radius: 3
                            color: Theme.bgBase

                            Rectangle {
                                height: parent.height
                                width: Math.max(4, parent.width * Math.min(1.0, AntigravityService.geminiWeeklyRemaining / 100.0))
                                radius: 3
                                color: AntigravityService.geminiWeeklyRemaining < 20 ? Theme.accentRose : (AntigravityService.geminiWeeklyRemaining < 50 ? Theme.accentAmber : Theme.accentEmerald)
                            }
                        }

                        Text {
                            width: parent.width
                            text: hudWindow.cleanDesc(AntigravityService.geminiWeeklyDesc) || "Weekly tier quota."
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            color: Theme.textMuted
                            wrapMode: Text.Wrap
                        }
                    }

                    // Claude & GPT Quota Limits
                    Column {
                        width: parent.width
                        spacing: 5

                        RowLayout {
                            width: parent.width
                            Text { text: "Claude & GPT Limit Remaining"; font.family: Theme.fontFamily; font.pixelSize: 11; color: Theme.textSecondary }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: "5h: " + AntigravityService.claude5hRemaining + "% | Wk: " + AntigravityService.claudeWeeklyRemaining + "%"
                                font.family: Theme.fontMono
                                font.pixelSize: 11
                                font.bold: true
                                color: AntigravityService.claudeWeeklyRemaining < 20 ? Theme.accentRose : (AntigravityService.claudeWeeklyRemaining < 50 ? Theme.accentAmber : Theme.accentViolet)
                            }
                        }

                        RowLayout {
                            width: parent.width
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
                                    color: AntigravityService.claudeWeeklyRemaining < 20 ? Theme.accentRose : (AntigravityService.claudeWeeklyRemaining < 50 ? Theme.accentAmber : Theme.accentViolet)
                                }
                            }
                        }

                        Text {
                            width: parent.width
                            text: hudWindow.cleanDesc(AntigravityService.claudeWeeklyDesc) || "Weekly 3rd party model allocation."
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            color: Theme.textMuted
                            wrapMode: Text.Wrap
                        }
                    }

                    // Activity snippet
                    Rectangle {
                        width: parent.width
                        height: 28
                        radius: 6
                        color: Theme.bgBase
                        visible: AntigravityService.lastText.length > 0

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            Text { text: "Activity:"; font.family: Theme.fontMono; font.pixelSize: 10; color: Theme.textMuted }
                            Text {
                                Layout.fillWidth: true
                                text: AntigravityService.lastText
                                font.family: Theme.fontMono
                                font.pixelSize: 10
                                color: Theme.textSecondary
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }
        }
    }
}
