import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../theme"
import "../services"
import "../components"
import "../services/SpotlightEngine.js" as Spotlight

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
    property var spotlightResult: null
    property var matchedApps: []
    property int selectedAppIndex: 0
    property bool isExecuting: false
    property var commandHistory: []
    property int historyIndex: -1

    onVisibleChanged: {
        if (visible) {
            const initQuery = ShellState.omnibarInitialQuery || "";
            ShellState.omnibarInitialQuery = "";
            omniInput.text = initQuery;
            parsedPlan = null;
            spotlightResult = initQuery ? Spotlight.inspect(initQuery) : null;
            matchedApps = (!spotlightResult && initQuery) ? AppService.search(initQuery) : [];
            selectedAppIndex = 0;
            isExecuting = false;
            historyIndex = -1;
            loadHistoryProc.running = true;
            Qt.callLater(() => {
                omniInput.forceActiveFocus();
                if (initQuery) {
                    omniInput.selectAll();
                }
            });
        }
    }

    Connections {
        target: ShellState
        function onOmnibarInitialQueryChanged() {
            if (ShellState.omnibarOpen && ShellState.omnibarInitialQuery) {
                omniInput.text = ShellState.omnibarInitialQuery;
                ShellState.omnibarInitialQuery = "";
                omniInput.forceActiveFocus();
                omniInput.selectAll();
            }
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

    // ── Eyedropper Process ──────────────────────────────────────────────
    Process {
        id: eyedropperProc
        running: false
        command: ["hyprpicker"]
        stdout: StdioCollector {
            onStreamFinished: {
                const picked = text.trim();
                if (picked && picked.startsWith("#")) {
                    omniInput.text = picked;
                    omniInput.forceActiveFocus();
                    Quickshell.execDetached(["wl-copy", picked]);
                    Quickshell.execDetached(["notify-send", "-a", "Antigravity", "Color Picked", picked]);
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
            if (q.length === 0 || omnibarWindow.spotlightResult !== null || (omnibarWindow.matchedApps && omnibarWindow.matchedApps.length > 0)) {
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

    // ── Execute Command / Launch App / Copy Spotlight Result ────────────
    function executeCurrentCommand(forceSemantic) {
        const query = omniInput.text.trim();

        // 1. Force Semantic Execution
        if (forceSemantic && query) {
            omnibarWindow.isExecuting = true;
            Quickshell.execDetached(["laya-cmd", query]);
            dismissTimer.restart();
            return;
        }

        // 2. Spotlight Result (Copy to clipboard)
        if (omnibarWindow.spotlightResult) {
            const val = omnibarWindow.spotlightResult.copyValue || "";
            if (val) {
                Quickshell.execDetached(["wl-copy", val]);
                Quickshell.execDetached(["notify-send", "-a", "Antigravity", "Copied to Clipboard", val]);
            }
            dismissTimer.restart();
            return;
        }

        // 3. Application Launch
        if (omnibarWindow.matchedApps && omnibarWindow.matchedApps.length > 0) {
            const idx = Math.max(0, Math.min(omnibarWindow.selectedAppIndex, omnibarWindow.matchedApps.length - 1));
            const app = omnibarWindow.matchedApps[idx];
            if (app) {
                omnibarWindow.isExecuting = true;
                app.execute();
                dismissTimer.restart();
                return;
            }
        }

        // 4. Fallback Semantic Execution
        if (!query) return;
        omnibarWindow.isExecuting = true;
        Quickshell.execDetached(["laya-cmd", query]);
        dismissTimer.restart();
    }

    Timer {
        id: dismissTimer
        interval: 140
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

        // Dynamic height based on active mode
        height: {
            if (omnibarWindow.spotlightResult) {
                if (omnibarWindow.spotlightResult.mode === "glyphs") return 290;
                if (omnibarWindow.spotlightResult.mode === "color") return 245;
                return 220; // math, conversion, time
            }
            if (omniInput.text.trim().length === 0) {
                return 440; // Quick actions & recent history
            }
            if (omnibarWindow.matchedApps && omnibarWindow.matchedApps.length > 0) {
                const count = Math.min(omnibarWindow.matchedApps.length, 5);
                return Math.min(540, 146 + count * 56 + 42);
            }
            if (omnibarWindow.parsedPlan && omnibarWindow.parsedPlan.actions && omnibarWindow.parsedPlan.actions.length > 0) {
                return Math.min(520, 150 + omnibarWindow.parsedPlan.actions.length * 80);
            }
            return 220;
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

        // Ambient neon glow
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
                            : (omnibarWindow.spotlightResult
                                ? Qt.rgba(Theme.accentAmber.r, Theme.accentAmber.g, Theme.accentAmber.b, 0.20)
                                : ((omnibarWindow.matchedApps && omnibarWindow.matchedApps.length > 0)
                                    ? Qt.rgba(Theme.accentCyan.r, Theme.accentCyan.g, Theme.accentCyan.b, 0.20)
                                    : Qt.rgba(Theme.accentCyan.r, Theme.accentCyan.g, Theme.accentCyan.b, 0.15)))

                        Icon {
                            anchors.centerIn: parent
                            name: omnibarWindow.isExecuting
                                ? "check"
                                : (omnibarWindow.spotlightResult && omnibarWindow.spotlightResult.lucide
                                    ? omnibarWindow.spotlightResult.lucide
                                    : ((omnibarWindow.matchedApps && omnibarWindow.matchedApps.length > 0)
                                        ? "search"
                                        : "zap"))
                            size: 16
                            color: omnibarWindow.isExecuting
                                ? Theme.accentEmerald
                                : (omnibarWindow.spotlightResult
                                    ? Theme.accentAmber
                                    : Theme.accentCyan)
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
                            text: "Type to search apps, math (1440 * 0.75), currency (120 usd to inr), hex (#ffaa00), glyphs (:fire:)..."
                            font.family: parent.font.family
                            font.pixelSize: parent.font.pixelSize
                            color: Theme.textMuted
                            visible: !parent.text && !parent.activeFocus
                            elide: Text.ElideRight
                        }

                        onTextChanged: {
                            omnibarWindow.historyIndex = -1;
                            omnibarWindow.spotlightResult = Spotlight.inspect(omniInput.text);
                            if (!omnibarWindow.spotlightResult) {
                                const q = omniInput.text.trim();
                                if (q.length > 0) {
                                    omnibarWindow.matchedApps = AppService.search(q);
                                    omnibarWindow.selectedAppIndex = 0;
                                } else {
                                    omnibarWindow.matchedApps = [];
                                    omnibarWindow.selectedAppIndex = 0;
                                }
                                parseDebounceTimer.restart();
                            } else {
                                omnibarWindow.matchedApps = [];
                                omnibarWindow.selectedAppIndex = 0;
                                omnibarWindow.parsedPlan = null;
                            }
                        }

                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                if (event.modifiers & Qt.ControlModifier) {
                                    omnibarWindow.executeCurrentCommand(true);
                                } else {
                                    omnibarWindow.executeCurrentCommand(false);
                                }
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Down) {
                                if (omnibarWindow.matchedApps && omnibarWindow.matchedApps.length > 0) {
                                    omnibarWindow.selectedAppIndex = (omnibarWindow.selectedAppIndex + 1) % omnibarWindow.matchedApps.length;
                                    if (appsListView) appsListView.positionViewAtIndex(omnibarWindow.selectedAppIndex, ListView.Contain);
                                    event.accepted = true;
                                } else if (omniInput.text.trim().length === 0) {
                                    if (omnibarWindow.historyIndex > 0) {
                                        omnibarWindow.historyIndex--;
                                        omniInput.text = omnibarWindow.commandHistory[omnibarWindow.historyIndex].prompt || "";
                                    } else if (omnibarWindow.historyIndex === 0) {
                                        omnibarWindow.historyIndex = -1;
                                        omniInput.text = "";
                                    }
                                    event.accepted = true;
                                }
                            } else if (event.key === Qt.Key_Up) {
                                if (omnibarWindow.matchedApps && omnibarWindow.matchedApps.length > 0) {
                                    omnibarWindow.selectedAppIndex = (omnibarWindow.selectedAppIndex - 1 + omnibarWindow.matchedApps.length) % omnibarWindow.matchedApps.length;
                                    if (appsListView) appsListView.positionViewAtIndex(omnibarWindow.selectedAppIndex, ListView.Contain);
                                    event.accepted = true;
                                } else if (omniInput.text.trim().length === 0) {
                                    if (omnibarWindow.commandHistory.length > 0) {
                                        omnibarWindow.historyIndex = Math.min(omnibarWindow.commandHistory.length - 1, omnibarWindow.historyIndex + 1);
                                        omniInput.text = omnibarWindow.commandHistory[omnibarWindow.historyIndex].prompt || "";
                                    }
                                    event.accepted = true;
                                }
                            } else if (event.key === Qt.Key_PageDown) {
                                if (omnibarWindow.matchedApps && omnibarWindow.matchedApps.length > 0) {
                                    omnibarWindow.selectedAppIndex = Math.min(omnibarWindow.matchedApps.length - 1, omnibarWindow.selectedAppIndex + 5);
                                    if (appsListView) appsListView.positionViewAtIndex(omnibarWindow.selectedAppIndex, ListView.Contain);
                                    event.accepted = true;
                                }
                            } else if (event.key === Qt.Key_PageUp) {
                                if (omnibarWindow.matchedApps && omnibarWindow.matchedApps.length > 0) {
                                    omnibarWindow.selectedAppIndex = Math.max(0, omnibarWindow.selectedAppIndex - 5);
                                    if (appsListView) appsListView.positionViewAtIndex(omnibarWindow.selectedAppIndex, ListView.Contain);
                                    event.accepted = true;
                                }
                            } else if (event.key === Qt.Key_Escape) {
                                ShellState.omnibarOpen = false;
                                event.accepted = true;
                            }
                        }
                    }

                    // Detected Mode Badge
                    Rectangle {
                        visible: omnibarWindow.spotlightResult !== null || (omnibarWindow.matchedApps && omnibarWindow.matchedApps.length > 0) || (omnibarWindow.parsedPlan && omnibarWindow.parsedPlan.actions && omnibarWindow.parsedPlan.actions.length > 0)
                        height: 24
                        radius: 6
                        implicitWidth: intentTagText.implicitWidth + 14
                        color: {
                            if (omnibarWindow.spotlightResult) {
                                return Qt.rgba(Theme.accentAmber.r, Theme.accentAmber.g, Theme.accentAmber.b, 0.20);
                            }
                            if (omnibarWindow.matchedApps && omnibarWindow.matchedApps.length > 0) {
                                return Qt.rgba(Theme.accentCyan.r, Theme.accentCyan.g, Theme.accentCyan.b, 0.20);
                            }
                            const act = omnibarWindow.parsedPlan && omnibarWindow.parsedPlan.actions && omnibarWindow.parsedPlan.actions[0];
                            return act ? Qt.rgba(Theme.accentViolet.r, Theme.accentViolet.g, Theme.accentViolet.b, 0.20) : "transparent";
                        }
                        border.color: omnibarWindow.spotlightResult ? Theme.accentAmber : ((omnibarWindow.matchedApps && omnibarWindow.matchedApps.length > 0) ? Theme.accentCyan : Theme.accentViolet)
                        border.width: 1

                        Text {
                            id: intentTagText
                            anchors.centerIn: parent
                            text: {
                                if (omnibarWindow.spotlightResult) {
                                    return omnibarWindow.spotlightResult.mode.toUpperCase();
                                }
                                if (omnibarWindow.matchedApps && omnibarWindow.matchedApps.length > 0) {
                                    return omnibarWindow.matchedApps.length === 1 ? "APPLICATION" : (omnibarWindow.matchedApps.length + " APPS");
                                }
                                const act = omnibarWindow.parsedPlan && omnibarWindow.parsedPlan.actions && omnibarWindow.parsedPlan.actions[0];
                                return act ? act.tag : "";
                            }
                            font.family: Theme.fontMono
                            font.pixelSize: 10
                            font.bold: true
                            color: omnibarWindow.spotlightResult ? Theme.accentAmber : ((omnibarWindow.matchedApps && omnibarWindow.matchedApps.length > 0) ? Theme.accentCyan : Theme.accentViolet)
                        }
                    }

                    // Latency Badge
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
                            text: omnibarWindow.spotlightResult ? "<0.1ms • Local" : ((omnibarWindow.matchedApps && omnibarWindow.matchedApps.length > 0) ? "<0.2ms • System" : (omnibarWindow.parsedPlan ? (omnibarWindow.parsedPlan.latency_ms + "ms • 0MB") : "<1ms • 0MB"))
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
                                omnibarWindow.spotlightResult = null;
                                omnibarWindow.matchedApps = [];
                                omnibarWindow.selectedAppIndex = 0;
                                omniInput.forceActiveFocus();
                            }
                        }
                    }
                }
            }

            // ── Section S: Spotlight Hero Results (Math, Conversions, Time) ──
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 8
                visible: omnibarWindow.spotlightResult !== null && (omnibarWindow.spotlightResult.mode === "math" || omnibarWindow.spotlightResult.mode === "conversion" || omnibarWindow.spotlightResult.mode === "time")

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 12
                    color: Theme.bgCard
                    border.color: Qt.rgba(Theme.accentEmerald.r, Theme.accentEmerald.g, Theme.accentEmerald.b, 0.4)
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 18
                        spacing: 16

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            RowLayout {
                                spacing: 6
                                Text {
                                    text: omnibarWindow.spotlightResult ? omnibarWindow.spotlightResult.icon : ""
                                    font.pixelSize: 16
                                }
                                Text {
                                    text: omnibarWindow.spotlightResult ? omnibarWindow.spotlightResult.title : ""
                                    font.family: Theme.fontMono
                                    font.pixelSize: 10
                                    font.bold: true
                                    color: Theme.accentCyan
                                }
                            }

                            Text {
                                text: omnibarWindow.spotlightResult ? omnibarWindow.spotlightResult.expression : ""
                                font.family: Theme.fontFamily
                                font.pixelSize: 14
                                font.bold: true
                                color: Theme.textSecondary
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        // Big Hero Result
                        Text {
                            text: omnibarWindow.spotlightResult ? omnibarWindow.spotlightResult.result : ""
                            font.family: Theme.fontMono
                            font.pixelSize: 26
                            font.bold: true
                            color: Theme.accentEmerald
                        }

                        // Copy Pill Action
                        Rectangle {
                            height: 32
                            implicitWidth: copyPillRow.implicitWidth + 16
                            radius: 8
                            color: copyM.containsMouse ? Theme.accentEmerald : Theme.bgPill
                            border.color: Theme.accentEmerald
                            border.width: 1

                            RowLayout {
                                id: copyPillRow
                                anchors.centerIn: parent
                                spacing: 6
                                Text {
                                    text: "↵"
                                    font.family: Theme.fontMono
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: copyM.containsMouse ? Theme.textOnAccent : Theme.accentEmerald
                                }
                                Text {
                                    text: "Copy"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: copyM.containsMouse ? Theme.textOnAccent : Theme.textPrimary
                                }
                            }

                            MouseArea {
                                id: copyM
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: omnibarWindow.executeCurrentCommand(false)
                            }
                        }
                    }
                }
            }

            // ── Section C: Spotlight Color & Palette Inspector ──────────────
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 8
                visible: omnibarWindow.spotlightResult !== null && omnibarWindow.spotlightResult.mode === "color"

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 12
                    color: Theme.bgCard
                    border.color: Qt.rgba(Theme.accentCyan.r, Theme.accentCyan.g, Theme.accentCyan.b, 0.4)
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 16

                        // Swatch Box
                        Rectangle {
                            width: 68
                            height: 68
                            radius: 10
                            color: omnibarWindow.spotlightResult ? omnibarWindow.spotlightResult.hex : "transparent"
                            border.color: Qt.rgba(1, 1, 1, 0.3)
                            border.width: 1.5

                            Icon {
                                anchors.centerIn: parent
                                name: "palette"
                                size: 20
                                color: Theme.accentCyan
                            }
                        }

                        // Color Value Badges
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Text {
                                text: "COLOR PALETTE INSPECTOR"
                                font.family: Theme.fontMono
                                font.pixelSize: 10
                                font.bold: true
                                color: Theme.accentCyan
                            }

                            RowLayout {
                                spacing: 8

                                // Hex Chip
                                Rectangle {
                                    height: 28
                                    implicitWidth: hexTxt.implicitWidth + 14
                                    radius: 6
                                    color: hexM.containsMouse ? Theme.accentCyan : Theme.bgBase
                                    border.color: Theme.borderDim
                                    border.width: 1
                                    Text {
                                        id: hexTxt
                                        anchors.centerIn: parent
                                        text: omnibarWindow.spotlightResult ? omnibarWindow.spotlightResult.hex : ""
                                        font.family: Theme.fontMono
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: hexM.containsMouse ? Theme.textOnAccent : Theme.accentCyan
                                    }
                                    MouseArea {
                                        id: hexM
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            Quickshell.execDetached(["wl-copy", hexTxt.text]);
                                            Quickshell.execDetached(["notify-send", "-a", "Antigravity", "HEX Copied", hexTxt.text]);
                                            omnibarWindow.dismissTimer.restart();
                                        }
                                    }
                                }

                                // RGB Chip
                                Rectangle {
                                    height: 28
                                    implicitWidth: rgbTxt.implicitWidth + 14
                                    radius: 6
                                    color: rgbM.containsMouse ? Theme.accentSky : Theme.bgBase
                                    border.color: Theme.borderDim
                                    border.width: 1
                                    Text {
                                        id: rgbTxt
                                        anchors.centerIn: parent
                                        text: omnibarWindow.spotlightResult ? omnibarWindow.spotlightResult.rgb : ""
                                        font.family: Theme.fontMono
                                        font.pixelSize: 11
                                        color: rgbM.containsMouse ? Theme.textOnAccent : Theme.textPrimary
                                    }
                                    MouseArea {
                                        id: rgbM
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            Quickshell.execDetached(["wl-copy", rgbTxt.text]);
                                            Quickshell.execDetached(["notify-send", "-a", "Antigravity", "RGB Copied", rgbTxt.text]);
                                            omnibarWindow.dismissTimer.restart();
                                        }
                                    }
                                }

                                // HSL Chip
                                Rectangle {
                                    height: 28
                                    implicitWidth: hslTxt.implicitWidth + 14
                                    radius: 6
                                    color: hslM.containsMouse ? Theme.accentViolet : Theme.bgBase
                                    border.color: Theme.borderDim
                                    border.width: 1
                                    Text {
                                        id: hslTxt
                                        anchors.centerIn: parent
                                        text: omnibarWindow.spotlightResult ? omnibarWindow.spotlightResult.hsl : ""
                                        font.family: Theme.fontMono
                                        font.pixelSize: 11
                                        color: hslM.containsMouse ? Theme.textOnAccent : Theme.textMuted
                                    }
                                    MouseArea {
                                        id: hslM
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            Quickshell.execDetached(["wl-copy", hslTxt.text]);
                                            Quickshell.execDetached(["notify-send", "-a", "Antigravity", "HSL Copied", hslTxt.text]);
                                            omnibarWindow.dismissTimer.restart();
                                        }
                                    }
                                }
                            }
                        }

                        // Eyedropper Button
                        Rectangle {
                            height: 34
                            implicitWidth: eyeRow.implicitWidth + 16
                            radius: 8
                            color: eyeM.containsMouse ? Theme.bgHover : Theme.bgPill
                            border.color: Theme.borderDim
                            border.width: 1

                            RowLayout {
                                id: eyeRow
                                anchors.centerIn: parent
                                spacing: 6
                                Icon {
                                    name: "palette"
                                    size: 14
                                    color: Theme.accentCyan
                                }
                                Text {
                                    text: "Pick Screen"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: Theme.textPrimary
                                }
                            }

                            MouseArea {
                                id: eyeM
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: eyedropperProc.running = true
                            }
                        }
                    }
                }
            }

            // ── Section G: Spotlight Glyphs & Symbols Inspector ──────────────
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 8
                visible: omnibarWindow.spotlightResult !== null && omnibarWindow.spotlightResult.mode === "glyphs"

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 12
                    color: Theme.bgCard
                    border.color: Qt.rgba(Theme.accentSky.r, Theme.accentSky.g, Theme.accentSky.b, 0.4)
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 10

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: "GLYPH & SYMBOL SEARCH"
                                font.family: Theme.fontMono
                                font.pixelSize: 10
                                font.bold: true
                                color: Theme.accentSky
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: "Click or press ↵ to copy"
                                font.family: Theme.fontMono
                                font.pixelSize: 10
                                color: Theme.textMuted
                            }
                        }

                        // Glyphs Row
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Repeater {
                                model: (omnibarWindow.spotlightResult && omnibarWindow.spotlightResult.matches) ? omnibarWindow.spotlightResult.matches.slice(0, 8) : []

                                delegate: Rectangle {
                                    width: 72
                                    height: 60
                                    radius: 8
                                    color: symM.containsMouse ? Qt.rgba(Theme.accentCyan.r, Theme.accentCyan.g, Theme.accentCyan.b, 0.22) : Theme.bgBase
                                    border.color: symM.containsMouse ? Theme.accentCyan : Theme.borderDim
                                    border.width: 1

                                    ColumnLayout {
                                        anchors.centerIn: parent
                                        spacing: 2
                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: modelData.char
                                            font.pixelSize: 22
                                            color: Theme.textPrimary
                                        }
                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: modelData.name
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 9
                                            color: Theme.textMuted
                                            elide: Text.ElideRight
                                            Layout.maximumWidth: 64
                                        }
                                    }

                                    MouseArea {
                                        id: symM
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            Quickshell.execDetached(["wl-copy", modelData.char]);
                                            Quickshell.execDetached(["notify-send", "-a", "Antigravity", "Copied", modelData.char + " (" + modelData.name + ")"]);
                                            omnibarWindow.dismissTimer.restart();
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ── Section M: Matched Applications List ────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 8
                visible: omnibarWindow.spotlightResult === null && omnibarWindow.matchedApps && omnibarWindow.matchedApps.length > 0

                // Header
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: "APPLICATIONS (" + omnibarWindow.matchedApps.length + ")"
                        font.family: Theme.fontMono
                        font.pixelSize: 11
                        font.bold: true
                        color: Theme.accentCyan
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: "↑↓ to navigate • ↵ to launch"
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        color: Theme.textMuted
                    }
                }

                // Applications ListView
                ListView {
                    id: appsListView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 4
                    model: omnibarWindow.matchedApps
                    currentIndex: omnibarWindow.selectedAppIndex
                    boundsBehavior: Flickable.StopAtBounds

                    ScrollBar.vertical: ScrollBar {
                        active: true
                        policy: appsListView.contentHeight > appsListView.height ? ScrollBar.AlwaysOn : ScrollBar.AsNeeded
                    }

                    delegate: Rectangle {
                        id: appItem
                        required property var modelData
                        required property int index

                        width: appsListView.width - (appsListView.contentHeight > appsListView.height ? 12 : 0)
                        height: 52
                        radius: 8
                        readonly property bool isSelected: omnibarWindow.selectedAppIndex === appItem.index
                        readonly property bool isHovered: appMouse.containsMouse

                        color: ShellState.glassEnabled
                            ? "transparent"
                            : ((isSelected || isHovered) ? Theme.bgHover : Theme.bgCard)
                        border.color: ShellState.glassEnabled
                            ? "transparent"
                            : (isSelected ? Theme.accentCyan : Theme.borderDim)
                        border.width: isSelected ? 1 : (ShellState.glassEnabled ? 0 : 1)

                        LiquidGlassSurface {
                            radius: 8
                            visible: ShellState.glassEnabled && (appItem.isSelected || appItem.isHovered)
                            accentColor: Theme.accentCyan
                            hovered: appItem.isHovered
                            pressed: appMouse.pressed
                            showShadow: false
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 12

                            // App Icon Box
                            Rectangle {
                                width: 36
                                height: 36
                                radius: 8
                                color: ShellState.glassEnabled ? Qt.rgba(Theme.bgCard.r, Theme.bgCard.g, Theme.bgCard.b, 0.4) : Theme.bgBase
                                border.color: Theme.borderDim
                                border.width: 1

                                Image {
                                    id: appIcon
                                    anchors.centerIn: parent
                                    width: 28
                                    height: 28
                                    sourceSize.width: 28
                                    sourceSize.height: 28
                                    fillMode: Image.PreserveAspectFit
                                    source: Quickshell.iconPath(appItem.modelData.icon) || ""
                                    asynchronous: true
                                }

                                // Fallback letter badge
                                Text {
                                    anchors.centerIn: parent
                                    text: (appItem.modelData.name || "A").charAt(0).toUpperCase()
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 15
                                    font.bold: true
                                    color: Theme.accentCyan
                                    visible: appIcon.status !== Image.Ready
                                }
                            }

                            // App Title & Description
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                RowLayout {
                                    spacing: 8
                                    Text {
                                        text: appItem.modelData.name || ""
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: appItem.isSelected ? Theme.accentCyan : Theme.textPrimary
                                        elide: Text.ElideRight
                                    }

                                    // Generic Name tag if available and distinct
                                    Text {
                                        text: (appItem.modelData.genericName && appItem.modelData.genericName.toLowerCase() !== appItem.modelData.name.toLowerCase()) ? ("• " + appItem.modelData.genericName) : ""
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 11
                                        color: Theme.textMuted
                                        visible: text.length > 0
                                        elide: Text.ElideRight
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: appItem.modelData.comment || appItem.modelData.execString || ""
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    color: appItem.isSelected ? Theme.textSecondary : Theme.textMuted
                                    elide: Text.ElideRight
                                    visible: text.length > 0
                                }
                            }

                            // Right-hand launch pill
                            Rectangle {
                                height: 24
                                implicitWidth: launchTxt.implicitWidth + 14
                                radius: 6
                                color: appItem.isSelected ? Theme.accentCyan : Theme.bgHover
                                border.color: appItem.isSelected ? Theme.accentCyan : Theme.borderDim
                                border.width: 1

                                RowLayout {
                                    id: launchTxt
                                    anchors.centerIn: parent
                                    spacing: 4
                                    Text {
                                        text: "↵"
                                        font.family: Theme.fontMono
                                        font.pixelSize: 10
                                        font.bold: true
                                        color: appItem.isSelected ? Theme.textOnAccent : Theme.accentCyan
                                    }
                                    Text {
                                        text: appItem.isSelected ? "Launch" : "Open"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 10
                                        font.bold: true
                                        color: appItem.isSelected ? Theme.textOnAccent : Theme.textMuted
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: appMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: {
                                omnibarWindow.selectedAppIndex = appItem.index;
                            }
                            onClicked: {
                                omnibarWindow.isExecuting = true;
                                appItem.modelData.execute();
                                omnibarWindow.dismissTimer.restart();
                            }
                        }
                    }
                }

                // Semantic Command Fallback Runner Strip
                Rectangle {
                    Layout.fillWidth: true
                    height: 34
                    radius: 8
                    color: semanticMouse.containsMouse ? Theme.bgHover : Theme.bgCard
                    border.color: semanticMouse.containsMouse ? Theme.accentAmber : Theme.borderDim
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 8

                        Icon {
                            name: "terminal"
                            size: 14
                            color: Theme.accentAmber
                        }

                        Text {
                            text: "Run with Antigravity Engine:"
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            color: Theme.textMuted
                        }

                        Text {
                            Layout.fillWidth: true
                            text: '"' + omniInput.text.trim() + '"'
                            font.family: Theme.fontMono
                            font.pixelSize: 11
                            color: Theme.accentAmber
                            elide: Text.ElideRight
                        }

                        Rectangle {
                            height: 20
                            implicitWidth: ctrlEnterTxt.implicitWidth + 8
                            radius: 4
                            color: Theme.bgHover
                            border.color: Theme.borderDim
                            border.width: 1

                            Text {
                                id: ctrlEnterTxt
                                anchors.centerIn: parent
                                text: "Ctrl+↵"
                                font.family: Theme.fontMono
                                font.pixelSize: 9
                                font.bold: true
                                color: Theme.textMuted
                            }
                        }
                    }

                    MouseArea {
                        id: semanticMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            omnibarWindow.executeCurrentCommand(true);
                        }
                    }
                }
            }

            // ── Section A: Live Execution Plan Visualizer (Active input, 0 apps) ──
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 8
                visible: omnibarWindow.spotlightResult === null && (omnibarWindow.matchedApps.length === 0) && omniInput.text.trim().length > 0

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
                            onClicked: omnibarWindow.executeCurrentCommand(true)
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
                            { title: "Pick Screen Color", sub: "Interactive eyedropper", cmd: ":eyedropper", icon: "palette", color: Theme.accentCyan },
                            { title: "Screenshot", sub: "Snip area to clipboard", cmd: "take a screenshot", icon: "image", color: Theme.accentAmber },
                            { title: "Currency Converter", sub: "120 USD to INR", cmd: "120 usd to inr", icon: "refresh-cw", color: Theme.accentEmerald },
                            { title: "World Clock", sub: "Current time in Tokyo", cmd: "time in tokyo", icon: "clock", color: Theme.accentSky },
                            { title: "Glyph & Symbols", sub: "Arrows, math & symbols", cmd: ":arrow", icon: "sparkles", color: Theme.accentViolet },
                            { title: "Virtual Display", sub: "Toggle 1080p Headless", cmd: "turn on virtual display", icon: "monitor", color: Theme.accentRose }
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

                                Icon {
                                    name: modelData.icon
                                    size: 18
                                    color: modelData.color
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
                                    if (modelData.cmd === ":eyedropper") {
                                        eyedropperProc.running = true;
                                    } else {
                                        omniInput.text = modelData.cmd;
                                        omniInput.forceActiveFocus();
                                    }
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
                                omnibarWindow.executeCurrentCommand(true);
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
                        Text {
                            text: omnibarWindow.spotlightResult ? "Copy Result" : ((omnibarWindow.matchedApps && omnibarWindow.matchedApps.length > 0) ? "Launch App" : "Execute")
                            font.family: Theme.fontMono
                            font.pixelSize: 10
                            color: omnibarWindow.spotlightResult ? Theme.accentEmerald : ((omnibarWindow.matchedApps && omnibarWindow.matchedApps.length > 0) ? Theme.accentCyan : Theme.textMuted)
                        }
                    }

                    RowLayout {
                        spacing: 4
                        Rectangle {
                            width: 28; height: 16; radius: 3; color: Theme.bgHover
                            Text { anchors.centerIn: parent; text: "↑↓"; font.pixelSize: 10; color: Theme.textMuted }
                        }
                        Text {
                            text: (omnibarWindow.matchedApps && omnibarWindow.matchedApps.length > 0) ? "Navigate" : "History"
                            font.family: Theme.fontMono
                            font.pixelSize: 10
                            color: Theme.textMuted
                        }
                    }

                    RowLayout {
                        spacing: 4
                        visible: omnibarWindow.matchedApps && omnibarWindow.matchedApps.length > 0
                        Rectangle {
                            width: 38; height: 16; radius: 3; color: Theme.bgHover
                            Text { anchors.centerIn: parent; text: "Ctrl+↵"; font.pixelSize: 9; color: Theme.textMuted }
                        }
                        Text { text: "Run as Cmd"; font.family: Theme.fontMono; font.pixelSize: 10; color: Theme.textMuted }
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
                            text: "Spotlight & App Suite v3.0"
                            font.family: Theme.fontMono
                            font.pixelSize: 10
                            color: Theme.accentAmber
                        }
                    }
                }
            }
        }
    }
}
