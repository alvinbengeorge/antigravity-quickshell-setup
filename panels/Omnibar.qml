import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../theme"
import "../services"
import "../components"

PanelWindow {
    id: omnibarWindow

    visible: ShellState.omnibarOpen
    color: "transparent"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "quickshell:omnibar"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: ShellState.omnibarOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property var parsedPlan: null
    property bool isExecuting: false
    property var commandHistory: []
    property int historyIndex: -1

    onVisibleChanged: {
        if (visible) {
            omniInput.text = "";
            parsedPlan = null;
            isExecuting = false;
            historyIndex = -1;
            loadHistoryProc.running = true;
            Qt.callLater(() => {
                omniInput.forceActiveFocus();
            });
        }
    }

    // ── Command History Loader ──────────────────────────────────────────
    Process {
        id: loadHistoryProc
        command: ["laya-cmd", "--history"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text.trim());
                    if (Array.isArray(data)) {
                        omnibarWindow.commandHistory = data;
                    }
                } catch(e) {
                    omnibarWindow.commandHistory = [];
                }
            }
        }
    }

    // ── Real-Time Intent Analyzer Subprocess ────────────────────────────
    Timer {
        id: parseDebounceTimer
        interval: 35
        repeat: false
        onTriggered: {
            const q = omniInput.text.trim();
            if (q.length === 0) {
                omnibarWindow.parsedPlan = null;
                return;
            }
            if (parsePlanProc.running) parsePlanProc.running = false;
            parsePlanProc.command = ["laya-cmd", "--json", q];
            parsePlanProc.running = true;
        }
    }

    Process {
        id: parsePlanProc
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const plan = JSON.parse(text.trim());
                    if (plan && plan.actions) {
                        omnibarWindow.parsedPlan = plan;
                    }
                } catch(e) {
                    // Ignore parse errors on rapid typing
                }
            }
        }
    }

    // ── Execute Command ────────────────────────────────────────────────
    function executeCurrentCommand() {
        const query = omniInput.text.trim();
        if (!query) return;

        omnibarWindow.isExecuting = true;
        Quickshell.execDetached(["laya-cmd", query]);

        dismissTimer.restart();
    }

    Timer {
        id: dismissTimer
        interval: 150
        repeat: false
        onTriggered: {
            ShellState.omnibarOpen = false;
        }
    }

    // ── Backdrop Dimmer ────────────────────────────────────────────────
    MouseArea {
        anchors.fill: parent
        onClicked: ShellState.omnibarOpen = false

        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: 0.65

            Behavior on opacity {
                NumberAnimation { duration: 150 }
            }
        }
    }

    // ── Floating Omnibar Card ──────────────────────────────────────────
    Rectangle {
        id: card
        width: 720
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.16

        // Dynamic height based on mode
        height: {
            if (omnibarWindow.parsedPlan && omnibarWindow.parsedPlan.actions && omnibarWindow.parsedPlan.actions.length > 0) {
                return Math.min(520, 150 + omnibarWindow.parsedPlan.actions.length * 80);
            }
            return (omniInput.text.trim().length === 0) ? 440 : 220;
        }

        radius: 18
        color: ShellState.glassEnabled ? Qt.rgba(Theme.bgModal.r, Theme.bgModal.g, Theme.bgModal.b, 0.45) : Theme.bgModal
        border.color: ShellState.glassEnabled
            ? Qt.rgba(1, 1, 1, 0.20)
            : (omnibarWindow.isExecuting
                ? Theme.accentEmerald
                : (omniInput.activeFocus ? Theme.accentCyan : Theme.borderGlow))
        border.width: 1.5

        LiquidGlassSurface {
            radius: 18
            visible: ShellState.glassEnabled
            accentColor: omnibarWindow.isExecuting ? Theme.accentEmerald : (omniInput.activeFocus ? Theme.accentCyan : Theme.borderGlow)
            showShadow: true
        }

        Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on border.color { ColorAnimation { duration: 150 } }

        // Subtle ambient neon glow
        Rectangle {
            anchors.fill: parent
            anchors.margins: -1
            radius: parent.radius + 1
            color: "transparent"
            border.color: Theme.accentCyan
            opacity: omniInput.text.length > 0 ? 0.35 : 0.15
            z: -1
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }

        // Inner Content
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            // ── Input Bar Row ──────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                height: 52
                radius: 12
                color: ShellState.glassEnabled ? "transparent" : (Theme.bgSurfaceGlass || Theme.bgSurface)
                border.color: ShellState.glassEnabled ? "transparent" : Theme.borderDim
                border.width: ShellState.glassEnabled ? 0 : 1

                LiquidGlassSurface {
                    radius: 12
                    visible: ShellState.glassEnabled
                    accentColor: omnibarWindow.isExecuting ? Theme.accentEmerald : (omniInput.activeFocus ? Theme.accentCyan : Theme.borderDim)
                    showShadow: false
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 14
                    spacing: 12

                    // Dynamic Glow Icon
                    Rectangle {
                        width: 30
                        height: 30
                        radius: 8
                        color: omnibarWindow.isExecuting
                            ? Qt.rgba(Theme.accentEmerald.r, Theme.accentEmerald.g, Theme.accentEmerald.b, 0.20)
                            : Qt.rgba(Theme.accentCyan.r, Theme.accentCyan.g, Theme.accentCyan.b, 0.15)

                        Text {
                            anchors.centerIn: parent
                            text: omnibarWindow.isExecuting ? "✓" : "⚡"
                            font.pixelSize: 16
                            color: omnibarWindow.isExecuting ? Theme.accentEmerald : Theme.accentCyan
                        }
                    }

                    // Main Text Input
                    TextInput {
                        id: omniInput
                        Layout.fillWidth: true
                        font.family: Theme.fontFamily
                        font.pixelSize: 15
                        color: Theme.textPrimary
                        selectionColor: Theme.accentCyan
                        selectedTextColor: Theme.textOnAccent
                        clip: true

                        Text {
                            text: "Type a desktop command, action, or prompt..."
                            font.family: parent.font.family
                            font.pixelSize: parent.font.pixelSize
                            color: Theme.textMuted
                            visible: !parent.text && !parent.activeFocus
                        }

                        onTextChanged: {
                            omnibarWindow.historyIndex = -1;
                            parseDebounceTimer.restart();
                        }

                        Keys.onReturnPressed: omnibarWindow.executeCurrentCommand()
                        Keys.onEnterPressed: omnibarWindow.executeCurrentCommand()

                        Keys.onEscapePressed: {
                            ShellState.omnibarOpen = false;
                        }

                        Keys.onUpPressed: {
                            if (omnibarWindow.commandHistory.length > 0) {
                                omnibarWindow.historyIndex = Math.min(omnibarWindow.commandHistory.length - 1, omnibarWindow.historyIndex + 1);
                                omniInput.text = omnibarWindow.commandHistory[omnibarWindow.historyIndex].prompt || "";
                            }
                        }

                        Keys.onDownPressed: {
                            if (omnibarWindow.historyIndex > 0) {
                                omnibarWindow.historyIndex--;
                                omniInput.text = omnibarWindow.commandHistory[omnibarWindow.historyIndex].prompt || "";
                            } else if (omnibarWindow.historyIndex === 0) {
                                omnibarWindow.historyIndex = -1;
                                omniInput.text = "";
                            }
                        }
                    }

                    // Detected Intent Tag Badge
                    Rectangle {
                        visible: omnibarWindow.parsedPlan && omnibarWindow.parsedPlan.actions && omnibarWindow.parsedPlan.actions.length > 0
                        height: 24
                        radius: 6
                        implicitWidth: intentTagText.implicitWidth + 14
                        color: {
                            const act = omnibarWindow.parsedPlan && omnibarWindow.parsedPlan.actions && omnibarWindow.parsedPlan.actions[0];
                            return act ? Qt.rgba(Theme.accentCyan.r, Theme.accentCyan.g, Theme.accentCyan.b, 0.20) : "transparent";
                        }
                        border.color: Theme.accentCyan
                        border.width: 1

                        Text {
                            id: intentTagText
                            anchors.centerIn: parent
                            text: {
                                const act = omnibarWindow.parsedPlan && omnibarWindow.parsedPlan.actions && omnibarWindow.parsedPlan.actions[0];
                                return act ? act.tag : "";
                            }
                            font.family: Theme.fontMono
                            font.pixelSize: 10
                            font.bold: true
                            color: Theme.accentCyan
                        }
                    }

                    // Engine Latency Badge
                    Rectangle {
                        height: 22
                        radius: 5
                        implicitWidth: latencyText.implicitWidth + 10
                        color: Theme.bgHover
                        border.color: Theme.borderDim
                        border.width: 1

                        Text {
                            id: latencyText
                            anchors.centerIn: parent
                            text: omnibarWindow.parsedPlan ? (omnibarWindow.parsedPlan.latency_ms + "ms • 0MB") : "<1ms • 0MB"
                            font.family: Theme.fontMono
                            font.pixelSize: 10
                            color: Theme.accentEmerald
                        }
                    }

                    // Clear button
                    Rectangle {
                        width: 22
                        height: 22
                        radius: 11
                        color: clearMouse.containsMouse ? Theme.bgHover : "transparent"
                        visible: omniInput.text.length > 0

                        Text {
                            anchors.centerIn: parent
                            text: "✕"
                            font.pixelSize: 10
                            color: Theme.textMuted
                        }

                        MouseArea {
                            id: clearMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                omniInput.text = "";
                                omnibarWindow.parsedPlan = null;
                                omniInput.forceActiveFocus();
                            }
                        }
                    }
                }
            }

            // ── Section A: Live Execution Plan Visualizer (Active input) ──
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 8
                visible: omniInput.text.trim().length > 0

                // Header
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: "EXECUTION PLAN"
                        font.family: Theme.fontMono
                        font.pixelSize: 11
                        font.bold: true
                        color: Theme.textMuted
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: "Press ↵ Enter to run"
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        color: Theme.accentSky
                    }
                }

                // Steps List
                ListView {
                    id: planList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 8
                    model: (omnibarWindow.parsedPlan && omnibarWindow.parsedPlan.actions) ? omnibarWindow.parsedPlan.actions : []

                    delegate: Rectangle {
                        required property var modelData
                        required property int index

                        width: planList.width
                        height: 68
                        radius: 10
                        color: Theme.bgCard
                        border.color: Theme.borderDim
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 12

                            // Step number badge
                            Rectangle {
                                width: 34
                                height: 34
                                radius: 8
                                color: Theme.bgHover
                                border.color: Theme.borderDim
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.icon || "⚡"
                                    font.pixelSize: 16
                                }
                            }

                            // Step details
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                RowLayout {
                                    spacing: 8
                                    Text {
                                        text: "Step " + (index + 1) + ":"
                                        font.family: Theme.fontMono
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: Theme.accentCyan
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.description || ""
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: Theme.textPrimary
                                        elide: Text.ElideRight
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: (modelData.commands && modelData.commands.length > 0) ? ("➜ " + modelData.commands.join("  &&  ")) : ""
                                    font.family: Theme.fontMono
                                    font.pixelSize: 10
                                    color: Theme.textMuted
                                    elide: Text.ElideRight
                                }
                            }

                            // Intent Tag Chip
                            Rectangle {
                                height: 20
                                radius: 4
                                implicitWidth: stepTag.implicitWidth + 8
                                color: Theme.bgHover
                                Text {
                                    id: stepTag
                                    anchors.centerIn: parent
                                    text: modelData.tag || "ACTION"
                                    font.family: Theme.fontMono
                                    font.pixelSize: 9
                                    color: Theme.accentSky
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: omnibarWindow.executeCurrentCommand()
                        }
                    }
                }
            }

            // ── Section B: Curated Quick Actions & Suggestions (Empty input) ──
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 12
                visible: omniInput.text.trim().length === 0

                // Quick Action Cards Header
                Text {
                    text: "QUICK ACTIONS"
                    font.family: Theme.fontMono
                    font.pixelSize: 11
                    font.bold: true
                    color: Theme.textMuted
                }

                // Grid of 6 Quick System Actions
                GridLayout {
                    Layout.fillWidth: true
                    columns: 3
                    rowSpacing: 8
                    columnSpacing: 8

                    Repeater {
                        model: [
                            { title: "Virtual Display", sub: "Toggle 1080p Headless", cmd: "turn on virtual display", icon: "🖥️", color: Theme.accentCyan },
                            { title: "Screenshot", sub: "Snip area to clipboard", cmd: "take a screenshot", icon: "📸", color: Theme.accentAmber },
                            { title: "Lock Screen", sub: "Secure with Hyprlock", cmd: "lock the screen", icon: "🔒", color: Theme.accentViolet },
                            { title: "Next Wallpaper", sub: "Rotate desktop background", cmd: "switch to next wallpaper", icon: "🎨", color: Theme.accentEmerald },
                            { title: "Plastic Mode", sub: "Toggle Apple plastic effect", cmd: "toggle plastic mode", icon: "🫧", color: Theme.accentSky },
                            { title: "Do Not Disturb", sub: "Toggle notifications", cmd: "turn on do not disturb", icon: "🔕", color: Theme.accentRose }
                        ]

                        Rectangle {
                            Layout.fillWidth: true
                            height: 52
                            radius: 8
                            color: ShellState.glassEnabled
                                ? "transparent"
                                : (quickMouse.containsMouse ? Theme.bgHover : Theme.bgCard)
                            border.color: ShellState.glassEnabled
                                ? "transparent"
                                : (quickMouse.containsMouse ? modelData.color : Theme.borderDim)
                            border.width: ShellState.glassEnabled ? 0 : 1

                            LiquidGlassSurface {
                                radius: 8
                                visible: ShellState.glassEnabled
                                accentColor: modelData.color
                                hovered: quickMouse.containsMouse
                                showShadow: true
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 8

                                Text {
                                    text: modelData.icon
                                    font.pixelSize: 18
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1

                                    Text {
                                        text: modelData.title
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 12
                                        font.bold: true
                                        color: quickMouse.containsMouse ? modelData.color : Theme.textPrimary
                                    }

                                    Text {
                                        text: modelData.sub
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 10
                                        color: Theme.textMuted
                                        elide: Text.ElideRight
                                    }
                                }
                            }

                            MouseArea {
                                id: quickMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    omniInput.text = modelData.cmd;
                                    omnibarWindow.executeCurrentCommand();
                                }
                            }
                        }
                    }
                }

                // Recent History Header
                RowLayout {
                    Layout.fillWidth: true
                    visible: omnibarWindow.commandHistory.length > 0

                    Text {
                        text: "RECENT COMMANDS"
                        font.family: Theme.fontMono
                        font.pixelSize: 11
                        font.bold: true
                        color: Theme.textMuted
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: "Use ↑ / ↓ to cycle"
                        font.family: Theme.fontMono
                        font.pixelSize: 10
                        color: Theme.textMuted
                    }
                }

                // Recent History List
                ListView {
                    id: historyList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 4
                    visible: omnibarWindow.commandHistory.length > 0
                    model: omnibarWindow.commandHistory.slice(0, 4)

                    delegate: Rectangle {
                        required property var modelData
                        required property int index

                        width: historyList.width
                        height: 34
                        radius: 6
                        color: histMouse.containsMouse ? Theme.bgHover : "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 8

                            Text {
                                text: modelData.icon || "⚡"
                                font.pixelSize: 13
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.prompt || ""
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                color: histMouse.containsMouse ? Theme.accentCyan : Theme.textPrimary
                                elide: Text.ElideRight
                            }

                            Rectangle {
                                height: 18
                                radius: 4
                                implicitWidth: histTag.implicitWidth + 8
                                color: Theme.bgHover
                                Text {
                                    id: histTag
                                    anchors.centerIn: parent
                                    text: modelData.tag || "CMD"
                                    font.family: Theme.fontMono
                                    font.pixelSize: 9
                                    color: Theme.textMuted
                                }
                            }
                        }

                        MouseArea {
                            id: histMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                omniInput.text = modelData.prompt;
                                omnibarWindow.executeCurrentCommand();
                            }
                        }
                    }
                }
            }

            // ── Footer Bar ─────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                height: 32
                color: "transparent"

                RowLayout {
                    anchors.fill: parent
                    spacing: 14

                    RowLayout {
                        spacing: 4
                        Rectangle {
                            width: 18; height: 16; radius: 3; color: Theme.bgHover
                            Text { anchors.centerIn: parent; text: "↵"; font.pixelSize: 10; color: Theme.textMuted }
                        }
                        Text { text: "Execute"; font.family: Theme.fontMono; font.pixelSize: 10; color: Theme.textMuted }
                    }

                    RowLayout {
                        spacing: 4
                        Rectangle {
                            width: 28; height: 16; radius: 3; color: Theme.bgHover
                            Text { anchors.centerIn: parent; text: "↑↓"; font.pixelSize: 10; color: Theme.textMuted }
                        }
                        Text { text: "History"; font.family: Theme.fontMono; font.pixelSize: 10; color: Theme.textMuted }
                    }

                    RowLayout {
                        spacing: 4
                        Rectangle {
                            width: 28; height: 16; radius: 3; color: Theme.bgHover
                            Text { anchors.centerIn: parent; text: "Esc"; font.pixelSize: 9; color: Theme.textMuted }
                        }
                        Text { text: "Close"; font.family: Theme.fontMono; font.pixelSize: 10; color: Theme.textMuted }
                    }

                    Item { Layout.fillWidth: true }

                    RowLayout {
                        spacing: 6
                        Text {
                            text: "Antigravity Omnibar"
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            font.bold: true
                            color: Theme.accentCyan
                        }
                        Text {
                            text: "v2.0"
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
