import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import "../theme"
import "../services"
import "../components"

PanelWindow {
    id: runnerWindow

    visible: ShellState.runnerOpen
    color: "transparent"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "quickshell:runner"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: ShellState.runnerOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property bool showCreateModal: false
    property string activeCategory: "all"
    property string confirmDeleteId: ""
    property string copiedNotificationText: ""

    // Create modal state
    property string newName: ""
    property string newCommand: ""
    property bool newInteractive: false
    property string newCategory: "Custom"

    onVisibleChanged: {
        if (visible) {
            searchInput.text = "";
            activeCategory = "all";
            showCreateModal = false;
            confirmDeleteId = "";
            TaskRunnerService.refresh();
            Qt.callLater(() => searchInput.forceActiveFocus());
        }
    }

    function showToast(msg) {
        copiedNotificationText = msg;
        toastTimer.restart();
    }

    Timer {
        id: toastTimer
        interval: 2500
        repeat: false
        onTriggered: copiedNotificationText = ""
    }

    function getCategories() {
        const list = TaskRunnerService.tasks || [];
        const cats = ["all"];
        for (let i = 0; i < list.length; i++) {
            const c = list[i].category || "General";
            if (!cats.includes(c)) cats.push(c);
        }
        return cats;
    }

    function getFilteredTasks() {
        const list = TaskRunnerService.tasks || [];
        const q = searchInput.text.toLowerCase().trim();
        return list.filter(t => {
            if (activeCategory !== "all" && (t.category || "General") !== activeCategory) {
                return false;
            }
            if (q.length > 0) {
                const name = (t.name || "").toLowerCase();
                const cmd = (t.command || "").toLowerCase();
                const cat = (t.category || "").toLowerCase();
                return name.includes(q) || cmd.includes(q) || cat.includes(q);
            }
            return true;
        });
    }

    readonly property var filteredTasks: {
        const _dummy = TaskRunnerService.tasks;
        const _q = searchInput.text;
        const _cat = activeCategory;
        return runnerWindow.getFilteredTasks();
    }

    // ── Backdrop Dimmer ─────────────────────────────────────────────────────
    MouseArea {
        anchors.fill: parent
        onClicked: {
            if (showCreateModal) {
                showCreateModal = false;
            } else if (confirmDeleteId !== "") {
                confirmDeleteId = "";
            } else {
                ShellState.runnerOpen = false;
            }
        }

        Rectangle {
            anchors.fill: parent
            color: "#05080E"
            opacity: 0.85
        }
    }

    // ── Main Glassmorphic Modal Card ────────────────────────────────────────
    Rectangle {
        id: card
        width: 860
        height: 600
        anchors.centerIn: parent
        radius: 18
        color: ShellState.glassEnabled ? "transparent" : Theme.bgModal
        border.color: ShellState.glassEnabled ? "transparent" : Theme.borderGlow
        border.width: ShellState.glassEnabled ? 0 : 1

        LiquidGlassSurface {
            radius: 18
            visible: ShellState.glassEnabled
            accentColor: Theme.accentEmerald
            showShadow: true
        }
        clip: true

        Keys.onEscapePressed: {
            if (showCreateModal) {
                showCreateModal = false;
            } else if (confirmDeleteId !== "") {
                confirmDeleteId = "";
            } else {
                ShellState.runnerOpen = false;
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 14

            // ── Header Bar ──────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                // Icon Box (Plastic Gem)
                Rectangle {
                    width: 42
                    height: 42
                    radius: 12
                    color: ShellState.plasticEnabled ? "transparent" : Qt.rgba(Theme.accentEmerald.r, Theme.accentEmerald.g, Theme.accentEmerald.b, 0.15)
                    border.color: ShellState.plasticEnabled ? "transparent" : Theme.accentEmerald
                    border.width: ShellState.plasticEnabled ? 0 : 1

                    LiquidGlassSurface {
                        radius: 12
                        visible: ShellState.plasticEnabled
                        accentColor: Theme.accentEmerald
                        showShadow: false
                    }

                    Icon {
                        anchors.centerIn: parent
                        name: "zap"
                        size: 20
                        color: Theme.accentEmerald
                    }
                }

                // Title & Subtitle
                ColumnLayout {
                    spacing: 2
                    Layout.fillWidth: true

                    RowLayout {
                        spacing: 8

                        Text {
                            text: "DEVELOPER TASK RUNNER"
                            font.family: Theme.fontFamily
                            font.pixelSize: 14
                            font.bold: true
                            color: Theme.textPrimary
                        }

                        // Super + R Plastic Badge
                        Rectangle {
                            height: 18
                            implicitWidth: badgeText.implicitWidth + 10
                            radius: 9
                            color: ShellState.plasticEnabled ? "transparent" : Qt.rgba(Theme.accentSky.r, Theme.accentSky.g, Theme.accentSky.b, 0.15)
                            border.color: ShellState.plasticEnabled ? "transparent" : Theme.accentSky
                            border.width: ShellState.plasticEnabled ? 0 : 1

                            LiquidGlassSurface {
                                radius: 9
                                visible: ShellState.plasticEnabled
                                accentColor: Theme.accentSky
                                showShadow: false
                            }

                            Text {
                                id: badgeText
                                anchors.centerIn: parent
                                text: "SUPER + R"
                                font.family: Theme.fontMono
                                font.pixelSize: 9
                                font.bold: true
                                color: Theme.accentSky
                            }
                        }
                    }

                    Text {
                        text: {
                            const count = TaskRunnerService.tasks ? TaskRunnerService.tasks.length : 0;
                            if (count === 0) {
                                return "No custom tasks configured  •  Click + Create Task to add one";
                            }
                            return count + (count === 1 ? " automation script ready" : " automation scripts & shortcuts ready");
                        }
                        font.family: Theme.fontMono
                        font.pixelSize: 10
                        color: Theme.textMuted
                    }
                }

                // + Create Button (Modal Trigger - Plastic Button)
                Rectangle {
                    height: 32
                    implicitWidth: createBtnLayout.implicitWidth + 24
                    radius: 8
                    color: ShellState.plasticEnabled ? "transparent" : (createBtnMouse.containsMouse ? Theme.accentEmerald : Qt.rgba(Theme.accentEmerald.r, Theme.accentEmerald.g, Theme.accentEmerald.b, 0.2))
                    border.color: ShellState.plasticEnabled ? "transparent" : Theme.accentEmerald
                    border.width: ShellState.plasticEnabled ? 0 : 1

                    LiquidGlassSurface {
                        radius: 8
                        visible: ShellState.plasticEnabled
                        accentColor: Theme.accentEmerald
                        hovered: createBtnMouse.containsMouse
                        pressed: createBtnMouse.pressed
                        showShadow: false
                    }

                    Behavior on color { ColorAnimation { duration: 120 } }

                    RowLayout {
                        id: createBtnLayout
                        anchors.centerIn: parent
                        spacing: 6

                        Icon {
                            name: "plus"
                            size: 13
                            color: createBtnMouse.containsMouse ? Theme.accentEmerald : Theme.textPrimary
                        }

                        Text {
                            text: "Create Task"
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            font.bold: true
                            color: createBtnMouse.containsMouse ? Theme.accentEmerald : Theme.textPrimary
                        }
                    }

                    MouseArea {
                        id: createBtnMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            runnerWindow.newName = "";
                            runnerWindow.newCommand = "";
                            runnerWindow.newInteractive = false;
                            runnerWindow.newCategory = "Custom";
                            runnerWindow.showCreateModal = true;
                        }
                    }
                }

                // Refresh Button (Plastic Gem)
                Rectangle {
                    width: 30
                    height: 30
                    radius: 8
                    color: ShellState.plasticEnabled ? "transparent" : (refreshMouse.containsMouse ? Theme.bgHover : Theme.bgPill)
                    border.color: ShellState.plasticEnabled ? "transparent" : Theme.borderDim
                    border.width: ShellState.plasticEnabled ? 0 : 1

                    LiquidGlassSurface {
                        radius: 8
                        visible: ShellState.plasticEnabled && refreshMouse.containsMouse
                        accentColor: Theme.accentSky
                        hovered: refreshMouse.containsMouse
                        pressed: refreshMouse.pressed
                        showShadow: false
                    }

                    Icon {
                        anchors.centerIn: parent
                        name: "refresh-cw"
                        size: 13
                        color: refreshMouse.containsMouse ? Theme.accentSky : Theme.textMuted
                    }

                    MouseArea {
                        id: refreshMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: TaskRunnerService.refresh()
                    }
                }

                // Close Button (Plastic Gem)
                Rectangle {
                    width: 30
                    height: 30
                    radius: 8
                    color: ShellState.plasticEnabled ? "transparent" : (closeMouse.containsMouse ? Qt.rgba(Theme.accentRose.r, Theme.accentRose.g, Theme.accentRose.b, 0.2) : Theme.bgPill)
                    border.color: ShellState.plasticEnabled ? "transparent" : (closeMouse.containsMouse ? Theme.accentRose : Theme.borderDim)
                    border.width: ShellState.plasticEnabled ? 0 : 1

                    LiquidGlassSurface {
                        radius: 8
                        visible: ShellState.plasticEnabled && closeMouse.containsMouse
                        accentColor: Theme.accentRose
                        hovered: closeMouse.containsMouse
                        pressed: closeMouse.pressed
                        showShadow: false
                    }

                    Icon {
                        anchors.centerIn: parent
                        name: "x"
                        size: 13
                        color: closeMouse.containsMouse ? Theme.accentRose : Theme.textMuted
                    }

                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ShellState.runnerOpen = false
                    }
                }
            }

            // Divider
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.borderDim
            }

            // ── Categories & Search Row ─────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                // Category chips
                RowLayout {
                    spacing: 6
                    visible: runnerWindow.getCategories().length > 1

                    Repeater {
                        model: runnerWindow.getCategories()

                        delegate: Rectangle {
                            required property string modelData
                            height: 28
                            implicitWidth: catChipText.implicitWidth + 16
                            radius: 14
                            color: ShellState.plasticEnabled ? "transparent" : (activeCategory === modelData ? Qt.rgba(Theme.accentEmerald.r, Theme.accentEmerald.g, Theme.accentEmerald.b, 0.25) : Theme.bgPill)
                            border.color: ShellState.plasticEnabled ? "transparent" : (activeCategory === modelData ? Theme.accentEmerald : Theme.borderDim)
                            border.width: ShellState.plasticEnabled ? 0 : 1

                            LiquidGlassSurface {
                                radius: 14
                                visible: ShellState.plasticEnabled && (activeCategory === modelData || catChipMouse.containsMouse)
                                accentColor: Theme.accentEmerald
                                hovered: catChipMouse.containsMouse
                                pressed: catChipMouse.pressed
                                showShadow: false
                            }

                            Rectangle {
                                anchors.fill: parent
                                radius: 14
                                visible: ShellState.plasticEnabled && activeCategory !== modelData && !catChipMouse.containsMouse
                                color: Qt.rgba(0.20, 0.28, 0.40, 0.22)
                                border.color: Qt.rgba(1.0, 1.0, 1.0, 0.12)
                                border.width: 1
                            }

                            Text {
                                id: catChipText
                                anchors.centerIn: parent
                                text: modelData === "all" ? "All Tasks" : modelData
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                font.bold: activeCategory === modelData
                                color: activeCategory === modelData ? Theme.accentEmerald : Theme.textMuted
                            }

                            MouseArea {
                                id: catChipMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: activeCategory = modelData
                            }
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    visible: runnerWindow.getCategories().length <= 1
                }

                Item { Layout.fillWidth: true }

                // Search field (Plastic Channel)
                Rectangle {
                    height: 34
                    implicitWidth: 260
                    radius: 10
                    color: ShellState.plasticEnabled ? "transparent" : Theme.bgPill
                    border.color: ShellState.plasticEnabled ? "transparent" : (searchInput.activeFocus ? Theme.accentSky : Theme.borderDim)
                    border.width: ShellState.plasticEnabled ? 0 : 1

                    LiquidGlassSurface {
                        radius: 10
                        visible: ShellState.plasticEnabled
                        accentColor: searchInput.activeFocus ? Theme.accentSky : Theme.borderDim
                        showShadow: false
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 8
                        spacing: 8

                        Icon {
                            name: "search"
                            size: 13
                            color: Theme.textMuted
                        }

                        TextInput {
                            id: searchInput
                            Layout.fillWidth: true
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            color: Theme.textPrimary
                            selectByMouse: true
                            clip: true

                            Text {
                                anchors.fill: parent
                                text: "Search tasks or commands..."
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                color: Theme.textMuted
                                opacity: 0.6
                                visible: !searchInput.text && !searchInput.activeFocus
                            }
                        }

                        Icon {
                            name: "x"
                            size: 12
                            color: Theme.textMuted
                            visible: searchInput.text.length > 0
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: searchInput.text = ""
                            }
                        }
                    }
                }
            }

            // ── Task Cards List ─────────────────────────────────────────────
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                ListView {
                    id: tasksList
                    anchors.fill: parent
                    spacing: 10
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    model: runnerWindow.filteredTasks

                    ScrollBar.vertical: ScrollBar {
                        policy: tasksList.contentHeight > tasksList.height ? ScrollBar.AlwaysOn : ScrollBar.AsNeeded
                    }

                    // Empty placeholder
                    Item {
                        anchors.fill: parent
                        visible: tasksList.count === 0 && !TaskRunnerService.loading

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 12

                            Rectangle {
                                Layout.alignment: Qt.AlignHCenter
                                width: 64
                                height: 64
                                radius: 32
                                color: Qt.rgba(Theme.accentEmerald.r, Theme.accentEmerald.g, Theme.accentEmerald.b, 0.12)
                                border.color: Theme.accentEmerald
                                border.width: 1

                                Icon {
                                    anchors.centerIn: parent
                                    name: "zap"
                                    size: 28
                                    color: Theme.accentEmerald
                                }
                            }

                            Text {
                                text: searchInput.text ? "No tasks matching '" + searchInput.text + "'" : "No Automation Tasks Configured"
                                font.family: Theme.fontFamily
                                font.pixelSize: 16
                                font.bold: true
                                color: Theme.textPrimary
                                Layout.alignment: Qt.AlignHCenter
                            }

                            Text {
                                text: searchInput.text
                                      ? "Try searching for a different keyword or clear the search filter."
                                      : "Create quick shortcuts, terminal scripts, or background automations to streamline your workflow."
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                color: Theme.textMuted
                                Layout.alignment: Qt.AlignHCenter
                                horizontalAlignment: Text.AlignHCenter
                                Layout.maximumWidth: 440
                                wrapMode: Text.WordWrap
                            }

                            Item { height: 6 }

                            // Action button to create task when empty
                            Rectangle {
                                Layout.alignment: Qt.AlignHCenter
                                height: 36
                                implicitWidth: emptyCreateRow.implicitWidth + 28
                                radius: 8
                                color: emptyCreateMouse.containsMouse ? Qt.lighter(Theme.accentEmerald, 1.1) : Theme.accentEmerald
                                visible: !searchInput.text

                                RowLayout {
                                    id: emptyCreateRow
                                    anchors.centerIn: parent
                                    spacing: 8

                                    Icon {
                                        name: "plus"
                                        size: 14
                                        color: "#000000"
                                    }

                                    Text {
                                        text: "Create Your First Task"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: "#000000"
                                    }
                                }

                                MouseArea {
                                    id: emptyCreateMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        runnerWindow.newName = "";
                                        runnerWindow.newCommand = "";
                                        runnerWindow.newInteractive = false;
                                        runnerWindow.newCategory = "Custom";
                                        runnerWindow.showCreateModal = true;
                                    }
                                }
                            }
                        }
                    }

                    delegate: Rectangle {
                        id: tCard
                        required property var modelData
                        required property int index

                        width: tasksList.width - (tasksList.contentHeight > tasksList.height ? 10 : 0)
                        implicitHeight: 88
                        radius: 12
                        color: ShellState.plasticEnabled ? "transparent" : (tCardMouse.containsMouse ? Theme.bgHover : Theme.bgCard)
                        border.color: ShellState.plasticEnabled ? "transparent" : (tCardMouse.containsMouse ? Theme.borderActive : Theme.borderDim)
                        border.width: ShellState.plasticEnabled ? 0 : 1

                        LiquidGlassSurface {
                            radius: 12
                            visible: ShellState.plasticEnabled
                            accentColor: tCard.modelData.interactive ? (tCardMouse.containsMouse ? Theme.accentViolet : Qt.rgba(Theme.accentViolet.r, Theme.accentViolet.g, Theme.accentViolet.b, 0.6)) : (tCardMouse.containsMouse ? Theme.accentEmerald : Qt.rgba(Theme.accentEmerald.r, Theme.accentEmerald.g, Theme.accentEmerald.b, 0.6))
                            hovered: tCardMouse.containsMouse
                            showShadow: false
                        }

                        // Left vertical accent strip
                        Rectangle {
                            width: 5
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.topMargin: 8
                            anchors.bottomMargin: 8
                            radius: 3
                            color: tCard.modelData.interactive ? Theme.accentViolet : Theme.accentEmerald
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 18
                            anchors.rightMargin: 14
                            anchors.topMargin: 10
                            anchors.bottomMargin: 10
                            spacing: 14

                            // Info Column
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                // Row 1: Name, Mode Badge, Category Pill
                                RowLayout {
                                    spacing: 8

                                    Text {
                                        text: tCard.modelData.name ?? "Untitled Task"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: Theme.textPrimary
                                    }

                                    // Mode Badge: TERMINAL vs BACKGROUND (Plastic Badge)
                                    Rectangle {
                                        height: 20
                                        implicitWidth: modeBadgeRow.implicitWidth + 12
                                        radius: 6
                                        color: ShellState.plasticEnabled ? "transparent" : (tCard.modelData.interactive
                                               ? Qt.rgba(Theme.accentViolet.r, Theme.accentViolet.g, Theme.accentViolet.b, 0.15)
                                               : Qt.rgba(Theme.accentEmerald.r, Theme.accentEmerald.g, Theme.accentEmerald.b, 0.15))
                                        border.color: ShellState.plasticEnabled ? "transparent" : (tCard.modelData.interactive ? Theme.accentViolet : Theme.accentEmerald)
                                        border.width: ShellState.plasticEnabled ? 0 : 1

                                        LiquidGlassSurface {
                                            radius: 6
                                            visible: ShellState.plasticEnabled
                                            accentColor: tCard.modelData.interactive ? Theme.accentViolet : Theme.accentEmerald
                                            showShadow: false
                                        }

                                        RowLayout {
                                            id: modeBadgeRow
                                            anchors.centerIn: parent
                                            spacing: 5

                                            Icon {
                                                name: tCard.modelData.interactive ? "terminal" : "zap"
                                                size: 10
                                                color: tCard.modelData.interactive ? Theme.accentViolet : Theme.accentEmerald
                                            }

                                            Text {
                                                text: tCard.modelData.interactive ? "TERMINAL" : "BACKGROUND"
                                                font.family: Theme.fontMono
                                                font.pixelSize: 9
                                                font.bold: true
                                                color: tCard.modelData.interactive ? Theme.accentViolet : Theme.accentEmerald
                                            }
                                        }
                                    }

                                    // Category Pill
                                    Rectangle {
                                        height: 20
                                        implicitWidth: tcatText.implicitWidth + 10
                                        radius: 6
                                        color: ShellState.plasticEnabled ? "transparent" : Theme.bgPill
                                        border.color: ShellState.plasticEnabled ? "transparent" : Theme.borderDim
                                        border.width: ShellState.plasticEnabled ? 0 : 1

                                        LiquidGlassSurface {
                                            radius: 6
                                            visible: ShellState.plasticEnabled
                                            accentColor: Theme.borderDim
                                            showShadow: false
                                        }

                                        Text {
                                            id: tcatText
                                            anchors.centerIn: parent
                                            text: tCard.modelData.category || "General"
                                            font.family: Theme.fontMono
                                            font.pixelSize: 9
                                            color: Theme.textMuted
                                        }
                                    }
                                }

                                // Row 2: Monospace Code Pill with copy action
                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 28
                                    radius: 6
                                    color: Qt.rgba(0, 0, 0, 0.35)
                                    border.color: Theme.borderDim
                                    border.width: 1

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 8
                                        anchors.rightMargin: 6
                                        spacing: 6

                                        Text {
                                            text: ">_"
                                            font.family: Theme.fontMono
                                            font.pixelSize: 10
                                            font.bold: true
                                            color: tCard.modelData.interactive ? Theme.accentViolet : Theme.accentEmerald
                                            opacity: 0.85
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            text: tCard.modelData.command ?? ""
                                            font.family: Theme.fontMono
                                            font.pixelSize: 10
                                            color: Theme.textSecondary
                                            elide: Text.ElideRight
                                        }

                                        // Copy command button
                                        Rectangle {
                                            width: 22
                                            height: 22
                                            radius: 4
                                            color: copyBtnMouse.containsMouse ? Theme.bgHover : "transparent"

                                            Icon {
                                                anchors.centerIn: parent
                                                name: "copy"
                                                size: 11
                                                color: copyBtnMouse.containsMouse ? Theme.accentEmerald : Theme.textMuted
                                            }

                                            MouseArea {
                                                id: copyBtnMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    Quickshell.execDetached(["wl-copy", tCard.modelData.command]);
                                                    runnerWindow.showToast("Copied command to clipboard!");
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // ── Actions (Apple Plastic) ──────────────────────
                            RowLayout {
                                spacing: 8

                                // RUN BUTTON (Plastic Button)
                                Rectangle {
                                    height: 32
                                    implicitWidth: runBtnRow.implicitWidth + 22
                                    radius: 8
                                    color: ShellState.plasticEnabled ? "transparent" : (runBtnMouse.containsMouse
                                           ? Theme.accentEmerald
                                           : Qt.rgba(Theme.accentEmerald.r, Theme.accentEmerald.g, Theme.accentEmerald.b, 0.18))
                                    border.color: ShellState.plasticEnabled ? "transparent" : Theme.accentEmerald
                                    border.width: ShellState.plasticEnabled ? 0 : 1

                                    LiquidGlassSurface {
                                        radius: 8
                                        visible: ShellState.plasticEnabled
                                        accentColor: Theme.accentEmerald
                                        hovered: runBtnMouse.containsMouse
                                        pressed: runBtnMouse.pressed
                                        showShadow: false
                                    }

                                    RowLayout {
                                        id: runBtnRow
                                        anchors.centerIn: parent
                                        spacing: 6

                                        Icon {
                                            name: TaskRunnerService.runningTaskId === tCard.modelData.id ? "refresh-cw" : "play"
                                            size: 11
                                            color: runBtnMouse.containsMouse ? Theme.accentEmerald : Theme.textPrimary

                                            RotationAnimation on rotation {
                                                running: TaskRunnerService.runningTaskId === tCard.modelData.id
                                                loops: Animation.Infinite
                                                from: 0; to: 360
                                                duration: 1000
                                            }
                                        }

                                        Text {
                                            id: runBtnText
                                            text: TaskRunnerService.runningTaskId === tCard.modelData.id ? "Running..." : "Run"
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 11
                                            font.bold: true
                                            color: runBtnMouse.containsMouse ? Theme.accentEmerald : Theme.textPrimary
                                        }
                                    }

                                    MouseArea {
                                        id: runBtnMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            TaskRunnerService.runTask(tCard.modelData.id);
                                            runnerWindow.showToast("Executing: " + tCard.modelData.name);
                                        }
                                    }
                                }

                                // DELETE BUTTON (Plastic Gem)
                                Rectangle {
                                    width: 32
                                    height: 32
                                    radius: 8
                                    color: ShellState.plasticEnabled ? "transparent" : (tdelMouse.containsMouse ? Qt.rgba(Theme.accentRose.r, Theme.accentRose.g, Theme.accentRose.b, 0.2) : Theme.bgPill)
                                    border.color: ShellState.plasticEnabled ? "transparent" : (tdelMouse.containsMouse ? Theme.accentRose : Theme.borderDim)
                                    border.width: ShellState.plasticEnabled ? 0 : 1

                                    LiquidGlassSurface {
                                        radius: 8
                                        visible: ShellState.plasticEnabled
                                        accentColor: tdelMouse.containsMouse ? Theme.accentRose : Theme.borderDim
                                        hovered: tdelMouse.containsMouse
                                        pressed: tdelMouse.pressed
                                        showShadow: false
                                    }

                                    Icon {
                                        anchors.centerIn: parent
                                        name: "trash-2"
                                        size: 13
                                        color: tdelMouse.containsMouse ? Theme.accentRose : Theme.textMuted
                                    }

                                    MouseArea {
                                        id: tdelMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: confirmDeleteId = tCard.modelData.id
                                    }
                                }
                            }
                        }

                        // Inline Delete Confirmation
                        Rectangle {
                            anchors.fill: parent
                            radius: 12
                            visible: confirmDeleteId === tCard.modelData.id
                            color: Qt.rgba(Theme.bgModal.r, Theme.bgModal.g, Theme.bgModal.b, 0.96)
                            border.color: Theme.accentRose
                            border.width: 1.5

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 14

                                Text {
                                    text: "Delete task '" + tCard.modelData.name + "'?"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: Theme.textPrimary
                                }

                                Rectangle {
                                    height: 28
                                    implicitWidth: yesTaskDelText.implicitWidth + 16
                                    radius: 6
                                    color: Theme.accentRose

                                    Text {
                                        id: yesTaskDelText
                                        anchors.centerIn: parent
                                        text: "Delete"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: "#FFFFFF"
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            confirmDeleteId = "";
                                            TaskRunnerService.deleteTask(tCard.modelData.id);
                                        }
                                    }
                                }

                                Rectangle {
                                    height: 28
                                    implicitWidth: cancelTaskDelText.implicitWidth + 16
                                    radius: 6
                                    color: Theme.bgPill
                                    border.color: Theme.borderDim
                                    border.width: 1

                                    Text {
                                        id: cancelTaskDelText
                                        anchors.centerIn: parent
                                        text: "Cancel"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 11
                                        color: Theme.textSecondary
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: confirmDeleteId = ""
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: tCardMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.NoButton
                        }
                    }
                }

                // ── CREATE TASK SUB-MODAL OVERLAY ───────────────────────────
                Rectangle {
                    anchors.fill: parent
                    radius: 14
                    visible: showCreateModal
                    color: ShellState.plasticEnabled ? "transparent" : Qt.rgba(Theme.bgModal.r, Theme.bgModal.g, Theme.bgModal.b, 0.98)
                    border.color: ShellState.plasticEnabled ? "transparent" : Theme.accentEmerald
                    border.width: ShellState.plasticEnabled ? 0 : 1.5

                    LiquidGlassSurface {
                        radius: 14
                        visible: ShellState.plasticEnabled
                        accentColor: Theme.accentEmerald
                        showShadow: true
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 22
                        spacing: 12

                        // Modal Header
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Icon {
                                name: "zap"
                                size: 15
                                color: Theme.accentEmerald
                            }

                            Text {
                                text: "CREATE NEW AUTOMATION TASK"
                                font.family: Theme.fontFamily
                                font.pixelSize: 13
                                font.bold: true
                                color: Theme.accentEmerald
                            }

                            Item { Layout.fillWidth: true }

                            Rectangle {
                                width: 26
                                height: 26
                                radius: 6
                                color: Theme.bgPill
                                border.color: Theme.borderDim
                                border.width: 1

                                Icon {
                                    anchors.centerIn: parent
                                    name: "x"
                                    size: 12
                                    color: Theme.textMuted
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: showCreateModal = false
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: Theme.borderDim
                        }

                        // Field 1: Task Name
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            Text {
                                text: "TASK NAME"
                                font.family: Theme.fontMono
                                font.pixelSize: 9
                                font.bold: true
                                color: Theme.textMuted
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 36
                                radius: 8
                                color: Theme.bgCard
                                border.color: nameInput.activeFocus ? Theme.accentEmerald : Theme.borderDim
                                border.width: 1

                                TextInput {
                                    id: nameInput
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    text: runnerWindow.newName
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    color: Theme.textPrimary
                                    onTextChanged: runnerWindow.newName = text

                                    Text {
                                        anchors.fill: parent
                                        text: "e.g. Restart Local Containers"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 11
                                        color: Theme.textMuted
                                        opacity: 0.5
                                        visible: !nameInput.text && !nameInput.activeFocus
                                    }
                                }
                            }
                        }

                        // Field 2: Command
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            Text {
                                text: "COMMAND TO EXECUTE"
                                font.family: Theme.fontMono
                                font.pixelSize: 9
                                font.bold: true
                                color: Theme.textMuted
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 36
                                radius: 8
                                color: Theme.bgCard
                                border.color: cmdInput.activeFocus ? Theme.accentEmerald : Theme.borderDim
                                border.width: 1

                                TextInput {
                                    id: cmdInput
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    text: runnerWindow.newCommand
                                    font.family: Theme.fontMono
                                    font.pixelSize: 10
                                    color: Theme.accentSky
                                    onTextChanged: runnerWindow.newCommand = text

                                    Text {
                                        anchors.fill: parent
                                        text: "e.g. docker restart lms-local-celery"
                                        font.family: Theme.fontMono
                                        font.pixelSize: 10
                                        color: Theme.textMuted
                                        opacity: 0.5
                                        visible: !cmdInput.text && !cmdInput.activeFocus
                                    }
                                }
                            }
                        }

                        // Field 3: Category
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            Text {
                                text: "CATEGORY"
                                font.family: Theme.fontMono
                                font.pixelSize: 9
                                font.bold: true
                                color: Theme.textMuted
                            }

                            RowLayout {
                                spacing: 8

                                Repeater {
                                    model: ["Backend", "Docker", "Git", "Scripts", "Custom"]

                                    delegate: Rectangle {
                                        required property string modelData
                                        height: 26
                                        implicitWidth: catOptText.implicitWidth + 14
                                        radius: 6
                                        color: runnerWindow.newCategory === modelData ? Qt.rgba(Theme.accentEmerald.r, Theme.accentEmerald.g, Theme.accentEmerald.b, 0.2) : Theme.bgCard
                                        border.color: runnerWindow.newCategory === modelData ? Theme.accentEmerald : Theme.borderDim
                                        border.width: 1

                                        Text {
                                            id: catOptText
                                            anchors.centerIn: parent
                                            text: modelData
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 10
                                            font.bold: runnerWindow.newCategory === modelData
                                            color: runnerWindow.newCategory === modelData ? Theme.accentEmerald : Theme.textSecondary
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: runnerWindow.newCategory = modelData
                                        }
                                    }
                                }
                            }
                        }

                        // Field 4: Interactive Yes / No
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Text {
                                text: "EXECUTION MODE"
                                font.family: Theme.fontMono
                                font.pixelSize: 9
                                font.bold: true
                                color: Theme.textMuted
                            }

                            RowLayout {
                                spacing: 10

                                // Option NO (Silent Background)
                                Rectangle {
                                    height: 38
                                    implicitWidth: optNoRow.implicitWidth + 24
                                    radius: 8
                                    color: !runnerWindow.newInteractive ? Qt.rgba(Theme.accentEmerald.r, Theme.accentEmerald.g, Theme.accentEmerald.b, 0.2) : Theme.bgCard
                                    border.color: !runnerWindow.newInteractive ? Theme.accentEmerald : Theme.borderDim
                                    border.width: 1

                                    RowLayout {
                                        id: optNoRow
                                        anchors.centerIn: parent
                                        spacing: 7

                                        Icon {
                                            name: "zap"
                                            size: 13
                                            color: !runnerWindow.newInteractive ? Theme.accentEmerald : Theme.textMuted
                                        }

                                        Text {
                                            id: optNoText
                                            text: "No (Silent Background)"
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 10
                                            font.bold: !runnerWindow.newInteractive
                                            color: !runnerWindow.newInteractive ? Theme.accentEmerald : Theme.textSecondary
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: runnerWindow.newInteractive = false
                                    }
                                }

                                // Option YES (Interactive Kitty Terminal)
                                Rectangle {
                                    height: 38
                                    implicitWidth: optYesRow.implicitWidth + 24
                                    radius: 8
                                    color: runnerWindow.newInteractive ? Qt.rgba(Theme.accentViolet.r, Theme.accentViolet.g, Theme.accentViolet.b, 0.2) : Theme.bgCard
                                    border.color: runnerWindow.newInteractive ? Theme.accentViolet : Theme.borderDim
                                    border.width: 1

                                    RowLayout {
                                        id: optYesRow
                                        anchors.centerIn: parent
                                        spacing: 7

                                        Icon {
                                            name: "terminal"
                                            size: 13
                                            color: runnerWindow.newInteractive ? Theme.accentViolet : Theme.textMuted
                                        }

                                        Text {
                                            id: optYesText
                                            text: "Yes (Interactive Kitty Terminal)"
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 10
                                            font.bold: runnerWindow.newInteractive
                                            color: runnerWindow.newInteractive ? Theme.accentViolet : Theme.textSecondary
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: runnerWindow.newInteractive = true
                                    }
                                }
                            }
                        }

                        Item { Layout.fillHeight: true }

                        // Form Buttons
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            Item { Layout.fillWidth: true }

                            Rectangle {
                                height: 34
                                implicitWidth: cancelFormText.implicitWidth + 22
                                radius: 8
                                color: Theme.bgPill
                                border.color: Theme.borderDim
                                border.width: 1

                                Text {
                                    id: cancelFormText
                                    anchors.centerIn: parent
                                    text: "Cancel"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    color: Theme.textSecondary
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: showCreateModal = false
                                }
                            }

                            Rectangle {
                                height: 34
                                implicitWidth: saveFormText.implicitWidth + 26
                                radius: 8
                                color: ShellState.plasticEnabled ? "transparent" : ((runnerWindow.newName.trim() && runnerWindow.newCommand.trim()) ? Theme.accentEmerald : Theme.bgPill)
                                border.color: ShellState.plasticEnabled ? "transparent" : ((runnerWindow.newName.trim() && runnerWindow.newCommand.trim()) ? Theme.accentEmerald : Theme.borderDim)
                                border.width: ShellState.plasticEnabled ? 0 : 1

                                LiquidGlassSurface {
                                    radius: 8
                                    visible: ShellState.plasticEnabled && !!(runnerWindow.newName.trim() && runnerWindow.newCommand.trim())
                                    accentColor: Theme.accentEmerald
                                    showShadow: false
                                }

                                Text {
                                    id: saveFormText
                                    anchors.centerIn: parent
                                    text: "Save & Add Task"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: (runnerWindow.newName.trim() && runnerWindow.newCommand.trim()) ? "#000000" : Theme.textMuted
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    enabled: !!(runnerWindow.newName.trim() && runnerWindow.newCommand.trim())
                                    onClicked: {
                                        TaskRunnerService.createTask(
                                            runnerWindow.newName.trim(),
                                            runnerWindow.newCommand.trim(),
                                            runnerWindow.newInteractive,
                                            runnerWindow.newCategory
                                        );
                                        showCreateModal = false;
                                        runnerWindow.showToast("Task '" + runnerWindow.newName + "' saved!");
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ── Footer Bar ──────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                // Toast notification pill
                Rectangle {
                    visible: copiedNotificationText.length > 0
                    height: 22
                    implicitWidth: toastRunnerRow.implicitWidth + 18
                    radius: 11
                    color: Qt.rgba(Theme.accentEmerald.r, Theme.accentEmerald.g, Theme.accentEmerald.b, 0.2)
                    border.color: Theme.accentEmerald
                    border.width: 1

                    RowLayout {
                        id: toastRunnerRow
                        anchors.centerIn: parent
                        spacing: 5

                        Icon {
                            name: "check"
                            size: 10
                            color: Theme.accentEmerald
                        }

                        Text {
                            text: copiedNotificationText
                            font.family: Theme.fontMono
                            font.pixelSize: 9
                            font.bold: true
                            color: Theme.accentEmerald
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: "SUPER + R to toggle  •  ESC to close  •  Click Run to execute"
                    font.family: Theme.fontMono
                    font.pixelSize: 9
                    color: Theme.textMuted
                }
            }
        }
    }
}
