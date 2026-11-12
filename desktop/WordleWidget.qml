import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import "../theme"
import "../services"
import "../components"

PanelWindow {
    id: root

    visible: !ShellState.liteMode && ShellState.desktopWordleVisible

    anchors {
        top: true
        right: true
    }

    margins {
        top: (!ShellState.desktopClockVisible) ? 76 : 596
        right: ShellState.desktopPullRequestsVisible ? 364 : 48
    }

    Behavior on margins.top {
        NumberAnimation { duration: 250; easing.type: Easing.OutQuad }
    }
    Behavior on margins.right {
        NumberAnimation { duration: 250; easing.type: Easing.OutQuad }
    }

    implicitWidth: 330
    implicitHeight: mainCard.implicitHeight

    color: "transparent"

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "quickshell:desktop:wordle"
    WlrLayershell.layer: WlrLayer.Bottom

    // ── Wordle Game State ───────────────────────────────────────────────────
    property var wordsList: [
        "REACT", "FLUID", "LIGHT", "PRISM", "SPACE", "CLOUD", "SMART", "BRAIN",
        "SPARK", "CYBER", "PIXEL", "GHOST", "MAGIC", "DREAM", "POWER", "BUILD",
        "SCOPE", "CACHE", "STACK", "FETCH", "ASYNC", "QUERY", "STATE", "ROBOT",
        "LOGIC", "ARRAY", "INDEX", "LINUX", "SHELL", "SWIFT", "CARGO", "PROXY",
        "TIMER", "TOKEN", "TRACK", "VALID", "ROUTE", "PATCH", "MERGE", "PULSE",
        "SCALE", "SHINE", "CLOCK", "SHARD", "DEBUG", "EVENT", "INPUT", "MOUSE",
        "SOUND", "NEONS", "THEME", "GLYPH", "GRAPH", "HYPER", "MODEL", "AGENT",
        "FLASH", "QUICK", "VIBES", "SHARP", "CLEAN", "DRIVE", "MEDIA", "AUDIO",
        "CRISP", "FOCUS", "FORGE", "FRAME", "LAYER", "MODAL", "PANEL", "RADAR",
        "RADIO", "RESET", "SLICK", "STORE", "STYLE", "SURRF", "VAPOR", "WAVES",
        "WORLD", "ZONES", "BATCH", "BLOCK", "BOOST", "BURST", "CHART", "CHECK",
        "CLEAR", "COUNT", "DELTA", "DRIFT", "ECHOES", "ENTRY", "EXTRA", "FIBER",
        "FLOAT", "GENUS", "GRAVE", "GUARD", "IMAGE", "INBOX", "KANBAN", "LABEL"
    ]

    property string targetWord: "REACT"
    property bool isDailyMode: true
    property var guesses: ["", "", "", "", "", ""]
    property var evaluations: [[], [], [], [], [], []] // "correct", "present", "absent"
    property int currentRow: 0
    property string currentInput: ""
    property bool gameOver: false
    property bool gameWon: false
    property string statusMessage: ""
    property var letterStatusMap: ({}) // 'A': 'correct'/'present'/'absent'

    // Stats
    property int playedCount: 0
    property int wonCount: 0
    property int currentStreak: 0
    property int maxStreak: 0

    readonly property string statsPath: Quickshell.env("HOME") + "/.local/state/quickshell/user/wordle-stats.json"

    function loadStats() {
        Quickshell.execDetached(["python3", "-c",
            "import json, os, sys; p=sys.argv[1]; print(open(p).read() if os.path.exists(p) else '{}')",
            statsPath
        ]);
    }

    function saveStats() {
        const payload = JSON.stringify({
            played: playedCount,
            won: wonCount,
            streak: currentStreak,
            maxStreak: maxStreak
        });
        Quickshell.execDetached(["python3", "-c",
            "import sys, os; os.makedirs(os.path.dirname(sys.argv[1]), exist_ok=True); open(sys.argv[1], 'w').write(sys.argv[2])",
            statsPath, payload
        ]);
    }

    function getDailyWord() {
        const today = new Date();
        const dateKey = today.getFullYear() * 10000 + (today.getMonth() + 1) * 100 + today.getDate();
        // Deterministic pseudo random index
        const idx = Math.abs((dateKey * 9301 + 49297) % wordsList.length);
        return wordsList[idx];
    }

    function startNewGame(daily) {
        isDailyMode = daily;
        if (daily) {
            targetWord = getDailyWord();
        } else {
            const r = Math.floor(Math.random() * wordsList.length);
            targetWord = wordsList[r];
        }

        guesses = ["", "", "", "", "", ""];
        evaluations = [[], [], [], [], [], []];
        currentRow = 0;
        currentInput = "";
        gameOver = false;
        gameWon = false;
        statusMessage = "";
        letterStatusMap = {};
    }

    Component.onCompleted: {
        startNewGame(true);
    }

    // Handle Keyboard Input
    function handleKey(k) {
        if (gameOver) return;

        const key = k.toUpperCase();

        if (key === "BACKSPACE" || key === "⌫") {
            if (currentInput.length > 0) {
                currentInput = currentInput.slice(0, -1);
                guesses[currentRow] = currentInput;
                guesses = guesses.slice();
            }
            return;
        }

        if (key === "ENTER" || key === "↵") {
            if (currentInput.length === 5) {
                submitGuess();
            } else {
                statusMessage = "Word too short";
                msgTimer.restart();
            }
            return;
        }

        // Letter A-Z
        if (/^[A-Z]$/.test(key)) {
            if (currentInput.length < 5) {
                currentInput += key;
                guesses[currentRow] = currentInput;
                guesses = guesses.slice();
            }
        }
    }

    // Evaluate Guess with standard Wordle logic
    function submitGuess() {
        const guess = currentInput;
        const target = targetWord;
        const result = ["absent", "absent", "absent", "absent", "absent"];
        const targetCounts = {};

        for (let i = 0; i < 5; i++) {
            const ch = target[i];
            targetCounts[ch] = (targetCounts[ch] || 0) + 1;
        }

        // Pass 1: find exact matches (correct)
        for (let i = 0; i < 5; i++) {
            if (guess[i] === target[i]) {
                result[i] = "correct";
                targetCounts[guess[i]]--;
            }
        }

        // Pass 2: find partial matches (present)
        for (let i = 0; i < 5; i++) {
            if (result[i] !== "correct") {
                const ch = guess[i];
                if (targetCounts[ch] && targetCounts[ch] > 0) {
                    result[i] = "present";
                    targetCounts[ch]--;
                }
            }
        }

        // Update keyboard letter status map
        const newMap = Object.assign({}, letterStatusMap);
        for (let i = 0; i < 5; i++) {
            const ch = guess[i];
            const current = newMap[ch];
            if (result[i] === "correct") {
                newMap[ch] = "correct";
            } else if (result[i] === "present" && current !== "correct") {
                newMap[ch] = "present";
            } else if (!current) {
                newMap[ch] = "absent";
            }
        }
        letterStatusMap = newMap;

        evaluations[currentRow] = result;
        evaluations = evaluations.slice();

        if (guess === target) {
            gameWon = true;
            gameOver = true;
            statusMessage = "GENIUS! SOLVED";
            playedCount++;
            wonCount++;
            currentStreak++;
            maxStreak = Math.max(maxStreak, currentStreak);
            saveStats();
            return;
        }

        if (currentRow === 5) {
            gameOver = true;
            statusMessage = targetWord;
            playedCount++;
            currentStreak = 0;
            saveStats();
            return;
        }

        currentRow++;
        currentInput = "";
    }

    Timer {
        id: msgTimer
        interval: 1800
        repeat: false
        onTriggered: {
            if (!gameOver) statusMessage = "";
        }
    }

    // ── Main Card Surface ───────────────────────────────────────────────────
    Rectangle {
        id: mainCard
        width: 330
        implicitHeight: cardContent.implicitHeight + 24
        radius: 14
        color: ShellState.glassEnabled ? "transparent" : (Theme.bgSurfaceGlass || Theme.bgSurface)
        border.color: ShellState.glassEnabled ? "transparent" : Theme.borderDim
        border.width: ShellState.glassEnabled ? 0 : 1

        LiquidGlassSurface {
            radius: 14
            visible: ShellState.glassEnabled
            accentColor: Theme.accentEmerald
            showShadow: true
        }

        // Keyboard focus catcher
        focus: true
        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Backspace) {
                root.handleKey("BACKSPACE");
                event.accepted = true;
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                root.handleKey("ENTER");
                event.accepted = true;
            } else if (event.text && event.text.length === 1 && /^[a-zA-Z]$/.test(event.text)) {
                root.handleKey(event.text);
                event.accepted = true;
            }
        }

        MouseArea {
            anchors.fill: parent
            propagateComposedEvents: true
            onClicked: (mouse) => {
                mainCard.forceActiveFocus();
                mouse.accepted = false;
            }
        }

        ColumnLayout {
            id: cardContent
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            // ── Header Bar ──
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Icon {
                    name: "type"
                    size: 15
                    color: Theme.accentEmerald
                }

                Text {
                    text: "WORDLE"
                    font.family: Theme.fontMono
                    font.pixelSize: 11
                    font.bold: true
                    color: Theme.textPrimary
                }

                // Daily / Free Mode Pill
                Rectangle {
                    height: 20
                    implicitWidth: modeTxt.implicitWidth + 10
                    radius: 4
                    color: modeM.containsMouse ? Theme.bgHover : Theme.bgBase
                    border.color: Theme.borderDim
                    border.width: 1

                    Text {
                        id: modeTxt
                        anchors.centerIn: parent
                        text: root.isDailyMode ? "DAILY" : "FREE"
                        font.family: Theme.fontMono
                        font.pixelSize: 9
                        font.bold: true
                        color: root.isDailyMode ? Theme.accentCyan : Theme.accentAmber
                    }

                    MouseArea {
                        id: modeM
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.startNewGame(!root.isDailyMode)
                    }
                }

                Item { Layout.fillWidth: true }

                // Status Toast
                Text {
                    text: root.statusMessage
                    font.family: Theme.fontMono
                    font.pixelSize: 10
                    font.bold: true
                    color: root.gameWon ? Theme.accentEmerald : (root.gameOver ? Theme.accentRose : Theme.accentAmber)
                    visible: root.statusMessage.length > 0
                }

                // Restart / New Game Button
                Rectangle {
                    width: 22
                    height: 22
                    radius: 5
                    color: resetM.containsMouse ? Theme.bgHover : "transparent"
                    border.color: resetM.containsMouse ? Theme.borderDim : "transparent"
                    border.width: 1

                    Icon {
                        anchors.centerIn: parent
                        name: "refresh-cw"
                        size: 12
                        color: Theme.accentCyan
                    }

                    MouseArea {
                        id: resetM
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.startNewGame(root.isDailyMode)
                    }
                }

                // Close / Minimize Button
                Rectangle {
                    width: 22
                    height: 22
                    radius: 5
                    color: closeM.containsMouse ? Theme.bgHover : "transparent"

                    Icon {
                        anchors.centerIn: parent
                        name: "x"
                        size: 12
                        color: Theme.textMuted
                    }

                    MouseArea {
                        id: closeM
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ShellState.desktopWordleVisible = false
                    }
                }
            }

            // ── Wordle Grid (6 Rows x 5 Letters) ──
            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 5

                Repeater {
                    model: 6

                    RowLayout {
                        id: rowLayout
                        readonly property int rowIndex: index
                        spacing: 5

                        Repeater {
                            model: 5

                            Rectangle {
                                id: tileRect
                                readonly property int colIndex: index
                                readonly property string letter: {
                                    const rowGuess = root.guesses[rowLayout.rowIndex] || "";
                                    return rowGuess[colIndex] || "";
                                }
                                readonly property string evalState: {
                                    const rowEval = root.evaluations[rowLayout.rowIndex] || [];
                                    return rowEval[colIndex] || "";
                                }

                                width: 36
                                height: 36
                                radius: 6

                                color: {
                                    if (evalState === "correct") return Theme.accentEmerald;
                                    if (evalState === "present") return Theme.accentAmber;
                                    if (evalState === "absent")  return Qt.rgba(Theme.bgSurface.r, Theme.bgSurface.g, Theme.bgSurface.b, 0.4);
                                    return (letter.length > 0 && rowLayout.rowIndex === root.currentRow) ? Theme.bgHover : Theme.bgBase;
                                }

                                border.color: {
                                    if (evalState === "correct" || evalState === "present") return "transparent";
                                    if (letter.length > 0 && rowLayout.rowIndex === root.currentRow) return Theme.accentCyan;
                                    return Theme.borderDim;
                                }
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: tileRect.letter
                                    font.family: Theme.fontMono
                                    font.pixelSize: 16
                                    font.bold: true
                                    color: (tileRect.evalState === "correct" || tileRect.evalState === "present")
                                        ? Theme.textOnAccent
                                        : (tileRect.letter.length > 0 ? Theme.textPrimary : Theme.textMuted)
                                }
                            }
                        }
                    }
                }
            }

            // ── Interactive Virtual Keyboard ──
            ColumnLayout {
                Layout.fillWidth: true
                Layout.topMargin: 4
                spacing: 4

                // Keyboard Row 1
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 3

                    Repeater {
                        model: ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"]
                        delegate: Rectangle {
                            id: key1
                            width: 27
                            height: 28
                            radius: 4
                            readonly property string kState: root.letterStatusMap[modelData] || ""

                            color: {
                                if (kState === "correct") return Theme.accentEmerald;
                                if (kState === "present") return Theme.accentAmber;
                                if (kState === "absent")  return Qt.rgba(255, 255, 255, 0.05);
                                return km1.containsMouse ? Theme.bgHover : Theme.bgBase;
                            }
                            border.color: Theme.borderDim
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                font.family: Theme.fontMono
                                font.pixelSize: 10
                                font.bold: true
                                color: (key1.kState === "correct" || key1.kState === "present") ? Theme.textOnAccent : Theme.textPrimary
                            }

                            MouseArea {
                                id: km1
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.handleKey(modelData)
                            }
                        }
                    }
                }

                // Keyboard Row 2
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 3

                    Repeater {
                        model: ["A", "S", "D", "F", "G", "H", "J", "K", "L"]
                        delegate: Rectangle {
                            id: key2
                            width: 27
                            height: 28
                            radius: 4
                            readonly property string kState: root.letterStatusMap[modelData] || ""

                            color: {
                                if (kState === "correct") return Theme.accentEmerald;
                                if (kState === "present") return Theme.accentAmber;
                                if (kState === "absent")  return Qt.rgba(255, 255, 255, 0.05);
                                return km2.containsMouse ? Theme.bgHover : Theme.bgBase;
                            }
                            border.color: Theme.borderDim
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                font.family: Theme.fontMono
                                font.pixelSize: 10
                                font.bold: true
                                color: (key2.kState === "correct" || key2.kState === "present") ? Theme.textOnAccent : Theme.textPrimary
                            }

                            MouseArea {
                                id: km2
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.handleKey(modelData)
                            }
                        }
                    }
                }

                // Keyboard Row 3
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 3

                    // Enter Key
                    Rectangle {
                        width: 38
                        height: 28
                        radius: 4
                        color: enterM.containsMouse ? Theme.accentCyan : Theme.bgBase
                        border.color: Theme.borderDim
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "↵"
                            font.family: Theme.fontMono
                            font.pixelSize: 11
                            font.bold: true
                            color: enterM.containsMouse ? Theme.textOnAccent : Theme.accentCyan
                        }

                        MouseArea {
                            id: enterM
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.handleKey("ENTER")
                        }
                    }

                    Repeater {
                        model: ["Z", "X", "C", "V", "B", "N", "M"]
                        delegate: Rectangle {
                            id: key3
                            width: 27
                            height: 28
                            radius: 4
                            readonly property string kState: root.letterStatusMap[modelData] || ""

                            color: {
                                if (kState === "correct") return Theme.accentEmerald;
                                if (kState === "present") return Theme.accentAmber;
                                if (kState === "absent")  return Qt.rgba(255, 255, 255, 0.05);
                                return km3.containsMouse ? Theme.bgHover : Theme.bgBase;
                            }
                            border.color: Theme.borderDim
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                font.family: Theme.fontMono
                                font.pixelSize: 10
                                font.bold: true
                                color: (key3.kState === "correct" || key3.kState === "present") ? Theme.textOnAccent : Theme.textPrimary
                            }

                            MouseArea {
                                id: km3
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.handleKey(modelData)
                            }
                        }
                    }

                    // Backspace Key
                    Rectangle {
                        width: 38
                        height: 28
                        radius: 4
                        color: bsM.containsMouse ? Theme.accentAmber : Theme.bgBase
                        border.color: Theme.borderDim
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "⌫"
                            font.family: Theme.fontMono
                            font.pixelSize: 11
                            color: bsM.containsMouse ? Theme.textOnAccent : Theme.textPrimary
                        }

                        MouseArea {
                            id: bsM
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.handleKey("BACKSPACE")
                        }
                    }
                }
            }
        }
    }
}
