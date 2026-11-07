import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import "../theme"
import "../services"
import "../components"

PanelWindow {
    id: dockerWindow

    visible: ShellState.dockerOpen
    color: "transparent"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "quickshell:docker"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: ShellState.dockerOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property string activeTab: "containers" // "containers", "images"
    property string statusFilter: "all"     // "all", "running", "stopped", "compose"
    property bool showLogDrawer: false
    property string selectedLogLines: "150"
    property string confirmDeleteTarget: ""
    property string copiedNotificationText: ""

    onVisibleChanged: {
        if (visible) {
            searchInput.text = "";
            activeTab = "containers";
            statusFilter = "all";
            showLogDrawer = false;
            confirmDeleteTarget = "";
            DockerService.refresh();
            DockerService.updateStats();
            Qt.callLater(() => {
                searchInput.forceActiveFocus();
            });
        }
    }

    // Reactive properties for filtered lists
    readonly property var filteredContainers: {
        const _dummy = DockerService.containers;
        const _q = searchInput.text;
        const _sf = statusFilter;
        return dockerWindow.getFilteredContainers();
    }

    readonly property var filteredImages: {
        const _dummy = DockerService.images;
        const _q = searchInput.text;
        return dockerWindow.getFilteredImages();
    }

    // Helper to filter containers
    function getFilteredContainers() {
        const list = DockerService.containers || [];
        const q = searchInput.text.toLowerCase().trim();
        return list.filter(c => {
            if (statusFilter === "running" && c.state !== "running") return false;
            if (statusFilter === "stopped" && c.state === "running") return false;
            if (statusFilter === "compose" && (!c.compose_project || c.compose_project.length === 0)) return false;

            if (q.length > 0) {
                const name = (c.name || "").toLowerCase();
                const image = (c.image || "").toLowerCase();
                const id = (c.id || "").toLowerCase();
                const ports = (c.ports || "").toLowerCase();
                const proj = (c.compose_project || "").toLowerCase();
                const status = (c.status || "").toLowerCase();
                return name.includes(q) || image.includes(q) || id.includes(q) || ports.includes(q) || proj.includes(q) || status.includes(q);
            }
            return true;
        });
    }

    // Helper to filter images
    function getFilteredImages() {
        const list = DockerService.images || [];
        const q = searchInput.text.toLowerCase().trim();
        return list.filter(img => {
            if (q.length > 0) {
                const repo = (img.repository || "").toLowerCase();
                const tag = (img.tag || "").toLowerCase();
                const id = (img.id || "").toLowerCase();
                return repo.includes(q) || tag.includes(q) || id.includes(q);
            }
            return true;
        });
    }

    function showCopiedToast(msg) {
        copiedNotificationText = msg;
        copyToastTimer.restart();
    }

    Timer {
        id: copyToastTimer
        interval: 2200
        repeat: false
        onTriggered: copiedNotificationText = ""
    }

    // ── Backdrop Dimmer ─────────────────────────────────────────────────────
    MouseArea {
        anchors.fill: parent
        onClicked: {
            if (confirmDeleteTarget !== "") {
                confirmDeleteTarget = "";
            } else if (showLogDrawer) {
                showLogDrawer = false;
            } else {
                ShellState.dockerOpen = false;
            }
        }

        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: 0.72
        }
    }

    // ── Main Glassmorphic Modal Card ────────────────────────────────────────
    Rectangle {
        id: card
        width: 920
        height: 660
        anchors.centerIn: parent
        radius: 18
        color: ShellState.glassEnabled ? "transparent" : Theme.bgModal
        border.color: ShellState.glassEnabled ? "transparent" : Theme.borderGlow
        border.width: ShellState.glassEnabled ? 0 : 1

        LiquidGlassSurface {
            radius: 18
            visible: ShellState.glassEnabled
            accentColor: Theme.accentSky
            showShadow: true
        }
        clip: true

        Keys.onEscapePressed: {
            if (confirmDeleteTarget !== "") {
                confirmDeleteTarget = "";
            } else if (showLogDrawer) {
                showLogDrawer = false;
            } else {
                ShellState.dockerOpen = false;
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {} // Prevents backdrop click propagation
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12

            // ── Header Bar ──────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                // Docker Icon Box (Plastic Gem)
                Rectangle {
                    width: 42
                    height: 42
                    radius: 12
                    color: ShellState.plasticEnabled ? "transparent" : Qt.rgba(Theme.accentSky.r, Theme.accentSky.g, Theme.accentSky.b, 0.15)
                    border.color: ShellState.plasticEnabled ? "transparent" : Theme.accentSky
                    border.width: ShellState.plasticEnabled ? 0 : 1

                    LiquidGlassSurface {
                        radius: 12
                        visible: ShellState.plasticEnabled
                        accentColor: Theme.accentSky
                        showShadow: false
                    }

                    Icon {
                        anchors.centerIn: parent
                        name: "layers"
                        size: 20
                        color: Theme.accentSky
                    }
                }

                // Title & Telemetry summary
                ColumnLayout {
                    spacing: 3
                    Layout.fillWidth: true

                    RowLayout {
                        spacing: 8

                        Text {
                            text: "DOCKER CONTAINER MANAGER"
                            font.family: Theme.fontFamily
                            font.pixelSize: 14
                            font.bold: true
                            color: Theme.textPrimary
                        }

                        // Daemon Status Badge
                        Rectangle {
                            height: 18
                            implicitWidth: daemonStatusRow.implicitWidth + 10
                            radius: 9
                            color: ShellState.plasticEnabled ? "transparent" : (DockerService.daemonRunning
                                   ? Qt.rgba(Theme.accentEmerald.r, Theme.accentEmerald.g, Theme.accentEmerald.b, 0.15)
                                   : Qt.rgba(Theme.accentRose.r, Theme.accentRose.g, Theme.accentRose.b, 0.15))
                            border.color: ShellState.plasticEnabled ? "transparent" : (DockerService.daemonRunning ? Theme.accentEmerald : Theme.accentRose)
                            border.width: ShellState.plasticEnabled ? 0 : 1

                            LiquidGlassSurface {
                                radius: 9
                                visible: ShellState.plasticEnabled
                                accentColor: DockerService.daemonRunning ? Theme.accentEmerald : Theme.accentRose
                                showShadow: false
                            }

                            RowLayout {
                                id: daemonStatusRow
                                anchors.centerIn: parent
                                spacing: 4

                                Rectangle {
                                    width: 6
                                    height: 6
                                    radius: 3
                                    color: DockerService.daemonRunning ? Theme.accentEmerald : Theme.accentRose
                                }

                                Text {
                                    text: DockerService.daemonRunning ? "DAEMON ONLINE" : "DAEMON OFFLINE"
                                    font.family: Theme.fontMono
                                    font.pixelSize: 8
                                    font.bold: true
                                    color: DockerService.daemonRunning ? Theme.accentEmerald : Theme.accentRose
                                }
                            }
                        }
                    }

                    // Secondary telemetry chips
                    RowLayout {
                        spacing: 10

                        Text {
                            text: "● " + DockerService.summary.running + " running"
                            font.family: Theme.fontMono
                            font.pixelSize: 9
                            font.bold: true
                            color: Theme.accentEmerald
                        }

                        Text {
                            text: "○ " + DockerService.summary.stopped + " stopped"
                            font.family: Theme.fontMono
                            font.pixelSize: 9
                            color: Theme.textMuted
                        }

                        Text {
                            text: "◆ " + DockerService.summary.images_count + " images"
                            font.family: Theme.fontMono
                            font.pixelSize: 9
                            color: Theme.accentViolet
                        }

                        Text {
                            text: "•  Updated " + DockerService.lastUpdated
                            font.family: Theme.fontMono
                            font.pixelSize: 8
                            color: Theme.textMuted
                        }
                    }
                }

                // Global Quick Action: Prune Stopped (Plastic Button)
                Rectangle {
                    height: 28
                    implicitWidth: pruneText.implicitWidth + 16
                    radius: 8
                    color: ShellState.plasticEnabled ? "transparent" : (pruneMouse.containsMouse ? Qt.rgba(Theme.accentRose.r, Theme.accentRose.g, Theme.accentRose.b, 0.2) : Theme.bgPill)
                    border.color: ShellState.plasticEnabled ? "transparent" : (pruneMouse.containsMouse ? Theme.accentRose : Theme.borderDim)
                    border.width: ShellState.plasticEnabled ? 0 : 1

                    LiquidGlassSurface {
                        radius: 8
                        visible: ShellState.plasticEnabled
                        accentColor: pruneMouse.containsMouse ? Theme.accentRose : Theme.borderDim
                        hovered: pruneMouse.containsMouse
                        pressed: pruneMouse.pressed
                        showShadow: false
                    }

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6

                        Icon {
                            name: "trash-2"
                            size: 11
                            color: pruneMouse.containsMouse ? Theme.accentRose : Theme.textSecondary
                        }

                        Text {
                            id: pruneText
                            text: "Prune Stopped"
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            font.bold: true
                            color: pruneMouse.containsMouse ? Theme.accentRose : Theme.textSecondary
                        }
                    }

                    MouseArea {
                        id: pruneMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            DockerService.pruneContainers();
                            showCopiedToast("Pruning stopped containers...");
                        }
                    }
                }

                // Refresh Button (Plastic Gem)
                Rectangle {
                    width: 28
                    height: 28
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

                        RotationAnimation on rotation {
                            running: DockerService.loading || DockerService.statsLoading
                            loops: Animation.Infinite
                            from: 0; to: 360
                            duration: 1000
                        }
                    }

                    MouseArea {
                        id: refreshMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            DockerService.refresh();
                            DockerService.updateStats();
                        }
                    }
                }

                // Close Button (Plastic Gem)
                Rectangle {
                    width: 28
                    height: 28
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
                        onClicked: ShellState.dockerOpen = false
                    }
                }
            }

            // Divider line
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.borderDim
            }

            // ── Navigation, Filters & Search Bar ────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                // Main Tabs (Containers / Images)
                RowLayout {
                    spacing: 6

                    // Containers Tab Button (Plastic Capsule)
                    Rectangle {
                        id: contTabBtn
                        height: 30
                        implicitWidth: contTabRow.implicitWidth + 18
                        radius: 8
                        color: ShellState.plasticEnabled ? "transparent" : (activeTab === "containers" ? Qt.rgba(Theme.accentSky.r, Theme.accentSky.g, Theme.accentSky.b, 0.2) : Theme.bgPill)
                        border.color: ShellState.plasticEnabled ? "transparent" : (activeTab === "containers" ? Theme.accentSky : Theme.borderDim)
                        border.width: ShellState.plasticEnabled ? 0 : 1

                        LiquidGlassSurface {
                            radius: 8
                            visible: ShellState.plasticEnabled && activeTab === "containers"
                            accentColor: Theme.accentSky
                            showShadow: false
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: 8
                            visible: ShellState.plasticEnabled && activeTab !== "containers"
                            color: Qt.rgba(0.20, 0.28, 0.40, 0.22)
                            border.color: Qt.rgba(1.0, 1.0, 1.0, 0.12)
                            border.width: 1
                        }

                        RowLayout {
                            id: contTabRow
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                text: "📦 Containers"
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                font.bold: true
                                color: activeTab === "containers" ? Theme.accentSky : Theme.textSecondary
                            }

                            Rectangle {
                                height: 16
                                implicitWidth: contCountText.implicitWidth + 8
                                radius: 8
                                color: Qt.rgba(Theme.accentSky.r, Theme.accentSky.g, Theme.accentSky.b, 0.2)

                                Text {
                                    id: contCountText
                                    anchors.centerIn: parent
                                    text: DockerService.summary.total
                                    font.family: Theme.fontMono
                                    font.pixelSize: 8
                                    font.bold: true
                                    color: Theme.accentSky
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: activeTab = "containers"
                        }
                    }

                    // Images Tab Button (Plastic Capsule)
                    Rectangle {
                        id: imgTabBtn
                        height: 30
                        implicitWidth: imgTabRow.implicitWidth + 18
                        radius: 8
                        color: ShellState.plasticEnabled ? "transparent" : (activeTab === "images" ? Qt.rgba(Theme.accentViolet.r, Theme.accentViolet.g, Theme.accentViolet.b, 0.2) : Theme.bgPill)
                        border.color: ShellState.plasticEnabled ? "transparent" : (activeTab === "images" ? Theme.accentViolet : Theme.borderDim)
                        border.width: ShellState.plasticEnabled ? 0 : 1

                        LiquidGlassSurface {
                            radius: 8
                            visible: ShellState.plasticEnabled && activeTab === "images"
                            accentColor: Theme.accentViolet
                            showShadow: false
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: 8
                            visible: ShellState.plasticEnabled && activeTab !== "images"
                            color: Qt.rgba(0.20, 0.28, 0.40, 0.22)
                            border.color: Qt.rgba(1.0, 1.0, 1.0, 0.12)
                            border.width: 1
                        }

                        RowLayout {
                            id: imgTabRow
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                text: "🖼 Images"
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                font.bold: true
                                color: activeTab === "images" ? Theme.accentViolet : Theme.textSecondary
                            }

                            Rectangle {
                                height: 16
                                implicitWidth: imgCountText.implicitWidth + 8
                                radius: 8
                                color: Qt.rgba(Theme.accentViolet.r, Theme.accentViolet.g, Theme.accentViolet.b, 0.2)

                                Text {
                                    id: imgCountText
                                    anchors.centerIn: parent
                                    text: DockerService.summary.images_count
                                    font.family: Theme.fontMono
                                    font.pixelSize: 8
                                    font.bold: true
                                    color: Theme.accentViolet
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: activeTab = "images"
                        }
                    }
                }

                // Sub-filter chips (only visible when in containers tab)
                RowLayout {
                    spacing: 5
                    visible: activeTab === "containers"

                    // "All" chip (Plastic Pill)
                    Rectangle {
                        id: allChipBtn
                        height: 26
                        implicitWidth: allChipText.implicitWidth + 14
                        radius: 13
                        color: ShellState.plasticEnabled ? "transparent" : (statusFilter === "all" ? Qt.rgba(Theme.accentCyan.r, Theme.accentCyan.g, Theme.accentCyan.b, 0.25) : Theme.bgPill)
                        border.color: ShellState.plasticEnabled ? "transparent" : (statusFilter === "all" ? Theme.accentCyan : Theme.borderDim)
                        border.width: ShellState.plasticEnabled ? 0 : 1

                        LiquidGlassSurface {
                            radius: 13
                            visible: ShellState.plasticEnabled && (statusFilter === "all" || allChipMouse.containsMouse)
                            accentColor: Theme.accentCyan
                            hovered: allChipMouse.containsMouse
                            pressed: allChipMouse.pressed
                            showShadow: false
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: 13
                            visible: ShellState.plasticEnabled && statusFilter !== "all" && !allChipMouse.containsMouse
                            color: Qt.rgba(0.20, 0.28, 0.40, 0.22)
                            border.color: Qt.rgba(1.0, 1.0, 1.0, 0.12)
                            border.width: 1
                        }

                        Text {
                            id: allChipText
                            anchors.centerIn: parent
                            text: "All"
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            font.bold: statusFilter === "all"
                            color: statusFilter === "all" ? Theme.accentCyan : Theme.textMuted
                        }

                        MouseArea {
                            id: allChipMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: statusFilter = "all"
                        }
                    }

                    // "Running" chip (Plastic Pill)
                    Rectangle {
                        id: runChipBtn
                        height: 26
                        implicitWidth: runChipText.implicitWidth + 14
                        radius: 13
                        color: ShellState.plasticEnabled ? "transparent" : (statusFilter === "running" ? Qt.rgba(Theme.accentEmerald.r, Theme.accentEmerald.g, Theme.accentEmerald.b, 0.25) : Theme.bgPill)
                        border.color: ShellState.plasticEnabled ? "transparent" : (statusFilter === "running" ? Theme.accentEmerald : Theme.borderDim)
                        border.width: ShellState.plasticEnabled ? 0 : 1

                        LiquidGlassSurface {
                            radius: 13
                            visible: ShellState.plasticEnabled && (statusFilter === "running" || runChipMouse.containsMouse)
                            accentColor: Theme.accentEmerald
                            hovered: runChipMouse.containsMouse
                            pressed: runChipMouse.pressed
                            showShadow: false
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: 13
                            visible: ShellState.plasticEnabled && statusFilter !== "running" && !runChipMouse.containsMouse
                            color: Qt.rgba(0.20, 0.28, 0.40, 0.22)
                            border.color: Qt.rgba(1.0, 1.0, 1.0, 0.12)
                            border.width: 1
                        }

                        Text {
                            id: runChipText
                            anchors.centerIn: parent
                            text: "Running (" + DockerService.summary.running + ")"
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            font.bold: statusFilter === "running"
                            color: statusFilter === "running" ? Theme.accentEmerald : Theme.textMuted
                        }

                        MouseArea {
                            id: runChipMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: statusFilter = "running"
                        }
                    }

                    // "Stopped" chip (Plastic Pill)
                    Rectangle {
                        id: stopChipBtn
                        height: 26
                        implicitWidth: stopChipText.implicitWidth + 14
                        radius: 13
                        color: ShellState.plasticEnabled ? "transparent" : (statusFilter === "stopped" ? Qt.rgba(Theme.textSecondary.r, Theme.textSecondary.g, Theme.textSecondary.b, 0.25) : Theme.bgPill)
                        border.color: ShellState.plasticEnabled ? "transparent" : (statusFilter === "stopped" ? Theme.textSecondary : Theme.borderDim)
                        border.width: ShellState.plasticEnabled ? 0 : 1

                        LiquidGlassSurface {
                            radius: 13
                            visible: ShellState.plasticEnabled && (statusFilter === "stopped" || stopChipMouse.containsMouse)
                            accentColor: Theme.textSecondary
                            hovered: stopChipMouse.containsMouse
                            pressed: stopChipMouse.pressed
                            showShadow: false
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: 13
                            visible: ShellState.plasticEnabled && statusFilter !== "stopped" && !stopChipMouse.containsMouse
                            color: Qt.rgba(0.20, 0.28, 0.40, 0.22)
                            border.color: Qt.rgba(1.0, 1.0, 1.0, 0.12)
                            border.width: 1
                        }

                        Text {
                            id: stopChipText
                            anchors.centerIn: parent
                            text: "Stopped (" + DockerService.summary.stopped + ")"
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            font.bold: statusFilter === "stopped"
                            color: statusFilter === "stopped" ? Theme.textPrimary : Theme.textMuted
                        }

                        MouseArea {
                            id: stopChipMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: statusFilter = "stopped"
                        }
                    }

                    // "Compose Stacks" chip (Plastic Pill)
                    Rectangle {
                        id: compChipBtn
                        height: 26
                        implicitWidth: compChipText.implicitWidth + 14
                        radius: 13
                        color: ShellState.plasticEnabled ? "transparent" : (statusFilter === "compose" ? Qt.rgba(Theme.accentViolet.r, Theme.accentViolet.g, Theme.accentViolet.b, 0.25) : Theme.bgPill)
                        border.color: ShellState.plasticEnabled ? "transparent" : (statusFilter === "compose" ? Theme.accentViolet : Theme.borderDim)
                        border.width: ShellState.plasticEnabled ? 0 : 1

                        LiquidGlassSurface {
                            radius: 13
                            visible: ShellState.plasticEnabled && (statusFilter === "compose" || compChipMouse.containsMouse)
                            accentColor: Theme.accentViolet
                            hovered: compChipMouse.containsMouse
                            pressed: compChipMouse.pressed
                            showShadow: false
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: 13
                            visible: ShellState.plasticEnabled && statusFilter !== "compose" && !compChipMouse.containsMouse
                            color: Qt.rgba(0.20, 0.28, 0.40, 0.22)
                            border.color: Qt.rgba(1.0, 1.0, 1.0, 0.12)
                            border.width: 1
                        }

                        Text {
                            id: compChipText
                            anchors.centerIn: parent
                            text: "Compose Stacks"
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            font.bold: statusFilter === "compose"
                            color: statusFilter === "compose" ? Theme.accentViolet : Theme.textMuted
                        }

                        MouseArea {
                            id: compChipMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: statusFilter = "compose"
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                // Search Input Field (Plastic Channel)
                Rectangle {
                    height: 32
                    implicitWidth: 260
                    radius: 16
                    color: ShellState.plasticEnabled ? "transparent" : Theme.bgPill
                    border.color: ShellState.plasticEnabled ? "transparent" : (searchInput.activeFocus ? Theme.accentSky : Theme.borderDim)
                    border.width: ShellState.plasticEnabled ? 0 : 1

                    LiquidGlassSurface {
                        radius: 16
                        visible: ShellState.plasticEnabled
                        accentColor: searchInput.activeFocus ? Theme.accentSky : Theme.borderDim
                        showShadow: false
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 8
                        spacing: 6

                        Text {
                            text: "🔍"
                            font.pixelSize: 11
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
                                text: activeTab === "containers" ? "Search containers, ports..." : "Search images..."
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                color: Theme.textMuted
                                opacity: 0.6
                                visible: !searchInput.text && !searchInput.activeFocus
                            }
                        }

                        // Clear Button
                        Text {
                            text: "✕"
                            font.pixelSize: 10
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

            // ── Main Content Area (Containers or Images or Log Drawer) ───────
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                // ── VIEW 1: Containers List ─────────────────────────────────
                ListView {
                    id: containersList
                    anchors.fill: parent
                    visible: activeTab === "containers" && !showLogDrawer
                    spacing: 8
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    model: dockerWindow.filteredContainers

                    ScrollBar.vertical: ScrollBar {
                        policy: containersList.contentHeight > containersList.height ? ScrollBar.AlwaysOn : ScrollBar.AsNeeded
                    }

                    // Empty placeholder
                    Item {
                        anchors.fill: parent
                        visible: containersList.count === 0 && !DockerService.loading

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 8

                            Text {
                                text: "📦"
                                font.pixelSize: 32
                                Layout.alignment: Qt.AlignHCenter
                            }

                            Text {
                                text: searchInput.text ? "No containers matching '" + searchInput.text + "'" : "No containers found"
                                font.family: Theme.fontFamily
                                font.pixelSize: 13
                                font.bold: true
                                color: Theme.textMuted
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }

                    delegate: Rectangle {
                        id: cCard
                        required property var modelData
                        required property int index

                        width: containersList.width - (containersList.contentHeight > containersList.height ? 10 : 0)
                        implicitHeight: cCardCol.implicitHeight + 18
                        radius: 12
                        color: ShellState.plasticEnabled ? "transparent" : (cCardMouse.containsMouse ? Theme.bgHover : Theme.bgCard)
                        border.color: ShellState.plasticEnabled ? "transparent" : (cCard.modelData.state === "running"
                                      ? Qt.rgba(Theme.accentEmerald.r, Theme.accentEmerald.g, Theme.accentEmerald.b, 0.3)
                                      : Theme.borderDim)
                        border.width: ShellState.plasticEnabled ? 0 : 1

                        LiquidGlassSurface {
                            radius: 12
                            visible: ShellState.plasticEnabled
                            accentColor: cCard.modelData.state === "running"
                                ? (cCardMouse.containsMouse ? Theme.accentEmerald : Qt.rgba(Theme.accentEmerald.r, Theme.accentEmerald.g, Theme.accentEmerald.b, 0.6))
                                : (cCardMouse.containsMouse ? Theme.accentSky : Theme.borderDim)
                            hovered: cCardMouse.containsMouse
                            showShadow: false
                        }

                        // Left vertical state strip
                        Rectangle {
                            width: 4
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.topMargin: 8
                            anchors.bottomMargin: 8
                            radius: 2
                            color: {
                                if (cCard.modelData.state === "running") return Theme.accentEmerald;
                                if (cCard.modelData.state === "paused") return Theme.accentAmber;
                                return Theme.textMuted;
                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 14
                            anchors.topMargin: 9
                            anchors.bottomMargin: 9
                            spacing: 12

                            // Container info columns
                            ColumnLayout {
                                id: cCardCol
                                Layout.fillWidth: true
                                spacing: 4

                                // Row 1: Name, Status, Compose Project, ID
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    // Status dot + status string
                                    Rectangle {
                                        height: 18
                                        implicitWidth: cStatusText.implicitWidth + 12
                                        radius: 9
                                        color: ShellState.plasticEnabled ? "transparent" : (cCard.modelData.state === "running"
                                               ? Qt.rgba(Theme.accentEmerald.r, Theme.accentEmerald.g, Theme.accentEmerald.b, 0.15)
                                               : Qt.rgba(Theme.textMuted.r, Theme.textMuted.g, Theme.textMuted.b, 0.12))
                                        border.color: ShellState.plasticEnabled ? "transparent" : (cCard.modelData.state === "running" ? Theme.accentEmerald : Theme.borderDim)
                                        border.width: ShellState.plasticEnabled ? 0 : 1

                                        LiquidGlassSurface {
                                            radius: 9
                                            visible: ShellState.plasticEnabled
                                            accentColor: cCard.modelData.state === "running" ? Theme.accentEmerald : Theme.textMuted
                                            showShadow: false
                                        }

                                        RowLayout {
                                            anchors.centerIn: parent
                                            spacing: 4

                                            Rectangle {
                                                width: 5
                                                height: 5
                                                radius: 2.5
                                                color: cCard.modelData.state === "running" ? Theme.accentEmerald : Theme.textMuted
                                            }

                                            Text {
                                                id: cStatusText
                                                text: (cCard.modelData.state === "running" ? "UP " : "EXITED ") + (cCard.modelData.created || "")
                                                font.family: Theme.fontMono
                                                font.pixelSize: 8
                                                font.bold: true
                                                color: cCard.modelData.state === "running" ? Theme.accentEmerald : Theme.textMuted
                                            }
                                        }
                                    }

                                    // Container Name
                                    Text {
                                        text: cCard.modelData.name ?? ""
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 12
                                        font.bold: true
                                        color: Theme.textPrimary
                                        elide: Text.ElideRight
                                    }

                                    // Compose stack pill if applicable
                                    Rectangle {
                                        visible: !!cCard.modelData.compose_project
                                        height: 16
                                        implicitWidth: composeText.implicitWidth + 10
                                        radius: 4
                                        color: Qt.rgba(Theme.accentViolet.r, Theme.accentViolet.g, Theme.accentViolet.b, 0.15)
                                        border.color: Qt.rgba(Theme.accentViolet.r, Theme.accentViolet.g, Theme.accentViolet.b, 0.4)
                                        border.width: 1

                                        Text {
                                            id: composeText
                                            anchors.centerIn: parent
                                            text: "compose: " + (cCard.modelData.compose_project || "")
                                            font.family: Theme.fontMono
                                            font.pixelSize: 8
                                            font.bold: true
                                            color: Theme.accentViolet
                                        }
                                    }

                                    // Short ID Pill (Click to copy)
                                    Rectangle {
                                        height: 16
                                        implicitWidth: cidText.implicitWidth + 8
                                        radius: 4
                                        color: idMouse.containsMouse ? Theme.bgHover : Theme.bgPill
                                        border.color: idMouse.containsMouse ? Theme.accentSky : Theme.borderDim
                                        border.width: 1

                                        Text {
                                            id: cidText
                                            anchors.centerIn: parent
                                            text: cCard.modelData.id ?? ""
                                            font.family: Theme.fontMono
                                            font.pixelSize: 8
                                            color: idMouse.containsMouse ? Theme.accentSky : Theme.textMuted
                                        }

                                        MouseArea {
                                            id: idMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                Quickshell.execDetached(["wl-copy", cCard.modelData.id]);
                                                showCopiedToast("Copied container ID " + cCard.modelData.id);
                                            }
                                        }
                                    }

                                    Item { Layout.fillWidth: true }
                                }

                                // Row 2: Image & Ports
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    Text {
                                        text: "📦 " + (cCard.modelData.image ?? "")
                                        font.family: Theme.fontMono
                                        font.pixelSize: 9
                                        color: Theme.textSecondary
                                        elide: Text.ElideRight
                                    }

                                    Rectangle {
                                        visible: !!cCard.modelData.ports
                                        height: 15
                                        implicitWidth: portsText.implicitWidth + 8
                                        radius: 3
                                        color: Qt.rgba(Theme.accentCyan.r, Theme.accentCyan.g, Theme.accentCyan.b, 0.14)
                                        border.color: Qt.rgba(Theme.accentCyan.r, Theme.accentCyan.g, Theme.accentCyan.b, 0.3)
                                        border.width: 0.5

                                        Text {
                                            id: portsText
                                            anchors.centerIn: parent
                                            text: "⚡ " + (cCard.modelData.ports || "")
                                            font.family: Theme.fontMono
                                            font.pixelSize: 8
                                            font.bold: true
                                            color: Theme.accentCyan
                                        }
                                    }
                                }

                                // Row 3: CPU & Memory telemetry for running containers
                                RowLayout {
                                    visible: cCard.modelData.state === "running"
                                    spacing: 12

                                    // CPU badge
                                    RowLayout {
                                        spacing: 4
                                        Text {
                                            text: "CPU:"
                                            font.family: Theme.fontMono
                                            font.pixelSize: 8
                                            color: Theme.textMuted
                                        }
                                        Text {
                                            text: cCard.modelData.cpu_perc || "0.0%"
                                            font.family: Theme.fontMono
                                            font.pixelSize: 8
                                            font.bold: true
                                            color: Theme.accentSky
                                        }
                                    }

                                    // Memory badge
                                    RowLayout {
                                        spacing: 4
                                        Text {
                                            text: "RAM:"
                                            font.family: Theme.fontMono
                                            font.pixelSize: 8
                                            color: Theme.textMuted
                                        }
                                        Text {
                                            text: (cCard.modelData.mem_usage ? cCard.modelData.mem_usage.split(" / ")[0] : "0B") + (cCard.modelData.mem_perc ? " (" + cCard.modelData.mem_perc + ")" : "")
                                            font.family: Theme.fontMono
                                            font.pixelSize: 8
                                            font.bold: true
                                            color: Theme.accentEmerald
                                        }
                                    }
                                }
                            }

                            // ── Action Buttons for Container (Apple Plastic) ──
                            RowLayout {
                                spacing: 6
                                Layout.alignment: Qt.AlignVCenter

                                // START / STOP Primary Toggle (Plastic Button)
                                Rectangle {
                                    height: 28
                                    implicitWidth: toggleActionText.implicitWidth + 16
                                    Layout.preferredWidth: implicitWidth
                                    Layout.preferredHeight: 28
                                    radius: 7
                                    color: ShellState.plasticEnabled ? "transparent" : (cCard.modelData.state === "running"
                                            ? (toggleActionMouse.containsMouse ? Qt.rgba(Theme.accentRose.r, Theme.accentRose.g, Theme.accentRose.b, 0.25) : Qt.rgba(Theme.accentRose.r, Theme.accentRose.g, Theme.accentRose.b, 0.12))
                                            : (toggleActionMouse.containsMouse ? Qt.rgba(Theme.accentEmerald.r, Theme.accentEmerald.g, Theme.accentEmerald.b, 0.25) : Qt.rgba(Theme.accentEmerald.r, Theme.accentEmerald.g, Theme.accentEmerald.b, 0.12)))
                                    border.color: ShellState.plasticEnabled ? "transparent" : (cCard.modelData.state === "running" ? Theme.accentRose : Theme.accentEmerald)
                                    border.width: ShellState.plasticEnabled ? 0 : 1

                                    LiquidGlassSurface {
                                        radius: 7
                                        visible: ShellState.plasticEnabled
                                        accentColor: cCard.modelData.state === "running" ? Theme.accentRose : Theme.accentEmerald
                                        hovered: toggleActionMouse.containsMouse
                                        pressed: toggleActionMouse.pressed
                                        showShadow: false
                                    }

                                    Text {
                                        id: toggleActionText
                                        anchors.centerIn: parent
                                        text: cCard.modelData.state === "running" ? "⏹ Stop" : "▶ Start"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 10
                                        font.bold: true
                                        color: cCard.modelData.state === "running" ? Theme.accentRose : Theme.accentEmerald
                                    }

                                    MouseArea {
                                        id: toggleActionMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (cCard.modelData.state === "running") {
                                                DockerService.stopContainer(cCard.modelData.name);
                                            } else {
                                                DockerService.startContainer(cCard.modelData.name);
                                            }
                                        }
                                    }
                                }

                                // RESTART Button (Plastic Gem)
                                Rectangle {
                                    visible: cCard.modelData.state === "running"
                                    width: 28
                                    height: 28
                                    Layout.preferredWidth: 28
                                    Layout.preferredHeight: 28
                                    radius: 7
                                    color: ShellState.plasticEnabled ? "transparent" : (restartMouse.containsMouse ? Theme.bgHover : Theme.bgPill)
                                    border.color: ShellState.plasticEnabled ? "transparent" : (restartMouse.containsMouse ? Theme.accentCyan : Theme.borderDim)
                                    border.width: ShellState.plasticEnabled ? 0 : 1

                                    LiquidGlassSurface {
                                        radius: 7
                                        visible: ShellState.plasticEnabled
                                        accentColor: restartMouse.containsMouse ? Theme.accentCyan : Theme.borderDim
                                        hovered: restartMouse.containsMouse
                                        pressed: restartMouse.pressed
                                        showShadow: false
                                    }

                                    Icon {
                                        anchors.centerIn: parent
                                        name: "refresh-cw"
                                        size: 12
                                        color: restartMouse.containsMouse ? Theme.accentCyan : Theme.textSecondary
                                    }

                                    MouseArea {
                                        id: restartMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: DockerService.restartContainer(cCard.modelData.name)
                                    }
                                }

                                // LOGS Button (Plastic Button)
                                Rectangle {
                                    height: 28
                                    implicitWidth: logsBtnRow.implicitWidth + 18
                                    Layout.preferredWidth: implicitWidth
                                    Layout.preferredHeight: 28
                                    radius: 7
                                    color: ShellState.plasticEnabled ? "transparent" : (logsBtnMouse.containsMouse ? Theme.bgHover : Theme.bgPill)
                                    border.color: ShellState.plasticEnabled ? "transparent" : (logsBtnMouse.containsMouse ? Theme.accentSky : Theme.borderDim)
                                    border.width: ShellState.plasticEnabled ? 0 : 1

                                    LiquidGlassSurface {
                                        radius: 7
                                        visible: ShellState.plasticEnabled
                                        accentColor: logsBtnMouse.containsMouse ? Theme.accentSky : Theme.borderDim
                                        hovered: logsBtnMouse.containsMouse
                                        pressed: logsBtnMouse.pressed
                                        showShadow: false
                                    }

                                    RowLayout {
                                        id: logsBtnRow
                                        anchors.centerIn: parent
                                        spacing: 5

                                        Icon {
                                            name: "file-text"
                                            size: 11
                                            color: logsBtnMouse.containsMouse ? Theme.accentSky : Theme.textSecondary
                                        }

                                        Text {
                                            id: logsBtnText
                                            text: "Logs"
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 10
                                            font.bold: true
                                            color: logsBtnMouse.containsMouse ? Theme.accentSky : Theme.textSecondary
                                        }
                                    }

                                    MouseArea {
                                        id: logsBtnMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            showLogDrawer = true;
                                            DockerService.fetchLogs(cCard.modelData.name, selectedLogLines);
                                        }
                                    }
                                }

                                // TERMINAL / CLI EXEC Button (Plastic Button)
                                Rectangle {
                                    visible: cCard.modelData.state === "running"
                                    height: 28
                                    implicitWidth: cliBtnRow.implicitWidth + 18
                                    Layout.preferredWidth: implicitWidth
                                    Layout.preferredHeight: 28
                                    radius: 7
                                    color: ShellState.plasticEnabled ? "transparent" : (cliBtnMouse.containsMouse ? Theme.bgHover : Theme.bgPill)
                                    border.color: ShellState.plasticEnabled ? "transparent" : (cliBtnMouse.containsMouse ? Theme.accentViolet : Theme.borderDim)
                                    border.width: ShellState.plasticEnabled ? 0 : 1

                                    LiquidGlassSurface {
                                        radius: 7
                                        visible: ShellState.plasticEnabled
                                        accentColor: cliBtnMouse.containsMouse ? Theme.accentViolet : Theme.borderDim
                                        hovered: cliBtnMouse.containsMouse
                                        pressed: cliBtnMouse.pressed
                                        showShadow: false
                                    }

                                    RowLayout {
                                        id: cliBtnRow
                                        anchors.centerIn: parent
                                        spacing: 5

                                        Icon {
                                            name: "terminal"
                                            size: 11
                                            color: cliBtnMouse.containsMouse ? Theme.accentViolet : Theme.textSecondary
                                        }

                                        Text {
                                            id: cliBtnText
                                            text: "CLI"
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 10
                                            font.bold: true
                                            color: cliBtnMouse.containsMouse ? Theme.accentViolet : Theme.textSecondary
                                        }
                                    }

                                    MouseArea {
                                        id: cliBtnMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: DockerService.openTerminal(cCard.modelData.name)
                                    }
                                }

                                // DELETE / REMOVE Button (Plastic Gem)
                                Rectangle {
                                    width: 28
                                    height: 28
                                    Layout.preferredWidth: 28
                                    Layout.preferredHeight: 28
                                    radius: 7
                                    color: ShellState.plasticEnabled ? "transparent" : (deleteMouse.containsMouse ? Qt.rgba(Theme.accentRose.r, Theme.accentRose.g, Theme.accentRose.b, 0.2) : Theme.bgPill)
                                    border.color: ShellState.plasticEnabled ? "transparent" : (deleteMouse.containsMouse ? Theme.accentRose : Theme.borderDim)
                                    border.width: ShellState.plasticEnabled ? 0 : 1

                                    LiquidGlassSurface {
                                        radius: 7
                                        visible: ShellState.plasticEnabled
                                        accentColor: deleteMouse.containsMouse ? Theme.accentRose : Theme.borderDim
                                        hovered: deleteMouse.containsMouse
                                        pressed: deleteMouse.pressed
                                        showShadow: false
                                    }

                                    Icon {
                                        anchors.centerIn: parent
                                        name: "trash-2"
                                        size: 12
                                        color: deleteMouse.containsMouse ? Theme.accentRose : Theme.textMuted
                                    }

                                    MouseArea {
                                        id: deleteMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            confirmDeleteTarget = cCard.modelData.name;
                                        }
                                    }
                                }
                            }
                        }

                        // Inline Delete Confirmation Overlay
                        Rectangle {
                            anchors.fill: parent
                            radius: 12
                            visible: confirmDeleteTarget === cCard.modelData.name
                            color: Qt.rgba(Theme.bgModal.r, Theme.bgModal.g, Theme.bgModal.b, 0.95)
                            border.color: Theme.accentRose
                            border.width: 1.5

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 14

                                Text {
                                    text: "Permanently remove container '" + cCard.modelData.name + "'?"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: Theme.textPrimary
                                }

                                Rectangle {
                                    height: 26
                                    implicitWidth: yesDeleteText.implicitWidth + 14
                                    radius: 6
                                    color: Theme.accentRose

                                    Text {
                                        id: yesDeleteText
                                        anchors.centerIn: parent
                                        text: "Yes, Delete"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 10
                                        font.bold: true
                                        color: "#FFFFFF"
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            confirmDeleteTarget = "";
                                            DockerService.removeContainer(cCard.modelData.name);
                                        }
                                    }
                                }

                                Rectangle {
                                    height: 26
                                    implicitWidth: cancelDeleteText.implicitWidth + 14
                                    radius: 6
                                    color: Theme.bgPill
                                    border.color: Theme.borderDim
                                    border.width: 1

                                    Text {
                                        id: cancelDeleteText
                                        anchors.centerIn: parent
                                        text: "Cancel"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 10
                                        color: Theme.textSecondary
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: confirmDeleteTarget = ""
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: cCardMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.NoButton
                        }
                    }
                }

                // ── VIEW 2: Images List ─────────────────────────────────────
                ListView {
                    id: imagesList
                    anchors.fill: parent
                    visible: activeTab === "images" && !showLogDrawer
                    spacing: 8
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    model: dockerWindow.filteredImages

                    ScrollBar.vertical: ScrollBar {
                        policy: imagesList.contentHeight > imagesList.height ? ScrollBar.AlwaysOn : ScrollBar.AsNeeded
                    }

                    // Empty placeholder
                    Item {
                        anchors.fill: parent
                        visible: imagesList.count === 0 && !DockerService.loading

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 8

                            Icon {
                                name: "layers"
                                size: 36
                                color: Theme.accentViolet
                                Layout.alignment: Qt.AlignHCenter
                            }

                            Text {
                                text: searchInput.text ? "No images matching '" + searchInput.text + "'" : "No images found"
                                font.family: Theme.fontFamily
                                font.pixelSize: 13
                                font.bold: true
                                color: Theme.textMuted
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }

                    delegate: Rectangle {
                        id: imgCard
                        required property var modelData
                        required property int index

                        width: imagesList.width - (imagesList.contentHeight > imagesList.height ? 10 : 0)
                        implicitHeight: 70
                        radius: 12
                        color: ShellState.plasticEnabled ? "transparent" : (imgCardMouse.containsMouse ? Theme.bgHover : Theme.bgCard)
                        border.color: ShellState.plasticEnabled ? "transparent" : Theme.borderDim
                        border.width: ShellState.plasticEnabled ? 0 : 1

                        LiquidGlassSurface {
                            radius: 12
                            visible: ShellState.plasticEnabled
                            accentColor: imgCardMouse.containsMouse ? Theme.accentViolet : Theme.borderDim
                            hovered: imgCardMouse.containsMouse
                            showShadow: false
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 12

                            Rectangle {
                                width: 36
                                height: 36
                                radius: 8
                                color: ShellState.plasticEnabled ? "transparent" : Qt.rgba(Theme.accentViolet.r, Theme.accentViolet.g, Theme.accentViolet.b, 0.15)
                                border.color: ShellState.plasticEnabled ? "transparent" : Theme.accentViolet
                                border.width: ShellState.plasticEnabled ? 0 : 1

                                LiquidGlassSurface {
                                    radius: 8
                                    visible: ShellState.plasticEnabled
                                    accentColor: Theme.accentViolet
                                    showShadow: false
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: "IMG"
                                    font.family: Theme.fontMono
                                    font.pixelSize: 9
                                    font.bold: true
                                    color: Theme.accentViolet
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 3

                                RowLayout {
                                    spacing: 8

                                    Text {
                                        text: imgCard.modelData.repository ?? ""
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 12
                                        font.bold: true
                                        color: Theme.textPrimary
                                        elide: Text.ElideRight
                                    }

                                    Rectangle {
                                        height: 16
                                        implicitWidth: tagText.implicitWidth + 8
                                        radius: 4
                                        color: Qt.rgba(Theme.accentCyan.r, Theme.accentCyan.g, Theme.accentCyan.b, 0.15)

                                        Text {
                                            id: tagText
                                            anchors.centerIn: parent
                                            text: imgCard.modelData.tag ?? "latest"
                                            font.family: Theme.fontMono
                                            font.pixelSize: 8
                                            font.bold: true
                                            color: Theme.accentCyan
                                        }
                                    }

                                    Rectangle {
                                        height: 16
                                        implicitWidth: imgIdText.implicitWidth + 8
                                        radius: 4
                                        color: Theme.bgPill

                                        Text {
                                            id: imgIdText
                                            anchors.centerIn: parent
                                            text: imgCard.modelData.id ?? ""
                                            font.family: Theme.fontMono
                                            font.pixelSize: 8
                                            color: Theme.textMuted
                                        }
                                    }
                                }

                                RowLayout {
                                    spacing: 12

                                    Text {
                                        text: "Disk Size: " + (imgCard.modelData.size ?? "")
                                        font.family: Theme.fontMono
                                        font.pixelSize: 9
                                        color: Theme.textSecondary
                                    }

                                    Text {
                                        text: "•  Created " + (imgCard.modelData.created ?? "")
                                        font.family: Theme.fontMono
                                        font.pixelSize: 9
                                        color: Theme.textMuted
                                    }

                                    Text {
                                        text: imgCard.modelData.containers > 0 ? ("● In use by " + imgCard.modelData.containers + " container(s)") : "○ Unused"
                                        font.family: Theme.fontMono
                                        font.pixelSize: 8
                                        color: imgCard.modelData.containers > 0 ? Theme.accentEmerald : Theme.textMuted
                                    }
                                }
                            }

                            // Delete Image Button (Plastic Gem)
                            Rectangle {
                                width: 28
                                height: 28
                                radius: 7
                                color: ShellState.plasticEnabled ? "transparent" : (imgDeleteMouse.containsMouse ? Qt.rgba(Theme.accentRose.r, Theme.accentRose.g, Theme.accentRose.b, 0.2) : Theme.bgPill)
                                border.color: ShellState.plasticEnabled ? "transparent" : (imgDeleteMouse.containsMouse ? Theme.accentRose : Theme.borderDim)
                                border.width: ShellState.plasticEnabled ? 0 : 1

                                LiquidGlassSurface {
                                    radius: 7
                                    visible: ShellState.plasticEnabled
                                    accentColor: imgDeleteMouse.containsMouse ? Theme.accentRose : Theme.borderDim
                                    hovered: imgDeleteMouse.containsMouse
                                    pressed: imgDeleteMouse.pressed
                                    showShadow: false
                                }

                                Icon {
                                    anchors.centerIn: parent
                                    name: "trash-2"
                                    size: 12
                                    color: imgDeleteMouse.containsMouse ? Theme.accentRose : Theme.textMuted
                                }

                                MouseArea {
                                    id: imgDeleteMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        confirmDeleteTarget = imgCard.modelData.id;
                                    }
                                }
                            }
                        }

                        // Inline Delete Confirmation
                        Rectangle {
                            anchors.fill: parent
                            radius: 12
                            visible: confirmDeleteTarget === imgCard.modelData.id
                            color: Qt.rgba(Theme.bgModal.r, Theme.bgModal.g, Theme.bgModal.b, 0.95)
                            border.color: Theme.accentRose
                            border.width: 1.5

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 14

                                Text {
                                    text: "Remove image '" + imgCard.modelData.repository + ":" + imgCard.modelData.tag + "'?"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: Theme.textPrimary
                                }

                                Rectangle {
                                    height: 26
                                    implicitWidth: yesImgDeleteText.implicitWidth + 14
                                    radius: 6
                                    color: Theme.accentRose

                                    Text {
                                        id: yesImgDeleteText
                                        anchors.centerIn: parent
                                        text: "Yes, Delete"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 10
                                        font.bold: true
                                        color: "#FFFFFF"
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            confirmDeleteTarget = "";
                                            DockerService.removeImage(imgCard.modelData.id);
                                        }
                                    }
                                }

                                Rectangle {
                                    height: 26
                                    implicitWidth: cancelImgDeleteText.implicitWidth + 14
                                    radius: 6
                                    color: Theme.bgPill
                                    border.color: Theme.borderDim
                                    border.width: 1

                                    Text {
                                        id: cancelImgDeleteText
                                        anchors.centerIn: parent
                                        text: "Cancel"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 10
                                        color: Theme.textSecondary
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: confirmDeleteTarget = ""
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: imgCardMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.NoButton
                        }
                    }
                }

                // ── VIEW 3: In-Modal Log Drawer / Inspector ─────────────────
                Rectangle {
                    anchors.fill: parent
                    visible: showLogDrawer
                    radius: 12
                    color: Theme.bgCard
                    border.color: Theme.accentSky
                    border.width: 1
                    clip: true

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 10

                        // Log Drawer Header
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            Rectangle {
                                width: 28
                                height: 28
                                radius: 7
                                color: Qt.rgba(Theme.accentSky.r, Theme.accentSky.g, Theme.accentSky.b, 0.2)

                                Text {
                                    anchors.centerIn: parent
                                    text: "📑"
                                    font.pixelSize: 12
                                }
                            }

                            ColumnLayout {
                                spacing: 2
                                Layout.fillWidth: true

                                Text {
                                    text: "CONTAINER LOGS: " + DockerService.activeLogContainer
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: Theme.textPrimary
                                }

                                Text {
                                    text: "Showing recent " + selectedLogLines + " lines"
                                    font.family: Theme.fontMono
                                    font.pixelSize: 8
                                    color: Theme.textMuted
                                }
                            }

                            // Line limit selector (100 / 300 / 500)
                            RowLayout {
                                spacing: 4

                                Repeater {
                                    model: ["100", "250", "500"]

                                    Rectangle {
                                        required property string modelData
                                        height: 24
                                        implicitWidth: lineBtnText.implicitWidth + 12
                                        radius: 6
                                        color: ShellState.plasticEnabled ? "transparent" : (selectedLogLines === modelData ? Qt.rgba(Theme.accentSky.r, Theme.accentSky.g, Theme.accentSky.b, 0.25) : Theme.bgPill)
                                        border.color: ShellState.plasticEnabled ? "transparent" : (selectedLogLines === modelData ? Theme.accentSky : Theme.borderDim)
                                        border.width: ShellState.plasticEnabled ? 0 : 1

                                        LiquidGlassSurface {
                                            radius: 6
                                            visible: ShellState.plasticEnabled && selectedLogLines === modelData
                                            accentColor: Theme.accentSky
                                            showShadow: false
                                        }

                                        Text {
                                            id: lineBtnText
                                            anchors.centerIn: parent
                                            text: modelData + " lines"
                                            font.family: Theme.fontMono
                                            font.pixelSize: 8
                                            color: selectedLogLines === modelData ? Theme.accentSky : Theme.textMuted
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                selectedLogLines = modelData;
                                                DockerService.fetchLogs(DockerService.activeLogContainer, selectedLogLines);
                                            }
                                        }
                                    }
                                }
                            }

                            // Copy All Button (Plastic Button)
                            Rectangle {
                                height: 26
                                implicitWidth: copyLogsText.implicitWidth + 14
                                radius: 6
                                color: ShellState.plasticEnabled ? "transparent" : (copyLogsMouse.containsMouse ? Theme.bgHover : Theme.bgPill)
                                border.color: ShellState.plasticEnabled ? "transparent" : Theme.borderDim
                                border.width: ShellState.plasticEnabled ? 0 : 1

                                LiquidGlassSurface {
                                    radius: 6
                                    visible: ShellState.plasticEnabled && copyLogsMouse.containsMouse
                                    accentColor: Theme.accentSky
                                    hovered: copyLogsMouse.containsMouse
                                    pressed: copyLogsMouse.pressed
                                    showShadow: false
                                }

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 5

                                    Icon {
                                        name: "copy"
                                        size: 11
                                        color: copyLogsMouse.containsMouse ? Theme.accentSky : Theme.textSecondary
                                    }

                                    Text {
                                        id: copyLogsText
                                        text: "Copy All"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 10
                                        color: copyLogsMouse.containsMouse ? Theme.accentSky : Theme.textSecondary
                                    }
                                }

                                MouseArea {
                                    id: copyLogsMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        Quickshell.execDetached(["wl-copy", DockerService.logsContent]);
                                        showCopiedToast("Logs copied to clipboard!");
                                    }
                                }
                            }

                            // Live Follow in Kitty Terminal Button (Plastic Button)
                            Rectangle {
                                height: 26
                                implicitWidth: liveLogsText.implicitWidth + 14
                                radius: 6
                                color: ShellState.plasticEnabled ? "transparent" : (liveLogsMouse.containsMouse ? Qt.rgba(Theme.accentViolet.r, Theme.accentViolet.g, Theme.accentViolet.b, 0.2) : Theme.bgPill)
                                border.color: ShellState.plasticEnabled ? "transparent" : (liveLogsMouse.containsMouse ? Theme.accentViolet : Theme.borderDim)
                                border.width: ShellState.plasticEnabled ? 0 : 1

                                LiquidGlassSurface {
                                    radius: 6
                                    visible: ShellState.plasticEnabled && liveLogsMouse.containsMouse
                                    accentColor: Theme.accentViolet
                                    hovered: liveLogsMouse.containsMouse
                                    pressed: liveLogsMouse.pressed
                                    showShadow: false
                                }

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 5

                                    Icon {
                                        name: "terminal"
                                        size: 11
                                        color: liveLogsMouse.containsMouse ? Theme.accentViolet : Theme.textSecondary
                                    }

                                    Text {
                                        id: liveLogsText
                                        text: "Live Tail (CLI)"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 10
                                        color: liveLogsMouse.containsMouse ? Theme.accentViolet : Theme.textSecondary
                                    }
                                }

                                MouseArea {
                                    id: liveLogsMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: DockerService.openLiveLogs(DockerService.activeLogContainer)
                                }
                            }

                            // Back / Close Drawer Button (Plastic Gem)
                            Rectangle {
                                width: 26
                                height: 26
                                radius: 6
                                color: ShellState.plasticEnabled ? "transparent" : (backLogsMouse.containsMouse ? Qt.rgba(Theme.accentRose.r, Theme.accentRose.g, Theme.accentRose.b, 0.2) : Theme.bgPill)
                                border.color: ShellState.plasticEnabled ? "transparent" : (backLogsMouse.containsMouse ? Theme.accentRose : Theme.borderDim)
                                border.width: ShellState.plasticEnabled ? 0 : 1

                                LiquidGlassSurface {
                                    radius: 6
                                    visible: ShellState.plasticEnabled && backLogsMouse.containsMouse
                                    accentColor: Theme.accentRose
                                    hovered: backLogsMouse.containsMouse
                                    pressed: backLogsMouse.pressed
                                    showShadow: false
                                }

                                Icon {
                                    anchors.centerIn: parent
                                    name: "x"
                                    size: 12
                                    color: backLogsMouse.containsMouse ? Theme.accentRose : Theme.textMuted
                                }

                                MouseArea {
                                    id: backLogsMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: showLogDrawer = false
                                }
                            }
                        }

                        // Terminal Log Content Viewport
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 8
                            color: Theme.bgBase
                            border.color: Theme.borderDim
                            border.width: 1
                            clip: true

                            Flickable {
                                id: logFlick
                                anchors.fill: parent
                                anchors.margins: 10
                                contentWidth: Math.max(width, logText.implicitWidth)
                                contentHeight: logText.implicitHeight
                                boundsBehavior: Flickable.StopAtBounds
                                clip: true

                                ScrollBar.vertical: ScrollBar {
                                    policy: logFlick.contentHeight > logFlick.height ? ScrollBar.AlwaysOn : ScrollBar.AsNeeded
                                }

                                ScrollBar.horizontal: ScrollBar {
                                    policy: logFlick.contentWidth > logFlick.width ? ScrollBar.AlwaysOn : ScrollBar.AsNeeded
                                }

                                Text {
                                    id: logText
                                    text: DockerService.logsLoading ? "Loading container logs..." : (DockerService.logsContent || "No log output recorded.")
                                    font.family: Theme.fontMono
                                    font.pixelSize: 10
                                    color: DockerService.logsLoading ? Theme.textMuted : Theme.textSecondary
                                    wrapMode: Text.NoWrap
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
                    height: 20
                    implicitWidth: toastText.implicitWidth + 16
                    radius: 10
                    color: Qt.rgba(Theme.accentEmerald.r, Theme.accentEmerald.g, Theme.accentEmerald.b, 0.2)
                    border.color: Theme.accentEmerald
                    border.width: 1

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 5

                        Icon {
                            name: "check"
                            size: 10
                            color: Theme.accentEmerald
                        }

                        Text {
                            id: toastText
                            text: copiedNotificationText
                            font.family: Theme.fontMono
                            font.pixelSize: 8
                            font.bold: true
                            color: Theme.accentEmerald
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: "SUPER + D to toggle  •  ESC to close  •  Click ID to copy  •  CLI launches Kitty"
                    font.family: Theme.fontMono
                    font.pixelSize: 8
                    color: Theme.textMuted
                }
            }
        }
    }
}
